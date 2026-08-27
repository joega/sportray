var DateModel = null;
if (typeof require === "function") DateModel = require("./DateModel.js");

var CACHE_VERSION = 1;
var PAST_DAYS = 30;
var FUTURE_DAYS = 30;
var MAX_FILES = 8 * (PAST_DAYS + FUTURE_DAYS + 1);
var MAX_BYTES = 8 * 1024 * 1024;
var MAX_GAMES_PER_DAY = 64;

function validDate(value) {
  return DateModel ? DateModel.isDateKey(value)
    : typeof value === "string" && /^\d{4}-\d{2}-\d{2}$/.test(value);
}

function addDays(value, days) {
  if (DateModel) return DateModel.addDays(value, days);
  if (!validDate(value)) return "";
  var parts = value.split("-").map(Number);
  var date = new Date(parts[0], parts[1] - 1, parts[2]);
  date.setDate(date.getDate() + Number(days || 0));
  function pad(number) { return number < 10 ? "0" + number : String(number); }
  return date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate());
}

function key(leagueId, dateKey) {
  var league = typeof leagueId === "string" ? leagueId.trim().toLowerCase() : "";
  return /^[a-z0-9.]{1,32}$/.test(league) && validDate(dateKey)
    ? league + ":" + dateKey : "";
}

function fileName(leagueId, dateKey) {
  var value = key(leagueId, dateKey);
  return value ? value.replace(/[^a-z0-9:.-]/gi, "_") + ".json" : "";
}

function keyParts(value) {
  if (typeof value !== "string") return null;
  var parts = value.split(":");
  return parts.length === 2 && key(parts[0], parts[1]) === value
    ? {leagueId: parts[0], dateKey: parts[1]} : null;
}

function inWindow(dateKey, todayDateKey) {
  if (!validDate(dateKey) || !validDate(todayDateKey)) return false;
  return dateKey >= addDays(todayDateKey, -PAST_DAYS)
    && dateKey <= addDays(todayDateKey, FUTURE_DAYS);
}

function safeGame(game) {
  if (!game || typeof game !== "object" || game.isValid !== true
      || typeof game.id !== "string" || !game.id) return null;
  var result = {};
  ["id", "league", "providerGameId", "startTime", "endTime", "status",
    "statusDetail", "period", "periodLabel", "clock", "awayTeam",
    "homeTeam", "awayScore", "homeScore", "venue", "link", "lastUpdated"]
    .forEach(function(field) {
      if (game[field] !== undefined) result[field] = game[field];
    });
  result.isValid = true;
  return result;
}

function sanitizeGames(games) {
  var result = [], seen = {};
  (Array.isArray(games) ? games : []).slice(0, MAX_GAMES_PER_DAY).forEach(function(game) {
    var safe = safeGame(game);
    if (!safe || seen[safe.id]) return;
    seen[safe.id] = true;
    result.push(safe);
  });
  return result;
}

function createDay(leagueId, dateKey, games, updatedAtMs) {
  var id = key(leagueId, dateKey);
  if (!id) return null;
  return {
    cacheVersion: CACHE_VERSION,
    leagueId: id.split(":")[0],
    dateKey: dateKey,
    updatedAtMs: Number(updatedAtMs) || 0,
    games: sanitizeGames(games)
  };
}

function createRetainedDay(leagueId, dateKey, games, updatedAtMs, todayDateKey) {
  if (!inWindow(dateKey, todayDateKey)) return null;
  return createDay(leagueId, dateKey, games, updatedAtMs);
}

function parseDayText(raw, leagueId, dateKey, todayDateKey) {
  if (typeof raw !== "string" || !raw || !inWindow(dateKey, todayDateKey)) return null;
  try {
    var parsed = JSON.parse(raw);
    if (!parsed || parsed.cacheVersion !== CACHE_VERSION
        || parsed.leagueId !== String(leagueId || "").toLowerCase()
        || parsed.dateKey !== dateKey || !Array.isArray(parsed.games)) return null;
    return createDay(parsed.leagueId, dateKey, parsed.games, parsed.updatedAtMs);
  } catch (error) {
    return null;
  }
}

function prune(entries, todayDateKey) {
  var result = {}, keys = Object.keys(entries || {});
  keys.sort(function(left, right) {
    return (Number(entries[right].updatedAtMs) || 0) - (Number(entries[left].updatedAtMs) || 0);
  });
  var bytes = 0, count = 0;
  keys.forEach(function(id) {
    var entry = entries[id];
    if (!entry || !inWindow(entry.dateKey, todayDateKey)) return;
    var serialized = JSON.stringify(entry);
    var size = typeof Buffer !== "undefined" && Buffer.byteLength
      ? Buffer.byteLength(serialized) : serialized.length;
    if (count >= MAX_FILES || bytes + size > MAX_BYTES) return;
    result[id] = entry;
    count++;
    bytes += size;
  });
  return result;
}

function manifest(entries, todayDateKey) {
  var kept = prune(entries, todayDateKey);
  return {cacheVersion: CACHE_VERSION, keys: Object.keys(kept).sort()};
}

// Report whether every retained day needed by the admitted calendar leagues
// is present. The caller supplies only provider-approved league ids; dates
// outside the rolling disk window are deliberately excluded because this
// cache cannot retain them across a restart.
function coverage(entries, leagueIds, dateKeys, todayDateKey) {
  var leagues = [];
  (Array.isArray(leagueIds) ? leagueIds : []).forEach(function(value) {
    var league = typeof value === "string" ? value.trim().toLowerCase() : "";
    if (/^[a-z0-9.]{1,32}$/.test(league) && leagues.indexOf(league) === -1)
      leagues.push(league);
  });
  var dates = [];
  (Array.isArray(dateKeys) ? dateKeys : []).forEach(function(value) {
    if (validDate(value) && inWindow(value, todayDateKey) && dates.indexOf(value) === -1)
      dates.push(value);
  });
  var availableCount = 0;
  leagues.forEach(function(leagueId) {
    dates.forEach(function(dateKey) {
      var id = key(leagueId, dateKey);
      if (id && entries && entries[id]) availableCount++;
    });
  });
  var requiredCount = leagues.length * dates.length;
  return {
    leagueCount: leagues.length,
    dateCount: dates.length,
    requiredCount: requiredCount,
    availableCount: availableCount,
    missingCount: Math.max(0, requiredCount - availableCount),
    needsHydration: requiredCount > 0 && availableCount < requiredCount
  };
}

function shouldRequestRange(coverage, cacheReady) {
  return cacheReady === true && !!coverage && coverage.needsHydration === true;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {CACHE_VERSION, PAST_DAYS, FUTURE_DAYS, MAX_FILES, MAX_BYTES,
    MAX_GAMES_PER_DAY, key, fileName, inWindow, sanitizeGames, createDay,
    createRetainedDay, parseDayText, prune, manifest, keyParts, coverage,
    shouldRequestRange};
}

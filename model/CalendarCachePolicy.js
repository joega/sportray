// Pure bounded state for the low-frequency calendar schedule owner. Provider
// parsing remains in providers/; this module only admits normalized chunks,
// tracks honest coverage, and merges schedule/live projections by game id.

var DateModel = null;
if (typeof require === "function") DateModel = require("./DateModel.js");

var MAX_CACHE_WINDOWS = 24;
var MAX_DAYS = 42;
var MAX_REQUESTS = 8;
var HISTORICAL_TTL_MS = 24 * 60 * 60 * 1000;
var FUTURE_TTL_MS = 6 * 60 * 60 * 1000;

function validDate(value) {
  return DateModel ? DateModel.isDateKey(value)
    : typeof value === "string" && /^\d{4}-\d{2}-\d{2}$/.test(value);
}

function addDays(value, days) {
  if (DateModel) return DateModel.addDays(value, days);
  if (!validDate(value) || !isFinite(Number(days))) return "";
  var parts = value.split("-").map(Number);
  var date = new Date(parts[0], parts[1] - 1, parts[2]);
  if (isNaN(date.getTime()) || date.getFullYear() !== parts[0]
      || date.getMonth() !== parts[1] - 1 || date.getDate() !== parts[2]) return "";
  date.setDate(date.getDate() + Math.trunc(Number(days)));
  function pad(number) { return number < 10 ? "0" + number : String(number); }
  return date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate());
}

function dateRange(startDate, endDate) {
  if (!validDate(startDate) || !validDate(endDate)) return [];
  var result = [];
  var cursor = startDate;
  while (cursor && result.length < MAX_DAYS) {
    result.push(cursor);
    if (cursor === endDate) break;
    cursor = addDays(cursor, 1);
  }
  return result.length > 0 && result[result.length - 1] === endDate ? result : [];
}

function gameId(game) {
  if (!game || typeof game !== "object") return "";
  return typeof game.id === "string" && game.id ? game.id
    : (typeof game.providerGameId === "string" && game.providerGameId
      ? String(game.league || "") + ":" + game.providerGameId : "");
}

function emptyDays(startDate, endDate, state) {
  return dateRange(startDate, endDate).map(function(dateKey) {
    return {dateKey: dateKey, games: [], complete: false, state: state || "unknown"};
  });
}

function createWindow(providerId, startDate, endDate, nowMs) {
  var days = emptyDays(startDate, endDate, "loading");
  return {
    providerId: providerId || "",
    startDate: startDate || "",
    endDate: endDate || "",
    status: "loading",
    stale: false,
    updatedAtMs: Number(nowMs) || 0,
    days: days,
    configurationValid: days.length > 0
  };
}

function mergeGames(existing, additions) {
  var result = Array.isArray(existing) ? existing.slice() : [];
  var seen = {};
  result.forEach(function(game) { var id = gameId(game); if (id) seen[id] = true; });
  (Array.isArray(additions) ? additions : []).forEach(function(game) {
    var id = gameId(game);
    if (!id || seen[id]) return;
    seen[id] = true;
    result.push(game);
  });
  return result;
}

function applyChunk(window, startDate, endDate, parsed, nowMs) {
  var next = createWindow(window && window.providerId, startDate, endDate, nowMs);
  if (next.configurationValid !== true) {
    next.status = "unavailable";
    return next;
  }
  if (!parsed || !Array.isArray(parsed.days) || !Array.isArray(parsed.errors)) {
    next.status = "unavailable";
    next.days = emptyDays(startDate, endDate, "unavailable");
    return next;
  }

  var byDate = {};
  parsed.days.forEach(function(day) {
    if (!day || !validDate(day.dateKey) || !Array.isArray(day.games)) return;
    byDate[day.dateKey] = day.games;
  });
  var hadErrors = parsed.errors.length > 0;
  next.days = dateRange(startDate, endDate).map(function(dateKey) {
    var present = Object.prototype.hasOwnProperty.call(byDate, dateKey);
    return {
      dateKey: dateKey,
      games: present ? byDate[dateKey].slice(0, 256) : [],
      complete: present && !hadErrors,
      state: present && !hadErrors ? "known" : (hadErrors ? "unavailable" : "partial")
    };
  });
  next.status = hadErrors ? "partial" : (next.days.every(function(day) { return day.complete; })
    ? "complete" : "partial");
  next.updatedAtMs = Number(nowMs) || 0;
  return next;
}

function isFresh(window, nowMs, todayDateKey) {
  if (!window || window.status === "loading") return false;
  var age = Math.max(0, Number(nowMs) - Number(window.updatedAtMs || 0));
  var future = validDate(window.startDate) && validDate(todayDateKey)
    && window.startDate >= todayDateKey;
  return age < (future ? FUTURE_TTL_MS : HISTORICAL_TTL_MS);
}

function mergeState(scheduleState, liveState) {
  var source = scheduleState && typeof scheduleState === "object" ? scheduleState : {};
  var live = liveState && typeof liveState === "object" ? liveState : {};
  var byDate = {};
  var order = [];
  function addDay(day) {
    if (!day || !validDate(day.dateKey)) return;
    if (!byDate[day.dateKey]) {
      byDate[day.dateKey] = {dateKey: day.dateKey, games: [], complete: false,
        state: day.state || "unknown", stale: day.stale === true};
      order.push(day.dateKey);
    }
    var target = byDate[day.dateKey];
    target.games = mergeGames(target.games, day.games);
    if (day.complete === true) target.complete = true;
    if (day.state === "unavailable") target.state = "unavailable";
    else if (day.state === "partial" && target.state !== "unavailable") target.state = "partial";
    target.stale = target.stale || day.stale === true;
  }
  (Array.isArray(source.days) ? source.days : []).forEach(addDay);
  (Array.isArray(live.days) ? live.days : []).forEach(addDay);
  return {
    leagueId: source.leagueId || live.leagueId || "",
    displayName: source.displayName || live.displayName || "",
    days: order.map(function(key) { return byDate[key]; }),
    status: source.status || "unknown",
    loading: source.loading === true,
    stale: source.stale === true,
    errorCode: source.errorCode || ""
  };
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    MAX_CACHE_WINDOWS: MAX_CACHE_WINDOWS,
    MAX_DAYS: MAX_DAYS,
    MAX_REQUESTS: MAX_REQUESTS,
    HISTORICAL_TTL_MS: HISTORICAL_TTL_MS,
    FUTURE_TTL_MS: FUTURE_TTL_MS,
    dateRange: dateRange,
    createWindow: createWindow,
    applyChunk: applyChunk,
    isFresh: isFresh,
    mergeState: mergeState,
    gameId: gameId
  };
}

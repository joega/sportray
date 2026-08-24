// Provider-neutral policy for choosing among already normalized, today-scoped
// live favorite games. It describes a bounded result for a caller; it does
// not own a timer, polling, provider data, or QML state.
var MAX_ROTATION_ITEMS = 4;
var DEFAULT_CADENCE_MS = 30 * 1000;
var MIN_CADENCE_MS = 5 * 1000;
var MAX_CADENCE_MS = 5 * 60 * 1000;
var MAX_TIMESTAMP_MS = 8640000000000000;
var DATE_KEY_PATTERN = /^\d{4}-\d{2}-\d{2}$/;
var FAVORITE_ID_PATTERN = /^[a-z0-9.-]{1,24}:[a-z0-9-]{1,32}$/;
var LIVE_STATES = {live: true, intermission: true};

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function isDateKey(value) {
  if (typeof value !== "string" || !DATE_KEY_PATTERN.test(value)) return false;
  var parts = value.split("-").map(Number);
  var date = new Date(parts[0], parts[1] - 1, parts[2]);
  return !isNaN(date.getTime())
    && date.getFullYear() === parts[0]
    && date.getMonth() === parts[1] - 1
    && date.getDate() === parts[2];
}

function dateKeyFromTimestamp(value) {
  if (typeof value !== "string" && !(value instanceof Date)) return "";
  var date = new Date(value);
  if (isNaN(date.getTime())) return "";
  var pad = function(number) { return String(number).length < 2 ? "0" + number : String(number); };
  return date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate());
}

function dayStartMs(dateKey) {
  if (!isDateKey(dateKey)) return 0;
  var parts = dateKey.split("-").map(Number);
  return new Date(parts[0], parts[1] - 1, parts[2]).getTime();
}

function normalizeFavoriteIds(value) {
  if (!Array.isArray(value)) return [];
  var result = [];
  for (var i = 0; i < value.length; i++) {
    if (typeof value[i] !== "string") continue;
    var id = value[i].trim().toLowerCase();
    if (!FAVORITE_ID_PATTERN.test(id) || result.indexOf(id) !== -1) continue;
    result.push(id);
  }
  return result;
}

function teamId(team) {
  if (!isRecord(team) || typeof team.id !== "string") return "";
  var id = team.id.trim().toLowerCase();
  return FAVORITE_ID_PATTERN.test(id) ? id : "";
}

function gameIdentity(game) {
  if (!isRecord(game)) return "";
  if (typeof game.id === "string" && game.id.trim()) return game.id.trim().toLowerCase();
  if (typeof game.providerGameId === "string" && game.providerGameId.trim())
    return game.providerGameId.trim().toLowerCase();
  return "";
}

function isFavoriteGame(game, favoriteIds) {
  if (!isRecord(game)) return false;
  return favoriteIds.indexOf(teamId(game.awayTeam)) !== -1
    || favoriteIds.indexOf(teamId(game.homeTeam)) !== -1;
}

function timestamp(value) {
  if (typeof value !== "string") return Number.POSITIVE_INFINITY;
  var parsed = Date.parse(value);
  return isFinite(parsed) ? parsed : Number.POSITIVE_INFINITY;
}

function compareEntries(left, right) {
  var leftTime = timestamp(left.game.startTime);
  var rightTime = timestamp(right.game.startTime);
  if (leftTime !== rightTime) return leftTime - rightTime;
  var leftIdentity = gameIdentity(left.game);
  var rightIdentity = gameIdentity(right.game);
  if (leftIdentity < rightIdentity) return -1;
  if (leftIdentity > rightIdentity) return 1;
  return left.index - right.index;
}

function normalizeCadenceMs(value) {
  var cadence = Number(value);
  if (!isFinite(cadence) || cadence <= 0) cadence = DEFAULT_CADENCE_MS;
  return Math.max(MIN_CADENCE_MS, Math.min(MAX_CADENCE_MS, Math.floor(cadence)));
}

function normalizeMaxItems(value) {
  var limit = Number(value);
  if (!isFinite(limit) || limit <= 0) limit = MAX_ROTATION_ITEMS;
  return Math.max(1, Math.min(MAX_ROTATION_ITEMS, Math.floor(limit)));
}

function normalizeNowMs(value, fallback) {
  var now = Number(value);
  if (!isFinite(now)) now = Number(fallback);
  if (!isFinite(now)) return 0;
  return Math.max(0, Math.min(MAX_TIMESTAMP_MS, Math.floor(now)));
}

function boundedIndex(nowMs, cadenceMs, count, todayDateKey) {
  if (!(count > 0)) return 0;
  var start = dayStartMs(todayDateKey);
  var elapsed = Math.max(0, normalizeNowMs(nowMs, start) - start);
  var slot = Math.floor(elapsed / cadenceMs);
  return Math.max(0, Math.min(count - 1, slot % count));
}

function emptyResult(source, kind, reason) {
  return {
    kind: kind,
    reason: reason,
    todayDateKey: source.todayDateKey,
    selectedDateKey: source.selectedDateKey,
    rotationGames: [],
    index: 0,
    game: null,
    count: 0,
    cadenceMs: null,
    nextAtMs: null
  };
}

function select(input) {
  var source = isRecord(input) ? input : {};
  var todayDateKey = isDateKey(source.todayDateKey) ? source.todayDateKey : "";
  var selectedDateKey = isDateKey(source.selectedDateKey) ? source.selectedDateKey : "";
  var base = {todayDateKey: todayDateKey, selectedDateKey: selectedDateKey};

  if (!todayDateKey || selectedDateKey !== todayDateKey)
    return emptyResult(base, "not-today", "today-scope");
  if (source.offline === true || (typeof source.errorCode === "string"
      && source.errorCode.trim() !== "" && source.hasData !== true))
    return emptyResult(base, "offline", "unavailable");
  if (source.hasData === false)
    return emptyResult(base, "empty", "no-data");

  var favorites = normalizeFavoriteIds(source.favoriteTeamIds);
  var values = Array.isArray(source.games) ? source.games : [];
  var entries = [];
  for (var i = 0; i < values.length; i++) {
    var game = values[i];
    if (!isRecord(game) || game.isValid === false || !LIVE_STATES[game.status]
        || !gameIdentity(game) || !isFavoriteGame(game, favorites)) continue;
    if (dateKeyFromTimestamp(game.startTime) !== todayDateKey) continue;
    entries.push({game: game, index: i});
  }
  entries.sort(compareEntries);

  var limit = normalizeMaxItems(source.maxItems);
  var rotationGames = entries.slice(0, limit).map(function(entry) { return entry.game; });
  if (rotationGames.length === 0)
    return emptyResult(base, "empty", "no-live-favorite");

  var cadenceMs = normalizeCadenceMs(source.cadenceMs);
  var index = boundedIndex(source.nowMs, cadenceMs, rotationGames.length, todayDateKey);
  var nowMs = normalizeNowMs(source.nowMs, dayStartMs(todayDateKey));
  var start = dayStartMs(todayDateKey);
  var slot = Math.floor(Math.max(0, nowMs - start) / cadenceMs);

  return {
    kind: rotationGames.length > 1 ? "rotation" : "live-favorite",
    reason: "live-favorite",
    todayDateKey: todayDateKey,
    selectedDateKey: selectedDateKey,
    rotationGames: rotationGames,
    index: index,
    game: rotationGames[index],
    count: rotationGames.length,
    cadenceMs: cadenceMs,
    nextAtMs: start + (slot + 1) * cadenceMs
  };
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    MAX_ROTATION_ITEMS: MAX_ROTATION_ITEMS,
    DEFAULT_CADENCE_MS: DEFAULT_CADENCE_MS,
    MIN_CADENCE_MS: MIN_CADENCE_MS,
    MAX_CADENCE_MS: MAX_CADENCE_MS,
    normalizeCadenceMs: normalizeCadenceMs,
    normalizeFavoriteIds: normalizeFavoriteIds,
    gameIdentity: gameIdentity,
    boundedIndex: boundedIndex,
    select: select
  };
}

// Provider-neutral countdown projection for one already normalized favorite
// upcoming game. The caller owns selection, refresh cadence, and timers.
var MAX_LABEL_LENGTH = 24;
var DEFAULT_LABEL_LENGTH = MAX_LABEL_LENGTH;
var MAX_TIMESTAMP_MS = 8640000000000000;
var MINUTE_MS = 60 * 1000;
var HOUR_MS = 60 * MINUTE_MS;
var DAY_MS = 24 * HOUR_MS;
var DATE_KEY_PATTERN = /^\d{4}-\d{2}-\d{2}$/;
var FAVORITE_ID_PATTERN = /^[a-z0-9.-]{1,24}:[a-z0-9-]{1,32}$/;

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
  var date = new Date(value);
  if (isNaN(date.getTime())) return "";
  var pad = function(number) {
    return String(number).length < 2 ? "0" + number : String(number);
  };
  return date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-"
    + pad(date.getDate());
}

function timestampFromGame(game) {
  if (!isRecord(game) || typeof game.startTime !== "string") return null;
  var parsed = Date.parse(game.startTime);
  return isFinite(parsed) ? parsed : null;
}

function finiteTimestamp(value) {
  if (typeof value !== "number" || !isFinite(value)) return null;
  if (value < 0 || value > MAX_TIMESTAMP_MS) return null;
  return Math.floor(value);
}

function normalizeNowMs(value) {
  return finiteTimestamp(value);
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

function isFavoriteGame(game, favoriteIds) {
  if (!isRecord(game)) return false;
  return favoriteIds.indexOf(teamId(game.awayTeam)) !== -1
    || favoriteIds.indexOf(teamId(game.homeTeam)) !== -1;
}

function gameIdentity(game) {
  if (!isRecord(game)) return "";
  if (typeof game.id === "string" && game.id.trim()) return game.id.trim().toLowerCase();
  if (typeof game.providerGameId === "string" && game.providerGameId.trim())
    return game.providerGameId.trim().toLowerCase();
  return "";
}

function capText(value, maxLength) {
  var text = typeof value === "string" ? value.trim() : "";
  var limit = typeof maxLength === "number" && isFinite(maxLength) && maxLength > 0
    ? Math.min(MAX_LABEL_LENGTH, Math.floor(maxLength)) : DEFAULT_LABEL_LENGTH;
  if (text.length <= limit) return text;
  if (limit === 1) return "…";
  return text.slice(0, limit - 1).replace(/\s+$/, "") + "…";
}

function normalizeLabelLength(value) {
  var length = Number(value);
  if (!isFinite(length) || length <= 0) return DEFAULT_LABEL_LENGTH;
  return Math.max(1, Math.min(MAX_LABEL_LENGTH, Math.floor(length)));
}

function futureLabel(remainingMs) {
  if (remainingMs < MINUTE_MS) return "Starts in <1m";
  var totalMinutes = Math.floor(remainingMs / MINUTE_MS);
  var days = Math.floor(totalMinutes / (24 * 60));
  var hours = Math.floor((totalMinutes % (24 * 60)) / 60);
  var minutes = totalMinutes % 60;
  if (days > 0) return "Starts in " + days + "d " + hours + "h";
  if (hours > 0) return "Starts in " + hours + "h " + minutes + "m";
  return "Starts in " + minutes + "m";
}

function identityFields(source) {
  return {
    todayDateKey: isDateKey(source.todayDateKey) ? source.todayDateKey : "",
    selectedDateKey: isDateKey(source.selectedDateKey) ? source.selectedDateKey : ""
  };
}

function emptyResult(source, kind, reason, label) {
  var identity = identityFields(source);
  return {
    kind: kind,
    reason: reason,
    todayDateKey: identity.todayDateKey,
    selectedDateKey: identity.selectedDateKey,
    game: null,
    startTimeMs: null,
    nowMs: normalizeNowMs(source.nowMs),
    remainingMs: null,
    label: capText(label, normalizeLabelLength(source.maxLabelLength))
  };
}

function project(input) {
  var source = isRecord(input) ? input : {};
  var identity = identityFields(source);
  if (!identity.todayDateKey || identity.selectedDateKey !== identity.todayDateKey)
    return emptyResult(source, "not-today", "today-scope", "Today only");

  if (source.offline === true || (typeof source.errorCode === "string"
      && source.errorCode.trim() !== "" && source.hasData !== true)) {
    return emptyResult(source, "offline", "unavailable", "Scores offline");
  }
  if (source.hasData === false)
    return emptyResult(source, "empty", "no-data", "No upcoming favorite");

  var nowMs = normalizeNowMs(source.nowMs);
  if (nowMs === null)
    return emptyResult(source, "invalid", "invalid-now", "Countdown unavailable");

  var game = source.game;
  var favorites = normalizeFavoriteIds(source.favoriteTeamIds);
  if (!isRecord(game) || game.isValid === false || game.status !== "scheduled"
      || !gameIdentity(game) || !isFavoriteGame(game, favorites)) {
    return emptyResult(source, "empty", "no-upcoming-favorite", "No upcoming favorite");
  }

  var startTimeMs = Object.prototype.hasOwnProperty.call(source, "startTimeMs")
    ? finiteTimestamp(source.startTimeMs) : timestampFromGame(game);
  if (startTimeMs === null)
    return emptyResult(source, "invalid", "invalid-start-time", "Countdown unavailable");
  if (dateKeyFromTimestamp(startTimeMs) !== identity.todayDateKey)
    return emptyResult(source, "not-today", "game-date", "Today only");

  var remainingMs = Math.max(0, startTimeMs - nowMs);
  var kind = startTimeMs <= nowMs ? "due" : "future";
  var label = kind === "due" ? "Starting now" : futureLabel(remainingMs);
  return {
    kind: kind,
    reason: "favorite-upcoming",
    todayDateKey: identity.todayDateKey,
    selectedDateKey: identity.selectedDateKey,
    game: game,
    startTimeMs: startTimeMs,
    nowMs: nowMs,
    remainingMs: remainingMs,
    label: capText(label, normalizeLabelLength(source.maxLabelLength))
  };
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    MAX_LABEL_LENGTH: MAX_LABEL_LENGTH,
    MAX_TIMESTAMP_MS: MAX_TIMESTAMP_MS,
    capText: capText,
    normalizeFavoriteIds: normalizeFavoriteIds,
    project: project
  };
}

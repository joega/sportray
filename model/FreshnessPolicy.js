var MIN_STALE_THRESHOLD_MS = 5 * 60 * 1000;
var MAX_STALE_THRESHOLD_MS = 30 * 60 * 1000;
var STALE_INTERVAL_MULTIPLIER = 2;
var DEFAULT_INTERVAL_MS = 10 * 60 * 1000;

var USER_SAFE_ERRORS = {
  configuration: "Scores are unavailable",
  timeout: "Scores are temporarily unavailable",
  unavailable: "Scores are temporarily unavailable",
  "invalid-data": "Scores could not be read",
  "partial-data": "Some scores could not be updated"
};

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function copyGames(value) {
  return Array.isArray(value) ? value.slice() : [];
}

function timestampMs(value) {
  if (typeof value === "number" && isFinite(value)) return value;
  if (value instanceof Date && !isNaN(value.getTime())) return value.getTime();
  if (typeof value === "string") {
    var parsed = Date.parse(value);
    if (isFinite(parsed)) return parsed;
  }
  return null;
}

function isoTimestamp(value) {
  var parsed = timestampMs(value);
  return parsed === null ? "" : new Date(parsed).toISOString();
}

function staleThresholdMs(intervalMs) {
  var interval = Number(intervalMs);
  if (!isFinite(interval) || interval <= 0) interval = DEFAULT_INTERVAL_MS;
  return Math.min(MAX_STALE_THRESHOLD_MS,
    Math.max(MIN_STALE_THRESHOLD_MS, interval * STALE_INTERVAL_MULTIPLIER));
}

function isPastStaleThreshold(lastSuccessAt, now, intervalMs) {
  var success = timestampMs(lastSuccessAt);
  var current = timestampMs(now);
  if (success === null || current === null || current < success) return false;
  return current - success > staleThresholdMs(intervalMs);
}

function userSafeError(code) {
  return USER_SAFE_ERRORS[code] || "Scores are temporarily unavailable";
}

function baseState(state) {
  var source = isRecord(state) ? state : {};
  return {
    games: copyGames(source.games),
    lastKnownGames: copyGames(source.lastKnownGames || source.games),
    hasData: source.hasData === true,
    loading: source.loading === true,
    stale: source.stale === true,
    errorCode: typeof source.errorCode === "string" ? source.errorCode : "",
    errorSummary: typeof source.errorSummary === "string" ? source.errorSummary : "",
    partialErrorCount: Number(source.partialErrorCount) || 0,
    lastAttemptAt: typeof source.lastAttemptAt === "string" ? source.lastAttemptAt : "",
    lastSuccessAt: typeof source.lastSuccessAt === "string" ? source.lastSuccessAt : ""
  };
}

function beginAttempt(state, attemptedAt) {
  var next = baseState(state);
  next.loading = true;
  next.errorCode = "";
  next.errorSummary = "";
  next.partialErrorCount = 0;
  next.lastAttemptAt = isoTimestamp(attemptedAt);
  return next;
}

function applySuccess(state, nextGames, succeededAt) {
  var next = baseState(state);
  next.games = copyGames(nextGames);
  next.lastKnownGames = copyGames(nextGames);
  next.hasData = true;
  next.loading = false;
  next.stale = false;
  next.errorCode = "";
  next.errorSummary = "";
  next.partialErrorCount = 0;
  next.lastSuccessAt = isoTimestamp(succeededAt);
  return next;
}

function applyFailure(state, code) {
  var next = baseState(state);
  next.loading = false;
  next.errorCode = typeof code === "string" && code !== "" ? code : "unavailable";
  next.errorSummary = userSafeError(next.errorCode);
  next.partialErrorCount = 0;
  next.stale = next.hasData;
  return next;
}

function applyPartial(state, partialGames, errorCount) {
  var next = baseState(state);
  var usableGames = copyGames(partialGames);
  if (!next.hasData && usableGames.length > 0) {
    next.games = usableGames;
    next.lastKnownGames = usableGames.slice();
    next.hasData = true;
  }
  next.loading = false;
  next.stale = next.hasData;
  next.errorCode = "partial-data";
  next.errorSummary = userSafeError(next.errorCode);
  next.partialErrorCount = Math.max(1, Number(errorCount) || 0);
  return next;
}

function effectiveStale(state, now, intervalMs) {
  var current = baseState(state);
  if (!current.hasData) return false;
  return current.stale || isPastStaleThreshold(current.lastSuccessAt, now, intervalMs);
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    MIN_STALE_THRESHOLD_MS: MIN_STALE_THRESHOLD_MS,
    MAX_STALE_THRESHOLD_MS: MAX_STALE_THRESHOLD_MS,
    STALE_INTERVAL_MULTIPLIER: STALE_INTERVAL_MULTIPLIER,
    DEFAULT_INTERVAL_MS: DEFAULT_INTERVAL_MS,
    staleThresholdMs: staleThresholdMs,
    isPastStaleThreshold: isPastStaleThreshold,
    userSafeError: userSafeError,
    beginAttempt: beginAttempt,
    applySuccess: applySuccess,
    applyFailure: applyFailure,
    applyPartial: applyPartial,
    effectiveStale: effectiveStale
  };
}

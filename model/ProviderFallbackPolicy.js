// Provider-neutral policy for ordered per-league provider fallback chains.
// It describes a deterministic decision from caller-supplied health state; it
// owns no timer, request, settings value, provider parsing, or QML state.
var MAX_CANDIDATES = 4;
var FAILURE_THRESHOLD = 3;
var COOLDOWN_MS = 15 * 60 * 1000;
var PROVIDER_ID_PATTERN = /^[a-z0-9][a-z0-9-]{0,31}$/;
var LEAGUE_ID_PATTERN = /^[a-z0-9][a-z0-9.-]{0,31}$/;
var MAX_TIMESTAMP_MS = 8640000000000000;

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function normalizeProviderId(value) {
  if (typeof value !== "string") return "";
  var id = value.trim().toLowerCase();
  return PROVIDER_ID_PATTERN.test(id) ? id : "";
}

function normalizeLeagueId(value) {
  if (typeof value !== "string") return "";
  var id = value.trim().toLowerCase();
  return LEAGUE_ID_PATTERN.test(id) ? id : "";
}

// Every candidate must be a valid unique provider id (plain string or a
// record with an `id` string); any malformed entry fails closed. The first
// entry is the league's primary provider.
function normalizeCandidates(value) {
  if (!Array.isArray(value)) return null;
  if (value.length < 1 || value.length > MAX_CANDIDATES) return null;
  var ids = [];
  for (var i = 0; i < value.length; i++) {
    var entry = value[i];
    var id = typeof entry === "string"
      ? normalizeProviderId(entry)
      : (isRecord(entry) ? normalizeProviderId(entry.id) : "");
    if (!id || ids.indexOf(id) !== -1) return null;
    ids.push(id);
  }
  return ids;
}

function normalizeTimestampMs(value) {
  var time = typeof value === "string" ? Date.parse(value) : Number(value);
  if (!isFinite(time) || time < 0) return 0;
  return Math.min(MAX_TIMESTAMP_MS, Math.floor(time));
}

function normalizeNowMs(value) {
  var now = Number(value);
  if (!isFinite(now) || now < 0) return -1;
  return Math.min(MAX_TIMESTAMP_MS, Math.floor(now));
}

// Keeps only finite, bounded failure records keyed by known candidates.
function normalizeHealth(value, candidateIds) {
  var source = isRecord(value) ? value : {};
  var health = {};
  for (var i = 0; i < candidateIds.length; i++) {
    var id = candidateIds[i];
    var state = isRecord(source[id]) ? source[id] : null;
    if (!state) continue;
    var count = Number(state.consecutiveFailures);
    if (!isFinite(count) || count <= 0) continue;
    health[id] = {
      consecutiveFailures: Math.min(FAILURE_THRESHOLD, Math.floor(count)),
      lastFailureAtMs: normalizeTimestampMs(state.lastFailureAtMs)
    };
  }
  return health;
}

// A provider at or beyond the failure threshold stays skipped until its
// cooldown expires, which gives it one bounded retry opportunity.
function isCoolingDown(state, nowMs) {
  if (!isRecord(state)) return false;
  var count = Number(state.consecutiveFailures);
  if (!isFinite(count) || count < FAILURE_THRESHOLD) return false;
  var elapsed = normalizeNowMs(nowMs) - normalizeTimestampMs(state.lastFailureAtMs);
  return elapsed >= 0 && elapsed < COOLDOWN_MS;
}

function baseResult(leagueId, kind, reason) {
  return {
    kind: kind,
    reason: reason,
    leagueId: leagueId,
    providerId: null,
    index: -1,
    attempted: [],
    cooldownMs: COOLDOWN_MS
  };
}

function evaluate(input) {
  var source = isRecord(input) ? input : {};
  var leagueId = normalizeLeagueId(source.leagueId);
  if (!leagueId) return baseResult("", "invalid", "league-id");
  var candidates = normalizeCandidates(source.candidates);
  if (!candidates) return baseResult(leagueId, "invalid", "candidates");
  var nowMs = normalizeNowMs(source.nowMs);
  if (nowMs < 0) return baseResult(leagueId, "invalid", "now-ms");
  var current = typeof source.currentProviderId === "string"
    ? normalizeProviderId(source.currentProviderId)
    : "";
  if (typeof source.currentProviderId === "string" && !current)
    return baseResult(leagueId, "invalid", "current-provider-id");

  // An unknown current provider id cannot describe this league's chain.
  if (current && candidates.indexOf(current) === -1)
    return baseResult(leagueId, "invalid", "current-provider-id");

  var health = normalizeHealth(source.health, candidates);

  var eligibleIndexes = [];
  for (var i = 0; i < candidates.length; i++) {
    if (!isCoolingDown(health[candidates[i]], nowMs)) eligibleIndexes.push(i);
  }

  var attempted = [];
  for (var j = 0; j < candidates.length; j++) {
    if (eligibleIndexes.indexOf(j) === -1) attempted.push(candidates[j]);
  }

  if (eligibleIndexes.length === 0) {
    var exhausted = baseResult(leagueId, "exhausted", "all-providers-cooling");
    exhausted.attempted = candidates.slice();
    return exhausted;
  }

  var choiceIndex = eligibleIndexes[0];
  var choiceId = candidates[choiceIndex];
  var kind = current
    ? (current === choiceId ? "current" : "fallback")
    : (choiceIndex === 0 ? "primary" : "fallback");
  var reason = kind === "current" ? "current-healthy" : "next-healthy";

  return {
    kind: kind,
    reason: reason,
    leagueId: leagueId,
    providerId: choiceId,
    index: choiceIndex,
    attempted: attempted,
    cooldownMs: COOLDOWN_MS
  };
}

// Pure failure/success bookkeeping helpers; each returns a new state object
// so callers own storage. Failure counts are capped at FAILURE_THRESHOLD.
function recordFailure(health, providerId, nowMs) {
  var source = isRecord(health) ? health : {};
  var id = normalizeProviderId(providerId);
  var time = normalizeTimestampMs(nowMs);
  if (!id) return source;
  var previous = isRecord(source[id]) ? source[id] : {};
  var count = Number(previous.consecutiveFailures);
  var nextCount = isFinite(count) && count > 0
    ? Math.min(FAILURE_THRESHOLD, Math.floor(count) + 1)
    : 1;
  var next = {};
  for (var key in source) {
    if (Object.prototype.hasOwnProperty.call(source, key) && key !== id)
      next[key] = source[key];
  }
  next[id] = {consecutiveFailures: nextCount, lastFailureAtMs: time};
  return next;
}

function recordSuccess(health, providerId) {
  var source = isRecord(health) ? health : {};
  var id = normalizeProviderId(providerId);
  if (!id) return source;
  var next = {};
  for (var key in source) {
    if (Object.prototype.hasOwnProperty.call(source, key) && key !== id)
      next[key] = source[key];
  }
  return next;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    MAX_CANDIDATES: MAX_CANDIDATES,
    FAILURE_THRESHOLD: FAILURE_THRESHOLD,
    COOLDOWN_MS: COOLDOWN_MS,
    normalizeCandidates: normalizeCandidates,
    normalizeHealth: normalizeHealth,
    isCoolingDown: isCoolingDown,
    evaluate: evaluate,
    recordFailure: recordFailure,
    recordSuccess: recordSuccess
  };
}

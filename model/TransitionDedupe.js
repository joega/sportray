var SCHEMA_VERSION = 1;
var MAX_FINGERPRINTS = 128;
var MAX_FINGERPRINT_LENGTH = 192;
var DEFAULT_MAX_AGE_MS = 7 * 24 * 60 * 60 * 1000;

var EVENT_TYPES = {
  GAME_START: "game-start",
  SCORE_CHANGE: "score-change",
  GAME_FINAL: "game-final",
  PREGAME_REMINDER: "pregame-reminder",
  CLOSE_GAME: "close-game"
};

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function integer(value) {
  return typeof value === "number" && isFinite(value) && Math.floor(value) === value;
}

function nowMs(value) {
  if (integer(value) && value >= 0) return value;
  return Date.now();
}

function option(value, fallback, minimum) {
  return integer(value) && value >= minimum ? value : fallback;
}

function limits(options) {
  var source = isRecord(options) ? options : {};
  return {
    maxFingerprints: option(source.maxFingerprints, MAX_FINGERPRINTS, 1),
    maxAgeMs: option(source.maxAgeMs, DEFAULT_MAX_AGE_MS, 0)
  };
}

function createDefaults() {
  return {
    schemaVersion: SCHEMA_VERSION,
    fingerprints: []
  };
}

function validFingerprint(value) {
  return typeof value === "string" && value.trim() !== ""
    && value.length <= MAX_FINGERPRINT_LENGTH
    && !/[\u0000-\u001f\u007f]/.test(value);
}

function validEntry(value, currentTime) {
  return isRecord(value) && validFingerprint(value.fingerprint)
    && integer(value.seenAt) && value.seenAt >= 0 && value.seenAt <= currentTime;
}

function compareEntries(left, right) {
  if (left.seenAt !== right.seenAt) return left.seenAt - right.seenAt;
  return left.fingerprint < right.fingerprint ? -1 : left.fingerprint > right.fingerprint ? 1 : 0;
}

function normalizedEntries(value, currentTime, configuredLimits) {
  var byFingerprint = Object.create(null);
  var entries = [];
  var source = isRecord(value) && Array.isArray(value.fingerprints) ? value.fingerprints : [];

  for (var i = 0; i < source.length; i++) {
    var candidate = source[i];
    if (!validEntry(candidate, currentTime)) continue;
    var fingerprint = candidate.fingerprint.trim();
    if (currentTime - candidate.seenAt > configuredLimits.maxAgeMs) continue;

    var existing = byFingerprint[fingerprint];
    if (!existing || candidate.seenAt > existing.seenAt) {
      var entry = { fingerprint: fingerprint, seenAt: candidate.seenAt };
      if (!existing) entries.push(entry);
      byFingerprint[fingerprint] = entry;
    }
  }

  entries.sort(compareEntries);
  if (entries.length > configuredLimits.maxFingerprints)
    entries = entries.slice(entries.length - configuredLimits.maxFingerprints);
  return entries;
}

function normalizeState(value, currentTime, options) {
  var time = nowMs(currentTime);
  var configuredLimits = limits(options);
  var defaults = createDefaults();
  if (!isRecord(value) || value.schemaVersion !== SCHEMA_VERSION) {
    return {
      state: defaults,
      status: isRecord(value) ? "unsupported-schema" : "missing",
      recovered: true,
      changed: true
    };
  }

  var source = Array.isArray(value.fingerprints) ? value.fingerprints : [];
  var malformed = !Array.isArray(value.fingerprints);
  for (var i = 0; i < source.length; i++) {
    if (!validEntry(source[i], time)) malformed = true;
  }
  var normalized = {
    schemaVersion: SCHEMA_VERSION,
    fingerprints: normalizedEntries(value, time, configuredLimits)
  };
  return {
    state: normalized,
    status: malformed ? "recovered" : "valid",
    recovered: malformed,
    changed: JSON.stringify(value) !== JSON.stringify(normalized)
  };
}

function eventGameId(event) {
  if (!isRecord(event) || typeof event.gameId !== "string") return null;
  var gameId = event.gameId.trim();
  if (!gameId || gameId.length > 128 || /[\u0000-\u001f\u007f]/.test(gameId)) return null;
  return gameId;
}

function score(value) {
  return integer(value) && value >= 0 ? value : null;
}

function fingerprintForEvent(event) {
  var gameId = eventGameId(event);
  if (!gameId || !isRecord(event)) return null;

  if (event.type === EVENT_TYPES.GAME_START) return gameId + ":start";
  if (event.type === EVENT_TYPES.GAME_FINAL) return gameId + ":final";
  if (event.type === EVENT_TYPES.PREGAME_REMINDER) return gameId + ":pregame";
  if (event.type === EVENT_TYPES.CLOSE_GAME) return gameId + ":close";
  if (event.type === EVENT_TYPES.SCORE_CHANGE) {
    var awayScore = score(event.awayScore);
    var homeScore = score(event.homeScore);
    if (awayScore === null || homeScore === null) return null;
    return gameId + ":score:" + awayScore + ":" + homeScore;
  }
  return null;
}

function acceptEvents(state, events, currentTime, options) {
  var time = nowMs(currentTime);
  var configuredLimits = limits(options);
  var normalized = normalizeState(state, time, configuredLimits);
  var entries = normalized.state.fingerprints.slice();
  var known = Object.create(null);
  for (var i = 0; i < entries.length; i++) known[entries[i].fingerprint] = true;

  var accepted = [];
  var source = Array.isArray(events) ? events : [];
  for (var j = 0; j < source.length; j++) {
    var fingerprint = fingerprintForEvent(source[j]);
    if (!fingerprint || known[fingerprint]) continue;
    known[fingerprint] = true;
    entries.push({ fingerprint: fingerprint, seenAt: time });
    accepted.push(source[j]);
  }

  var next = normalizeState({
    schemaVersion: SCHEMA_VERSION,
    fingerprints: entries
  }, time, configuredLimits);
  return {
    events: accepted,
    state: next.state,
    changed: normalized.changed || accepted.length > 0 || next.changed
  };
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    SCHEMA_VERSION: SCHEMA_VERSION,
    MAX_FINGERPRINTS: MAX_FINGERPRINTS,
    DEFAULT_MAX_AGE_MS: DEFAULT_MAX_AGE_MS,
    EVENT_TYPES: EVENT_TYPES,
    createDefaults: createDefaults,
    normalizeState: normalizeState,
    fingerprintForEvent: fingerprintForEvent,
    acceptEvents: acceptEvents
  };
}

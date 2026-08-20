var STARTING_SOON_WINDOW_MS = 10 * 60 * 1000;
var LIVE_FAVORITE_INTERVAL_MS = 30 * 1000;
var PANEL_LIVE_INTERVAL_MS = 20 * 1000;
var BACKGROUND_LIVE_INTERVAL_MS = 2 * 60 * 1000;
var STARTING_SOON_INTERVAL_MS = 2 * 60 * 1000;
var NEAR_GAME_INTERVAL_MS = 10 * 60 * 1000;
var PREGAME_WINDOW_MS = 10 * 60 * 1000;
var SCHEDULE_RECHECK_MAX_INTERVAL_MS = 12 * 60 * 60 * 1000;
var EMPTY_INTERVAL_MS = 6 * 60 * 60 * 1000;
var FINAL_BASE_INTERVAL_MS = 6 * 60 * 60 * 1000;
var FINAL_JITTER_MS = 0;
var FINAL_MIN_INTERVAL_MS = FINAL_BASE_INTERVAL_MS;
var FINAL_MAX_INTERVAL_MS = FINAL_BASE_INTERVAL_MS;
var HISTORICAL_INTERVAL_MS = 24 * 60 * 60 * 1000;
var UNKNOWN_INTERVAL_MS = 30 * 60 * 1000;
var RETRY_BASE_INTERVAL_MS = 60 * 1000;
var RETRY_MAX_INTERVAL_MS = 30 * 60 * 1000;
var JITTER_RATIO = 0.10;
var MAX_JITTER_MS = 5 * 60 * 1000;
// Kept as a compatibility export for freshness callers and older tests.
var IDLE_INTERVAL_MS = EMPTY_INTERVAL_MS;

var IMMEDIATE_REFRESH_REASONS = {
  initialization: true,
  manual: true,
  "enabled-leagues-changed": true,
  "date-changed": true
};

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function normalizeFavoriteIds(value) {
  if (!Array.isArray(value)) return [];
  var result = [];
  for (var i = 0; i < value.length; i++) {
    if (typeof value[i] !== "string") continue;
    var id = value[i].trim().toLowerCase();
    if (!/^[a-z0-9.-]{1,24}:[a-z0-9-]{1,32}$/.test(id)) continue;
    if (result.indexOf(id) === -1) result.push(id);
  }
  return result;
}

function teamId(team) {
  if (!isRecord(team) || typeof team.id !== "string") return null;
  return team.id.trim().toLowerCase();
}

function isFavoriteGame(game, favoriteIds) {
  if (!isRecord(game)) return false;
  var favorites = normalizeFavoriteIds(favoriteIds);
  return favorites.indexOf(teamId(game.awayTeam)) !== -1
    || favorites.indexOf(teamId(game.homeTeam)) !== -1;
}

function isLiveGame(game) {
  return isRecord(game) && (game.status === "live" || game.status === "intermission");
}

function timestamp(value) {
  if (typeof value !== "string") return Number.POSITIVE_INFINITY;
  var parsed = Date.parse(value);
  return isFinite(parsed) ? parsed : Number.POSITIVE_INFINITY;
}

function nowTimestamp(value) {
  if (typeof value === "number" && isFinite(value)) return value;
  if (value instanceof Date && !isNaN(value.getTime())) return value.getTime();
  if (typeof value === "string") {
    var parsed = Date.parse(value);
    if (isFinite(parsed)) return parsed;
  }
  return Date.now();
}

function hasLiveGame(games) {
  return games.some(isLiveGame);
}

function hasLiveFavorite(games, favorites) {
  return games.some(function(game) {
    return isLiveGame(game) && isFavoriteGame(game, favorites);
  });
}

function hasFavoriteStartingSoon(games, favorites, now) {
  return games.some(function(game) {
    if (!isRecord(game) || game.status !== "scheduled" || !isFavoriteGame(game, favorites))
      return false;
    var start = timestamp(game.startTime);
    return start !== Number.POSITIVE_INFINITY
      && start >= now && start <= now + STARTING_SOON_WINDOW_MS;
  });
}

function allGamesFinal(games) {
  return games.length > 0 && games.every(function(game) {
    return isRecord(game) && game.status === "final";
  });
}

function earliestScheduledStart(games) {
  var earliest = Number.POSITIVE_INFINITY;
  games.forEach(function(game) {
    if (!isRecord(game) || game.status !== "scheduled") return;
    earliest = Math.min(earliest, timestamp(game.startTime));
  });
  return earliest;
}

function isDateKey(value) {
  return typeof value === "string" && /^\d{4}-\d{2}-\d{2}$/.test(value);
}

function seedForGames(games) {
  var values = Array.isArray(games) ? games : [];
  var text = values.map(function(game) {
    if (!isRecord(game)) return "";
    return String(game.id || game.providerGameId || "") + ":" + String(game.status || "");
  }).join("|");
  var hash = 2166136261;
  for (var i = 0; i < text.length; i++) {
    hash ^= text.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}

function finalJitterMs(seed) {
  var value = Number(seed);
  if (!isFinite(value)) value = 0;
  value = Math.abs(Math.floor(value));
  return value % (FINAL_JITTER_MS + 1);
}

function selectCadence(games, favoriteTeamIds, panelOpen, now, jitterSeed,
    selectedDateKey, todayDateKey) {
  var values = Array.isArray(games) ? games.filter(isRecord) : [];
  var favorites = normalizeFavoriteIds(favoriteTeamIds);
  var currentTime = nowTimestamp(now);

  if (isDateKey(selectedDateKey) && isDateKey(todayDateKey)
      && selectedDateKey < todayDateKey) {
    return {kind: "historical", intervalMs: HISTORICAL_INTERVAL_MS};
  }

  if (panelOpen === true && hasLiveGame(values)) {
    return {kind: "panel-live", intervalMs: PANEL_LIVE_INTERVAL_MS};
  }
  if (hasLiveFavorite(values, favorites)) {
    return {kind: "live-favorite", intervalMs: LIVE_FAVORITE_INTERVAL_MS};
  }
  if (hasLiveGame(values)) {
    return {kind: "background-live", intervalMs: BACKGROUND_LIVE_INTERVAL_MS};
  }
  if (hasFavoriteStartingSoon(values, favorites, currentTime)) {
    return {kind: "favorite-starting-soon", intervalMs: STARTING_SOON_INTERVAL_MS};
  }

  var nextStart = earliestScheduledStart(values);
  if (nextStart !== Number.POSITIVE_INFINITY) {
    var untilPregame = nextStart - currentTime - PREGAME_WINDOW_MS;
    if (untilPregame > 0) {
      return {
        kind: "scheduled-cached",
        intervalMs: Math.min(SCHEDULE_RECHECK_MAX_INTERVAL_MS, untilPregame)
      };
    }
    return {
      kind: panelOpen === true ? "panel-pregame" : "pregame",
      intervalMs: panelOpen === true ? STARTING_SOON_INTERVAL_MS : NEAR_GAME_INTERVAL_MS
    };
  }
  if (allGamesFinal(values)) {
    return {
      kind: "final",
      intervalMs: FINAL_BASE_INTERVAL_MS + finalJitterMs(jitterSeed)
    };
  }
  if (values.length === 0) return {kind: "empty", intervalMs: EMPTY_INTERVAL_MS};
  return {kind: "unknown", intervalMs: UNKNOWN_INTERVAL_MS};
}

function retryDelayMs(failureCount) {
  var count = Number(failureCount);
  if (!isFinite(count) || count < 1) count = 1;
  count = Math.floor(count);
  return Math.min(RETRY_MAX_INTERVAL_MS,
    RETRY_BASE_INTERVAL_MS * Math.pow(2, Math.min(count - 1, 20)));
}

function spreadIntervalMs(intervalMs, jitterUnit) {
  var interval = Number(intervalMs);
  if (!isFinite(interval) || interval <= 0) interval = UNKNOWN_INTERVAL_MS;
  var unit = Number(jitterUnit);
  if (!isFinite(unit)) unit = 0;
  unit = Math.max(0, Math.min(1, unit));
  return Math.round(interval + Math.min(interval * JITTER_RATIO, MAX_JITTER_MS) * unit);
}

function isRequestDue(state, reason, now) {
  var source = isRecord(state) ? state : {};
  var current = nowTimestamp(now);
  if (reason === "manual") return true;

  var failures = Number(source.consecutiveFailures) || 0;
  if (failures > 0) return current >= (Number(source.retryNotBeforeMs) || 0);
  if (source.hasData !== true || !(Number(source.lastSuccessMs) > 0)) return true;

  var cadence = selectCadence(source.games, source.favoriteTeamIds,
    source.panelOpen === true, current, seedForGames(source.games),
    source.selectedDateKey, source.todayDateKey);
  var dueAt = Number(source.nextEligibleAtMs) || 0;
  if (cadence.kind !== "scheduled-cached") {
    var cadenceDueAt = Number(source.lastSuccessMs)
      + spreadIntervalMs(cadence.intervalMs, source.jitterUnit);
    dueAt = dueAt > 0 ? Math.min(dueAt, cadenceDueAt) : cadenceDueAt;
  }
  return current >= dueAt;
}

function isImmediateRefreshTrigger(reason) {
  return typeof reason === "string" && IMMEDIATE_REFRESH_REASONS[reason] === true;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    STARTING_SOON_WINDOW_MS: STARTING_SOON_WINDOW_MS,
    LIVE_FAVORITE_INTERVAL_MS: LIVE_FAVORITE_INTERVAL_MS,
    PANEL_LIVE_INTERVAL_MS: PANEL_LIVE_INTERVAL_MS,
    BACKGROUND_LIVE_INTERVAL_MS: BACKGROUND_LIVE_INTERVAL_MS,
    STARTING_SOON_INTERVAL_MS: STARTING_SOON_INTERVAL_MS,
    NEAR_GAME_INTERVAL_MS: NEAR_GAME_INTERVAL_MS,
    PREGAME_WINDOW_MS: PREGAME_WINDOW_MS,
    SCHEDULE_RECHECK_MAX_INTERVAL_MS: SCHEDULE_RECHECK_MAX_INTERVAL_MS,
    EMPTY_INTERVAL_MS: EMPTY_INTERVAL_MS,
    IDLE_INTERVAL_MS: IDLE_INTERVAL_MS,
    FINAL_BASE_INTERVAL_MS: FINAL_BASE_INTERVAL_MS,
    FINAL_JITTER_MS: FINAL_JITTER_MS,
    FINAL_MIN_INTERVAL_MS: FINAL_MIN_INTERVAL_MS,
    FINAL_MAX_INTERVAL_MS: FINAL_MAX_INTERVAL_MS,
    HISTORICAL_INTERVAL_MS: HISTORICAL_INTERVAL_MS,
    UNKNOWN_INTERVAL_MS: UNKNOWN_INTERVAL_MS,
    RETRY_BASE_INTERVAL_MS: RETRY_BASE_INTERVAL_MS,
    RETRY_MAX_INTERVAL_MS: RETRY_MAX_INTERVAL_MS,
    JITTER_RATIO: JITTER_RATIO,
    MAX_JITTER_MS: MAX_JITTER_MS,
    IMMEDIATE_REFRESH_REASONS: IMMEDIATE_REFRESH_REASONS,
    finalJitterMs: finalJitterMs,
    isImmediateRefreshTrigger: isImmediateRefreshTrigger,
    isRequestDue: isRequestDue,
    retryDelayMs: retryDelayMs,
    selectCadence: selectCadence,
    seedForGames: seedForGames,
    spreadIntervalMs: spreadIntervalMs
  };
}

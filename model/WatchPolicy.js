var MAX_WATCHES = 32;
var HARD_MAX_AGE_MS = 30 * 24 * 60 * 60 * 1000;
var TERMINAL_RECOVERY_MS = 6 * 60 * 60 * 1000;

function isRecord(value) { return value !== null && typeof value === "object" && !Array.isArray(value); }
function clean(value, max) {
  if (typeof value !== "string") return null;
  var result = value.trim();
  return result && result.length <= max && !/[\u0000-\u001f\u007f]/.test(result) ? result : null;
}
function timestamp(value) {
  var result = clean(value, 40);
  if (!result) return null;
  var date = new Date(result);
  return isNaN(date.getTime()) ? null : date.toISOString();
}
function nowMs(value) { return typeof value === "number" && isFinite(value) && value >= 0 ? value : Date.now(); }

function normalizeEntry(value) {
  if (!isRecord(value)) return null;
  var gameId = clean(value.gameId, 128);
  var league = clean(value.league, 32);
  var providerGameId = clean(value.providerGameId, 96);
  var startTime = timestamp(value.startTime);
  var createdAt = timestamp(value.createdAt);
  var expiresAt = timestamp(value.expiresAt);
  if (!gameId || !league || !providerGameId || !startTime || !createdAt || !expiresAt
      || gameId.toLowerCase() !== league.toLowerCase() + ":" + providerGameId.toLowerCase()) return null;
  return {
    gameId: gameId.toLowerCase(), league: league.toLowerCase(), providerGameId: providerGameId.toLowerCase(),
    startTime: startTime, createdAt: createdAt, expiresAt: expiresAt,
    status: value.status === "expired" || value.expired === true ? "expired" : "active"
  };
}

function expiry(entry, currentTime, game) {
  var now = nowMs(currentTime);
  if (entry.status === "expired" || now >= Date.parse(entry.expiresAt)
      || now >= Date.parse(entry.createdAt) + HARD_MAX_AGE_MS) return "expired";
  // Terminal observations get a recovery window when W2 supplies the observed
  // transition; the persisted expiry remains the hard safety bound in W1.
  if (isRecord(game) && (game.status === "final" || game.status === "canceled")) return "active";
  return "active";
}

function normalizeWatches(value, currentTime, gamesById) {
  var source = Array.isArray(value) ? value : [];
  var byId = Object.create(null), recovered = !Array.isArray(value);
  for (var i = 0; i < source.length; i++) {
    var entry = normalizeEntry(source[i]);
    if (!entry) { recovered = true; continue; }
    entry.status = expiry(entry, currentTime, isRecord(gamesById) ? gamesById[entry.gameId] : null);
    var observedGame = isRecord(gamesById) ? gamesById[entry.gameId] : null;
    if (isRecord(observedGame) && (observedGame.status === "final" || observedGame.status === "canceled")) {
      var recoveryExpiry = new Date(nowMs(currentTime) + TERMINAL_RECOVERY_MS).toISOString();
      if (Date.parse(entry.expiresAt) > Date.parse(recoveryExpiry)) entry.expiresAt = recoveryExpiry;
    }
    var existing = byId[entry.gameId];
    if (!existing || Date.parse(entry.createdAt) > Date.parse(existing.createdAt)) byId[entry.gameId] = entry;
    if (JSON.stringify(source[i]) !== JSON.stringify(entry)) recovered = true;
  }
  var watches = Object.keys(byId).map(function(id) { return byId[id]; });
  watches.sort(function(a, b) { return Date.parse(a.createdAt) - Date.parse(b.createdAt) || a.gameId.localeCompare(b.gameId); });
  if (watches.length > MAX_WATCHES) { watches = watches.slice(watches.length - MAX_WATCHES); recovered = true; }
  return {watches: watches, recovered: recovered, changed: recovered || JSON.stringify(value) !== JSON.stringify(watches)};
}

function createWatch(game, createdAt, currentTime) {
  if (!isRecord(game)) return null;
  var league = clean(game.league, 32), providerGameId = clean(game.providerGameId, 96);
  var startTime = timestamp(game.startTime), created = timestamp(createdAt) || new Date(nowMs(currentTime)).toISOString();
  if (!league || !providerGameId || !startTime) return null;
  return normalizeEntry({
    gameId: league + ":" + providerGameId, league: league, providerGameId: providerGameId,
    startTime: startTime, createdAt: created,
    expiresAt: new Date(Date.parse(created) + HARD_MAX_AGE_MS).toISOString(), status: "active"
  });
}

if (typeof module !== "undefined" && module.exports) module.exports = {
  MAX_WATCHES: MAX_WATCHES, HARD_MAX_AGE_MS: HARD_MAX_AGE_MS,
  TERMINAL_RECOVERY_MS: TERMINAL_RECOVERY_MS, normalizeEntry: normalizeEntry,
  normalizeWatches: normalizeWatches, createWatch: createWatch, expiry: expiry
};

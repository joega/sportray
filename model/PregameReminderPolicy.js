var MAX_LEAD_TIME_MS = 30 * 60 * 1000;

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function integer(value) {
  return typeof value === "number" && isFinite(value) && Math.floor(value) === value;
}

function pad(value) {
  var text = String(value);
  return text.length < 2 ? "0" + text : text;
}

function localDateKey(timestampMs) {
  var date = new Date(timestampMs);
  if (isNaN(date.getTime())) return "";
  var year = date.getFullYear();
  var month = pad(date.getMonth() + 1);
  var day = pad(date.getDate());
  return year + "-" + month + "-" + day;
}

function notificationsFor(settings) {
  var source = isRecord(settings) && isRecord(settings.notifications)
    ? settings.notifications : {};
  return {enabled: source.enabled === true, pregameReminder: source.pregameReminder === true};
}

function favoriteTeamIds(settings) {
  var source = isRecord(settings) && Array.isArray(settings.favoriteTeamIds)
    ? settings.favoriteTeamIds : [];
  return source.map(function(value) {
    return typeof value === "string" ? value.trim().toLowerCase() : "";
  }).filter(function(value) { return value !== ""; });
}

function isFavorite(game, favorites) {
  if (!isRecord(game)) return false;
  var awayId = isRecord(game.awayTeam) && typeof game.awayTeam.id === "string"
    ? game.awayTeam.id.trim().toLowerCase() : "";
  var homeId = isRecord(game.homeTeam) && typeof game.homeTeam.id === "string"
    ? game.homeTeam.id.trim().toLowerCase() : "";
  return favorites.indexOf(awayId) !== -1 || favorites.indexOf(homeId) !== -1;
}

function eventFor(game, startTimeMs, nowMs) {
  return {
    type: "pregame-reminder",
    gameId: game.id,
    league: game.league,
    currentStatus: game.status,
    startTimeMs: startTimeMs,
    remainingMs: startTimeMs - nowMs
  };
}

function eligibleEvents(games, settings, now, todayDate, watches) {
  var source = Array.isArray(games) ? games : [];
  var nowMs = integer(now) && now >= 0 ? now : Date.now();
  var todayDateKey = typeof todayDate === "string" && /^\d{4}-\d{2}-\d{2}$/.test(todayDate)
    ? todayDate : localDateKey(nowMs);
  var notifications = notificationsFor(settings);
  if (!notifications.enabled || !notifications.pregameReminder) return [];

  var seen = Object.create(null);
  var events = [];
  for (var i = 0; i < source.length; i++) {
    var game = source[i];
    if (!isRecord(game) || game.isValid !== true || typeof game.id !== "string"
        || !game.id.trim() || seen[game.id] || game.status !== "scheduled"
        || !(isFavorite(game, favoriteTeamIds(settings)) || isActiveWatch(game, watches, nowMs))
        || typeof game.startTime !== "string") continue;

    var startTimeMs = Date.parse(game.startTime);
    if (!isFinite(startTimeMs) || startTimeMs <= nowMs
        || startTimeMs - nowMs > MAX_LEAD_TIME_MS
        || localDateKey(startTimeMs) !== todayDateKey) continue;

    seen[game.id] = true;
    events.push(eventFor(game, startTimeMs, nowMs));
  }
  return events;
}

function isActiveWatch(game, watches, currentTime) {
  if (!isRecord(game) || game.isValid !== true || typeof game.id !== "string"
      || !Array.isArray(watches)) return false;
  var gameId = game.id.trim().toLowerCase();
  var nowMs = integer(currentTime) && currentTime >= 0 ? currentTime : Date.now();
  for (var i = 0; i < watches.length; i++) {
    var watch = watches[i];
    if (!isRecord(watch) || watch.status !== "active"
        || typeof watch.gameId !== "string" || typeof watch.league !== "string"
        || typeof watch.providerGameId !== "string" || typeof watch.expiresAt !== "string") continue;
    var watchId = watch.gameId.trim().toLowerCase();
    var league = watch.league.trim().toLowerCase();
    var providerGameId = watch.providerGameId.trim().toLowerCase();
    var expiresAt = Date.parse(watch.expiresAt);
    if (watchId === gameId && watchId === league + ":" + providerGameId
        && isFinite(expiresAt) && expiresAt > nowMs) return true;
  }
  return false;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    MAX_LEAD_TIME_MS: MAX_LEAD_TIME_MS,
    localDateKey: localDateKey,
    eligibleEvents: eligibleEvents
  };
}

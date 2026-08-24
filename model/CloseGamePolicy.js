var CLOSE_MARGIN = 1;
var IN_PROGRESS_STATES = {live: true, intermission: true};

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function integerScore(value) {
  return typeof value === "number" && isFinite(value) && value >= 0
    && Math.floor(value) === value;
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

function validIdentity(game) {
  return isRecord(game) && game.isValid === true
    && typeof game.id === "string" && game.id.trim() !== ""
    && typeof game.league === "string" && game.league.trim() !== "";
}

function validScores(game) {
  return validIdentity(game) && integerScore(game.awayScore)
    && integerScore(game.homeScore);
}

function isClose(game) {
  return validScores(game) && IN_PROGRESS_STATES[game.status] === true
    && Math.abs(game.awayScore - game.homeScore) <= CLOSE_MARGIN;
}

function localDateKey(timestampMs) {
  var date = new Date(timestampMs);
  if (isNaN(date.getTime())) return "";
  var month = String(date.getMonth() + 1);
  var day = String(date.getDate());
  if (month.length < 2) month = "0" + month;
  if (day.length < 2) day = "0" + day;
  return date.getFullYear() + "-" + month + "-" + day;
}

function notificationSettings(settings) {
  var source = isRecord(settings) && isRecord(settings.notifications)
    ? settings.notifications : {};
  return {enabled: source.enabled === true, closeGame: source.closeGame === true};
}

function eventFor(game) {
  return {
    type: "close-game",
    gameId: game.id,
    league: game.league,
    currentStatus: game.status,
    awayScore: game.awayScore,
    homeScore: game.homeScore
  };
}

// Admit only a transition into a one-score-or-tied in-progress game. The
// previous snapshot is required so a startup snapshot cannot replay an alert;
// first-fetch suppression remains owned by NotificationService.
function eligibleEvents(previousGames, currentGames, settings, todayDate) {
  var notifications = notificationSettings(settings);
  if (!notifications.enabled || !notifications.closeGame) return [];

  var favorites = favoriteTeamIds(settings);
  var previous = Array.isArray(previousGames) ? previousGames : [];
  var current = Array.isArray(currentGames) ? currentGames : [];
  var dateKey = typeof todayDate === "string" && /^\d{4}-\d{2}-\d{2}$/.test(todayDate)
    ? todayDate : "";
  if (!dateKey) return [];

  var events = [];
  var seen = Object.create(null);
  for (var i = 0; i < current.length; i++) {
    var game = current[i];
    if (!validIdentity(game) || seen[game.id] || !isClose(game)
        || !isFavorite(game, favorites) || typeof game.startTime !== "string") continue;

    var startTimeMs = Date.parse(game.startTime);
    if (!isFinite(startTimeMs) || localDateKey(startTimeMs) !== dateKey) continue;

    var prior = null;
    for (var j = 0; j < previous.length; j++) {
      if (validIdentity(previous[j]) && previous[j].id === game.id) {
        prior = previous[j];
        break;
      }
    }
    if (isClose(prior)) continue;

    seen[game.id] = true;
    events.push(eventFor(game));
  }
  return events;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    CLOSE_MARGIN: CLOSE_MARGIN,
    isClose: isClose,
    eligibleEvents: eligibleEvents
  };
}

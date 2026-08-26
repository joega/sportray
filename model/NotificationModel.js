var EVENT_TYPES = {
  GAME_START: "game-start",
  SCORE_CHANGE: "score-change",
  GAME_FINAL: "game-final",
  PREGAME_REMINDER: "pregame-reminder",
  CLOSE_GAME: "close-game"
};

var MAX_DISPLAY_TEXT_LENGTH = 160;
var MAX_DESCRIPTION_LENGTH = 320;

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function text(value, fallback) {
  if (typeof value !== "string") return fallback || "";
  var result = value.trim().replace(/[\u0000-\u001f\u007f]+/g, " ");
  return result || (fallback || "");
}

function notificationText(value, fallback) {
  var result = text(value, fallback).slice(0, MAX_DISPLAY_TEXT_LENGTH);
  // omarchy-notification-send treats a hyphen-leading description as an
  // option. Keep provider-controlled text unambiguously positional.
  return result.indexOf("-") === 0 ? "· " + result : result;
}

function teamLabel(team) {
  if (!isRecord(team)) return "TBD";
  return notificationText(team.abbreviation) || notificationText(team.shortName)
    || notificationText(team.name) || "TBD";
}

function teamId(team) {
  return isRecord(team) && typeof team.id === "string" ? team.id.trim().toLowerCase() : "";
}

function score(value) {
  return typeof value === "number" && isFinite(value) && value >= 0
    && Math.floor(value) === value ? String(value) : "—";
}

function hasScores(game) {
  return isRecord(game) && score(game.awayScore) !== "—" && score(game.homeScore) !== "—";
}

function matchup(game) {
  return teamLabel(game && game.awayTeam) + " vs " + teamLabel(game && game.homeTeam);
}

function scoreLine(game) {
  return teamLabel(game.awayTeam) + " " + score(game.awayScore) + "–"
    + score(game.homeScore) + " " + teamLabel(game.homeTeam);
}

function statusDetail(game) {
  if (!isRecord(game)) return "Status unavailable";
  if (game.status === "final") return "Final";

  var period = notificationText(game.periodLabel) || notificationText(game.statusDetail);
  var clock = notificationText(game.clock);
  if (period && clock && period.indexOf(clock) === -1) return period + " · " + clock;
  if (period) return period;
  if (clock) return clock;
  if (game.status === "live") return "Live";
  if (game.status === "intermission") return "Intermission";
  if (game.status === "scheduled") return "Scheduled";
  return "Status unavailable";
}

function eventKey(event) {
  if (!isRecord(event) || typeof event.gameId !== "string") return null;
  var gameId = event.gameId.trim();
  if (!gameId) return null;
  if (event.type === EVENT_TYPES.GAME_START) return gameId + ":start";
  if (event.type === EVENT_TYPES.GAME_FINAL) return gameId + ":final";
  if (event.type === EVENT_TYPES.PREGAME_REMINDER) return gameId + ":pregame";
  if (event.type === EVENT_TYPES.CLOSE_GAME) return gameId + ":close";
  if (event.type === EVENT_TYPES.SCORE_CHANGE
      && typeof event.awayScore === "number" && typeof event.homeScore === "number"
      && isFinite(event.awayScore) && isFinite(event.homeScore)
      && event.awayScore >= 0 && event.homeScore >= 0
      && Math.floor(event.awayScore) === event.awayScore
      && Math.floor(event.homeScore) === event.homeScore) {
    return gameId + ":score:" + event.awayScore + ":" + event.homeScore;
  }
  return null;
}

function notificationsFor(settings) {
  var source = isRecord(settings) ? settings : {};
  var value = isRecord(source.notifications) ? source.notifications : {};
  return {
    enabled: value.enabled === true,
    gameStart: value.gameStart === true,
    scoreChange: value.scoreChange === true,
    gameFinal: value.gameFinal === true,
    pregameReminder: value.pregameReminder === true,
    closeGame: value.closeGame === true
  };
}

function eventEnabled(event, settings) {
  var notifications = notificationsFor(settings);
  if (!notifications.enabled || !isRecord(event)) return false;
  if (event.type === EVENT_TYPES.GAME_START) return notifications.gameStart;
  if (event.type === EVENT_TYPES.SCORE_CHANGE) return notifications.scoreChange;
  if (event.type === EVENT_TYPES.GAME_FINAL) return notifications.gameFinal;
  if (event.type === EVENT_TYPES.PREGAME_REMINDER) return notifications.pregameReminder;
  if (event.type === EVENT_TYPES.CLOSE_GAME) return notifications.closeGame;
  return false;
}

function favoriteTeamIds(settings) {
  var source = isRecord(settings) && Array.isArray(settings.favoriteTeamIds)
    ? settings.favoriteTeamIds : [];
  return source.map(function(value) {
    return typeof value === "string" ? value.trim().toLowerCase() : "";
  }).filter(function(value) { return value !== ""; });
}

function isFavoriteGame(game, settings) {
  if (!isRecord(game)) return false;
  var favorites = favoriteTeamIds(settings);
  return favorites.indexOf(teamId(game.awayTeam)) !== -1
    || favorites.indexOf(teamId(game.homeTeam)) !== -1;
}

function isActiveWatch(game, watches, currentTime) {
  if (!isRecord(game) || game.isValid !== true || typeof game.id !== "string") return false;
  var gameId = game.id.trim().toLowerCase();
  if (!gameId || !Array.isArray(watches)) return false;
  var now = typeof currentTime === "number" && isFinite(currentTime) && currentTime >= 0
    ? currentTime : Date.now();
  for (var i = 0; i < watches.length; i++) {
    var watch = watches[i];
    if (!isRecord(watch) || watch.status !== "active") continue;
    if (typeof watch.gameId !== "string" || typeof watch.league !== "string"
        || typeof watch.providerGameId !== "string" || typeof watch.expiresAt !== "string") continue;
    var watchId = watch.gameId.trim().toLowerCase();
    var league = watch.league.trim().toLowerCase();
    var providerGameId = watch.providerGameId.trim().toLowerCase();
    var expiresAt = Date.parse(watch.expiresAt);
    if (!watchId || !league || !providerGameId || watchId !== league + ":" + providerGameId
        || watchId !== gameId || !isFinite(expiresAt) || expiresAt <= now) continue;
    return true;
  }
  return false;
}

function isAdmittedGame(game, settings, watches, currentTime) {
  return isFavoriteGame(game, settings) || isActiveWatch(game, watches, currentTime);
}

function gameForId(games, gameId) {
  if (!Array.isArray(games)) return null;
  for (var i = 0; i < games.length; i++) {
    if (isRecord(games[i]) && games[i].id === gameId) return games[i];
  }
  return null;
}

function headlineFor(type) {
  if (type === EVENT_TYPES.GAME_START) return "Sportray · Game started";
  if (type === EVENT_TYPES.SCORE_CHANGE) return "Sportray · Score change";
  if (type === EVENT_TYPES.GAME_FINAL) return "Sportray · Final";
  if (type === EVENT_TYPES.PREGAME_REMINDER) return "Sportray · Upcoming game";
  if (type === EVENT_TYPES.CLOSE_GAME) return "Sportray · Close game";
  return "Sportray";
}

function buildDelivery(event, game) {
  var fingerprint = eventKey(event);
  if (!fingerprint || !isRecord(game) || game.isValid !== true || !game.id) return null;

  var summary = hasScores(game) ? scoreLine(game) : matchup(game);
  var description = summary + " · " + statusDetail(game);
  if (event.type === EVENT_TYPES.PREGAME_REMINDER) {
    var remainingMs = typeof event.remainingMs === "number" && isFinite(event.remainingMs)
      && event.remainingMs > 0 ? event.remainingMs : 60000;
    var minutes = Math.max(1, Math.ceil(remainingMs / 60000));
    description = summary + " · Starts in " + minutes + " min";
  }
  description = description.slice(0, MAX_DESCRIPTION_LENGTH);
  var headline = headlineFor(event.type);
  return {
    event: event,
    fingerprint: fingerprint,
    gameId: game.id,
    headline: headline,
    description: description,
    argv: [
      "/usr/bin/omarchy-notification-send",
      "--app-name", "Sportray",
      "-u", "normal",
      headline,
      description
    ]
  };
}

function buildDeliveries(events, games, settings, watches, currentTime) {
  if (!Array.isArray(events)) return [];
  var result = [];
  for (var i = 0; i < events.length; i++) {
    var event = events[i];
    var game = gameForId(games, event && event.gameId);
    if (!eventEnabled(event, settings)
        || !isAdmittedGame(game, settings, watches, currentTime)) continue;
    var delivery = buildDelivery(event, game);
    if (delivery) result.push(delivery);
  }
  return result;
}

function buildTestDelivery() {
  var headline = "Sportray · Test notification";
  var description = "Alerts are working. This is a preview from Sportray.";
  return {
    headline: headline,
    description: description,
    argv: [
      "/usr/bin/omarchy-notification-send",
      "--app-name", "Sportray",
      "-u", "normal",
      headline,
      description
    ]
  };
}

function helperOutcome(exitCode, exitStatus) {
  return {
    ok: exitCode === 0,
    exitCode: typeof exitCode === "number" ? exitCode : null,
    exitStatus: typeof exitStatus === "number" ? exitStatus : null
  };
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    EVENT_TYPES: EVENT_TYPES,
    eventKey: eventKey,
    eventEnabled: eventEnabled,
    isFavoriteGame: isFavoriteGame,
    isActiveWatch: isActiveWatch,
    isAdmittedGame: isAdmittedGame,
    buildDelivery: buildDelivery,
    buildDeliveries: buildDeliveries,
    buildTestDelivery: buildTestDelivery,
    helperOutcome: helperOutcome
  };
}

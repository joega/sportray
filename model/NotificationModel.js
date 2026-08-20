var EVENT_TYPES = {
  GAME_START: "game-start",
  SCORE_CHANGE: "score-change",
  GAME_FINAL: "game-final"
};

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function text(value, fallback) {
  if (typeof value !== "string") return fallback || "";
  var result = value.trim().replace(/[\u0000-\u001f\u007f]+/g, " ");
  return result || (fallback || "");
}

function teamLabel(team) {
  if (!isRecord(team)) return "TBD";
  return text(team.abbreviation) || text(team.shortName) || text(team.name) || "TBD";
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

  var period = text(game.periodLabel) || text(game.statusDetail);
  var clock = text(game.clock);
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
    gameFinal: value.gameFinal === true
  };
}

function eventEnabled(event, settings) {
  var notifications = notificationsFor(settings);
  if (!notifications.enabled || !isRecord(event)) return false;
  if (event.type === EVENT_TYPES.GAME_START) return notifications.gameStart;
  if (event.type === EVENT_TYPES.SCORE_CHANGE) return notifications.scoreChange;
  if (event.type === EVENT_TYPES.GAME_FINAL) return notifications.gameFinal;
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
  return "Sportray";
}

function buildDelivery(event, game) {
  var fingerprint = eventKey(event);
  if (!fingerprint || !isRecord(game) || game.isValid !== true || !game.id) return null;

  var summary = hasScores(game) ? scoreLine(game) : matchup(game);
  var description = summary + " · " + statusDetail(game);
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

function buildDeliveries(events, games, settings) {
  if (!Array.isArray(events)) return [];
  var result = [];
  for (var i = 0; i < events.length; i++) {
    var event = events[i];
    var game = gameForId(games, event && event.gameId);
    if (!eventEnabled(event, settings) || !isFavoriteGame(game, settings)) continue;
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
    buildDelivery: buildDelivery,
    buildDeliveries: buildDeliveries,
    buildTestDelivery: buildTestDelivery,
    helperOutcome: helperOutcome
  };
}

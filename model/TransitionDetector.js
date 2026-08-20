var EVENT_TYPES = {
  GAME_START: "game-start",
  SCORE_CHANGE: "score-change",
  GAME_FINAL: "game-final"
};

var COMPARABLE_STATES = {
  scheduled: true,
  live: true,
  intermission: true,
  final: true
};

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function isScore(value) {
  return value === null ||
    (typeof value === "number" && isFinite(value) && value >= 0 && Math.floor(value) === value);
}

function isUsableGame(game) {
  return isRecord(game) && game.isValid === true &&
    typeof game.id === "string" && game.id.trim() !== "" &&
    typeof game.league === "string" && game.league.trim() !== "" &&
    typeof game.providerGameId === "string" && game.providerGameId.trim() !== "" &&
    game.id === game.league + ":" + game.providerGameId &&
    typeof game.status === "string" && COMPARABLE_STATES[game.status] === true &&
    isScore(game.awayScore) && isScore(game.homeScore);
}

function sameGame(previousGame, currentGame) {
  return isUsableGame(previousGame) && isUsableGame(currentGame) &&
    previousGame.id === currentGame.id;
}

function hasKnownScores(game) {
  return game.awayScore !== null && game.homeScore !== null;
}

function scoreChanged(previousGame, currentGame) {
  return hasKnownScores(previousGame) && hasKnownScores(currentGame) &&
    (previousGame.awayScore !== currentGame.awayScore ||
      previousGame.homeScore !== currentGame.homeScore);
}

function event(type, previousGame, currentGame) {
  return {
    type: type,
    gameId: currentGame.id,
    league: currentGame.league,
    previousStatus: previousGame ? previousGame.status : null,
    currentStatus: currentGame.status,
    previousAwayScore: previousGame ? previousGame.awayScore : null,
    previousHomeScore: previousGame ? previousGame.homeScore : null,
    awayScore: currentGame.awayScore,
    homeScore: currentGame.homeScore
  };
}

function detect(previousGame, currentGame) {
  // A missing prior snapshot is the silent first-fetch baseline.
  if (!sameGame(previousGame, currentGame)) return [];

  var events = [];
  var started = previousGame.status === "scheduled" &&
    (currentGame.status === "live" || currentGame.status === "intermission");
  var final = currentGame.status === "final" && previousGame.status !== "final";

  if (started) events.push(event(EVENT_TYPES.GAME_START, previousGame, currentGame));

  // Do not notify a score change separately when the same fetch first reveals final.
  if (scoreChanged(previousGame, currentGame) && !final) {
    events.push(event(EVENT_TYPES.SCORE_CHANGE, previousGame, currentGame));
  }

  if (final) events.push(event(EVENT_TYPES.GAME_FINAL, previousGame, currentGame));
  return events;
}

function findGame(games, id) {
  if (!Array.isArray(games)) return null;
  for (var i = 0; i < games.length; i++) {
    if (isRecord(games[i]) && games[i].id === id) return games[i];
  }
  return null;
}

function detectGames(previousGames, currentGames) {
  if (!Array.isArray(currentGames)) return [];

  var events = [];
  var seenIds = Object.create(null);
  for (var i = 0; i < currentGames.length; i++) {
    var currentGame = currentGames[i];
    if (!isRecord(currentGame) || seenIds[currentGame.id]) continue;
    seenIds[currentGame.id] = true;
    events = events.concat(detect(findGame(previousGames, currentGame.id), currentGame));
  }
  return events;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    EVENT_TYPES: EVENT_TYPES,
    isUsableGame: isUsableGame,
    detect: detect,
    detectGames: detectGames
  };
}

var FavoritePresentation = null;
if (typeof require === "function") FavoritePresentation = require("./FavoritePresentation.js");
var DateModel = null;
if (typeof require === "function") DateModel = require("./DateModel.js");

var LEAGUE_ORDER = ["nhl", "nfl", "mlb", "nba", "college-football", "eng.1", "usa.1",
  "mens-college-basketball"];

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function normalizeLeagueId(value) {
  if (typeof value !== "string") return null;
  var id = value.trim().toLowerCase();
  return LEAGUE_ORDER.indexOf(id) === -1 ? null : id;
}

function normalizeLeagueIds(value) {
  if (!Array.isArray(value)) return [];
  var result = [];
  for (var i = 0; i < value.length; i++) {
    var id = normalizeLeagueId(value[i]);
    if (id && result.indexOf(id) === -1) result.push(id);
  }
  return result;
}

function orderGames(games, favoriteTeamIds, orderer) {
  var values = Array.isArray(games) ? games : [];
  if (typeof orderer === "function") return orderer(values, favoriteTeamIds);
  if (FavoritePresentation) return FavoritePresentation.orderGames(values, favoriteTeamIds);
  return values.slice();
}

function stateFor(states, leagueId) {
  if (!Array.isArray(states)) return null;
  for (var i = 0; i < states.length; i++) {
    if (isRecord(states[i]) && states[i].leagueId === leagueId) return states[i];
  }
  return null;
}

function gameDateKey(game) {
  if (!isRecord(game) || typeof game.startTime !== "string") return "";
  if (DateModel) return DateModel.dateKeyFromTimestamp(game.startTime);
  var date = new Date(game.startTime);
  if (isNaN(date.getTime())) return "";
  return date.getFullYear() + "-" + String(date.getMonth() + 1).padStart(2, "0")
    + "-" + String(date.getDate()).padStart(2, "0");
}

function cleanGames(value, leagueId, selectedDateKey) {
  if (!Array.isArray(value)) return [];
  return value.filter(function(game) {
    if (!isRecord(game) || game.isValid !== true || game.league !== leagueId) return false;
    return !selectedDateKey || gameDateKey(game) === selectedDateKey;
  });
}

function safeErrorSummary(errorCode) {
  switch (errorCode) {
  case "configuration": return "Scores are unavailable";
  case "timeout":
  case "unavailable": return "Scores are temporarily unavailable";
  case "invalid-data": return "Scores could not be read";
  case "partial-data": return "Some scores could not be updated";
  default: return "Scores are temporarily unavailable";
  }
}

function compose(states, enabledLeagues, favoriteTeamIds, orderer, selectedDateKey) {
  var enabled = normalizeLeagueIds(enabledLeagues);
  var sections = [];
  var statuses = [];
  var leagueStates = [];
  var allGames = [];
  var hasData = false;
  var loading = false;

  for (var i = 0; i < enabled.length; i++) {
    var leagueId = enabled[i];
    var state = stateFor(states, leagueId) || {leagueId: leagueId, displayName: leagueId.toUpperCase()};
    var games = cleanGames(state.games, leagueId, selectedDateKey);
    var ordered = orderGames(games, favoriteTeamIds, orderer);
    allGames = allGames.concat(ordered);
    hasData = hasData || state.hasData === true;
    loading = loading || state.loading === true;

    leagueStates.push({
      leagueId: leagueId,
      displayName: state.displayName || leagueId.toUpperCase(),
      games: ordered,
      hasData: state.hasData === true,
      loading: state.loading === true,
      stale: state.stale === true,
      errorCode: state.errorCode || "",
      errorSummary: state.errorCode ? safeErrorSummary(state.errorCode) : "",
      partialErrorCount: Number(state.partialErrorCount) || 0,
      lastSuccessAt: state.lastSuccessAt || null,
      nextGame: state.nextGame || null,
      nextGameDateKey: state.nextGameDateKey || "",
      nextGameStatus: state.nextGameStatus || "idle"
    });

    if (ordered.length > 0) {
      sections.push({
        leagueId: leagueId,
        displayName: state.displayName || leagueId.toUpperCase(),
        games: ordered,
        stale: state.stale === true,
        errorSummary: state.errorCode ? safeErrorSummary(state.errorCode) : "",
        partialErrorCount: Number(state.partialErrorCount) || 0
      });
    } else if (state.loading === true || (typeof state.errorCode === "string" && state.errorCode !== "")) {
      statuses.push({
        leagueId: leagueId,
        displayName: state.displayName || leagueId.toUpperCase(),
        loading: state.loading === true,
        errorCode: state.errorCode || "",
        errorSummary: safeErrorSummary(state.errorCode),
        stale: state.stale === true,
        partialErrorCount: Number(state.partialErrorCount) || 0
      });
    }
  }

  return {
    enabledLeagues: enabled,
    games: orderGames(allGames, favoriteTeamIds, orderer),
    sections: sections,
    statuses: statuses,
    leagueStates: leagueStates,
    hasData: hasData,
    hasGames: allGames.length > 0,
    loading: loading
  };
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    LEAGUE_ORDER: LEAGUE_ORDER,
    normalizeLeagueIds: normalizeLeagueIds,
    gameDateKey: gameDateKey,
    compose: compose
  };
}

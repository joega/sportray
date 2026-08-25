var GameModel = null;
var ResponsePolicy = null;
if (typeof require === "function") {
  GameModel = require("../model/GameModel.js");
  ResponsePolicy = require("../model/ResponsePolicy.js");
}

var MLB_STATS_BASE_URL = "https://statsapi.mlb.com";
var MLB_STATS_SCORE_PATH = "/api/v1/schedule";
var MLB_STATS_HYDRATE = "team,linescore";
var MLB_SITE_URL = "https://www.mlb.com";
var MLB_STATS_PROVIDER = "mlb-stats";
var MAX_EVENTS = ResponsePolicy ? ResponsePolicy.MAX_EVENTS : 256;

// The MLB StatsAPI identifies teams by its own numeric ids, which differ from
// the ESPN ids Sportray persists as canonical mlb:<providerTeamId> favorites.
// This explicit translation table maps every current MLB StatsAPI team id to
// the ESPN provider id verified live on 2026-08-25 from both the ESPN MLB
// scoreboard competitor ids and the ESPN MLB team-catalog endpoint (the two
// live ESPN sources agreed for all 30 teams). A provider switch must not
// change favorite identity, so unknown StatsAPI team ids fail closed instead
// of inventing a new canonical id.
var TEAM_IDS_BY_STATS_ID = {
  "108": "3", "109": "29", "110": "1", "111": "2", "112": "16",
  "113": "17", "114": "5", "115": "27", "116": "6", "117": "18",
  "118": "7", "119": "19", "120": "20", "121": "21", "133": "11",
  "134": "23", "135": "25", "136": "12", "137": "26", "138": "24",
  "139": "30", "140": "13", "141": "14", "142": "9", "143": "22",
  "144": "15", "145": "4", "146": "28", "147": "10", "158": "8"
};

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function cleanString(value) {
  if (typeof value !== "string") return null;
  var result = value.trim();
  return result || null;
}

function providerId(value) {
  if (typeof value === "number" && isFinite(value)) value = String(value);
  return cleanString(value);
}

function integerOrNull(value) {
  if (typeof value === "string" && /^\d+$/.test(value.trim())) value = Number(value);
  if (typeof value !== "number" || !isFinite(value) || value < 0 || Math.floor(value) !== value)
    return null;
  return value;
}

function positiveIntegerOrNull(value) {
  var result = integerOrNull(value);
  return result !== null && result > 0 ? result : null;
}

function normalizeTimestamp(value) {
  if (typeof value !== "string") return null;
  var date = new Date(value);
  return isNaN(date.getTime()) ? null : date.toISOString();
}

// The schedule endpoint reports a three-valued abstractGameState plus a
// free-form detailedState. detailedState is authoritative for administrative
// outcomes (postponed, delayed, suspended, cancelled) regardless of the
// abstract state; a decided-but-unofficial "Game Over" game is final for
// scoreboard purposes. Unknown shapes fail closed to "unknown".
function normalizeStatus(status) {
  if (!isRecord(status)) return "unknown";

  var detailed = cleanString(status.detailedState);
  detailed = detailed ? detailed.toLowerCase() : "";
  if (detailed.indexOf("postpon") !== -1 || detailed.indexOf("suspend") !== -1
      || detailed.indexOf("delay") !== -1) return "postponed";
  if (detailed.indexOf("cancel") !== -1) return "canceled";

  var abstractState = cleanString(status.abstractGameState);
  abstractState = abstractState ? abstractState.toLowerCase() : null;
  if (abstractState === "final") return "final";
  if (abstractState === "preview") return "scheduled";
  if (abstractState === "live") {
    if (detailed === "game over") return "final";
    return "live";
  }
  return "unknown";
}

function normalizeTeam(side) {
  if (!isRecord(side) || !isRecord(side.team)) return null;

  var statsTeamId = providerId(side.team.id);
  if (!statsTeamId) return null;
  var canonicalTeamId = TEAM_IDS_BY_STATS_ID[statsTeamId];
  if (!canonicalTeamId) return null;

  return {
    id: "mlb:" + canonicalTeamId,
    league: "mlb",
    providerTeamId: canonicalTeamId,
    name: cleanString(side.team.name),
    shortName: cleanString(side.team.teamName) || cleanString(side.team.shortName),
    abbreviation: cleanString(side.team.abbreviation),
    primaryColor: null,
    logoUrl: null,
    link: null
  };
}

function scoreFor(side, normalizedStatus) {
  if (normalizedStatus === "scheduled") return null;
  return isRecord(side) ? integerOrNull(side.score) : null;
}

function liveInningLabel(linescore) {
  if (!isRecord(linescore)) return null;
  var inning = cleanString(linescore.currentInningOrdinal);
  var state = cleanString(linescore.inningState);
  if (!inning || !state) return null;
  return state + " " + inning;
}

function boundaryGame(game) {
  if (!isRecord(game)) return null;

  var providerGameId = providerId(game.gamePk);
  var awayTeam = normalizeTeam(game.teams && game.teams.away);
  var homeTeam = normalizeTeam(game.teams && game.teams.home);
  if (!providerGameId || !awayTeam || !homeTeam) return null;

  var normalizedStatus = normalizeStatus(game.status);
  var linescore = isRecord(game.linescore) ? game.linescore : null;
  var detail = null;
  if (normalizedStatus === "final") detail = "Final";
  if (normalizedStatus === "live") detail = liveInningLabel(linescore)
    || cleanString(game.status && game.status.detailedState);
  if (normalizedStatus === "postponed" || normalizedStatus === "canceled")
    detail = cleanString(game.status && game.status.detailedState);

  return {
    id: "mlb:" + providerGameId,
    league: "mlb",
    providerGameId: providerGameId,
    startTime: normalizeTimestamp(game.gameDate),
    endTime: null,
    status: normalizedStatus,
    statusDetail: detail,
    period: normalizedStatus === "scheduled" ? null
      : positiveIntegerOrNull(linescore && linescore.currentInning),
    periodLabel: normalizedStatus === "live" ? detail : null,
    clock: null,
    awayTeam: awayTeam,
    homeTeam: homeTeam,
    awayScore: scoreFor(game.teams && game.teams.away, normalizedStatus),
    homeScore: scoreFor(game.teams && game.teams.home, normalizedStatus),
    venue: isRecord(game.venue) ? cleanString(game.venue.name) : null,
    link: buildGameUrl(providerGameId),
    lastUpdated: null,
    isValid: true
  };
}

function parseGame(game) {
  var candidate = boundaryGame(game);
  if (!candidate) return null;
  return GameModel ? GameModel.normalizeGame(candidate) : candidate;
}

function parseScoreResponse(payload) {
  var result = {games: [], errors: []};
  if (!isRecord(payload) || !Array.isArray(payload.dates)) {
    result.errors.push({index: null, code: "invalid-score-response"});
    return result;
  }

  var eventCount = 0;
  for (var dayIndex = 0; dayIndex < payload.dates.length; dayIndex++) {
    var day = payload.dates[dayIndex];
    if (!isRecord(day) || !Array.isArray(day.games)) continue;
    eventCount += day.games.length;
    if (eventCount > MAX_EVENTS) {
      result.errors.push({index: null, code: "too-many-events"});
      return result;
    }
  }

  payload.dates.forEach(function(day, dayIndex) {
    if (!isRecord(day) || !Array.isArray(day.games)) return;
    day.games.forEach(function(game, gameIndex) {
      var normalized = parseGame(game);
      if (!normalized || normalized.status === "malformed" || normalized.isValid !== true) {
        result.errors.push({index: dayIndex + ":" + gameIndex, code: "invalid-game"});
        return;
      }
      result.games.push(normalized);
    });
  });
  return result;
}

function buildScoreUrl(dateKey) {
  if (dateKey === undefined || dateKey === null || dateKey === "")
    return MLB_STATS_BASE_URL + MLB_STATS_SCORE_PATH
      + "?sportId=1&hydrate=" + MLB_STATS_HYDRATE;
  if (typeof dateKey !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(dateKey)) return null;
  return MLB_STATS_BASE_URL + MLB_STATS_SCORE_PATH + "?sportId=1&date="
    + dateKey + "&hydrate=" + MLB_STATS_HYDRATE;
}

function buildGameUrl(providerGameId) {
  var gameId = providerId(providerGameId);
  return gameId ? MLB_SITE_URL + "/gameday/" + gameId : null;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    MLB_STATS_BASE_URL: MLB_STATS_BASE_URL,
    MLB_STATS_PROVIDER: MLB_STATS_PROVIDER,
    TEAM_IDS_BY_STATS_ID: TEAM_IDS_BY_STATS_ID,
    buildScoreUrl: buildScoreUrl,
    buildGameUrl: buildGameUrl,
    normalizeStatus: normalizeStatus,
    parseGame: parseGame,
    parseScoreResponse: parseScoreResponse
  };
}

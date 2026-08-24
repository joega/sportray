// Provider-neutral game-detail boundary. Providers first normalize their
// payloads into GameModel's game shape; this model exposes only the small
// detail shape that a future drill-down can consume.

var TeamModel = null;
if (typeof require === "function") TeamModel = require("./TeamModel.js");

var MAX_DETAILS = 256;
var MAX_OUTCOME_SCORE = 9999;
var VALID_STATES = {
  scheduled: true,
  live: true,
  intermission: true,
  final: true,
  postponed: true,
  canceled: true,
  unknown: true
};

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function cleanString(value) {
  if (typeof value !== "string") return null;
  var result = value.trim();
  return result || null;
}

function nonNegativeInteger(value) {
  if (typeof value === "string" && /^\d+$/.test(value.trim())) value = Number(value);
  if (typeof value !== "number" || !isFinite(value) || value < 0 || Math.floor(value) !== value)
    return null;
  return value;
}

function normalizeTimestamp(value) {
  if (typeof value !== "string") return null;
  var date = new Date(value);
  return isNaN(date.getTime()) ? null : date.toISOString();
}

function normalizeTeam(team) {
  if (!isRecord(team)) return null;
  if (TeamModel) return TeamModel.normalizeTeam(team);

  var id = cleanString(team.id);
  var league = cleanString(team.league);
  var providerTeamId = cleanString(team.providerTeamId);
  if (!id || !league || !providerTeamId) return null;
  return {
    id: id,
    league: league,
    providerTeamId: providerTeamId,
    name: cleanString(team.name),
    shortName: cleanString(team.shortName),
    abbreviation: cleanString(team.abbreviation),
    primaryColor: cleanString(team.primaryColor),
    logoUrl: cleanString(team.logoUrl),
    link: cleanString(team.link)
  };
}

function normalizeSource(source, game) {
  var input = isRecord(source) ? source : {};
  var url = cleanString(input.url) || (game ? cleanString(game.link) : null);
  if (url && !/^https:\/\//i.test(url)) url = null;
  return {
    provider: cleanString(input.provider),
    label: cleanString(input.label),
    url: url
  };
}

function normalizeOutcome(game) {
  if (!isRecord(game) || game.status !== "final") return null;

  var awayScore = nonNegativeInteger(game.awayScore);
  var homeScore = nonNegativeInteger(game.homeScore);
  if (awayScore === null || homeScore === null
      || awayScore > MAX_OUTCOME_SCORE || homeScore > MAX_OUTCOME_SCORE) return null;

  return {
    winner: awayScore === homeScore ? "draw" : awayScore > homeScore ? "away" : "home",
    margin: Math.abs(awayScore - homeScore)
  };
}

function emptyDetail(errorCode) {
  return {
    id: null,
    league: null,
    providerGameId: null,
    participants: [
      {side: "away", team: null, score: null},
      {side: "home", team: null, score: null}
    ],
    status: {
      state: "unknown",
      detail: null,
      period: null,
      periodLabel: null,
      clock: null
    },
    timing: {
      startTime: null,
      endTime: null,
      lastUpdated: null
    },
    venue: null,
    outcome: null,
    source: {
      provider: null,
      label: null,
      url: null
    },
    isValid: false,
    errors: errorCode ? [{code: errorCode}] : []
  };
}

function normalizeDetail(game, source) {
  if (!isRecord(game)) return emptyDetail("invalid-game");

  var league = cleanString(game.league);
  var providerGameId = cleanString(game.providerGameId);
  if (!league || !providerGameId || game.isValid !== true) return emptyDetail("invalid-game");

  var state = cleanString(game.status);
  state = state && VALID_STATES[state] ? state : "unknown";
  var detail = {
    id: league.toLowerCase() + ":" + providerGameId,
    league: league.toLowerCase(),
    providerGameId: providerGameId,
    participants: [
      {
        side: "away",
        team: normalizeTeam(game.awayTeam),
        score: nonNegativeInteger(game.awayScore)
      },
      {
        side: "home",
        team: normalizeTeam(game.homeTeam),
        score: nonNegativeInteger(game.homeScore)
      }
    ],
    status: {
      state: state,
      detail: cleanString(game.statusDetail),
      period: nonNegativeInteger(game.period),
      periodLabel: cleanString(game.periodLabel),
      clock: cleanString(game.clock)
    },
    timing: {
      startTime: normalizeTimestamp(game.startTime),
      endTime: normalizeTimestamp(game.endTime),
      lastUpdated: normalizeTimestamp(game.lastUpdated)
    },
    venue: cleanString(game.venue),
    outcome: normalizeOutcome(game),
    source: normalizeSource(source, game),
    isValid: true,
    errors: []
  };
  return detail;
}

function compareDetails(left, right) {
  var leftTime = left && left.timing ? left.timing.startTime : null;
  var rightTime = right && right.timing ? right.timing.startTime : null;
  if (leftTime === null && rightTime !== null) return 1;
  if (leftTime !== null && rightTime === null) return -1;
  if (leftTime !== rightTime) return leftTime < rightTime ? -1 : 1;

  var leftId = left && typeof left.id === "string" ? left.id : "";
  var rightId = right && typeof right.id === "string" ? right.id : "";
  if (leftId === rightId) return 0;
  return leftId < rightId ? -1 : 1;
}

function normalizeDetails(games, source) {
  var result = {details: [], errors: []};
  if (!Array.isArray(games)) {
    result.errors.push({index: null, code: "invalid-games"});
    return result;
  }
  if (games.length > MAX_DETAILS) {
    result.errors.push({index: null, code: "too-many-games"});
    return result;
  }

  games.forEach(function(game, index) {
    var detail = normalizeDetail(game, source);
    if (!detail.isValid) {
      result.errors.push({index: index, code: "invalid-game"});
      return;
    }
    result.details.push(detail);
  });
  result.details.sort(compareDetails);
  return result;
}

function createDefaultDetail() {
  return emptyDetail();
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    MAX_DETAILS: MAX_DETAILS,
    MAX_OUTCOME_SCORE: MAX_OUTCOME_SCORE,
    compareDetails: compareDetails,
    createDefaultDetail: createDefaultDetail,
    normalizeOutcome: normalizeOutcome,
    normalizeDetail: normalizeDetail,
    normalizeDetails: normalizeDetails
  };
}

var GameModel = null;
var AssetUrlPolicy = null;
if (typeof require === "function") {
  GameModel = require("../model/GameModel.js");
  AssetUrlPolicy = require("../model/AssetUrlPolicy.js");
}

var NHL_BASE_URL = "https://api-web.nhle.com";
var NHL_SCORE_PATH = "/v1/score";
var NHL_SITE_URL = "https://www.nhl.com";

// The NHL scoreboard contract supplies logos but no colors. Keep this small,
// reviewed current-team palette provider-owned and let TeamModel reject any
// malformed value before it reaches QML.
var PRIMARY_COLORS = {
  "1": "E30B2B", "2": "00529B", "3": "0056AE", "4": "FE5823",
  "5": "000000", "6": "231F20", "7": "00468B", "8": "C41230",
  "9": "DD1A32", "10": "003E7E", "12": "E30426", "13": "E51937",
  "14": "003E7E", "15": "D71830", "16": "E31937", "17": "E30526",
  "18": "FDBA31", "19": "0070B9", "20": "DD1A32", "21": "860038",
  "22": "00205B", "23": "003E7E", "24": "FC4C02", "25": "20864C",
  "26": "121212", "28": "00788A", "29": "002D62", "30": "124734",
  "52": "002D62", "54": "344043", "55": "000D33", "68": "000000"
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

function safeUrl(value) {
  var url = cleanString(value);
  if (!url || !/^https?:\/\//i.test(url)) return null;
  return url;
}

function safeLogoUrl(value) {
  if (AssetUrlPolicy) return AssetUrlPolicy.safeLogoUrl(value);

  var url = cleanString(value);
  if (!url || !/^https:\/\//i.test(url)) return null;
  var match = /^https:\/\/([^/?#]+)(?:[/?#]|$)/i.exec(url);
  if (!match) return null;
  return match[1].toLowerCase() === "assets.nhle.com" ? url : null;
}

function safeGameUrl(value) {
  var url = cleanString(value);
  if (!url || !/^https:\/\//i.test(url)) return null;
  var match = /^https:\/\/([^/?#]+)(?:[/?#]|$)/i.exec(url);
  if (!match) return null;
  var host = match[1].toLowerCase();
  return host === "nhl.com" || host === "www.nhl.com" ? url : null;
}

function absoluteNhlLink(value) {
  var link = cleanString(value);
  if (!link) return null;
  if (/^https?:\/\//i.test(link)) return safeGameUrl(link);
  return link.charAt(0) === "/" ? NHL_SITE_URL + link : null;
}

function defaultText(value) {
  if (!isRecord(value)) return null;
  return cleanString(value.default);
}

function normalizeTimestamp(value) {
  if (typeof value !== "string") return null;
  var date = new Date(value);
  return isNaN(date.getTime()) ? null : date.toISOString();
}

function periodLabel(periodDescriptor) {
  if (!isRecord(periodDescriptor)) return null;

  var periodType = cleanString(periodDescriptor.periodType);
  periodType = periodType ? periodType.toUpperCase() : null;
  if (periodType === "OT") return "OT";
  if (periodType === "SO") return "Shootout";

  var number = positiveIntegerOrNull(periodDescriptor.number);
  if (number === null) return null;
  if (number === 1) return "1st";
  if (number === 2) return "2nd";
  if (number === 3) return "3rd";
  return number + "th";
}

function normalizeStatus(event) {
  if (!isRecord(event)) return "unknown";

  var scheduleState = cleanString(event.gameScheduleState);
  scheduleState = scheduleState ? scheduleState.toUpperCase() : null;
  if (scheduleState === "CNCL" || scheduleState === "CANC" || scheduleState === "CANCELED" || scheduleState === "CANCELLED")
    return "canceled";
  if (scheduleState === "PPD" || scheduleState === "POST" || scheduleState === "POSTPONED" || scheduleState === "DELAYED")
    return "postponed";

  var gameState = cleanString(event.gameState);
  gameState = gameState ? gameState.toUpperCase() : null;
  if (gameState === "FUT" || gameState === "PRE" || gameState === "PREGAME" || gameState === "NOT_STARTED")
    return "scheduled";
  if (gameState === "FINAL" || gameState === "OFF" || gameState === "COMPLETED") return "final";
  if (gameState === "INTERMISSION" || gameState === "BREAK") return "intermission";
  if (gameState === "LIVE" || gameState === "CRIT" || gameState === "IN_PROGRESS" || gameState === "PLAYING") {
    if (isRecord(event.clock) && event.clock.running === false) return "intermission";
    return "live";
  }
  if (gameState === "PPD" || gameState === "POST" || gameState === "POSTPONED" || gameState === "DELAYED")
    return "postponed";
  if (gameState === "CANC" || gameState === "CANCELED" || gameState === "CANCELLED") return "canceled";
  return "unknown";
}

function normalizeTeam(rawTeam) {
  if (!isRecord(rawTeam)) return null;

  var providerTeamId = providerId(rawTeam.id);
  if (!providerTeamId) return null;

  var shortName = defaultText(rawTeam.commonName) || defaultText(rawTeam.name);
  return {
    id: "nhl:" + providerTeamId,
    league: "nhl",
    providerTeamId: providerTeamId,
    name: defaultText(rawTeam.name),
    shortName: shortName,
    abbreviation: cleanString(rawTeam.abbrev),
    primaryColor: PRIMARY_COLORS[providerTeamId] || null,
    logoUrl: safeLogoUrl(rawTeam.logo),
    link: null
  };
}

function boundaryGame(event) {
  if (!isRecord(event)) return null;

  var providerGameId = providerId(event.id);
  var awayTeam = normalizeTeam(event.awayTeam);
  var homeTeam = normalizeTeam(event.homeTeam);
  if (!providerGameId || !awayTeam || !homeTeam) return null;

  var descriptor = isRecord(event.periodDescriptor) ? event.periodDescriptor : null;
  var clock = isRecord(event.clock) ? event.clock : null;
  var normalizedStatus = normalizeStatus(event);
  var detail = null;
  if (normalizedStatus === "final") detail = "Final";
  if (normalizedStatus === "postponed") detail = "Postponed";
  if (normalizedStatus === "canceled") detail = "Canceled";

  return {
    id: "nhl:" + providerGameId,
    league: "nhl",
    providerGameId: providerGameId,
    startTime: normalizeTimestamp(event.startTimeUTC),
    endTime: normalizeTimestamp(event.gameEndTimeUTC || event.endTimeUTC),
    status: normalizedStatus,
    statusDetail: detail,
    period: descriptor ? positiveIntegerOrNull(descriptor.number) : null,
    periodLabel: periodLabel(descriptor),
    clock: clock ? cleanString(clock.timeRemaining) : null,
    awayTeam: awayTeam,
    homeTeam: homeTeam,
    awayScore: integerOrNull(event.awayTeam.score),
    homeScore: integerOrNull(event.homeTeam.score),
    venue: defaultText(event.venue),
    link: absoluteNhlLink(event.gameCenterLink) || buildGameUrl(providerGameId),
    lastUpdated: null,
    isValid: true
  };
}

function parseGame(event) {
  var candidate = boundaryGame(event);
  if (!candidate) return null;
  return GameModel ? GameModel.normalizeGame(candidate) : candidate;
}

function parseScoreResponse(payload) {
  var result = {games: [], errors: []};
  if (!isRecord(payload) || !Array.isArray(payload.games)) {
    result.errors.push({index: null, code: "invalid-score-response"});
    return result;
  }

  payload.games.forEach(function(event, index) {
    var game = parseGame(event);
    if (!game || game.status === "malformed" || game.isValid !== true) {
      result.errors.push({index: index, code: "invalid-game"});
      return;
    }
    result.games.push(game);
  });
  return result;
}

function buildScoreUrl(date) {
  if (date === undefined || date === null || date === "") return NHL_BASE_URL + NHL_SCORE_PATH + "/now";
  if (typeof date !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(date)) return null;
  return NHL_BASE_URL + NHL_SCORE_PATH + "/" + date;
}

function buildNextGamesUrl(date) {
  if (typeof date !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(date)) return null;
  return NHL_BASE_URL + "/v1/schedule/" + date;
}

function buildGameUrl(providerGameId) {
  var gameId = providerId(providerGameId);
  return gameId ? NHL_SITE_URL + "/gamecenter/" + gameId : null;
}

function parseScheduleResponse(payload) {
  var result = {games: [], errors: [], nextDateKey: ""};
  if (!isRecord(payload) || !Array.isArray(payload.gameWeek)) {
    result.errors.push({index: null, code: "invalid-schedule-response"});
    return result;
  }

  payload.gameWeek.forEach(function(day, dayIndex) {
    if (!isRecord(day) || !Array.isArray(day.games)) return;
    day.games.forEach(function(event, gameIndex) {
      var game = parseGame(event);
      if (!game || game.status === "malformed" || game.isValid !== true) {
        result.errors.push({index: dayIndex + ":" + gameIndex, code: "invalid-game"});
        return;
      }
      result.games.push(game);
    });
  });

  result.nextDateKey = typeof payload.nextStartDate === "string"
    ? payload.nextStartDate : "";
  return result;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    NHL_BASE_URL: NHL_BASE_URL,
    ENDPOINT: NHL_BASE_URL + NHL_SCORE_PATH + "/now",
    buildScoreUrl: buildScoreUrl,
    buildNextGamesUrl: buildNextGamesUrl,
    buildGameUrl: buildGameUrl,
    normalizeStatus: normalizeStatus,
    parseGame: parseGame,
    parseScoreResponse: parseScoreResponse,
    parseScheduleResponse: parseScheduleResponse
  };
}

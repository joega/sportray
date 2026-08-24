var GameModel = null;
var AssetUrlPolicy = null;
var ResponsePolicy = null;
var StandingsModel = null;
if (typeof require === "function") {
  GameModel = require("../model/GameModel.js");
  AssetUrlPolicy = require("../model/AssetUrlPolicy.js");
  ResponsePolicy = require("../model/ResponsePolicy.js");
  StandingsModel = require("../model/StandingsModel.js");
}

var NHL_BASE_URL = "https://api-web.nhle.com";
var NHL_SCORE_PATH = "/v1/score";
var NHL_STANDINGS_PATH = "/v1/standings";
var NHL_SITE_URL = "https://www.nhl.com";
var MAX_EVENTS = ResponsePolicy ? ResponsePolicy.MAX_EVENTS : 256;

// The standings endpoint identifies teams by triCode, while favorites use the
// numeric IDs from the bounded current-roster catalog. Keep this map explicit
// so a provider-added or historical team cannot silently become a favorite.
var TEAM_IDS_BY_ABBREVIATION = {
  ANA: "24", BOS: "6", BUF: "7", CAR: "12", CBJ: "29", CGY: "20",
  CHI: "16", COL: "21", DAL: "25", DET: "17", EDM: "22", FLA: "13",
  LAK: "26", MIN: "30", MTL: "8", NJD: "1", NSH: "18", NYI: "2",
  NYR: "3", OTT: "9", PHI: "4", PIT: "5", SEA: "55", SJS: "28",
  STL: "19", TBL: "14", TOR: "10", UTA: "68", VAN: "23", VGK: "54",
  WPG: "52", WSH: "15"
};

var CONFERENCE_ORDER = ["E", "W"];

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

function numberOrNull(value) {
  if (typeof value === "string" && value.trim() !== "") value = Number(value.trim());
  if (typeof value !== "number" || !isFinite(value)) return null;
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

function standingsText(value) {
  return cleanString(value) || defaultText(value);
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
  if (payload.games.length > MAX_EVENTS) {
    result.errors.push({index: null, code: "too-many-events"});
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

  var eventCount = 0;
  for (var dayIndex = 0; dayIndex < payload.gameWeek.length; dayIndex++) {
    var day = payload.gameWeek[dayIndex];
    if (!isRecord(day) || !Array.isArray(day.games)) continue;
    eventCount += day.games.length;
    if (eventCount > MAX_EVENTS) {
      result.errors.push({index: null, code: "too-many-events"});
      return result;
    }
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

function standingsTeam(entry) {
  if (!isRecord(entry)) return null;

  var abbreviation = standingsText(entry.teamAbbrev);
  if (!abbreviation) return null;
  abbreviation = abbreviation.toUpperCase();
  var providerTeamId = TEAM_IDS_BY_ABBREVIATION[abbreviation];
  if (!providerTeamId) return null;

  return normalizeTeam({
    id: providerTeamId,
    name: entry.teamName,
    commonName: entry.teamCommonName,
    abbrev: abbreviation,
    logo: entry.teamLogo
  });
}

function conferenceId(entry) {
  var id = standingsText(entry.conferenceAbbrev);
  if (id) return id.toUpperCase();
  var name = standingsText(entry.conferenceName);
  return name ? name.toLowerCase().replace(/\s+/g, "-") : "league";
}

function conferenceLabel(entry) {
  var name = standingsText(entry.conferenceName);
  if (!name) return "League";
  return /conference$/i.test(name) ? name : name + " Conference";
}

function standingsRank(entry) {
  var conferenceSequence = positiveIntegerOrNull(entry.conferenceSequence);
  return conferenceSequence !== null
    ? conferenceSequence : positiveIntegerOrNull(entry.leagueSequence);
}

function standingsRecordLabel(entry) {
  var wins = integerOrNull(entry.wins);
  var losses = integerOrNull(entry.losses);
  var overtimeLosses = integerOrNull(entry.otLosses);
  if (wins === null || losses === null || overtimeLosses === null) return null;
  return wins + "-" + losses + "-" + overtimeLosses;
}

function normalizeStandingsEntry(entry) {
  if (!isRecord(entry)) return null;
  var team = standingsTeam(entry);
  if (!team) return null;

  return {
    team: team,
    rank: standingsRank(entry),
    played: integerOrNull(entry.gamesPlayed),
    wins: integerOrNull(entry.wins),
    losses: integerOrNull(entry.losses),
    // NHL's third record value is overtime losses, not ties. The generic
    // standings projection uses this slot for the sport's third record value.
    ties: integerOrNull(entry.otLosses),
    points: integerOrNull(entry.points),
    differential: numberOrNull(entry.goalDifferential),
    recordLabel: standingsRecordLabel(entry),
    conferenceId: conferenceId(entry),
    conferenceLabel: conferenceLabel(entry)
  };
}

function orderedConferenceGroups(groupMap) {
  var groups = [];
  CONFERENCE_ORDER.forEach(function(id) {
    if (groupMap[id]) groups.push(groupMap[id]);
  });
  Object.keys(groupMap).forEach(function(id) {
    if (CONFERENCE_ORDER.indexOf(id) === -1) groups.push(groupMap[id]);
  });
  return groups;
}

function parseStandingsResponse(payload) {
  var result = {leagueId: "nhl", groups: [], rows: [], errors: []};
  if (!isRecord(payload) || !Array.isArray(payload.standings)) {
    result.errors.push({index: null, code: "invalid-standings-response"});
    return result;
  }
  if (payload.standings.length > MAX_EVENTS) {
    result.errors.push({index: null, code: "too-many-standings"});
    return result;
  }

  var groupMap = {};
  payload.standings.forEach(function(entry, index) {
    var normalized = normalizeStandingsEntry(entry);
    if (!normalized) {
      result.errors.push({index: index, code: "invalid-standing-entry"});
      return;
    }
    var id = normalized.conferenceId;
    if (!groupMap[id]) {
      groupMap[id] = {
        id: id,
        label: normalized.conferenceLabel,
        entries: []
      };
    }
    groupMap[id].entries.push(normalized);
  });

  var groups = orderedConferenceGroups(groupMap);
  return StandingsModel
    ? StandingsModel.normalizeGroups(groups, "nhl", result.errors)
    : result;
}

function buildStandingsUrl(date) {
  if (date === undefined || date === null || date === "")
    return NHL_BASE_URL + NHL_STANDINGS_PATH + "/now";
  if (typeof date !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(date)) return null;
  return NHL_BASE_URL + NHL_STANDINGS_PATH + "/" + date;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    NHL_BASE_URL: NHL_BASE_URL,
    ENDPOINT: NHL_BASE_URL + NHL_SCORE_PATH + "/now",
    STANDINGS_ENDPOINT: NHL_BASE_URL + NHL_STANDINGS_PATH + "/now",
    buildScoreUrl: buildScoreUrl,
    buildStandingsUrl: buildStandingsUrl,
    buildNextGamesUrl: buildNextGamesUrl,
    buildGameUrl: buildGameUrl,
    normalizeStatus: normalizeStatus,
    parseGame: parseGame,
    parseScoreResponse: parseScoreResponse,
    parseScheduleResponse: parseScheduleResponse,
    normalizeStandingsEntry: normalizeStandingsEntry,
    parseStandingsResponse: parseStandingsResponse
  };
}

var TeamModel = null;
var AssetUrlPolicy = null;
if (typeof require === "function") {
  TeamModel = require("./TeamModel.js");
  AssetUrlPolicy = require("./AssetUrlPolicy.js");
}

var GAME_STATES = {
  SCHEDULED: "scheduled",
  LIVE: "live",
  INTERMISSION: "intermission",
  FINAL: "final",
  POSTPONED: "postponed",
  CANCELED: "canceled",
  UNKNOWN: "unknown",
  MALFORMED: "malformed"
};

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function cleanString(value) {
  if (typeof value !== "string") return null;
  var result = value.trim();
  return result || null;
}

function safeLogoUrl(value) {
  if (AssetUrlPolicy) return AssetUrlPolicy.safeLogoUrl(value);

  var url = cleanString(value);
  if (!url || !/^https:\/\//i.test(url)) return null;
  var match = /^https:\/\/([^/?#]+)(?:[/?#]|$)/i.exec(url);
  if (!match) return null;
  var host = match[1].toLowerCase();
  return host === "a.espncdn.com" || host === "assets.nhle.com" ? url : null;
}

function safeUrl(value) {
  var url = cleanString(value);
  if (!url || !/^https?:\/\//i.test(url)) return null;
  return url;
}

function safeGameUrl(value) {
  var url = cleanString(value);
  if (!url || !/^https:\/\//i.test(url)) return null;
  var match = /^https:\/\/([^/?#]+)(?:[/?#]|$)/i.exec(url);
  if (!match) return null;
  var host = match[1].toLowerCase();
  return host === "espn.com" || host === "www.espn.com"
    || host === "nhl.com" || host === "www.nhl.com"
    || host === "mlb.com" || host === "www.mlb.com" ? url : null;
}

function normalizePrimaryColor(value) {
  var color = cleanString(value);
  if (!color) return null;
  if (color.charAt(0) === "#") color = color.slice(1);
  return /^[0-9a-f]{6}$/i.test(color) ? "#" + color.toLowerCase() : null;
}

function normalizeLeague(value) {
  var result = cleanString(value);
  return result ? result.toLowerCase() : null;
}

function normalizeProviderGameId(value) {
  if (typeof value === "number" && isFinite(value)) value = String(value);
  return cleanString(value);
}

function normalizeTimestamp(value) {
  if (typeof value !== "string" && !(value instanceof Date)) return null;
  var date = new Date(value);
  if (isNaN(date.getTime())) return null;
  return date.toISOString();
}

function normalizeScore(value) {
  if (typeof value === "string" && /^\d+$/.test(value.trim())) value = Number(value);
  if (typeof value !== "number" || !isFinite(value) || value < 0 || Math.floor(value) !== value)
    return null;
  return value;
}

function normalizePeriod(value) {
  if (typeof value === "string" && /^\d+$/.test(value.trim())) value = Number(value);
  if (typeof value !== "number" || !isFinite(value) || value < 1 || Math.floor(value) !== value)
    return null;
  return value;
}

function normalizeState(value) {
  var state = cleanString(value);
  if (!state) return GAME_STATES.UNKNOWN;

  state = state.toLowerCase().replace(/[ _-]+/g, "");
  if (state === "scheduled" || state === "pregame" || state === "notstarted")
    return GAME_STATES.SCHEDULED;
  if (state === "live" || state === "inprogress" || state === "playing")
    return GAME_STATES.LIVE;
  if (state === "intermission" || state === "halftime" || state === "break")
    return GAME_STATES.INTERMISSION;
  if (state === "final" || state === "finished" || state === "completed")
    return GAME_STATES.FINAL;
  if (state === "postponed" || state === "delayed") return GAME_STATES.POSTPONED;
  if (state === "canceled" || state === "cancelled") return GAME_STATES.CANCELED;
  return GAME_STATES.UNKNOWN;
}

function normalizeTeamBoundary(input) {
  if (TeamModel) return TeamModel.normalizeTeam(input);
  if (!isRecord(input)) return null;

  var league = normalizeLeague(input.league);
  var providerTeamId = normalizeProviderGameId(input.providerTeamId);
  var id = cleanString(input.id);
  if (!league || !providerTeamId || id !== league + ":" + providerTeamId) return null;

  return {
    id: id,
    league: league,
    providerTeamId: providerTeamId,
    name: cleanString(input.name),
    shortName: cleanString(input.shortName),
    abbreviation: cleanString(input.abbreviation),
    primaryColor: TeamModel && TeamModel.normalizePrimaryColor
      ? TeamModel.normalizePrimaryColor(input.primaryColor)
      : normalizePrimaryColor(input.primaryColor),
    logoUrl: safeLogoUrl(input.logoUrl),
    link: safeUrl(input.link)
  };
}

function emptyGame(state) {
  return {
    id: null,
    league: null,
    providerGameId: null,
    startTime: null,
    endTime: null,
    status: state || GAME_STATES.UNKNOWN,
    statusDetail: null,
    period: null,
    periodLabel: null,
    clock: null,
    awayTeam: null,
    homeTeam: null,
    awayScore: null,
    homeScore: null,
    venue: null,
    link: null,
    lastUpdated: null,
    isValid: false
  };
}

function normalizeGame(input) {
  if (!isRecord(input)) return emptyGame(GAME_STATES.MALFORMED);

  var league = normalizeLeague(input.league);
  var providerGameId = normalizeProviderGameId(input.providerGameId);
  if (!league || !providerGameId) return emptyGame(GAME_STATES.MALFORMED);

  var status = normalizeState(input.status);
  var awayTeam = normalizeTeamBoundary(input.awayTeam);
  var homeTeam = normalizeTeamBoundary(input.homeTeam);

  return {
    id: league + ":" + providerGameId,
    league: league,
    providerGameId: providerGameId,
    startTime: normalizeTimestamp(input.startTime),
    endTime: normalizeTimestamp(input.endTime),
    status: status,
    statusDetail: cleanString(input.statusDetail),
    period: normalizePeriod(input.period),
    periodLabel: cleanString(input.periodLabel),
    clock: cleanString(input.clock),
    awayTeam: awayTeam,
    homeTeam: homeTeam,
    awayScore: normalizeScore(input.awayScore),
    homeScore: normalizeScore(input.homeScore),
    venue: cleanString(input.venue),
    link: safeGameUrl(input.link),
    lastUpdated: normalizeTimestamp(input.lastUpdated),
    isValid: true
  };
}

function createDefaultGame() {
  return emptyGame(GAME_STATES.UNKNOWN);
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    GAME_STATES: GAME_STATES,
    normalizeTimestamp: normalizeTimestamp,
    normalizeState: normalizeState,
    normalizeScore: normalizeScore,
    normalizeGame: normalizeGame,
    createDefaultGame: createDefaultGame
  };
}

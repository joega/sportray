var GameModel = null;
var AssetUrlPolicy = null;
var ResponsePolicy = null;
var StandingsModel = null;
var GameDetailModel = null;
if (typeof require === "function") {
  GameModel = require("../model/GameModel.js");
  AssetUrlPolicy = require("../model/AssetUrlPolicy.js");
  ResponsePolicy = require("../model/ResponsePolicy.js");
  StandingsModel = require("../model/StandingsModel.js");
  GameDetailModel = require("../model/GameDetailModel.js");
}

var ESPN_BASE_URL = "https://site.api.espn.com/apis/site/v2/sports";
var ESPN_PROVIDER = "espn";
var MAX_EVENTS = ResponsePolicy ? ResponsePolicy.MAX_EVENTS : 256;

var LEAGUE_METADATA = {
  nfl: {id: "nfl", displayName: "NFL", sport: "football", slug: "nfl"},
  mlb: {id: "mlb", displayName: "MLB", sport: "baseball", slug: "mlb"},
  nba: {id: "nba", displayName: "NBA", sport: "basketball", slug: "nba"},
  "college-football": {
    id: "college-football", displayName: "NCAA Football", sport: "football", slug: "college-football"
  },
  "eng.1": {
    id: "eng.1", displayName: "Premier League", sport: "soccer", slug: "eng.1"
  },
  "usa.1": {
    id: "usa.1", displayName: "MLS", sport: "soccer", slug: "usa.1"
  },
  "mens-college-basketball": {
    id: "mens-college-basketball", displayName: "NCAA Men's Basketball",
    sport: "basketball", slug: "mens-college-basketball"
  }
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

function safeUrl(value) {
  var url = cleanString(value);
  return url && /^https?:\/\//i.test(url) ? url : null;
}

function safeLogoUrl(value) {
  if (AssetUrlPolicy) return AssetUrlPolicy.safeLogoUrl(value);

  var url = cleanString(value);
  if (!url || !/^https:\/\//i.test(url)) return null;
  var match = /^https:\/\/([^/?#]+)(?:[/?#]|$)/i.exec(url);
  if (!match) return null;
  return match[1].toLowerCase() === "a.espncdn.com" ? url : null;
}

function safeGameUrl(value) {
  var url = cleanString(value);
  if (!url || !/^https:\/\//i.test(url)) return null;
  var match = /^https:\/\/([^/?#]+)(?:[/?#]|$)/i.exec(url);
  if (!match) return null;
  var host = match[1].toLowerCase();
  return host === "espn.com" || host === "www.espn.com" ? url : null;
}

function normalizeTimestamp(value) {
  if (typeof value !== "string") return null;
  var date = new Date(value);
  return isNaN(date.getTime()) ? null : date.toISOString();
}

function metadataFor(leagueId) {
  if (typeof leagueId !== "string") return null;
  var normalized = leagueId.trim().toLowerCase();
  return LEAGUE_METADATA[normalized] || null;
}

function buildScoreUrl(leagueId, date) {
  var metadata = metadataFor(leagueId);
  if (!metadata) return null;

  var url = ESPN_BASE_URL + "/" + metadata.sport + "/" + metadata.slug + "/scoreboard";
  if (date === undefined || date === null || date === "") return url;
  if (typeof date !== "string" || !/^\d{8}$/.test(date)) return null;
  return url + "?dates=" + date;
}

function buildNextGamesUrl(leagueId, startDate, endDate) {
  if (typeof startDate !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(startDate)
      || typeof endDate !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(endDate)) return null;
  var start = typeof startDate === "string" ? startDate.replace(/-/g, "") : "";
  var end = typeof endDate === "string" ? endDate.replace(/-/g, "") : "";
  if (!/^\d{8}$/.test(start) || !/^\d{8}$/.test(end)) return null;
  var metadata = metadataFor(leagueId);
  if (!metadata) return null;
  return ESPN_BASE_URL + "/" + metadata.sport + "/" + metadata.slug
    + "/scoreboard?dates=" + start + "-" + end;
}

function buildStandingsUrl(leagueId) {
  var metadata = metadataFor(leagueId);
  if (!metadata) return null;
  return ESPN_BASE_URL + "/" + metadata.sport + "/" + metadata.slug + "/standings";
}

function buildGameUrl(leagueId, providerGameId) {
  var metadata = metadataFor(leagueId);
  var gameId = providerId(providerGameId);
  if (!metadata || !gameId) return null;
  var sportPath = metadata.sport === "soccer" ? "soccer" : metadata.slug;
  return "https://www.espn.com/" + sportPath + "/game/_/gameId/" + gameId;
}

function errorFor(leagueId, code, index) {
  return {
    provider: ESPN_PROVIDER,
    league: leagueId || null,
    endpoint: buildScoreUrl(leagueId) || ESPN_BASE_URL,
    index: index === undefined ? null : index,
    code: code
  };
}

function findLink(links) {
  if (!Array.isArray(links)) return null;
  var first = null;
  for (var i = 0; i < links.length; i++) {
    if (!isRecord(links[i])) continue;
    var href = safeGameUrl(links[i].href);
    if (!href) continue;
    if (Array.isArray(links[i].rel) && links[i].rel.indexOf("event") !== -1) return href;
    if (!first) first = href;
  }
  return first;
}

function teamLink(team) {
  if (!isRecord(team)) return null;
  var links = team.links;
  if (!Array.isArray(links)) return null;
  for (var i = 0; i < links.length; i++) {
    if (!isRecord(links[i])) continue;
    var href = safeUrl(links[i].href);
    if (href) return href;
  }
  return null;
}

function normalizeTeam(competitor, leagueId) {
  if (!isRecord(competitor) || !isRecord(competitor.team)) return null;
  var team = competitor.team;
  var providerTeamId = providerId(competitor.id || team.id);
  if (!providerTeamId) return null;
  return {
    id: leagueId + ":" + providerTeamId,
    league: leagueId,
    providerTeamId: providerTeamId,
    name: cleanString(team.displayName) || cleanString(team.name),
    shortName: cleanString(team.shortDisplayName) || cleanString(team.name),
    abbreviation: cleanString(team.abbreviation),
    primaryColor: cleanString(team.color),
    logoUrl: safeLogoUrl(team.logo),
    link: teamLink(team)
  };
}

function normalizeStatus(status) {
  if (!isRecord(status) || !isRecord(status.type)) return "unknown";
  var state = cleanString(status.type.state);
  state = state ? state.toLowerCase() : null;
  var typeName = cleanString(status.type.name);
  typeName = typeName ? typeName.toUpperCase() : "";

  if (typeName.indexOf("POSTPON") !== -1 || typeName.indexOf("DELAY") !== -1) return "postponed";
  if (typeName.indexOf("CANCEL") !== -1) return "canceled";
  if (state === "post" || status.type.completed === true) return "final";
  if (state === "pre") return "scheduled";
  if (state === "in") {
    if (typeName.indexOf("HALFTIME") !== -1 || typeName.indexOf("INTERMISSION") !== -1
      || typeName.indexOf("BREAK") !== -1) return "intermission";
    return "live";
  }
  return "unknown";
}

function statusDetail(status) {
  if (!isRecord(status) || !isRecord(status.type)) return null;
  return cleanString(status.type.detail) || cleanString(status.type.shortDetail)
    || cleanString(status.type.description);
}

function statusPeriod(status) {
  return isRecord(status) ? integerOrNull(status.period) : null;
}

function statusClock(status, normalizedStatus) {
  if (!isRecord(status) || normalizedStatus === "scheduled") return null;
  return cleanString(status.displayClock);
}

function scoreFor(competitor, normalizedStatus) {
  if (normalizedStatus === "scheduled") return null;
  return isRecord(competitor) ? integerOrNull(competitor.score) : null;
}

function findCompetition(event) {
  if (!isRecord(event) || !Array.isArray(event.competitions) || event.competitions.length === 0)
    return null;
  return isRecord(event.competitions[0]) ? event.competitions[0] : null;
}

function boundaryGame(event, leagueId) {
  if (!isRecord(event)) return null;
  var competition = findCompetition(event);
  if (!competition || !Array.isArray(competition.competitors)) return null;

  var away = null;
  var home = null;
  for (var i = 0; i < competition.competitors.length; i++) {
    var competitor = competition.competitors[i];
    if (!isRecord(competitor)) continue;
    if (competitor.homeAway === "away" && !away) away = competitor;
    if (competitor.homeAway === "home" && !home) home = competitor;
  }
  var awayTeam = normalizeTeam(away, leagueId);
  var homeTeam = normalizeTeam(home, leagueId);
  var providerGameId = providerId(event.id || competition.id);
  if (!providerGameId || !awayTeam || !homeTeam) return null;

  var status = isRecord(competition.status) ? competition.status
    : (isRecord(event.status) ? event.status : null);
  var normalizedStatus = normalizeStatus(status);
  var detail = statusDetail(status);
  var period = statusPeriod(status);
  var periodLabel = normalizedStatus === "live" || normalizedStatus === "intermission" ? detail : null;

  return {
    id: leagueId + ":" + providerGameId,
    league: leagueId,
    providerGameId: providerGameId,
    startTime: normalizeTimestamp(event.date || event.startDate || competition.date),
    endTime: null,
    status: normalizedStatus,
    statusDetail: detail,
    period: period,
    periodLabel: periodLabel,
    clock: statusClock(status, normalizedStatus),
    awayTeam: awayTeam,
    homeTeam: homeTeam,
    awayScore: scoreFor(away, normalizedStatus),
    homeScore: scoreFor(home, normalizedStatus),
    venue: isRecord(competition.venue) ? cleanString(competition.venue.fullName) : null,
    link: findLink(event.links) || buildGameUrl(leagueId, providerGameId),
    lastUpdated: null,
    isValid: true
  };
}

function parseGame(event, leagueId) {
  var candidate = boundaryGame(event, leagueId);
  if (!candidate) return null;
  return GameModel ? GameModel.normalizeGame(candidate) : candidate;
}

function parseScoreboardResponse(payload, leagueId) {
  var result = {games: [], errors: []};
  var metadata = metadataFor(leagueId);
  if (!metadata) {
    result.errors.push(errorFor(leagueId, "unsupported-league", null));
    return result;
  }
  if (!isRecord(payload) || !Array.isArray(payload.events)) {
    result.errors.push(errorFor(leagueId, "invalid-scoreboard-response", null));
    return result;
  }
  if (payload.events.length > MAX_EVENTS) {
    result.errors.push(errorFor(metadata.id, "too-many-events", null));
    return result;
  }

  for (var i = 0; i < payload.events.length; i++) {
    var game = parseGame(payload.events[i], metadata.id);
    if (!game || game.status === "malformed" || game.isValid !== true) {
      result.errors.push(errorFor(metadata.id, "invalid-event", i));
      continue;
    }
    result.games.push(game);
  }
  return result;
}

function parseNextGamesResponse(payload, leagueId) {
  return parseScoreboardResponse(payload, leagueId);
}

function parseGameDetailResponse(payload, leagueId) {
  var scoreboard = parseScoreboardResponse(payload, leagueId);
  if (!GameDetailModel) return {details: [], errors: scoreboard.errors};
  var details = GameDetailModel.normalizeDetails(scoreboard.games, {
    provider: ESPN_PROVIDER,
    label: "ESPN"
  });
  return {
    details: details.details,
    errors: scoreboard.errors.concat(details.errors)
  };
}

function standingsStat(stats, names) {
  if (!Array.isArray(stats) || !Array.isArray(names)) return null;
  for (var i = 0; i < stats.length; i++) {
    if (!isRecord(stats[i]) || names.indexOf(stats[i].name) === -1) continue;
    return stats[i];
  }
  return null;
}

function standingsNumber(stats, names) {
  var stat = standingsStat(stats, names);
  if (!stat) return null;
  var value = stat.value;
  if (typeof value === "string" && value.trim() !== "") value = Number(value.trim());
  if (typeof value !== "number" || !isFinite(value) || Math.floor(value) !== value) return null;
  return value;
}

function standingsTeam(rawTeam, leagueId) {
  if (!isRecord(rawTeam)) return null;
  var logo = rawTeam.logo;
  if (!logo && Array.isArray(rawTeam.logos) && isRecord(rawTeam.logos[0]))
    logo = rawTeam.logos[0].href;
  return normalizeTeam({id: rawTeam.id, team: {
    id: rawTeam.id,
    displayName: rawTeam.displayName || rawTeam.name,
    shortDisplayName: rawTeam.shortDisplayName || rawTeam.abbreviation,
    abbreviation: rawTeam.abbreviation,
    logo: logo,
    links: rawTeam.links
  }}, leagueId);
}

function normalizeStandingsEntry(entry, leagueId) {
  if (!isRecord(entry) || !isRecord(entry.team)) return null;
  var stats = Array.isArray(entry.stats) ? entry.stats : [];
  var wins = standingsNumber(stats, ["wins"]);
  var losses = standingsNumber(stats, ["losses"]);
  var draws = standingsNumber(stats, ["draws"]);
  var ties = standingsNumber(stats, ["ties"]);
  var points = standingsNumber(stats, ["points", "leaguePoints"]);
  var differential = standingsNumber(stats, ["pointDifferential", "goalDifference", "differential"]);
  var played = standingsNumber(stats, ["gamesPlayed", "eventsPlayed", "played"]);
  var rank = integerOrNull(entry.rank);
  if (rank === null) rank = standingsNumber(stats, ["rank", "order"]);
  var record = standingsStat(stats, ["record"]);
  var recordLabel = record ? cleanString(record.displayValue) : null;

  return {
    team: standingsTeam(entry.team, leagueId),
    rank: rank,
    played: played,
    wins: wins,
    losses: losses,
    draws: draws,
    ties: ties,
    points: points,
    differential: differential,
    recordLabel: recordLabel
  };
}

function parseStandingsResponse(payload, leagueId) {
  var result = {leagueId: leagueId || "", groups: [], rows: [], errors: []};
  var metadata = metadataFor(leagueId);
  if (!metadata) {
    result.errors.push(errorFor(leagueId, "unsupported-league", null));
    return result;
  }
  if (!isRecord(payload) || !Array.isArray(payload.standings)) {
    result.errors.push({provider: ESPN_PROVIDER, league: metadata.id,
      endpoint: buildStandingsUrl(metadata.id), index: null,
      code: "invalid-standings-response"});
    return result;
  }

  var groups = [];
  payload.standings.forEach(function(standing, index) {
    if (!isRecord(standing) || !Array.isArray(standing.entries)) {
      result.errors.push({provider: ESPN_PROVIDER, league: metadata.id,
        endpoint: buildStandingsUrl(metadata.id), index: index,
        code: "invalid-standings-group"});
      return;
    }
    var groupId = providerId(standing.id || standing.uid || standing.name) || "group-" + index;
    var groupLabel = cleanString(standing.displayName) || cleanString(standing.name)
      || "Standings";
    var entries = [];
    standing.entries.forEach(function(entry, entryIndex) {
      var normalized = normalizeStandingsEntry(entry, metadata.id);
      if (!normalized || !normalized.team) {
        result.errors.push({provider: ESPN_PROVIDER, league: metadata.id,
          endpoint: buildStandingsUrl(metadata.id), index: entryIndex, group: groupId,
          code: "invalid-standing-entry"});
        return;
      }
      entries.push(normalized);
    });
    groups.push({id: groupId, label: groupLabel, entries: entries});
  });

  return StandingsModel
    ? StandingsModel.normalizeGroups(groups, metadata.id, result.errors)
    : result;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    ESPN_BASE_URL: ESPN_BASE_URL,
    ESPN_PROVIDER: ESPN_PROVIDER,
    LEAGUE_METADATA: LEAGUE_METADATA,
    metadataFor: metadataFor,
    buildScoreUrl: buildScoreUrl,
    buildNextGamesUrl: buildNextGamesUrl,
    buildStandingsUrl: buildStandingsUrl,
    buildGameUrl: buildGameUrl,
    normalizeStatus: normalizeStatus,
    parseGame: parseGame,
    parseScoreboardResponse: parseScoreboardResponse,
    parseNextGamesResponse: parseNextGamesResponse,
    parseGameDetailResponse: parseGameDetailResponse,
    parseStandingsResponse: parseStandingsResponse,
    normalizeStandingsEntry: normalizeStandingsEntry
  };
}

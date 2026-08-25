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

var MAX_EVENT_LINKS = 2;

function eventLinks(event) {
  var result = [];
  if (!isRecord(event)) return result;

  var competition = findCompetition(event);
  var highlights = competition && Array.isArray(competition.highlights)
    ? competition.highlights : null;
  if (highlights) {
    for (var i = 0; i < highlights.length; i++) {
      var highlight = highlights[i];
      var webHref = isRecord(highlight) && isRecord(highlight.links)
        && isRecord(highlight.links.web) ? safeGameUrl(highlight.links.web.href) : null;
      if (!webHref) continue;
      result.push({key: "highlights", label: "Highlights", url: webHref});
      break;
    }
  }

  if (result.length < MAX_EVENT_LINKS && Array.isArray(event.links)) {
    for (var j = 0; j < event.links.length; j++) {
      var link = event.links[j];
      if (!isRecord(link)) continue;
      if (!Array.isArray(link.rel) || link.rel.indexOf("preview") === -1) continue;
      var href = safeGameUrl(link.href);
      if (!href) continue;
      result.push({key: "preview", label: "Preview", url: href});
      break;
    }
  }
  return result;
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

  var lines = detailLinesByGameId(payload);
  var stats = detailStatsByGameId(payload);
  var situations = detailSituationByGameId(payload);
  var odds = detailOddsByGameId(payload);

  for (var i = 0; i < payload.events.length; i++) {
    var game = parseGame(payload.events[i], metadata.id);
    if (!game || game.status === "malformed" || game.isValid !== true) {
      result.errors.push(errorFor(metadata.id, "invalid-event", i));
      continue;
    }
    var eventLines = lines[game.providerGameId];
    var eventStats = stats[game.providerGameId];
    var eventSituation = situations[game.providerGameId];
    var eventOdds = odds[game.providerGameId];
    if (eventLines) game.lines = eventLines;
    if (eventStats) game.stats = eventStats;
    if (eventSituation) game.situation = eventSituation;
    if (eventOdds) game.odds = eventOdds;
    var links = eventLinks(payload.events[i]);
    if (links.length > 0) game.links = links;
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

function competitionLineSide(competitor) {
  if (!isRecord(competitor) || !Array.isArray(competitor.linescores)) return null;
  var entries = [];
  for (var i = 0; i < competitor.linescores.length; i++) {
    var raw = competitor.linescores[i];
    if (!isRecord(raw)) return null;
    var period = integerOrNull(raw.period);
    var value = integerOrNull(raw.value);
    if (period === null || value === null) return null;
    entries.push({period: period, value: value});
  }
  return entries.length > 0 ? entries : null;
}

function detailLinesByGameId(payload) {
  var result = {};
  if (!isRecord(payload) || !Array.isArray(payload.events)) return result;

  for (var i = 0; i < payload.events.length; i++) {
    var event = payload.events[i];
    var competition = findCompetition(event);
    if (!competition || !Array.isArray(competition.competitors)) continue;

    var away = null;
    var home = null;
    for (var j = 0; j < competition.competitors.length; j++) {
      var competitor = competition.competitors[j];
      if (!isRecord(competitor)) continue;
      if (competitor.homeAway === "away" && !away)
        away = competitionLineSide(competitor);
      if (competitor.homeAway === "home" && !home)
        home = competitionLineSide(competitor);
    }
    if (!away || !home) continue;

    var providerGameId = providerId(event.id || competition.id);
    if (!providerGameId) continue;
    result[providerGameId] = {away: away, home: home};
  }
  return result;
}

var MAX_SITUATION_TEXT_LENGTH = GameDetailModel
  ? GameDetailModel.MAX_SITUATION_TEXT_LENGTH : 160;

var MAX_ODDS_DETAILS_LENGTH = GameDetailModel
  ? GameDetailModel.MAX_ODDS_DETAILS_LENGTH : 48;
var MAX_ODDS_PROVIDER_LENGTH = GameDetailModel
  ? GameDetailModel.MAX_ODDS_PROVIDER_LENGTH : 32;

function competitionOdds(competition) {
  if (!isRecord(competition) || !Array.isArray(competition.odds)) return null;
  var raw = isRecord(competition.odds[0]) ? competition.odds[0] : null;
  if (!raw) return null;

  var details = cleanString(raw.details);
  if (!details) return null;
  if (details.length > MAX_ODDS_DETAILS_LENGTH)
    details = details.slice(0, MAX_ODDS_DETAILS_LENGTH);
  var provider = isRecord(raw.provider) ? cleanString(raw.provider.name) : null;
  if (!provider) return null;
  if (provider.length > MAX_ODDS_PROVIDER_LENGTH)
    provider = provider.slice(0, MAX_ODDS_PROVIDER_LENGTH);
  var overUnder = raw.overUnder;
  if (typeof overUnder !== "number" || !isFinite(overUnder)) overUnder = null;
  return {details: details, overUnder: overUnder, provider: provider};
}

function detailOddsByGameId(payload) {
  var result = {};
  if (!isRecord(payload) || !Array.isArray(payload.events)) return result;

  for (var i = 0; i < payload.events.length; i++) {
    var event = payload.events[i];
    var competition = findCompetition(event);
    var odds = competitionOdds(competition);
    if (!odds) continue;

    var providerGameId = providerId(event.id || (competition && competition.id));
    if (!providerGameId) continue;
    result[providerGameId] = odds;
  }
  return result;
}

function competitionSituation(competition) {
  if (!isRecord(competition) || !isRecord(competition.situation)) return null;
  var raw = competition.situation;
  var balls = integerOrNull(raw.balls);
  var strikes = integerOrNull(raw.strikes);
  var outs = integerOrNull(raw.outs);
  var onFirst = raw.onFirst;
  var onSecond = raw.onSecond;
  var onThird = raw.onThird;
  if (balls === null || strikes === null || outs === null) return null;
  if (typeof onFirst !== "boolean" || typeof onSecond !== "boolean"
      || typeof onThird !== "boolean") return null;
  var lastPlay = isRecord(raw.lastPlay) ? cleanString(raw.lastPlay.text) : null;
  if (lastPlay && lastPlay.length > MAX_SITUATION_TEXT_LENGTH)
    lastPlay = lastPlay.slice(0, MAX_SITUATION_TEXT_LENGTH);
  return {
    balls: balls,
    strikes: strikes,
    outs: outs,
    onFirst: onFirst,
    onSecond: onSecond,
    onThird: onThird,
    lastPlay: lastPlay
  };
}

function detailSituationByGameId(payload) {
  var result = {};
  if (!isRecord(payload) || !Array.isArray(payload.events)) return result;

  for (var i = 0; i < payload.events.length; i++) {
    var event = payload.events[i];
    var competition = findCompetition(event);
    var situation = competitionSituation(competition);
    if (!situation) continue;

    var providerGameId = providerId(event.id || competition.id);
    if (!providerGameId) continue;
    result[providerGameId] = situation;
  }
  return result;
}

var DETAIL_STAT_KEYS = {hits: "Hits", errors: "Errors"};

function competitionStatSide(competitor) {
  if (!isRecord(competitor)) return null;
  var entries = [];
  Object.keys(DETAIL_STAT_KEYS).forEach(function(key) {
    var value = integerOrNull(competitor[key]);
    if (value === null) return;
    entries.push({key: key, label: DETAIL_STAT_KEYS[key], value: value});
  });
  return entries.length > 0 ? entries : null;
}

function detailStatsByGameId(payload) {
  var result = {};
  if (!isRecord(payload) || !Array.isArray(payload.events)) return result;

  for (var i = 0; i < payload.events.length; i++) {
    var event = payload.events[i];
    var competition = findCompetition(event);
    if (!competition || !Array.isArray(competition.competitors)) continue;

    var away = null;
    var home = null;
    for (var j = 0; j < competition.competitors.length; j++) {
      var competitor = competition.competitors[j];
      if (!isRecord(competitor)) continue;
      if (competitor.homeAway === "away" && !away)
        away = competitionStatSide(competitor);
      if (competitor.homeAway === "home" && !home)
        home = competitionStatSide(competitor);
    }
    if (!away || !home) continue;

    var providerGameId = providerId(event.id || competition.id);
    if (!providerGameId) continue;
    result[providerGameId] = {away: away, home: home};
  }
  return result;
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
    eventLinks: eventLinks,
    MAX_EVENT_LINKS: MAX_EVENT_LINKS,
    parseGame: parseGame,
    parseScoreboardResponse: parseScoreboardResponse,
    parseNextGamesResponse: parseNextGamesResponse,
    parseGameDetailResponse: parseGameDetailResponse,
    parseStandingsResponse: parseStandingsResponse,
    normalizeStandingsEntry: normalizeStandingsEntry
  };
}

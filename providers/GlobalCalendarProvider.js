// Global calendar discovery reads one selected provider day per followed
// league. Unvisited days remain unknown; this never starts month hydration.
var ResponsePolicy = null;
var NhlProvider = null;
var EspnProvider = null;
var MlbStatsProvider = null;
if (typeof require === "function") {
  ResponsePolicy = require("../model/ResponsePolicy.js");
  NhlProvider = require("./NhlProvider.js");
  EspnProvider = require("./EspnProvider.js");
  MlbStatsProvider = require("./MlbStatsProvider.js");
}
var MAX_RESPONSE_BYTES = ResponsePolicy ? ResponsePolicy.MAX_RESPONSE_BYTES : 2 * 1024 * 1024;
var MAX_RESPONSE_CHARS = ResponsePolicy ? ResponsePolicy.MAX_RESPONSE_CHARS : 699050;
var MAX_EVENTS = ResponsePolicy ? ResponsePolicy.MAX_EVENTS : 256;
var MAX_LEAGUES = 8;
var ESPN_EVENT_CAP = 100;
var ESPN_PATHS = {
  nfl: "football/nfl", nba: "basketball/nba",
  "college-football": "football/college-football",
  "mens-college-basketball": "basketball/mens-college-basketball",
  "eng.1": "soccer/eng.1", "usa.1": "soccer/usa.1"
};
var ESPN_LEAGUE_IDS = {nfl: "28", nba: "46", "college-football": "23",
  "mens-college-basketball": "41", "eng.1": "700", "usa.1": "770"};

function espnLeague(value) { return Object.prototype.hasOwnProperty.call(ESPN_PATHS, value); }

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function validDate(value) {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  var instant = new Date(value + "T12:00:00Z");
  return !isNaN(instant.getTime()) && instant.toISOString().slice(0, 10) === value;
}

function addDays(value, days) {
  return new Date(new Date(value + "T12:00:00Z").getTime() + days * 86400000)
    .toISOString().slice(0, 10);
}

function localDate(value) {
  var instant = new Date(value);
  if (isNaN(instant.getTime())) return "";
  function pad(number) { return number < 10 ? "0" + number : String(number); }
  return instant.getFullYear() + "-" + pad(instant.getMonth() + 1) + "-" + pad(instant.getDate());
}

function boundedIds(value) {
  if (value === null || typeof value !== "object") return null;
  var length = value.length;
  if (typeof length !== "number" || !isFinite(length) || length < 0 || length > MAX_LEAGUES
      || Math.floor(length) !== length) return null;
  var result = [];
  for (var i = 0; i < length; i++) {
    if (typeof value[i] !== "string") return null;
    var id = value[i].trim().toLowerCase();
    if ((id === "nhl" || id === "mlb" || espnLeague(id)) && result.indexOf(id) === -1) result.push(id);
  }
  return result;
}

function buildUrl(leagueId, dateKey) {
  if (leagueId === "nhl") return NhlProvider ? NhlProvider.buildScoreUrl(dateKey)
    : "https://api-web.nhle.com/v1/score/" + dateKey;
  if (leagueId === "mlb") return MlbStatsProvider ? MlbStatsProvider.buildScoreUrl(dateKey)
    : "https://statsapi.mlb.com/api/v1/schedule?sportId=1&date=" + dateKey + "&hydrate=team,linescore";
  if (!espnLeague(leagueId)) return "";
  return EspnProvider ? EspnProvider.buildScoreUrl(leagueId, dateKey.replace(/-/g, ""))
    : "https://site.api.espn.com/apis/site/v2/sports/" + ESPN_PATHS[leagueId]
      + "/scoreboard?dates=" + dateKey.replace(/-/g, "");
}

function buildPlan(followedLeagueIds, enabledLeagueIds, dateKey) {
  var followed = boundedIds(followedLeagueIds), enabled = boundedIds(enabledLeagueIds);
  if (!followed || !enabled || !validDate(dateKey))
    return {kind: "invalid", scope: "global", requests: [], reason: "invalid-selection", maxConcurrency: 1};
  var selected = followed.filter(function(id) { return enabled.indexOf(id) !== -1; });
  var selectionKey = selected.slice().sort().join(",");
  return {kind: selected.length ? "plan" : "empty", scope: "global", teamId: "", leagueId: "",
    startDate: dateKey, endDate: dateKey, selectionKey: selectionKey,
    cacheKey: "global:" + selectionKey + ":" + dateKey, maxConcurrency: 1,
    requests: selected.map(function(id) {
      return {kind: "global-day", leagueId: id, teamId: "", dateKey: dateKey,
        startDate: dateKey, endDate: dateKey, maxResponseChars: MAX_RESPONSE_CHARS,
        url: buildUrl(id, dateKey)};
    })};
}

function validRequest(request) {
  return isRecord(request) && request.kind === "global-day" && request.teamId === ""
    && validDate(request.dateKey) && request.startDate === request.dateKey && request.endDate === request.dateKey
    && request.maxResponseChars === MAX_RESPONSE_CHARS && !!buildUrl(request.leagueId, request.dateKey)
    && request.url === buildUrl(request.leagueId, request.dateKey);
}

function canAppend(current, chunk, request) {
  return validRequest(request) && typeof current === "string" && typeof chunk === "string"
    && current.length <= MAX_RESPONSE_CHARS && chunk.length <= MAX_RESPONSE_CHARS - current.length;
}

function failed(reason) { return {accepted: false, complete: false, reason: reason, entries: []}; }

function parseResponse(request, body, parsers) {
  if (!validRequest(request) || typeof body !== "string" || body.length > MAX_RESPONSE_CHARS)
    return failed("response-limit");
  var payload;
  try { payload = JSON.parse(body); } catch (error) { return failed("invalid-json"); }
  if (!isRecord(payload)) return failed("invalid-response");
  parsers = parsers || (NhlProvider && EspnProvider && MlbStatsProvider ? {
    parseNhl: NhlProvider.parseScoreResponse, parseEspn: EspnProvider.parseScoreboardResponse,
    parseMlb: MlbStatsProvider.parseScoreResponse} : null);
  if (!isRecord(parsers)) return failed("missing-parser");
  var raw = [], sourceById = Object.create(null), parsed;
  var first = addDays(request.dateKey, -1), last = addDays(request.dateKey, 1);
  function timestampDate(value) {
    if (typeof value !== "string" || isNaN(new Date(value).getTime())) return "";
    return new Date(value).toISOString().slice(0, 10);
  }
  if (request.leagueId === "nhl") {
    if (payload.currentDate !== request.dateKey || !Array.isArray(payload.games)) return failed("mismatched-date");
    raw = payload.games;
    if (raw.length > MAX_EVENTS) return failed("incomplete-events");
    for (var n = 0; n < raw.length; n++) {
      var nhl = raw[n];
      if (!isRecord(nhl) || nhl.gameDate !== request.dateKey) return failed("mismatched-date");
      sourceById[String(nhl.id)] = {timeKnown: nhl.gameScheduleState !== "TBD" && !!nhl.startTimeUTC,
        provisionalDate: nhl.gameDate};
    }
    if (typeof parsers.parseNhl !== "function") return failed("missing-parser");
    parsed = parsers.parseNhl(payload);
  } else if (request.leagueId === "mlb") {
    if (!Array.isArray(payload.dates)) return failed("invalid-response");
    for (var d = 0; d < payload.dates.length; d++) {
      var day = payload.dates[d];
      if (!isRecord(day) || day.date !== request.dateKey || !Array.isArray(day.games)) return failed("mismatched-date");
      if (day.totalGames !== day.games.length) return failed("incomplete-events");
      raw = raw.concat(day.games);
    }
    if (raw.length > MAX_EVENTS || payload.totalGames !== raw.length) return failed("incomplete-events");
    for (var m = 0; m < raw.length; m++) {
      var mlb = raw[m];
      if (!isRecord(mlb) || mlb.officialDate !== request.dateKey) return failed("mismatched-date");
      sourceById[String(mlb.gamePk)] = {timeKnown: !(mlb.status && mlb.status.startTimeTBD === true) && !!mlb.gameDate,
        provisionalDate: mlb.officialDate};
    }
    if (typeof parsers.parseMlb !== "function") return failed("missing-parser");
    parsed = parsers.parseMlb(payload);
  } else {
    if (!Array.isArray(payload.leagues) || payload.leagues.length !== 1
        || !isRecord(payload.leagues[0]) || String(payload.leagues[0].id) !== ESPN_LEAGUE_IDS[request.leagueId]
        || !Array.isArray(payload.events)) return failed("mismatched-league");
    if (payload.day !== undefined && (!isRecord(payload.day) || payload.day.date !== request.dateKey))
      return failed("mismatched-date");
    raw = payload.events;
    // The unpaginated ESPN scoreboard has an observed 100-event ceiling.
    // A result at that ceiling cannot establish complete selected-day data.
    if (raw.length >= ESPN_EVENT_CAP || raw.length > MAX_EVENTS) return failed("incomplete-events");
    for (var e = 0; e < raw.length; e++) {
      var event = raw[e];
      if (!isRecord(event)) return failed("invalid-events");
      var utcDate = timestampDate(event.date);
      if (!utcDate || utcDate < first || utcDate > last) return failed("mismatched-date");
      var competition = Array.isArray(event.competitions) ? event.competitions[0] : null;
      sourceById[String(event.id)] = {timeKnown: event.timeValid !== false && !(competition && competition.timeValid === false),
        provisionalDate: request.dateKey};
    }
    if (typeof parsers.parseEspn !== "function") return failed("missing-parser");
    parsed = parsers.parseEspn(payload, request.leagueId);
  }
  if (!isRecord(parsed) || !Array.isArray(parsed.games) || !Array.isArray(parsed.errors)
      || parsed.errors.length || parsed.games.length !== raw.length) return failed("invalid-events");
  var entries = [], seen = Object.create(null);
  for (var i = 0; i < parsed.games.length; i++) {
    var game = parsed.games[i];
    if (!isRecord(game) || game.isValid !== true || game.league !== request.leagueId
        || typeof game.id !== "string" || seen[game.id]) return failed("invalid-events");
    seen[game.id] = true;
    var source = sourceById[String(game.providerGameId)];
    if (!source) return failed("invalid-events");
    var utcKey = timestampDate(game.startTime);
    if (utcKey && (utcKey < first || utcKey > last)) return failed("mismatched-date");
    var known = source.timeKnown && !!utcKey;
    var key = known ? localDate(game.startTime) : source.provisionalDate;
    if (!validDate(key)) return failed("invalid-event-date");
    if (key === request.dateKey && game.status !== "canceled")
      entries.push({game: game, dateKey: key, timeKnown: !!known});
  }
  // A single provider-day query cannot prove absence for a viewer-local day
  // in every timezone, or establish that an unpublished season is empty.
  return {accepted: true, complete: false, reason: "provider-day", entries: entries};
}

if (typeof module !== "undefined" && module.exports) module.exports = {
  MAX_RESPONSE_BYTES: MAX_RESPONSE_BYTES, MAX_RESPONSE_CHARS: MAX_RESPONSE_CHARS,
  MAX_EVENTS: MAX_EVENTS, MAX_LEAGUES: MAX_LEAGUES,
  buildPlan: buildPlan, canAppend: canAppend, parseResponse: parseResponse
};

// On-demand, selected-team schedules. This does not admit or hydrate the
// dormant all-league calendar. The transport still enforces 2 MiB of bytes.
// Only these reviewed team-schedule URLs may use the larger QString budget;
// the shared ResponsePolicy and daily-score admission limits stay unchanged.
var MAX_JSON_CHARS = 2 * 1024 * 1024;
var DEFAULT_JSON_CHARS = Math.floor(MAX_JSON_CHARS / 3);
var MAX_EVENTS = 256;
var MAX_DAYS = 35;
var MAX_REQUESTS = 8;
var MAX_CATALOG_TEAMS = 4096;
var DAY_MS = 86400000;
var ESPN_BASE = "https://site.api.espn.com/apis/site/v2/sports/";
var ESPN_PATHS = {
  nfl: "football/nfl", nba: "basketball/nba",
  "college-football": "football/college-football",
  "mens-college-basketball": "basketball/mens-college-basketball",
  "eng.1": "soccer/eng.1", "usa.1": "soccer/usa.1"
};

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

// QML var properties can expose QVariantList as an array-like object rather
// than a JavaScript Array. Admit that one trusted catalog boundary with a
// fixed iteration bound; provider JSON arrays remain strict below.
function catalogLength(value) {
  if (value === null || typeof value !== "object") return -1;
  var length = value.length;
  return typeof length === "number" && isFinite(length) && length >= 0
    && Math.floor(length) === length && length <= MAX_CATALOG_TEAMS ? length : -1;
}

function canonicalTeam(value) {
  return isRecord(value) && typeof value.league === "string"
    && /^\d+$/.test(String(value.providerTeamId))
    && value.id === value.league + ":" + String(value.providerTeamId);
}

function dateKey(value) {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return "";
  var instant = new Date(value + "T12:00:00Z");
  return !isNaN(instant.getTime()) && instant.toISOString().slice(0, 10) === value ? value : "";
}

function addDays(value, count) {
  return new Date(new Date(value + "T12:00:00Z").getTime() + count * DAY_MS)
    .toISOString().slice(0, 10);
}

function localDate(value) {
  var instant = new Date(value);
  if (isNaN(instant.getTime())) return "";
  function pad(number) { return number < 10 ? "0" + number : String(number); }
  return instant.getFullYear() + "-" + pad(instant.getMonth() + 1) + "-" + pad(instant.getDate());
}

function seasonFor(leagueId, day) {
  var year = Number(day.slice(0, 4)), month = Number(day.slice(5, 7));
  if (leagueId === "nba" || leagueId === "mens-college-basketball")
    return month >= 7 ? year + 1 : year;
  if (leagueId === "nfl" || leagueId === "college-football")
    return month <= 2 ? year - 1 : year;
  if (leagueId === "eng.1") return month >= 7 ? year : year - 1;
  return year;
}

function requestUrl(request) {
  if (request.kind === "nhl-month")
    return "https://api-web.nhle.com/v1/club-schedule/" + request.clubAbbreviation
      + "/month/" + request.monthKey;
  if (request.kind === "mlb-range")
    return "https://statsapi.mlb.com/api/v1/schedule?sportId=1&teamId=" + request.statsTeamId
      + "&startDate=" + request.providerStartDate + "&endDate=" + request.providerEndDate
      + "&hydrate=team,linescore";
  var base = ESPN_BASE + ESPN_PATHS[request.leagueId] + "/teams/" + request.providerTeamId;
  if (request.kind === "espn-hint") return base;
  if (request.kind === "espn-fixture") return base + "/schedule?season=" + request.seasonYear + "&fixture=true";
  if (request.kind === "espn-season") return base + "/schedule?season=" + request.seasonYear
    + "&seasontype=" + request.seasonType;
  return "";
}

function responseLimit(request) {
  return request && (request.kind === "espn-season" || request.kind === "espn-fixture")
    ? MAX_JSON_CHARS : DEFAULT_JSON_CHARS;
}

function validRequest(request) {
  if (!isRecord(request) || !dateKey(request.startDate) || !dateKey(request.endDate)
      || request.startDate > request.endDate || typeof request.providerTeamId !== "string"
      || !/^\d+$/.test(request.providerTeamId)
      || request.teamId !== request.leagueId + ":" + request.providerTeamId
      || request.maxResponseChars !== responseLimit(request)) return false;
  if (request.kind === "nhl-month") {
    if (request.leagueId !== "nhl" || !/^[A-Z]{3}$/.test(request.clubAbbreviation || "")
        || !dateKey(request.monthKey + "-01")) return false;
  } else if (request.kind === "mlb-range") {
    if (request.leagueId !== "mlb" || !/^\d+$/.test(request.statsTeamId || "")
        || !dateKey(request.providerStartDate) || !dateKey(request.providerEndDate)) return false;
  } else {
    if (!ESPN_PATHS[request.leagueId]) return false;
    if (request.kind === "espn-fixture") {
      if (request.leagueId !== "eng.1" && request.leagueId !== "usa.1") return false;
    } else if (request.kind === "espn-season") {
      if (request.leagueId === "eng.1" || request.leagueId === "usa.1"
          || [1, 2, 3].indexOf(request.seasonType) < 0) return false;
    } else if (request.kind !== "espn-hint") return false;
    if (request.kind !== "espn-hint"
        && (typeof request.seasonYear !== "number" || request.seasonYear < 2000
            || request.seasonYear > 2100 || Math.floor(request.seasonYear) !== request.seasonYear)) return false;
  }
  return request.url === requestUrl(request);
}

function buildPlan(teamId, startDate, endDate, catalogTeams, mlbStatsIdMap) {
  var invalid = {kind: "invalid", teamId: teamId, leagueId: "", startDate: startDate,
    endDate: endDate, requests: [], maxConcurrency: 1, reason: "invalid-selection"};
  var teamCount = catalogLength(catalogTeams);
  if (!dateKey(startDate) || !dateKey(endDate) || startDate > endDate
      || endDate > addDays(startDate, MAX_DAYS - 1) || teamCount < 0) return invalid;
  var team = null;
  for (var i = 0; i < teamCount; i++) {
    if (!canonicalTeam(catalogTeams[i])) return invalid;
    if (catalogTeams[i].id === teamId) team = catalogTeams[i];
  }
  if (!team) return invalid;
  var leagueId = team.league;
  if (leagueId !== "nhl" && leagueId !== "mlb" && !ESPN_PATHS[leagueId]) return invalid;
  var result = {kind: "plan", teamId: teamId, leagueId: leagueId,
    startDate: startDate, endDate: endDate, requests: [], maxConcurrency: 1};
  function append(kind, fields) {
    var request = {kind: kind, teamId: teamId, leagueId: leagueId,
      providerTeamId: String(team.providerTeamId), startDate: startDate, endDate: endDate};
    Object.keys(fields).forEach(function(key) { request[key] = fields[key]; });
    request.maxResponseChars = responseLimit(request);
    request.url = requestUrl(request);
    result.requests.push(request);
  }
  // Include a provider-day margin at both ends for viewer-local conversion.
  var providerStart = addDays(startDate, -1), providerEnd = addDays(endDate, 1);
  if (leagueId === "nhl") {
    if (!/^[A-Z]{3}$/.test(team.abbreviation || "")) return invalid;
    var month = providerStart.slice(0, 7);
    while (month <= providerEnd.slice(0, 7)) {
      append("nhl-month", {clubAbbreviation: team.abbreviation, monthKey: month});
      var nextMonth = new Date(month + "-01T12:00:00Z");
      nextMonth.setUTCMonth(nextMonth.getUTCMonth() + 1);
      month = nextMonth.toISOString().slice(0, 7);
    }
  } else if (leagueId === "mlb") {
    var statsId = "";
    Object.keys(isRecord(mlbStatsIdMap) ? mlbStatsIdMap : {}).forEach(function(key) {
      if (mlbStatsIdMap[key] === String(team.providerTeamId) && /^\d+$/.test(key)) statsId = key;
    });
    if (!statsId) return invalid;
    append("mlb-range", {statsTeamId: statsId, providerStartDate: providerStart, providerEndDate: providerEnd});
  } else {
    var years = [seasonFor(leagueId, providerStart)];
    var lastYear = seasonFor(leagueId, providerEnd);
    if (years[0] !== lastYear) years.push(lastYear);
    var soccer = leagueId === "eng.1" || leagueId === "usa.1";
    years.forEach(function(year) {
      if (soccer) append("espn-fixture", {seasonYear: year});
      else [2, 3, 1].forEach(function(type) { append("espn-season", {seasonYear: year, seasonType: type}); });
    });
    // A positive hint recovers e.g. an MLS playoff omitted by fixture=true.
    // It is never used to prove absence or authoritative next-game order.
    if (soccer) append("espn-hint", {});
  }
  if (result.requests.length > MAX_REQUESTS || result.requests.some(function(request) { return !validRequest(request); }))
    return invalid;
  return result;
}

function canAppend(current, chunk, request) {
  return validRequest(request) && typeof current === "string" && typeof chunk === "string"
    && current.length <= request.maxResponseChars
    && chunk.length <= request.maxResponseChars - current.length;
}

function failed(reason) { return {entries: [], complete: false, accepted: false, reason: reason}; }

function parseResponse(request, body, parsers) {
  if (!validRequest(request) || typeof body !== "string" || body.length > request.maxResponseChars)
    return failed("response-limit");
  var payload;
  try { payload = JSON.parse(body); } catch (error) { return failed("invalid-json"); }
  if (!isRecord(payload) || !isRecord(parsers)) return failed("invalid-response");
  var raw = [], parsed, complete = false, reason = "phase-limited";
  var rawById = {};
  if (request.kind === "nhl-month") {
    if (payload.currentMonth !== request.monthKey || !Array.isArray(payload.games))
      return failed("mismatched-month");
    raw = payload.games;
    if (raw.length >= MAX_EVENTS || raw.some(function(game) {
      return !isRecord(game) || !dateKey(game.gameDate) || game.gameDate.slice(0, 7) !== request.monthKey;
    })) return failed("invalid-events");
    if (typeof parsers.parseNhl !== "function") return failed("missing-parser");
    parsed = parsers.parseNhl({gameWeek: [{date: request.monthKey + "-01", games: raw}]});
    complete = raw.length > 0;
    reason = complete ? "" : "unpublished-or-empty";
    raw.forEach(function(game) { rawById[String(game.id)] = {
      timeKnown: game.gameScheduleState !== "TBD" && !!game.startTimeUTC,
      provisionalDate: game.gameDate
    }; });
  } else if (request.kind === "mlb-range") {
    if (!Array.isArray(payload.dates)) return failed("invalid-response");
    for (var d = 0; d < payload.dates.length; d++) {
      var day = payload.dates[d];
      if (!isRecord(day) || !dateKey(day.date) || day.date < request.providerStartDate
          || day.date > request.providerEndDate || !Array.isArray(day.games)) return failed("invalid-events");
      raw = raw.concat(day.games);
    }
    if (raw.length >= MAX_EVENTS || payload.totalGames !== raw.length) return failed("incomplete-events");
    if (typeof parsers.parseMlb !== "function") return failed("missing-parser");
    parsed = parsers.parseMlb(payload);
    complete = raw.length > 0;
    reason = complete ? "" : "unpublished-or-empty";
    raw.forEach(function(game) { rawById[String(game.gamePk)] = {
      timeKnown: !(game.status && game.status.startTimeTBD === true) && !!game.gameDate,
      provisionalDate: game.officialDate
    }; });
  } else {
    if (!isRecord(payload.team) || String(payload.team.id) !== request.providerTeamId)
      return failed("mismatched-team");
    if (request.kind === "espn-hint") {
      if (!Array.isArray(payload.team.nextEvent)) return failed("missing-next-event");
      raw = payload.team.nextEvent;
      reason = "next-event-hint";
    } else {
      if (!Array.isArray(payload.events)) return failed("invalid-events");
      // ESPN's unpublished phase response has no requestedSeason. It is a
      // valid partial response, never proof that the selected dates are empty.
      if (!isRecord(payload.requestedSeason) && payload.events.length === 0)
        return {entries: [], complete: false, accepted: true, reason: "unpublished-season"};
      if (!isRecord(payload.requestedSeason) || Number(payload.requestedSeason.year) !== request.seasonYear
          || (request.kind === "espn-season" && Number(payload.requestedSeason.type) !== request.seasonType))
        return failed("mismatched-season");
      raw = payload.events;
    }
    if (raw.length >= MAX_EVENTS) return failed("incomplete-events");
    if (typeof parsers.parseEspn !== "function") return failed("missing-parser");
    // Team schedules encode scores as objects, unlike scoreboards. Adapt that
    // boundary before reusing the existing normalized-game parser.
    raw.forEach(function(event) {
      var competition = isRecord(event) && Array.isArray(event.competitions) ? event.competitions[0] : null;
      if (!isRecord(event)) return;
      rawById[String(event.id)] = {
        timeKnown: event.timeValid !== false && !(competition && competition.timeValid === false),
        provisionalDate: typeof event.date === "string" ? event.date.slice(0, 10) : ""
      };
      if (competition && Array.isArray(competition.competitors)) competition.competitors.forEach(function(side) {
        if (isRecord(side.score)) side.score = side.score.value;
      });
    });
    parsed = parsers.parseEspn({events: raw}, request.leagueId);
  }
  if (!isRecord(parsed) || !Array.isArray(parsed.games) || !Array.isArray(parsed.errors)
      || parsed.errors.length || parsed.games.length !== raw.length) return failed("invalid-events");
  var entries = [], seen = {};
  for (var i = 0; i < parsed.games.length; i++) {
    var game = parsed.games[i];
    if (!isRecord(game) || game.isValid !== true || !game.awayTeam || !game.homeTeam
        || (game.awayTeam.id !== request.teamId && game.homeTeam.id !== request.teamId)) return failed("mismatched-team");
    if (seen[game.id]) return failed("duplicate-event");
    seen[game.id] = true;
    var source = rawById[String(game.providerGameId)];
    if (!source) return failed("invalid-events");
    var known = source.timeKnown && !!game.startTime;
    var key = known ? localDate(game.startTime) : dateKey(source.provisionalDate);
    if (!key) return failed("invalid-event-date");
    if (key < request.startDate || key > request.endDate || game.status === "canceled") continue;
    if (request.kind === "espn-hint" && game.status !== "scheduled" && game.status !== "live") continue;
    entries.push({game: game, dateKey: key, timeKnown: !!known});
  }
  return {entries: entries, complete: complete, accepted: true, reason: reason};
}

if (typeof module !== "undefined" && module.exports) module.exports = {
  MAX_JSON_CHARS: MAX_JSON_CHARS, DEFAULT_JSON_CHARS: DEFAULT_JSON_CHARS,
  MAX_DAYS: MAX_DAYS, MAX_REQUESTS: MAX_REQUESTS,
  buildPlan: buildPlan, parseResponse: parseResponse, canAppend: canAppend
};

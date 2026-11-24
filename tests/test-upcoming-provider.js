#!/usr/bin/env node
"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const Upcoming = require("../providers/UpcomingScheduleProvider.js");
const Espn = require("../providers/EspnProvider.js");
const Nhl = require("../providers/NhlProvider.js");
const Mlb = require("../providers/MlbStatsProvider.js");
const EspnTeams = require("../providers/EspnTeamCatalog.js");
const NhlTeams = require("../providers/NhlTeamCatalog.js");
const ResponsePolicy = require("../model/ResponsePolicy.js");
const parsers = {parseEspn: Espn.parseScoreboardResponse,
  parseNhl: Nhl.parseScheduleResponse, parseMlb: Mlb.parseScoreResponse};
const catalog = NhlTeams.listTeams().concat(EspnTeams.listTeamsForLeagues([
  "nfl", "mlb", "nba", "college-football", "mens-college-basketball", "eng.1", "usa.1"
]));
const fixture = name => fs.readFileSync(path.join(__dirname, "../fixtures/upcoming", name + ".json"), "utf8");
const json = name => JSON.parse(fixture(name));
const plan = (team, start = "2026-11-24", end = "2026-12-28") =>
  Upcoming.buildPlan(team, start, end, catalog, Mlb.TEAM_IDS_BY_STATS_ID);
const request = (team, kind, extra = {}) => plan(team, extra.start, extra.end).requests.find(r =>
  r.kind === kind && (kind !== "espn-season" || !extra.type || r.seasonType === extra.type));
let count = 0;
function test(name, run) { run(); count++; console.log("ok " + count + " - " + name); }

test("all eight trusted leagues have a bounded team-only sequential plan", () => {
  for (const id of ["nhl:54", "nfl:2", "mlb:10", "nba:2", "college-football:130",
    "mens-college-basketball:26", "eng.1:360", "usa.1:9723"]) {
    const p = plan(id);
    assert.equal(p.kind, "plan", id);
    assert.equal(p.maxConcurrency, 1);
    assert(p.requests.length > 0 && p.requests.length <= 8);
    assert(p.requests.every(r => !r.url.includes("scoreboard") && !r.url.includes("/now")));
  }
});

test("rejects unknown, malformed, noncanonical and overly wide selections", () => {
  for (const id of ["nfl:999999", "nfl:2/../../", "nfl:02", "mens-college-basketball:130", "nba:2?x=1"])
    assert.equal(plan(id).kind, "invalid");
  for (const [start, end] of [["2026-02-30", "2026-03-01"], ["2026-11-24", "2026-12-29"],
    ["2026-12-28", "2026-11-24"]]) assert.equal(plan("nfl:2", start, end).kind, "invalid");
});

test("QML array-like catalogs are bounded and their elements stay canonical", () => {
  const team = catalog.find(t => t.id === "nfl:2");
  const arrayLike = {0: team, length: 1};
  assert.equal(Upcoming.buildPlan("nfl:2", "2026-11-24", "2026-12-28", arrayLike, {}).kind, "plan");
  for (const length of [4097, Infinity, NaN, -1, 1.5, "1", undefined]) {
    assert.equal(Upcoming.buildPlan("nfl:2", "2026-11-24", "2026-12-28", {0: team, length}, {}).kind, "invalid");
  }
  for (const value of ["x", null, {0: null, length: 1}, {0: {...team, id: "nfl:3"}, length: 1},
    {0: team, length: 2}]) {
    assert.equal(Upcoming.buildPlan("nfl:2", "2026-11-24", "2026-12-28", value, {}).kind, "invalid");
  }
  assert.equal(Upcoming.buildPlan("nfl:2", "2026-11-24", "2026-12-28", new Array(4097).fill(team), {}).kind, "invalid");
});

test("NHL fixed month paths include local-day boundary margins", () => {
  const p = plan("nhl:54", "2026-11-01", "2026-12-05");
  assert.deepEqual(p.requests.map(r => r.monthKey), ["2026-10", "2026-11", "2026-12"]);
  assert.equal(p.requests[0].url, "https://api-web.nhle.com/v1/club-schedule/VGK/month/2026-10");
});

test("MLB reverses the reviewed StatsAPI map and requests only one team/range", () => {
  const r = plan("mlb:10", "2027-03-01", "2027-04-04").requests[0];
  assert.equal(r.statsTeamId, "147");
  assert.equal(r.url, "https://statsapi.mlb.com/api/v1/schedule?sportId=1&teamId=147"
    + "&startDate=2027-02-28&endDate=2027-04-05&hydrate=team,linescore");
  assert.equal(Upcoming.buildPlan("mlb:10", "2027-03-01", "2027-04-04", catalog, {}).kind, "invalid");
});

test("explicit season/year plans include all three phases and handle boundaries", () => {
  assert.deepEqual(plan("nfl:2").requests.map(r => [r.seasonYear, r.seasonType]), [[2026, 2], [2026, 3], [2026, 1]]);
  assert.equal(plan("nba:2").requests[0].seasonYear, 2027);
  assert.equal(plan("mens-college-basketball:26").requests[0].seasonYear, 2027);
  const january = plan("college-football:130", "2027-01-01", "2027-02-04");
  assert(january.requests.every(r => r.seasonYear === 2026));
  const rollover = plan("nba:2", "2027-06-20", "2027-07-24");
  assert.equal(rollover.requests.length, 6);
  assert.deepEqual([...new Set(rollover.requests.map(r => r.seasonYear))], [2027, 2028]);
});

test("soccer plans use fixture=true plus an explicitly partial team hint", () => {
  const p = plan("usa.1:9723");
  assert.deepEqual(p.requests.map(r => r.kind), ["espn-fixture", "espn-hint"]);
  assert.equal(p.requests[0].seasonYear, 2026);
  assert(p.requests[0].url.endsWith("/teams/9723/schedule?season=2026&fixture=true"));
  assert(p.requests[1].url.endsWith("/teams/9723"));
});

test("new schedule character budget is closed to the reviewed team URLs", () => {
  const r = request("nba:2", "espn-season", {type: 2});
  assert.equal(ResponsePolicy.MAX_RESPONSE_CHARS, 699050);
  assert.equal(Upcoming.MAX_JSON_CHARS, ResponsePolicy.MAX_RESPONSE_BYTES);
  assert.equal(r.maxResponseChars, 2097152);
  assert(Upcoming.canAppend("x".repeat(699051), "x", r));
  assert(Upcoming.canAppend("x".repeat(r.maxResponseChars - 1), "x", r));
  assert(!Upcoming.canAppend("x".repeat(r.maxResponseChars), "x", r));
  assert(!Upcoming.canAppend("", "x", {...r, url: r.url + "&limit=999"}));
  assert(!Upcoming.canAppend("", "x", {...r, maxResponseChars: Infinity}));
  assert.equal(plan("mlb:10").requests[0].maxResponseChars, ResponsePolicy.MAX_RESPONSE_CHARS);
  const evidence = json("evidence").sources.find(s => s.fixture === "nba-bos-2027-regular.json");
  assert(evidence.sourceChars > ResponsePolicy.MAX_RESPONSE_CHARS);
  assert(evidence.sourceBytes < ResponsePolicy.MAX_RESPONSE_BYTES);
});

test("all verified selected-team schedules normalize through existing parsers", () => {
  const cases = [["nfl:2", "nfl-buf-2026-regular", "espn-season"],
    ["nba:2", "nba-bos-2027-regular", "espn-season"],
    ["college-football:130", "cfb-mich-2026-regular", "espn-season"],
    ["mens-college-basketball:26", "ncaab-ucla-2027-regular", "espn-season"],
    ["eng.1:360", "epl-man-2026-fixture", "espn-fixture"],
    ["nhl:54", "nhl-vgk-2026-11", "nhl-month"]];
  for (const [team, file, kind] of cases) {
    const result = Upcoming.parseResponse(request(team, kind, {type: 2}), fixture(file), parsers);
    assert.equal(result.accepted, true, file + ":" + result.reason);
    assert(result.entries.length > 0, file);
    assert(result.entries.every(e => e.game.awayTeam.id === team || e.game.homeTeam.id === team));
    assert(result.entries.every(e => e.dateKey >= "2026-11-24" && e.dateKey <= "2026-12-28"));
    if (kind !== "nhl-month") assert.equal(result.complete, false);
  }
});

test("missing/unpublished phases are partial; mismatched seasons are rejected", () => {
  const r = request("nfl:2", "espn-season", {type: 3});
  const unpublished = Upcoming.parseResponse(r, fixture("nfl-buf-2026-post-unpublished"), parsers);
  assert.equal(unpublished.accepted, true);
  assert.equal(unpublished.complete, false);
  assert.deepEqual(unpublished.entries, []);
  const mismatched = json("nfl-buf-2026-regular");
  mismatched.requestedSeason.year = 2025;
  assert.equal(Upcoming.parseResponse(request("nfl:2", "espn-season", {type: 2}), JSON.stringify(mismatched), parsers).accepted, false);
  const mls = Upcoming.parseResponse(request("usa.1:9723", "espn-fixture"), fixture("mls-por-mismatched-fixture"), parsers);
  assert.equal(mls.accepted, false);
  assert.equal(mls.complete, false);
});

test("positive MLS playoff hint recovers the omitted fixture without proving order", () => {
  const result = Upcoming.parseResponse(request("usa.1:9723", "espn-hint"), fixture("mls-por-next-hint"), parsers);
  assert.equal(result.accepted, true);
  assert.equal(result.complete, false);
  assert.equal(result.reason, "next-event-hint");
  assert.equal(result.entries.length, 1);
  assert.equal(result.entries[0].game.status, "scheduled");
});

test("stale final nextEvent cannot become the selected team's next game", () => {
  // A hint request from the same closed URL family, as soccer uses in production.
  const nfl = request("nfl:2", "espn-season", {type: 2});
  const r = {...nfl, kind: "espn-hint", maxResponseChars: Upcoming.DEFAULT_JSON_CHARS,
    url: "https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams/2"};
  const result = Upcoming.parseResponse(r, fixture("nfl-buf-stale-hint"), parsers);
  assert.equal(result.accepted, true);
  assert.deepEqual(result.entries, []);
  assert.equal(result.complete, false);
});

test("TBD ESPN time retains the provisional date in a western timezone", () => {
  const previous = process.env.TZ;
  process.env.TZ = "America/Los_Angeles";
  try {
    const r = request("nfl:2", "espn-season", {type: 2, start: "2027-01-01", end: "2027-02-04"});
    const result = Upcoming.parseResponse(r, fixture("nfl-buf-2026-regular"), parsers);
    const tbd = result.entries.find(e => !e.timeKnown);
    assert(tbd);
    assert.equal(tbd.dateKey, "2027-01-10");
    assert.equal(new Date(tbd.game.startTime).getDate(), 9);
  } finally { if (previous === undefined) delete process.env.TZ; else process.env.TZ = previous; }
});

test("known times use viewer-local dates; team-schedule score objects are adapted", () => {
  const r = request("nfl:2", "espn-season", {type: 2, start: "2026-09-01", end: "2026-10-05"});
  const result = Upcoming.parseResponse(r, fixture("nfl-buf-2026-regular"), parsers);
  const first = result.entries[0];
  assert.equal(first.game.status, "final");
  assert.equal(typeof first.game.awayScore, "number");
  assert.equal(typeof first.game.homeScore, "number");
  assert.equal(first.timeKnown, true);
});

test("MLB team-range source counts are required and empty publication stays unknown", () => {
  const r = request("mlb:10", "mlb-range", {start: "2027-03-01", end: "2027-04-04"});
  const good = Upcoming.parseResponse(r, fixture("mlb-nyy-march-window"), parsers);
  assert.equal(good.accepted, true);
  assert.equal(good.complete, true);
  assert(good.entries.length > 0);
  const truncated = json("mlb-nyy-march-window");
  truncated.totalGames++;
  assert.equal(Upcoming.parseResponse(r, JSON.stringify(truncated), parsers).accepted, false);
  const empty = Upcoming.parseResponse(request("mlb:10", "mlb-range"), fixture("mlb-nyy-empty-window"), parsers);
  assert.equal(empty.accepted, true);
  assert.equal(empty.complete, false);
});

test("NHL wrong-month and empty unpublished responses cannot imply empty days", () => {
  const r = request("nhl:54", "nhl-month");
  const wrong = json("nhl-vgk-2026-11"); wrong.currentMonth = "2025-11";
  assert.equal(Upcoming.parseResponse(r, JSON.stringify(wrong), parsers).accepted, false);
  const empty = Upcoming.parseResponse(r, JSON.stringify({currentMonth: r.monthKey, games: []}), parsers);
  assert.equal(empty.accepted, true);
  assert.equal(empty.complete, false);
});

test("oversize, malformed, capped, duplicate and wrong-team responses fail closed", () => {
  const r = request("nfl:2", "espn-season", {type: 2});
  for (const value of ["{", "x".repeat(r.maxResponseChars + 1), "null", "[]"])
    assert.equal(Upcoming.parseResponse(r, value, parsers).accepted, false);
  const p = json("nfl-buf-2026-regular");
  p.events = new Array(256).fill(p.events[0]);
  assert.equal(Upcoming.parseResponse(r, JSON.stringify(p), parsers).accepted, false);
  p.events = [p.events[0], p.events[0]];
  assert.equal(Upcoming.parseResponse(r, JSON.stringify(p), parsers).accepted, false);
  const wrong = json("nfl-buf-2026-regular"); wrong.team.id = "1";
  assert.equal(Upcoming.parseResponse(r, JSON.stringify(wrong), parsers).accepted, false);
  const malformed = json("nfl-buf-2026-regular"); malformed.events[0].competitions = [];
  assert.equal(Upcoming.parseResponse(r, JSON.stringify(malformed), parsers).accepted, false);
});

test("QML require-free scope exposes the same bounded planner", () => {
  const scope = {};
  vm.createContext(scope);
  vm.runInContext(fs.readFileSync(path.join(__dirname, "../providers/UpcomingScheduleProvider.js"), "utf8"), scope);
  const p = scope.buildPlan("nfl:2", "2026-11-24", "2026-12-28", catalog, Mlb.TEAM_IDS_BY_STATS_ID);
  assert.equal(p.kind, "plan");
  assert.equal(p.requests.length, 3);
  assert(scope.canAppend("", "{}", p.requests[0]));
  assert.equal(scope.parseResponse(p.requests[0], fixture("nfl-buf-2026-regular"), parsers).accepted, true);
});

console.log("Upcoming provider: " + count + " checks passed");

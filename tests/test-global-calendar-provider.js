#!/usr/bin/env node
"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const Global = require("../providers/GlobalCalendarProvider.js");
const Policy = require("../model/ResponsePolicy.js");
const Nhl = require("../providers/NhlProvider.js");
const Espn = require("../providers/EspnProvider.js");
const Mlb = require("../providers/MlbStatsProvider.js");
const parsers = {parseNhl: Nhl.parseScoreResponse, parseEspn: Espn.parseScoreboardResponse,
  parseMlb: Mlb.parseScoreResponse};
const ids = ["nhl", "nfl", "mlb", "nba", "college-football", "mens-college-basketball", "eng.1", "usa.1"];
const fixture = name => fs.readFileSync(path.join(__dirname, "../fixtures/globalcalendar", name + ".json"), "utf8");
const json = name => JSON.parse(fixture(name));
const request = (league, date = "2026-11-24") => Global.buildPlan([league], ids, date).requests[0];
const previousTz = process.env.TZ;
process.env.TZ = "America/New_York";
let count = 0;
function test(name, run) { run(); count++; console.log("ok " + count + " - " + name); }

test("global daily plan has exact identity, ordered requests and one sequential slot", () => {
  const plan = Global.buildPlan(ids, ids, "2026-11-24");
  assert.equal(plan.kind, "plan");
  assert.equal(plan.scope, "global");
  assert.equal(plan.teamId, "");
  assert.equal(plan.leagueId, "");
  assert.equal(plan.startDate, "2026-11-24");
  assert.equal(plan.endDate, "2026-11-24");
  assert.equal(plan.selectionKey, ids.slice().sort().join(","));
  assert.equal(plan.cacheKey, "global:" + plan.selectionKey + ":2026-11-24");
  assert.equal(plan.maxConcurrency, 1);
  assert.equal(plan.requests.length, 8);
  assert.deepEqual(plan.requests.map(r => r.leagueId), ids);
  for (const r of plan.requests) {
    assert.equal(r.kind, "global-day");
    assert.equal(r.teamId, "");
    assert.equal(r.startDate, r.dateKey);
    assert.equal(r.endDate, r.dateKey);
    assert.equal(r.maxResponseChars, 699050);
  }
});

test("sanitizes duplicates and intersects followed with enabled without expanding scope", () => {
  const plan = Global.buildPlan([" NFL ", "nba", "nfl", "unknown", "nhl"], ["nfl", "nhl"], "2026-11-24");
  assert.deepEqual(plan.requests.map(r => r.leagueId), ["nfl", "nhl"]);
  assert.equal(plan.selectionKey, "nfl,nhl");
  assert.equal(Global.buildPlan(["nhl", "nfl"], ["nhl", "nfl"], "2026-11-24").cacheKey, plan.cacheKey);
  assert.equal(Global.buildPlan(["nhl"], ["nhl"], "2026-11-24").cacheKey === plan.cacheKey, false);
  const empty = Global.buildPlan(["constructor", "toString", "__proto__", "nfl"], ["nba"], "2026-11-24");
  assert.equal(empty.kind, "empty");
  assert.deepEqual(empty.requests, []);
  assert.equal(Global.buildPlan([], ids, "2026-11-24").kind, "empty");
});

test("bounded QML list admission rejects bad length, sparse and malformed values", () => {
  const plan = Global.buildPlan({0: "nhl", 1: "nfl", length: 2}, {0: "nfl", length: 1}, "2026-11-24");
  assert.equal(plan.kind, "plan");
  assert.equal(plan.requests[0].leagueId, "nfl");
  let lengthReads = 0;
  const fixedBound = {0: "nhl", get length() { lengthReads++; return lengthReads === 1 ? 1 : Infinity; }};
  assert.equal(Global.buildPlan(fixedBound, ids, "2026-11-24").kind, "plan");
  assert.equal(lengthReads, 1);
  for (const value of [null, "nfl", {length: 1}, {0: "nfl", length: 1.5},
    {0: "nfl", length: Infinity}, {0: "nfl", length: "1"}, {0: null, length: 1},
    {0: "nfl", length: -1}, new Array(9).fill("nfl")]) {
    assert.equal(Global.buildPlan(value, ids, "2026-11-24").kind, "invalid");
    assert.equal(Global.buildPlan(ids, value, "2026-11-24").kind, "invalid");
  }
  for (const day of ["2026-02-30", "20261124", "2026-11-24?x=1", ""])
    assert.equal(Global.buildPlan(ids, ids, day).kind, "invalid");
});

test("daily URLs exactly reuse the approved primary-provider builders", () => {
  assert.equal(request("nhl").url, Nhl.buildScoreUrl("2026-11-24"));
  assert.equal(request("mlb").url, Mlb.buildScoreUrl("2026-11-24"));
  for (const league of ids.filter(id => id !== "nhl" && id !== "mlb"))
    assert.equal(request(league).url, Espn.buildScoreUrl(league, "20261124"));
  assert(Global.buildPlan(ids, ids, "2026-11-24").requests.every(r => !r.url.includes("/teams/")
    && !r.url.includes("/now") && !r.url.includes("20261124-")));
});

test("global character and transport caps remain the existing conservative limits", () => {
  assert.equal(Global.MAX_RESPONSE_BYTES, Policy.MAX_RESPONSE_BYTES);
  assert.equal(Global.MAX_RESPONSE_CHARS, Policy.MAX_RESPONSE_CHARS);
  assert.equal(Global.MAX_EVENTS, 256);
  const r = request("nba");
  assert(Global.canAppend("x".repeat(699049), "x", r));
  assert(!Global.canAppend("x".repeat(699050), "x", r));
  assert(!Global.canAppend("", "x", {...r, maxResponseChars: 2097152}));
  assert(!Global.canAppend("", "x", {...r, url: r.url + "&limit=256"}));
  assert(!Global.canAppend("", "x", {...r, teamId: "nba:2"}));
});

test("all eight official daily samples parse through existing normalized providers", () => {
  const cases = [["nhl", "nhl", "2026-11-24", 1], ["nfl", "nfl", "2026-11-24", 0],
    ["mlb", "mlb", "2027-04-01", 8], ["nba", "nba", "2026-11-24", 3],
    ["college-football", "cfb", "2026-11-24", 2],
    ["mens-college-basketball", "ncaab", "2026-11-24", 10],
    ["eng.1", "epl", "2026-11-28", 3], ["usa.1", "mls", "2026-11-28", 6]];
  for (const [league, file, date, expected] of cases) {
    const result = Global.parseResponse(request(league, date), fixture("daily-" + file), parsers);
    assert.equal(result.accepted, true, league + ":" + result.reason);
    assert.equal(result.entries.length, expected, league);
    assert.equal(result.complete, false);
    assert(result.entries.every(e => e.game.league === league && e.dateKey === date));
    assert(result.entries.every(e => e.game.isValid === true));
  }
  for (const source of json("evidence").sources) {
    const payload = json(source.name);
    const rawCount = source.name === "daily-nhl" ? payload.games.length
      : source.name === "daily-mlb" ? payload.dates.reduce((total, day) => total + day.games.length, 0)
      : payload.events.length;
    assert.equal(source.eventCount, rawCount, source.name + " source event count");
    assert.equal(source.fixtureEventCount, rawCount, source.name + " fixture event count");
    assert(source.bytes <= Global.MAX_RESPONSE_BYTES);
    assert(source.chars <= Global.MAX_RESPONSE_CHARS);
  }
});

test("a provider-day cannot imply complete viewer-local-day coverage", () => {
  const r = request("mens-college-basketball");
  const source = json("daily-ncaab");
  assert.equal(source.events.length, 11);
  const result = Global.parseResponse(r, JSON.stringify(source));
  assert.equal(result.entries.length, 10);
  assert.equal(result.complete, false);
  assert.equal(result.reason, "provider-day");
  process.env.TZ = "Asia/Tokyo";
  try {
    const distant = Global.parseResponse(request("nba"), fixture("daily-nba"));
    assert.equal(distant.accepted, true);
    assert.deepEqual(distant.entries, []);
    assert.equal(distant.complete, false);
  } finally { process.env.TZ = "America/New_York"; }
});

test("unknown start times retain their requested provisional provider date", () => {
  const p = json("daily-nba");
  p.events[0].timeValid = false;
  p.events[0].competitions[0].timeValid = false;
  p.events[0].date = "2026-11-25T05:00:00Z";
  const result = Global.parseResponse(request("nba"), JSON.stringify(p));
  const tbd = result.entries.find(e => e.game.providerGameId === p.events[0].id);
  assert(tbd);
  assert.equal(tbd.timeKnown, false);
  assert.equal(tbd.dateKey, "2026-11-24");
  const hockey = json("daily-nhl");
  hockey.games[0].gameScheduleState = "TBD";
  const nhl = Global.parseResponse(request("nhl"), JSON.stringify(hockey));
  assert.equal(nhl.entries[0].timeKnown, false);
});

test("empty/unpublished daily responses never prove absence", () => {
  const emptyNhl = Global.parseResponse(request("nhl"), JSON.stringify({currentDate: "2026-11-24", games: []}));
  const emptyMlb = Global.parseResponse(request("mlb"), JSON.stringify({dates: [], totalGames: 0}));
  const emptyEspn = Global.parseResponse(request("nfl"), fixture("daily-nfl"));
  for (const result of [emptyNhl, emptyMlb, emptyEspn]) {
    assert.equal(result.accepted, true);
    assert.equal(result.complete, false);
    assert.deepEqual(result.entries, []);
  }
});

test("wrong explicit dates, leagues and out-of-envelope events fail closed", () => {
  const nhl = json("daily-nhl"); nhl.currentDate = "2026-11-23";
  assert.equal(Global.parseResponse(request("nhl"), JSON.stringify(nhl)).accepted, false);
  const mlb = json("daily-mlb"); mlb.dates[0].date = "2027-04-02";
  assert.equal(Global.parseResponse(request("mlb", "2027-04-01"), JSON.stringify(mlb)).accepted, false);
  const college = json("daily-ncaab"); college.day.date = "2026-11-23";
  assert.equal(Global.parseResponse(request("mens-college-basketball"), JSON.stringify(college)).accepted, false);
  const nba = json("daily-nba"); nba.leagues[0].id = "28";
  assert.equal(Global.parseResponse(request("nba"), JSON.stringify(nba)).accepted, false);
  nba.leagues[0].id = "46"; nba.events[0].date = "2026-12-01T00:00Z";
  assert.equal(Global.parseResponse(request("nba"), JSON.stringify(nba)).accepted, false);
});

test("event-count mismatches and ESPN's observed cap cannot become empty success", () => {
  const mlb = json("daily-mlb"); mlb.totalGames++;
  assert.equal(Global.parseResponse(request("mlb", "2027-04-01"), JSON.stringify(mlb)).accepted, false);
  mlb.totalGames--; mlb.dates[0].totalGames++;
  assert.equal(Global.parseResponse(request("mlb", "2027-04-01"), JSON.stringify(mlb)).accepted, false);
  const nba = json("daily-nba"); nba.events = new Array(100).fill(nba.events[0]);
  assert.equal(Global.parseResponse(request("nba"), JSON.stringify(nba)).accepted, false);
  const nhl = json("daily-nhl"); nhl.games = new Array(257).fill(nhl.games[0]);
  assert.equal(Global.parseResponse(request("nhl"), JSON.stringify(nhl)).accepted, false);
});

test("malformed, duplicate, parser-failed and oversized responses are rejected", () => {
  const r = request("nba");
  for (const body of ["{", "null", "[]", "x".repeat(699051)])
    assert.equal(Global.parseResponse(r, body).accepted, false);
  const duplicate = json("daily-nba"); duplicate.events.push(duplicate.events[0]);
  assert.equal(Global.parseResponse(r, JSON.stringify(duplicate)).accepted, false);
  const malformed = json("daily-nba"); malformed.events[0].competitions = [];
  assert.equal(Global.parseResponse(r, JSON.stringify(malformed)).accepted, false);
  assert.equal(Global.parseResponse(r, fixture("daily-nba"), {}).accepted, false);
  assert.equal(Global.parseResponse(r, fixture("daily-nba"), {parseEspn: () => ({games: [], errors: []})}).accepted, false);
});

test("QML require-free planner and injected parser path match Node behavior", () => {
  const scope = {};
  vm.createContext(scope);
  vm.runInContext(fs.readFileSync(path.join(__dirname, "../providers/GlobalCalendarProvider.js"), "utf8"), scope);
  const p = scope.buildPlan({0: "nhl", 1: "nba", length: 2}, ids, "2026-11-24");
  assert.equal(p.kind, "plan");
  assert.equal(p.requests[0].url, request("nhl").url);
  assert(scope.canAppend("", "{}", p.requests[0]));
  assert.equal(scope.parseResponse(p.requests[0], fixture("daily-nhl"), parsers).accepted, true);
  assert.equal(scope.parseResponse(p.requests[0], fixture("daily-nhl")).accepted, false);
});

if (previousTz === undefined) delete process.env.TZ; else process.env.TZ = previousTz;
console.log("Global calendar provider: " + count + " checks passed");

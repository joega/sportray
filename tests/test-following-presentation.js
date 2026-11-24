const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const following = require("../model/FollowingPresentation.js");
const panel = require("../model/PanelPresentation.js");
const rows = require("../model/ResultRows.js");
const fixture = JSON.parse(fs.readFileSync(path.join(__dirname, "../tools/readme/sample-state.json")));
const sample = fixture.games;
function game(id, status, favorite, league = "nhl") {
  return {...sample.find(value => value.league === league), id, league, status,
    presentation: {isFavorite: favorite, leagueLabel: league.toUpperCase()}};
}
const live = game("nhl:live", "live", true);
const watched = game("nfl:watched", "intermission", false, "nfl");
const next = game("nhl:next", "scheduled", true);
const final = game("nfl:final", "final", false, "nfl");
const changed = game("nhl:postponed", "postponed", false);
const canceled = game("nhl:canceled", "canceled", false);
const view = {kind: "following", games: [live, watched, live, next, final, changed, canceled],
  hasGames: true, hasFavorites: true, followedLeagueIds: ["nhl", "nfl"],
  leagueStates: [{leagueId: "nhl", displayName: "NHL", hasData: true},
    {leagueId: "nfl", displayName: "NFL", hasData: true}]};
let checks = 0;
function test(name, callback) { callback(); checks++; process.stdout.write("ok - " + name + "\n"); }
test("All preserves the deduplicated favorite, watched and followed union", () => {
  const result = following.project(view, "all");
  assert.deepEqual(result.view.games.map(value => value.id), [live, watched, next, final, changed, canceled].map(value => value.id));
  assert.deepEqual(result.counts, {all: 6, live: 2, favorites: 2, upcoming: 1, final: 1, changes: 2});
  assert.equal(view.games.length, 7);
});
test("Live includes intermissions, Favorites excludes watch-only games", () => {
  assert.deepEqual(following.project(view, "live").view.games.map(value => value.id), [live.id, watched.id]);
  assert.deepEqual(following.project(view, "favorites").view.games.map(value => value.id), [live.id, next.id]);
  assert.deepEqual(following.project(view, "live").counts, following.project(view, "all").counts);
});
test("Canceled and postponed games stay visible without being counted upcoming", () => {
  const result = rows.flatten(following.project(view, "all").view, "following", "Today");
  assert.equal(result.filter(value => value.kind === "game").length, 6);
  assert.equal(rows.slateBucket(changed), "changes");
  assert.equal(rows.slateBucket(canceled), "changes");
  assert(result.some(value => value.kind === "section-header" && value.label === "Schedule changes"));
});
test("Empty filters offer Show all while retaining a failing league notice", () => {
  const failing = {...view, games: [next], leagueStates: [{leagueId: "nfl", displayName: "NFL",
    hasData: true, stale: true, errorCode: "unavailable", errorSummary: "Request failed"}]};
  const projected = following.project(failing, "live");
  assert.equal(projected.limited, true);
  const result = rows.flatten(projected.view, "following", "Today");
  assert(result.some(value => value.kind === "status"));
  assert(result.some(value => value.kind === "empty" && value.action.type === "show-all"));
  assert(!result.some(value => value.title === "No followed games today"));
});
test("Displayed league context follows the filtered slate", () => {
  assert(following.project(view, "all").view.games.every(value => value.presentation.showLeagueContext));
  assert(following.project(view, "favorites").view.games.every(value => !value.presentation.showLeagueContext));
  const nhl = {...live, awayTeam: {id: "nhl:6"}, homeTeam: {id: "nhl:10"}};
  const nba = game("nba:followed", "scheduled", false, "nba");
  const states = {leagueStates: [{leagueId: "nhl", displayName: "NHL", games: [nhl], hasData: true},
    {leagueId: "nba", displayName: "NBA", games: [nba], hasData: true}]};
  const built = panel.build(states, ["nhl:6"], values => values, undefined, ["nba"], 0, [], Date.now());
  assert.equal(built.following.games.length, 2);
  assert(built.following.games.every(value => value.presentation.showLeagueContext));
});
test("Session filter normalization and cycling are deterministic", () => {
  assert.equal(following.normalizeFilter("unknown"), "all");
  assert.deepEqual(["all", "live", "favorites"].map(following.nextFilter), ["live", "favorites", "all"]);
  assert.equal(following.project({games: [], leagueStates: []}, "favorites").view.filteredEmpty, true);
});
test("The QML require-free module produces the same projection", () => {
  const context = vm.createContext({});
  vm.runInContext(fs.readFileSync(path.join(__dirname, "../model/FollowingPresentation.js"), "utf8"), context);
  const value = context.project(view, "live");
  assert.deepEqual(JSON.parse(JSON.stringify(value)), following.project(view, "live"));
});
process.stdout.write("Following presentation: " + checks + " checks passed\n");

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const model = require("../model/SettingsModel.js");
let count = 0;
function test(name, body) { body(); count++; console.log("ok - " + name); }
function fixture() {
  const value = model.createDefaults();
  value.enabledLeagues = ["nhl", "nfl", "nba"];
  value.followedLeagueIds = ["nhl", "nfl"];
  value.favoriteTeamIds = ["nhl:6", "nfl:2"];
  value.notifications = {enabled: true, gameStart: false, scoreChange: true,
    gameFinal: false, pregameReminder: true, closeGame: false};
  value.ticker = {enabled: false, position: "top", speed: "slow"};
  return value;
}
function preserved(before, after, changed) {
  for (const key of Object.keys(before)) {
    if (!changed.includes(key)) assert.deepEqual(after[key], before[key], "Unrelated field changed: " + key);
  }
}

test("adding and removing a favorite preserves all other preferences", () => {
  const before = fixture();
  const added = model.toggleFavoriteTeam(before, "nba:13");
  assert.deepEqual(added.favoriteTeamIds, ["nhl:6", "nfl:2", "nba:13"]);
  preserved(before, added, ["favoriteTeamIds"]);
  assert.deepEqual(model.toggleFavoriteTeam(added, "nba:13"), before);
});
test("enabling and disabling a league only changes its enabled/followed state", () => {
  const before = fixture();
  const added = model.toggleLeague(before, "mlb");
  assert.deepEqual(added.enabledLeagues, ["nhl", "nfl", "nba", "mlb"]);
  preserved(before, added, ["enabledLeagues"]);
  const removed = model.toggleLeague(before, "nfl");
  assert.deepEqual(removed.enabledLeagues, ["nhl", "nba"]);
  assert.deepEqual(removed.followedLeagueIds, ["nhl"]);
  preserved(before, removed, ["enabledLeagues", "followedLeagueIds"]);
});
test("following and unfollowing a league preserves favorites and ticker settings", () => {
  const before = fixture();
  const followed = model.toggleFollowedLeague(before, "nba");
  assert.deepEqual(followed.followedLeagueIds, ["nhl", "nfl", "nba"]);
  preserved(before, followed, ["followedLeagueIds"]);
  assert.deepEqual(model.toggleFollowedLeague(followed, "nba"), before);
});
test("reordering followed leagues changes only their order", () => {
  const before = fixture();
  const moved = model.moveFollowedLeague(before, "nfl", "up");
  assert.deepEqual(moved.followedLeagueIds, ["nfl", "nhl"]);
  preserved(before, moved, ["followedLeagueIds"]);
  assert.deepEqual(model.moveFollowedLeague(moved, "nfl", "down"), before);
});
test("each notification toggle preserves every other notification and preference", () => {
  const before = fixture();
  for (const key of Object.keys(before.notifications)) {
    const after = model.toggleNotification(before, key);
    preserved(before, after, ["notifications"]);
    assert.deepEqual(after.notifications, {...before.notifications, [key]: !before.notifications[key]});
  }
});
test("all valid ticker combinations survive each preference mutation", () => {
  for (const enabled of [false, true]) for (const position of ["top", "bottom"])
    for (const speed of ["slow", "normal", "fast"]) {
      const before = fixture(); before.ticker = {enabled, position, speed};
      const results = [model.toggleFavoriteTeam(before, "nba:13"), model.toggleLeague(before, "mlb"),
        model.toggleFollowedLeague(before, "nba"), model.moveFollowedLeague(before, "nfl", "up"),
        model.toggleNotification(before, "enabled")];
      results.forEach(after => assert.deepEqual(after.ticker, before.ticker));
    }
});
test("invalid intents and unavailable reorder/follow actions remain normalized no-ops", () => {
  const before = fixture();
  const results = [model.toggleFavoriteTeam(before, "not-canonical"), model.toggleLeague(before, "invalid"),
    model.toggleFollowedLeague(before, "mlb"), model.moveFollowedLeague(before, "nhl", "up"),
    model.moveFollowedLeague(before, "nfl", "sideways"), model.toggleNotification(before, "unknown")];
  results.forEach(after => assert.deepEqual(after, before));
});
test("normalization still drops unknown fields and recovers malformed ticker settings", () => {
  const before = fixture(); before.ticker = {enabled: "no", position: "side", speed: null}; before.unknown = 1;
  const after = model.toggleFavoriteTeam(before, "nba:13");
  assert.deepEqual(after.ticker, model.createDefaults().ticker);
  assert.equal(Object.hasOwn(after, "unknown"), false);
});
test("favorite capacity and input immutability remain enforced", () => {
  const before = fixture();
  before.favoriteTeamIds = Array.from({length: model.MAX_FAVORITE_TEAM_IDS}, (_, i) => "nhl:" + (i + 1));
  const snapshot = JSON.stringify(before);
  assert.deepEqual(model.toggleFavoriteTeam(before, "nhl:99"), before);
  model.toggleLeague(before, "nfl"); model.toggleNotification(before, "gameStart");
  assert.equal(JSON.stringify(before), snapshot);
});
test("the QML require-free module preserves the same unrelated fields", () => {
  const source = fs.readFileSync(path.join(__dirname, "../model/SettingsModel.js"), "utf8");
  const scope = {}; vm.createContext(scope); vm.runInContext(source, scope);
  const before = fixture();
  assert.equal(JSON.stringify(scope.toggleFavoriteTeam(before, "nba:13")),
    JSON.stringify(model.toggleFavoriteTeam(before, "nba:13")));
  assert.deepEqual(JSON.parse(JSON.stringify(scope.toggleNotification(before, "closeGame").ticker)), before.ticker);
});
console.log("Settings preservation: " + count + " checks passed");

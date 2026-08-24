const assert = require("node:assert/strict");
const childProcess = require("node:child_process");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const catalog = require(path.join(root, "providers/LeagueCatalog.js"));
const teams = require(path.join(root, "model/TeamModel.js"));
const games = require(path.join(root, "model/GameModel.js"));
const gameDetails = require(path.join(root, "model/GameDetailModel.js"));
const formatters = require(path.join(root, "model/Formatters.js"));
const barPresentation = require(path.join(root, "model/BarPresentation.js"));
const presentation = require(path.join(root, "model/FavoritePresentation.js"));
const nhl = require(path.join(root, "providers/NhlProvider.js"));
const espn = require(path.join(root, "providers/EspnProvider.js"));
const nhlTeams = require(path.join(root, "providers/NhlTeamCatalog.js"));
const espnTeams = require(path.join(root, "providers/EspnTeamCatalog.js"));
const pickerModel = require(path.join(root, "model/TeamPickerModel.js"));
const settingsModel = require(path.join(root, "model/SettingsModel.js"));
const settingsPermissionPolicy = require(path.join(root, "model/SettingsPermissionPolicy.js"));
const scoreboard = require(path.join(root, "model/ScoreboardModel.js"));
const panelPresentation = require(path.join(root, "model/PanelPresentation.js"));
const resultRows = require(path.join(root, "model/ResultRows.js"));
const standingsModel = require(path.join(root, "model/StandingsModel.js"));
const standingsRows = require(path.join(root, "model/StandingsRows.js"));
const pollPolicy = require(path.join(root, "model/PollPolicy.js"));
const freshness = require(path.join(root, "model/FreshnessPolicy.js"));
const transitions = require(path.join(root, "model/TransitionDetector.js"));
const transitionDedupe = require(path.join(root, "model/TransitionDedupe.js"));
const stateModel = require(path.join(root, "model/StateModel.js"));
const notificationModel = require(path.join(root, "model/NotificationModel.js"));
const iconography = require(path.join(root, "model/Iconography.js"));
const dateModel = require(path.join(root, "model/DateModel.js"));
const dateCachePolicy = require(path.join(root, "model/DateCachePolicy.js"));
const nextEvent = require(path.join(root, "model/NextEventModel.js"));
const lookahead = require(path.join(root, "model/LookaheadPolicy.js"));
const monitorOwnership = require(path.join(root, "model/MonitorOwnership.js"));
const panelLayout = require(path.join(root, "model/PanelLayout.js"));
const gameRowLayout = require(path.join(root, "model/GameRowLayout.js"));
const pointerInteraction = require(path.join(root, "model/PointerInteractionPolicy.js"));
const keyboardRouting = require(path.join(root, "model/KeyboardRoutingPolicy.js"));
const lifecycle = require(path.join(root, "model/LifecyclePolicy.js"));
const assetUrlPolicy = require(path.join(root, "model/AssetUrlPolicy.js"));
const responsePolicy = require(path.join(root, "model/ResponsePolicy.js"));
const liveFavoriteRotation = require(path.join(root, "model/LiveFavoriteRotationPolicy.js"));
const countdownProjection = require(path.join(root, "model/CountdownProjectionPolicy.js"));
const pregameReminder = require(path.join(root, "model/PregameReminderPolicy.js"));
const closeGame = require(path.join(root, "model/CloseGamePolicy.js"));
const calendarModel = require(path.join(root, "model/CalendarModel.js"));
const providerFallback = require(path.join(root, "model/ProviderFallbackPolicy.js"));

function readFixture(name) {
  const fixturePath = path.join(root, "fixtures/nhl", `${name}.json`);
  return JSON.parse(fs.readFileSync(fixturePath, "utf8"));
}

function readRawFixture(name) {
  const fixturePath = path.join(root, "fixtures/nhl/raw", `${name}.json`);
  return JSON.parse(fs.readFileSync(fixturePath, "utf8"));
}

function readLookaheadFixture(name) {
  const fixturePath = path.join(root, "fixtures/nhl/lookahead", `${name}.json`);
  return JSON.parse(fs.readFileSync(fixturePath, "utf8"));
}

function readEspnFixture(name) {
  const fixturePath = path.join(root, "fixtures/espn/raw", `${name}.json`);
  return JSON.parse(fs.readFileSync(fixturePath, "utf8"));
}

function readStandingsFixture() {
  return JSON.parse(fs.readFileSync(
    path.join(root, "fixtures/espn/raw/standings-nfl.json"), "utf8"));
}

function readNhlStandingsFixture() {
  return JSON.parse(fs.readFileSync(
    path.join(root, "fixtures/nhl/standings.json"), "utf8"));
}

function readGameDetailFixture() {
  return JSON.parse(fs.readFileSync(
    path.join(root, "fixtures/espn/raw/game-detail.json"), "utf8"));
}

function readEspnTeamFixture(league) {
  const fixturePath = path.join(root, "fixtures/espn", `teams-${league}.json`);
  return JSON.parse(fs.readFileSync(fixturePath, "utf8"));
}

function readTeamFixture(name) {
  const fixturePath = path.join(root, "fixtures/nhl", `${name}.json`);
  return JSON.parse(fs.readFileSync(fixturePath, "utf8"));
}

function readPresentationFixture() {
  return JSON.parse(fs.readFileSync(path.join(root, "fixtures/nhl/presentation.json"), "utf8"));
}

function readU3ScoreCardFixture() {
  return JSON.parse(fs.readFileSync(path.join(root, "fixtures/nhl/u3-score-cards.json"), "utf8"));
}

function readSource(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), "utf8");
}

function readTransitionFixture() {
  return JSON.parse(fs.readFileSync(path.join(root, "fixtures/transitions/m6-1.json"), "utf8"));
}

function readDedupeFixture() {
  return JSON.parse(fs.readFileSync(path.join(root, "fixtures/transitions/m6-2.json"), "utf8"));
}

function readDateCacheFixture() {
  return JSON.parse(fs.readFileSync(path.join(root, "fixtures/transitions/m6-4.json"), "utf8"));
}

function readLogoUrlFixture() {
  return JSON.parse(fs.readFileSync(path.join(root, "fixtures/asset-hosts/team-logo-urls.json"), "utf8"));
}

function readResponseBoundsFixture() {
  return JSON.parse(fs.readFileSync(path.join(root, "fixtures/response-bounds/limits.json"), "utf8"));
}

function readSettingsPermissionFixture() {
  return JSON.parse(fs.readFileSync(
    path.join(root, "fixtures/settings-permissions/permissions.json"), "utf8"));
}

function readSettingsSchemaFixture() {
  return JSON.parse(fs.readFileSync(
    path.join(root, "fixtures/settings-schemas/state.json"), "utf8"));
}

function readMixedFollowingLayoutFixture() {
  return JSON.parse(fs.readFileSync(
    path.join(root, "fixtures/layout/mixed-following.json"), "utf8"));
}

function readAccessibilityActionsFixture() {
  return JSON.parse(fs.readFileSync(
    path.join(root, "fixtures/accessibility-actions/actions.json"), "utf8"));
}

function readGameDetailRouteFixture() {
  return JSON.parse(fs.readFileSync(
    path.join(root, "fixtures/game-detail-route/route.json"), "utf8"));
}

function readSettingsBoundaryFixture() {
  return JSON.parse(fs.readFileSync(
    path.join(root, "fixtures/settings-boundary/panel.json"), "utf8"));
}

function readBarPresentationFixture() {
  return JSON.parse(fs.readFileSync(
    path.join(root, "fixtures/bar-presentation/policy.json"), "utf8"));
}

function readLiveFavoriteRotationFixture() {
  return JSON.parse(fs.readFileSync(
    path.join(root, "fixtures/bar-presentation/live-favorite-rotation.json"), "utf8"));
}

function readCountdownFixture() {
  return JSON.parse(fs.readFileSync(
    path.join(root, "fixtures/bar-presentation/countdown.json"), "utf8"));
}

function readNotificationFixture() {
  return JSON.parse(fs.readFileSync(path.join(root, "fixtures/transitions/m6-3.json"), "utf8"));
}

function readPregameReminderFixture() {
  return JSON.parse(fs.readFileSync(path.join(root, "fixtures/transitions/m6-5.json"), "utf8"));
}

function readCloseGameFixture() {
  return JSON.parse(fs.readFileSync(
    path.join(root, "fixtures/transitions/m6-6.json"), "utf8"));
}

function readCalendarFixture() {
  return JSON.parse(fs.readFileSync(
    path.join(root, "fixtures/calendar/calendar.json"), "utf8"));
}

function readProviderFallbackFixture() {
  return JSON.parse(fs.readFileSync(
    path.join(root, "fixtures/provider-fallback/chain.json"), "utf8"));
}

function normalizeFixtureGames(fixture) {
  return fixture.games.map((game) => games.normalizeGame(game));
}

function test(name, callback) {
  callback();
  process.stdout.write(`ok - ${name}\n`);
}

test("catalog exposes NHL enabled by default", () => {
  assert.deepEqual(catalog.defaultLeagueIds(), ["nhl"]);
  assert.equal(catalog.getLeague("NHL").displayName, "NHL");
  assert.equal(catalog.getLeague("mlb").displayName, "MLB");
  assert.equal(catalog.getLeague("college-football").displayName, "NCAA Football");
  assert.equal(catalog.getLeague("ENG.1").displayName, "Premier League");
  assert.equal(catalog.getLeague("USA.1").displayName, "MLS");
  assert.equal(catalog.getLeague("MENS-COLLEGE-BASKETBALL").displayName,
    "NCAA Men's Basketball");
  assert.deepEqual(catalog.listLeagues().map((league) => league.id),
    ["nhl", "nfl", "mlb", "nba", "college-football", "eng.1", "usa.1",
      "mens-college-basketball"]);
  assert.deepEqual(catalog.ESPN_LEAGUE_METADATA, {
    nfl: {id: "nfl", name: "NFL", displayName: "NFL", enabledByDefault: false, provider: "espn", sport: "football", slug: "nfl", standingsSupported: true},
    mlb: {id: "mlb", name: "MLB", displayName: "MLB", enabledByDefault: false, provider: "espn", sport: "baseball", slug: "mlb", standingsSupported: true},
    nba: {id: "nba", name: "NBA", displayName: "NBA", enabledByDefault: false, provider: "espn", sport: "basketball", slug: "nba", standingsSupported: true},
    "college-football": {id: "college-football", name: "NCAA Football", displayName: "NCAA Football", enabledByDefault: false, provider: "espn", sport: "football", slug: "college-football", standingsSupported: true},
    "eng.1": {id: "eng.1", name: "Premier League", displayName: "Premier League", enabledByDefault: false, provider: "espn", sport: "soccer", slug: "eng.1", standingsSupported: true},
    "usa.1": {id: "usa.1", name: "MLS", displayName: "MLS", enabledByDefault: false, provider: "espn", sport: "soccer", slug: "usa.1", standingsSupported: true},
    "mens-college-basketball": {id: "mens-college-basketball", name: "NCAA Men's Basketball", displayName: "NCAA Men's Basketball", enabledByDefault: false, provider: "espn", sport: "basketball", slug: "mens-college-basketball", standingsSupported: true}
  });
  assert.equal(catalog.NHL.standingsSupported, true);
});

test("ESPN team catalogs expose canonical identities without provider payloads", () => {
  assert.equal(espnTeams.listTeams("nfl").length, 32);
  assert.equal(espnTeams.listTeams("mlb").length, 30);
  assert.equal(espnTeams.listTeams("nba").length, 30);
  assert.equal(espnTeams.listTeams("college-football").length, 45);
  assert.equal(espnTeams.listTeams("eng.1").length, 20);
  assert.equal(espnTeams.listTeams("usa.1").length, 30);
  assert.equal(espnTeams.listTeams("mens-college-basketball").length, 50);
  assert.equal(espnTeams.listTeams("NFL").find((team) => team.abbreviation === "NE").id, "nfl:17");
  assert.equal(espnTeams.listTeams("MLB").find((team) => team.abbreviation === "BOS").id, "mlb:2");
  assert.equal(espnTeams.listTeams("NBA").find((team) => team.abbreviation === "BOS").id, "nba:2");
  assert.equal(espnTeams.listTeams("college-football").find((team) => team.abbreviation === "UNC").id,
    "college-football:153");
  assert.equal(espnTeams.listTeams("eng.1").find((team) => team.abbreviation === "ARS").id,
    "eng.1:359");
  assert.equal(espnTeams.listTeams("usa.1").find((team) => team.abbreviation === "MIA").id,
    "usa.1:20232");
  assert.equal(espnTeams.listTeams("mens-college-basketball").find((team) => team.abbreviation === "AMER").id,
    "mens-college-basketball:44");
  assert.equal(espnTeams.buildTeamCatalogUrl("mens-college-basketball"),
    "https://site.api.espn.com/apis/site/v2/sports/basketball/mens-college-basketball/teams");
  assert.equal(espnTeams.buildTeamCatalogUrl("ncaab"), null);
  assert.equal(espnTeams.listTeamsForLeagues(["nhl"])[0], undefined);
});

test("ESPN team catalogs isolate malformed and unknown provider records", () => {
  const nfl = espnTeams.parseTeamCatalogResponse(readEspnTeamFixture("nfl"), "nfl");
  assert.deepEqual(nfl.teams.map((team) => team.id), ["nfl:2", "nfl:17"]);
  assert.deepEqual(nfl.errors, [{index: 2, code: "invalid-team"}, {index: 3, code: "invalid-team"}]);
  const mlb = espnTeams.parseTeamCatalogResponse(readEspnTeamFixture("mlb"), "mlb");
  assert.deepEqual(mlb.teams.map((team) => team.id), ["mlb:2", "mlb:10"]);
  const nba = espnTeams.parseTeamCatalogResponse(readEspnTeamFixture("nba"), "nba");
  assert.deepEqual(nba.teams.map((team) => team.id), ["nba:2", "nba:13"]);
  const ncaaf = espnTeams.parseTeamCatalogResponse(
    readEspnTeamFixture("college-football"), "college-football");
  assert.deepEqual(ncaaf.teams.map((team) => team.id),
    ["college-football:153", "college-football:2628"]);
  assert.deepEqual(ncaaf.errors, [{index: 2, code: "invalid-team"}, {index: 4, code: "invalid-team"}]);
  const epl = espnTeams.parseTeamCatalogResponse(readEspnTeamFixture("eng.1"), "eng.1");
  assert.deepEqual(epl.teams.map((team) => team.id), ["eng.1:359", "eng.1:388", "eng.1:360", "eng.1:361"]);
  assert.deepEqual(epl.errors, [{index: 3, code: "invalid-team"}]);
  const mls = espnTeams.parseTeamCatalogResponse(readEspnTeamFixture("usa.1"), "usa.1");
  assert.deepEqual(mls.teams.map((team) => team.id), ["usa.1:183", "usa.1:20232", "usa.1:189"]);
  assert.deepEqual(mls.errors, [{index: 3, code: "invalid-team"}, {index: 4, code: "invalid-team"}]);
  const ncaab = espnTeams.parseTeamCatalogResponse(
    readEspnTeamFixture("mens-college-basketball"), "mens-college-basketball");
  assert.deepEqual(ncaab.teams.map((team) => team.id),
    ["mens-college-basketball:44", "mens-college-basketball:9"]);
  assert.deepEqual(ncaab.errors, [{index: 2, code: "invalid-team"}, {index: 4, code: "invalid-team"}]);
  assert.deepEqual(espnTeams.parseTeamCatalogResponse({}, "nba"), {
    teams: [], errors: [{code: "invalid-team-response"}]
  });
});

test("NHL team catalog is bounded to the current normalized roster", () => {
  const teams = nhlTeams.listTeams();
  assert.equal(teams.length, 32);
  assert.deepEqual(teams[0], {
    id: "nhl:24",
    league: "nhl",
    providerTeamId: "24",
    name: "Anaheim Ducks",
    shortName: "Anaheim Ducks",
    abbreviation: "ANA",
    primaryColor: null,
    logoUrl: null,
    link: null
  });
  assert.equal(teams.some((team) => team.providerTeamId === "36"), false);
  assert.equal(teams.some((team) => team.providerTeamId === "68" && team.abbreviation === "UTA"), true);
});

test("NHL team discovery normalizes current records and skips history", () => {
  const result = nhlTeams.parseTeamCatalogResponse(readTeamFixture("teams"));
  assert.equal(result.teams.length, 4);
  assert.deepEqual(result.teams.map((team) => team.id), ["nhl:6", "nhl:13", "nhl:10", "nhl:68"]);
  assert.equal(result.teams.find((team) => team.id === "nhl:6").logoUrl,
    "https://assets.nhle.com/logos/nhl/svg/BOS_light.svg");
  assert.equal(result.errors.length, 0);
});

test("NHL standings fixture projects conference order, canonical teams, and nulls", () => {
  assert.equal(nhl.buildStandingsUrl(), "https://api-web.nhle.com/v1/standings/now");
  assert.equal(nhl.STANDINGS_ENDPOINT, nhl.buildStandingsUrl());
  assert.equal(nhl.buildStandingsUrl("2026-08-24"),
    "https://api-web.nhle.com/v1/standings/2026-08-24");
  assert.equal(nhl.buildStandingsUrl("20260824"), null);

  const result = nhl.parseStandingsResponse(readNhlStandingsFixture());
  assert.deepEqual(result.groups.map((group) => group.label),
    ["Eastern Conference", "Western Conference"]);
  assert.deepEqual(result.rows.map((row) => row.team.id),
    ["nhl:12", "nhl:6", "nhl:21", "nhl:25"]);
  assert.deepEqual(result.groups.map((group) => group.rows.map((row) => row.rank)),
    [[1, 5], [1, 2]]);
  assert.equal(result.rows[0].ties, 7);
  assert.equal(result.rows[0].recordLabel, "53-22-7");
  assert.equal(result.rows[0].team.logoUrl,
    "https://assets.nhle.com/logos/nhl/svg/CAR_light.svg");
  assert.equal(result.rows[1].team.id, "nhl:6");
  assert.equal(result.rows[1].team.name, null);
  assert.equal(result.rows[1].played, null);
  assert.equal(result.rows[1].wins, null);
  assert.equal(result.rows[1].points, null);
  assert.equal(result.rows[1].recordLabel, null);
  assert.equal(result.errors.length, 1);
  assert.deepEqual(result.errors[0], {index: 4, code: "invalid-standing-entry"});
  assert.equal(JSON.stringify(result).includes("teamLogo"), false);
});

test("NHL standings rejects malformed and empty payloads without inventing rows", () => {
  assert.deepEqual(nhl.parseStandingsResponse({standings: []}), {
    leagueId: "nhl", groups: [], rows: [], errors: []
  });
  assert.equal(nhl.parseStandingsResponse({}).errors[0].code,
    "invalid-standings-response");
  const mixed = nhl.parseStandingsResponse({standings: [
    {conferenceAbbrev: "E", conferenceName: "Eastern", conferenceSequence: 1,
      teamAbbrev: {default: "NOPE"}},
    {conferenceAbbrev: "E", conferenceName: "Eastern", conferenceSequence: 2,
      teamAbbrev: {default: "NYR"}, wins: "not-a-number"}
  ]});
  assert.equal(mixed.rows.length, 1);
  assert.equal(mixed.rows[0].team.id, "nhl:3");
  assert.equal(mixed.rows[0].wins, null);
  assert.equal(mixed.errors[0].code, "invalid-standing-entry");
});

test("malformed or missing team data fails safely", () => {
  const malformed = nhlTeams.parseTeamCatalogResponse(readTeamFixture("teams-malformed"));
  assert.deepEqual(malformed.teams.map((team) => team.id), ["nhl:6"]);
  assert.deepEqual(malformed.errors, [{index: 1, code: "invalid-team"}]);
  const missing = nhlTeams.parseTeamCatalogResponse(readTeamFixture("teams-missing"));
  assert.deepEqual(missing, {teams: [], errors: [{code: "invalid-team-response"}]});
});

test("keyboard cursor and activation bounds are deterministic", () => {
  assert.equal(pickerModel.clampCursor(0, -1, 3), 0);
  assert.equal(pickerModel.clampCursor(2, 1, 3), 2);
  assert.equal(pickerModel.clampCursor(1, -1, 3), 0);
  assert.equal(pickerModel.clampCursor(0, 1, 0), -1);
  const list = [{id: "nhl:6"}, {id: "nhl:13"}];
  assert.deepEqual(pickerModel.teamAt(list, 1), {id: "nhl:13"});
  assert.equal(pickerModel.teamAt(list, 2), null);
});

test("favorite team picker filters, chips, and selected-first ordering are deterministic", () => {
  const catalog = [
    {id: "nfl:2", league: "nfl", name: "Buffalo Bills", abbreviation: "BUF"},
    {id: "college-football:194", league: "college-football", name: "Ohio State Buckeyes", abbreviation: "OSU"},
    {id: "nfl:17", league: "nfl", name: "New England Patriots", abbreviation: "NE"},
    {id: "nhl:6", league: "nhl", name: "Boston Bruins", abbreviation: "BOS"}
  ];
  const favorites = ["nfl:17", "nhl:6"];
  assert.deepEqual(
    pickerModel.filterAndOrderTeams(catalog, "", "all", favorites).map((team) => team.id),
    ["nhl:6", "nfl:17", "nfl:2", "college-football:194"]
  );
  assert.deepEqual(
    pickerModel.filterAndOrderTeams(catalog, "ohio", "college-football", favorites)
      .map((team) => team.id),
    ["college-football:194"]
  );
  assert.deepEqual(
    pickerModel.filterAndOrderTeams(catalog, "buf", "nfl", favorites).map((team) => team.id),
    ["nfl:2"]
  );
  assert.equal(pickerModel.selectedCount(catalog, favorites), 2);
  assert.deepEqual(pickerModel.filterAndOrderTeams(catalog, "", "nba", favorites), []);
});

test("team IDs are canonical and preserve provider identity", () => {
  assert.equal(teams.canonicalTeamId("NHL", "bruins"), "nhl:bruins");
  const team = teams.normalizeTeam({
    league: "NHL",
    providerTeamId: "bruins",
    name: " Boston Bruins ",
    abbreviation: " BOS ",
    logoUrl: "not-a-url"
  });
  assert.deepEqual(team, {
    id: "nhl:bruins",
    league: "nhl",
    providerTeamId: "bruins",
    name: "Boston Bruins",
    shortName: null,
    abbreviation: "BOS",
    primaryColor: null,
    logoUrl: null,
    link: null
  });
  assert.equal(teams.normalizeTeam({ league: "nhl", providerTeamId: "" }), null);
  assert.equal(teams.normalizePrimaryColor(" BD3039 "), "#bd3039");
  assert.equal(teams.normalizePrimaryColor("not-a-color"), null);
  assert.equal(teams.createUnknownTeam("nhl", "bruins").name, null);
});

test("team logo URLs accept reviewed HTTPS hosts and preserve neutral fallbacks", () => {
  const fixture = readLogoUrlFixture();
  assert.deepEqual(Object.keys(assetUrlPolicy.REVIEWED_LOGO_HOSTS).sort(),
    ["a.espncdn.com", "assets.nhle.com"]);

  fixture.accepted.forEach((url, index) => {
    assert.equal(assetUrlPolicy.safeLogoUrl(url), url);
    const team = teams.normalizeTeam({league: "nhl", providerTeamId: String(index + 1),
      name: "Team", abbreviation: "T", logoUrl: url});
    assert.equal(team.logoUrl, url);
    const game = games.normalizeGame({league: "nhl", providerGameId: "logo-" + index,
      awayTeam: {league: "nhl", providerTeamId: String(index + 1), logoUrl: url},
      homeTeam: {league: "nhl", providerTeamId: String(index + 2), logoUrl: url}});
    assert.equal(game.awayTeam.logoUrl, url);
    assert.equal(game.homeTeam.logoUrl, url);
  });

  fixture.rejected.forEach(({label, url}, index) => {
    assert.equal(assetUrlPolicy.safeLogoUrl(url), null, label);
    const team = teams.normalizeTeam({league: "nhl", providerTeamId: "reject-" + index,
      name: "Team", abbreviation: "T", logoUrl: url});
    assert.equal(team.logoUrl, null, label);
    const game = games.normalizeGame({league: "nhl", providerGameId: "reject-" + index,
      awayTeam: {league: "nhl", providerTeamId: "reject-away-" + index, logoUrl: url},
      homeTeam: {league: "nhl", providerTeamId: "reject-home-" + index, logoUrl: url}});
    assert.equal(game.awayTeam.logoUrl, null, label);
    assert.equal(game.homeTeam.logoUrl, null, label);
  });

  const gameRow = readSource("components/GameRow.qml");
  const picker = readSource("components/TeamPicker.qml");
  assert.match(gameRow, /source: root\.game\.awayTeam && root\.game\.awayTeam\.logoUrl/);
  assert.match(gameRow, /visible: !awayLogo\.visible/);
  assert.match(picker, /source: modelData\.logoUrl \|\| ""/);
  assert.match(picker, /visible: !logo\.visible \|\| logo\.status !== Image\.Ready/);
});

test("scheduled fixture normalizes without inventing scores", () => {
  const [game] = normalizeFixtureGames(readFixture("scheduled"));
  assert.equal(game.isValid, true);
  assert.equal(game.status, games.GAME_STATES.SCHEDULED);
  assert.equal(game.id, "nhl:20261007-bos-mtl");
  assert.equal(game.startTime, "2026-10-08T00:00:00.000Z");
  assert.equal(game.awayScore, null);
  assert.equal(game.homeScore, null);
  assert.equal(game.awayTeam.id, "nhl:bruins");
  assert.equal(game.homeTeam.id, "nhl:canadiens");
});

test("live and intermission fixtures retain status details", () => {
  const normalized = normalizeFixtureGames(readFixture("live"));
  assert.equal(normalized[0].status, games.GAME_STATES.LIVE);
  assert.equal(normalized[0].period, 2);
  assert.equal(normalized[0].clock, "08:42");
  assert.equal(normalized[1].status, games.GAME_STATES.INTERMISSION);
  assert.equal(normalized[1].period, 1);
  assert.equal(normalized[1].clock, null);
});

test("final fixture normalizes end time and scores", () => {
  const [game] = normalizeFixtureGames(readFixture("final"));
  assert.equal(game.status, games.GAME_STATES.FINAL);
  assert.equal(game.awayScore, 4);
  assert.equal(game.homeScore, 3);
  assert.equal(game.endTime, "2026-10-10T01:42:00.000Z");
});

test("postponed, canceled, and unknown states are provider-neutral", () => {
  assert.equal(games.normalizeState("postponed"), "postponed");
  assert.equal(games.normalizeState("cancelled"), "canceled");
  assert.equal(games.normalizeState("provider-added-state"), "unknown");
  assert.equal(games.normalizeState(undefined), "unknown");
});

test("pure transition sequences cover all required leagues and silent baselines", () => {
  const fixture = readTransitionFixture();
  const expected = [
    ["game-start", "score-change", "game-final"],
    ["game-start", "score-change", "game-final"],
    ["game-start", "score-change", "game-final"],
    ["game-start", "score-change", "game-final"]
  ];

  fixture.sequences.forEach((sequence, sequenceIndex) => {
    const normalized = sequence.snapshots.map((snapshot) => games.normalizeGame(snapshot));
    assert.equal(normalized[0].id, sequence.gameId);
    assert.deepEqual(transitions.detect(null, normalized[0]), []);
    assert.deepEqual(transitions.detect(undefined, normalized[0]), []);

    const actual = [];
    for (let i = 1; i < normalized.length; i++) {
      actual.push(...transitions.detect(normalized[i - 1], normalized[i]).map((event) => event.type));
    }
    assert.deepEqual(actual, expected[sequenceIndex], sequence.league);
  });
});

test("a first fetch that discovers an already-live or final game is silent", () => {
  const fixture = readTransitionFixture();
  [fixture.sequences[0].snapshots[1], fixture.sequences[0].snapshots[4]].forEach((snapshot) => {
    assert.deepEqual(transitions.detect(null, games.normalizeGame(snapshot)), []);
  });
});

test("final transition coalesces an unseen score change", () => {
  const fixture = readTransitionFixture();
  const sequence = fixture.sequences[0].snapshots.map((snapshot) => games.normalizeGame(snapshot));
  const events = transitions.detect(sequence[3], sequence[4]);
  assert.deepEqual(events.map((event) => event.type), ["game-final"]);
  assert.deepEqual(events[0], {
    type: "game-final",
    gameId: "nhl:m6-nhl",
    league: "nhl",
    previousStatus: "intermission",
    currentStatus: "final",
    previousAwayScore: 1,
    previousHomeScore: 0,
    awayScore: 2,
    homeScore: 0
  });
});

test("corrections are observable score changes but repeated payloads are silent", () => {
  const fixture = readTransitionFixture();
  const normalized = fixture.correction.map((snapshot) => games.normalizeGame(snapshot));
  assert.deepEqual(transitions.detect(normalized[0], normalized[1]).map((event) => event.type), ["score-change"]);
  assert.deepEqual(transitions.detect(normalized[1], normalized[2]), []);
});

test("unknown, malformed, mismatched, and sibling games never create false transitions", () => {
  const fixture = readTransitionFixture();
  const normalized = fixture.sequences[0].snapshots.map((snapshot) => games.normalizeGame(snapshot));
  const unknown = games.normalizeGame({
    league: "nhl", providerGameId: "m6-nhl", status: "provider-added-state", awayScore: 2, homeScore: 0
  });
  const malformed = games.normalizeGame({league: "nhl", status: "live", awayScore: 2, homeScore: 0});
  const other = games.normalizeGame({
    league: "nhl", providerGameId: "m6-other", status: "live", awayScore: 2, homeScore: 0
  });

  assert.deepEqual(transitions.detect(normalized[2], unknown), []);
  assert.deepEqual(transitions.detect(normalized[2], malformed), []);
  assert.deepEqual(transitions.detect(normalized[2], other), []);
  assert.deepEqual(transitions.detectGames([normalized[2]], [other, normalized[4], normalized[4]]).map((event) => event.gameId), ["nhl:m6-nhl"]);
  assert.equal(transitions.isUsableGame(unknown), false);
  assert.equal(transitions.isUsableGame(malformed), false);
});

test("persistent dedupe fingerprints duplicate transition events", () => {
  const fixture = readDedupeFixture();
  const first = transitionDedupe.acceptEvents(
    transitionDedupe.createDefaults(),
    fixture.events.concat(fixture.events),
    fixture.now
  );

  assert.deepEqual(first.events.map((event) => event.type), [
    "game-start", "score-change", "game-final"
  ]);
  assert.deepEqual(first.state.fingerprints.map((entry) => entry.fingerprint), [
    "nhl:m6-2:final",
    "nhl:m6-2:score:1:0",
    "nhl:m6-2:start"
  ]);

  const replay = transitionDedupe.acceptEvents(first.state, fixture.events, fixture.now + 1);
  assert.deepEqual(replay.events, []);
  assert.equal(replay.state.fingerprints.length, 3);
});

test("persisted dedupe state survives a state-file reload without replay", () => {
  const fixture = readDedupeFixture();
  const accepted = transitionDedupe.acceptEvents(
    transitionDedupe.createDefaults(), fixture.events, fixture.now
  );
  const persisted = stateModel.createState(settingsModel.createDefaults(), accepted.state,
    settingsModel, transitionDedupe, fixture.now);
  const loaded = stateModel.parseStateText(JSON.stringify(persisted), fixture.now + 1);

  assert.equal(loaded.status, "valid");
  assert.equal(loaded.recovered, false);
  assert.deepEqual(loaded.transitionDedupe, accepted.state);
  assert.deepEqual(
    transitionDedupe.acceptEvents(loaded.transitionDedupe, fixture.events, fixture.now + 1).events,
    []
  );
});

test("dedupe pruning is deterministic by age and count", () => {
  const fixture = readDedupeFixture();
  const result = transitionDedupe.normalizeState({
    schemaVersion: 1,
    fingerprints: fixture.pruning.entries
  }, fixture.pruning.now, fixture.pruning);

  assert.deepEqual(result.state.fingerprints, [
    {fingerprint: "nhl:first", seenAt: 901},
    {fingerprint: "nhl:second", seenAt: 950},
    {fingerprint: "nhl:latest", seenAt: 1000}
  ]);
  assert.equal(result.changed, true);

  const bounded = transitionDedupe.acceptEvents(transitionDedupe.createDefaults(), [
    {type: "game-start", gameId: "nhl:a"},
    {type: "game-start", gameId: "nhl:b"},
    {type: "game-start", gameId: "nhl:c"},
    {type: "game-start", gameId: "nhl:d"}
  ], 1000, {maxFingerprints: 3, maxAgeMs: 1000});
  assert.equal(bounded.state.fingerprints.length, 3);
  assert.deepEqual(bounded.state.fingerprints.map((entry) => entry.fingerprint), [
    "nhl:b:start", "nhl:c:start", "nhl:d:start"
  ]);
  assert.equal(transitionDedupe.acceptEvents(bounded.state, [
    {type: "game-start", gameId: "nhl:a"}
  ], 1000, {maxFingerprints: 3, maxAgeMs: 1000}).events.length, 1);
});

test("missing or corrupt persisted dedupe state recovers to safe defaults", () => {
  const fixture = readDedupeFixture();
  const missing = stateModel.parseStateText("", fixture.now);
  assert.equal(missing.status, "missing");
  assert.deepEqual(missing.transitionDedupe, transitionDedupe.createDefaults());

  const legacy = stateModel.parseStateText(JSON.stringify(settingsModel.createDefaults()), fixture.now);
  assert.equal(legacy.recovered, true);
  assert.equal(legacy.needsWrite, true);
  assert.deepEqual(legacy.transitionDedupe, transitionDedupe.createDefaults());

  const corrupt = stateModel.parseStateText(JSON.stringify({
    schemaVersion: 1,
    enabledLeagues: ["nhl"],
    favoriteTeamIds: [],
    notifications: settingsModel.createDefaults().notifications,
    transitionDedupe: {schemaVersion: 1, fingerprints: ["not-an-entry"]}
  }), fixture.now);
  assert.equal(corrupt.recovered, true);
  assert.equal(corrupt.needsWrite, true);
  assert.deepEqual(corrupt.transitionDedupe, transitionDedupe.createDefaults());
  assert.deepEqual(transitionDedupe.acceptEvents(corrupt.transitionDedupe, fixture.events, fixture.now).events,
    fixture.events);
});

test("future state schemas stay opaque and never request a destructive write", () => {
  const fixture = readSettingsSchemaFixture();
  const future = stateModel.parseStateText(fixture.futureWithExtraFields, 1700000000000,
    settingsModel, transitionDedupe);
  assert.equal(future.status, "unsupported-schema");
  assert.equal(future.recovered, true);
  assert.equal(future.needsWrite, false);
  assert.equal(future.preservedRawText, fixture.futureWithExtraFields);
  assert.deepEqual(future.settings, settingsModel.createDefaults());
  assert.deepEqual(future.transitionDedupe, transitionDedupe.createDefaults());
  assert.equal(JSON.stringify(future.settings).includes("futurePreference"), false);

  const malformedFuture = stateModel.parseStateText(fixture.futureMalformed, 1700000000000,
    settingsModel, transitionDedupe);
  assert.equal(malformedFuture.status, "unsupported-schema");
  assert.equal(malformedFuture.needsWrite, false);
  assert.equal(malformedFuture.preservedRawText, fixture.futureMalformed);
  assert.deepEqual(malformedFuture.settings, settingsModel.createDefaults());

  const settingsFuture = settingsModel.parseSettingsText(fixture.futureWithExtraFields);
  assert.equal(settingsFuture.status, "unsupported-schema");
  assert.equal(settingsFuture.needsWrite, false);
  assert.equal(settingsFuture.preservedRawText, fixture.futureWithExtraFields);

  const schema1 = stateModel.parseStateText(fixture.schema1, 1700000000000,
    settingsModel, transitionDedupe);
  assert.equal(schema1.status, "field-recovered");
  assert.equal(schema1.needsWrite, true);
  assert.equal(schema1.preservedRawText, "");

  const corrupt = stateModel.parseStateText(fixture.corrupt, 1700000000000,
    settingsModel, transitionDedupe);
  assert.equal(corrupt.status, "invalid-json");
  assert.equal(corrupt.needsWrite, true);
  assert.equal(corrupt.preservedRawText, "");
});

test("loading persisted state never creates a first-load transition", () => {
  const transitionsFixture = readTransitionFixture();
  const live = games.normalizeGame(transitionsFixture.sequences[0].snapshots[1]);
  const firstFetchEvents = transitions.detect(null, live);
  const loaded = stateModel.parseStateText("", 1700000000000);

  assert.deepEqual(firstFetchEvents, []);
  assert.deepEqual(
    transitionDedupe.acceptEvents(loaded.transitionDedupe, firstFetchEvents, 1700000000000).events,
    []
  );
});

test("notification delivery gates favorites and global/event preferences", () => {
  const fixture = readNotificationFixture();
  const favorite = games.normalizeGame(fixture.favoriteGame);
  const other = games.normalizeGame(fixture.otherGame);
  const [start, scoreChange, final, otherScore] = fixture.events;
  const all = [start, scoreChange, final, otherScore];

  assert.deepEqual(
    notificationModel.buildDeliveries(all, [favorite, other], fixture.favoriteSettings)
      .map((delivery) => delivery.event.type),
    ["game-start", "score-change", "game-final"]
  );

  [
    ["gameStart", start],
    ["scoreChange", scoreChange],
    ["gameFinal", final]
  ].forEach(([key, event]) => {
    const disabled = JSON.parse(JSON.stringify(fixture.favoriteSettings));
    disabled.notifications[key] = false;
    assert.deepEqual(notificationModel.buildDeliveries([event], [favorite], disabled), []);
  });

  const globallyDisabled = JSON.parse(JSON.stringify(fixture.favoriteSettings));
  globallyDisabled.notifications.enabled = false;
  assert.deepEqual(notificationModel.buildDeliveries(all, [favorite, other], globallyDisabled), []);
});

test("notification argv and sport-neutral score/status text are deterministic", () => {
  const fixture = readNotificationFixture();
  const game = games.normalizeGame(fixture.favoriteGame);
  const delivery = notificationModel.buildDelivery(fixture.events[1], game);
  const started = notificationModel.buildDelivery(fixture.events[0], game);
  const finalGame = games.normalizeGame(fixture.scorePlusFinal.current);
  const finalized = notificationModel.buildDelivery(fixture.events[2], finalGame);
  assert.deepEqual(delivery.argv, fixture.expectedScoreArgv);
  assert.equal(started.headline, "Sportray · Game started");
  assert.equal(finalized.headline, "Sportray · Final");
  assert.equal(finalized.description, "BOS 4–2 TOR · Final");
  assert.equal(delivery.description.includes("BOS 3–2 TOR"), true);
  assert.equal(delivery.description.includes("2nd · 08:42"), true);
  assert.equal(delivery.description.includes("goal"), false);
  assert.equal(delivery.description.includes("touchdown"), false);
  assert.equal(delivery.description.includes("home run"), false);
});

test("provider notification text cannot become helper options", () => {
  const fixture = readNotificationFixture();
  const game = games.normalizeGame(fixture.favoriteGame);
  game.awayTeam.abbreviation = "--hint=string:omarchy-exec:touch /tmp/should-not-run";
  game.homeTeam.abbreviation = "\u0000 Knicks; echo injected";
  game.periodLabel = "--app-name injected";
  game.clock = "a".repeat(300);

  const delivery = notificationModel.buildDelivery(fixture.events[1], game);
  assert.equal(delivery.description.startsWith("· --hint="), true);
  assert.equal(delivery.description.includes("\u0000"), false);
  assert.equal(delivery.description.length <= 320, true);
  assert.equal(delivery.argv[delivery.argv.length - 1].startsWith("-"), false);

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "sportray-notification-"));
  const capturePath = path.join(tempDir, "argv.json");
  const stubPath = path.join(tempDir, "notify-send");
  fs.writeFileSync(stubPath, "#!/bin/sh\nprintf '%s\\n' \"$@\" > \"$CAPTURE_PATH\"\n");
  fs.chmodSync(stubPath, 0o700);
  const result = childProcess.spawnSync("/bin/bash", ["/usr/bin/omarchy-notification-send", ...delivery.argv.slice(1)], {
    env: {...process.env, PATH: tempDir, CAPTURE_PATH: capturePath},
    encoding: "utf8"
  });
  assert.equal(result.status, 0, result.stderr);
  const helperArgs = fs.readFileSync(capturePath, "utf8").trim().split("\n");
  assert.equal(helperArgs.at(-1), delivery.description);
  assert.equal(helperArgs.includes("--hint=string:omarchy-exec:touch /tmp/should-not-run"), false);
  fs.rmSync(tempDir, {recursive: true, force: true});
});

test("notification preview uses the real helper boundary without preferences", () => {
  const preview = notificationModel.buildTestDelivery();
  assert.deepEqual(preview.argv, [
    "/usr/bin/omarchy-notification-send", "--app-name", "Sportray", "-u", "normal",
    "Sportray · Test notification",
    "Alerts are working. This is a preview from Sportray."
  ]);
  assert.equal(preview.headline, "Sportray · Test notification");
  assert.equal(readSource("services/NotificationService.qml").includes(
    "function sendTestNotification()"), true);
  assert.equal(readSource("components/SettingsView.qml").includes(
    "Send test notification"), true);
});

test("notification dedupe suppresses accepted deliveries after state reload", () => {
  const fixture = readNotificationFixture();
  const game = games.normalizeGame(fixture.favoriteGame);
  const delivery = notificationModel.buildDelivery(fixture.events[1], game);
  const accepted = transitionDedupe.acceptEvents(
    transitionDedupe.createDefaults(), [delivery.event], fixture.now
  );
  const persisted = stateModel.createState(settingsModel.createDefaults(), accepted.state,
    settingsModel, transitionDedupe, fixture.now);
  const loaded = stateModel.parseStateText(JSON.stringify(persisted), fixture.now + 1);
  const replay = transitionDedupe.acceptEvents(loaded.transitionDedupe, [delivery.event], fixture.now + 1);
  assert.equal(accepted.events.length, 1);
  assert.equal(replay.events.length, 0);
});

test("score-plus-final transition produces one final notification", () => {
  const fixture = readNotificationFixture();
  const previous = games.normalizeGame(fixture.scorePlusFinal.previous);
  const current = games.normalizeGame(fixture.scorePlusFinal.current);
  const events = transitions.detect(previous, current);
  assert.deepEqual(events.map((event) => event.type), ["game-final"]);
  const deliveries = notificationModel.buildDeliveries(
    events, [current], fixture.favoriteSettings
  );
  assert.deepEqual(deliveries.map((delivery) => delivery.headline), ["Sportray · Final"]);
});

test("notification helper failure is represented safely without throwing", () => {
  assert.deepEqual(notificationModel.helperOutcome(0, 0), {
    ok: true, exitCode: 0, exitStatus: 0
  });
  assert.deepEqual(notificationModel.helperOutcome(1, 1), {
    ok: false, exitCode: 1, exitStatus: 1
  });
  assert.doesNotThrow(() => notificationModel.helperOutcome(undefined, undefined));
  assert.equal(readSource("services/NotificationService.qml").includes(
    "Sportray notification helper failed"), true);
});

test("pregame reminders admit only opted-in favorite games in the bounded local-date window", () => {
  const fixture = readPregameReminderFixture();
  const normalized = fixture.games.map((game) => games.normalizeGame(game));
  const now = Date.parse(fixture.now);
  const events = pregameReminder.eligibleEvents(
    normalized, fixture.settings, now, fixture.todayDateKey);
  assert.deepEqual(events, [fixture.expectedEvent]);

  const delivery = notificationModel.buildDelivery(events[0], normalized[0]);
  assert.deepEqual(delivery.argv, fixture.expectedArgv);
  assert.equal(delivery.description.includes("nhl:m6-5-eligible"), false);
  assert.equal(delivery.description.length <= 320, true);

  const disabled = JSON.parse(JSON.stringify(fixture.settings));
  disabled.notifications.pregameReminder = false;
  assert.deepEqual(pregameReminder.eligibleEvents(normalized, disabled, now,
    fixture.todayDateKey), []);
});

test("pregame reminder fingerprints use the existing persisted transition dedupe", () => {
  const fixture = readPregameReminderFixture();
  const event = fixture.expectedEvent;
  assert.equal(notificationModel.eventKey(event), "nhl:m6-5-eligible:pregame");
  assert.equal(transitionDedupe.fingerprintForEvent(event), "nhl:m6-5-eligible:pregame");

  const first = transitionDedupe.acceptEvents(
    transitionDedupe.createDefaults(), [event], Date.parse(fixture.now));
  const persisted = stateModel.createState(settingsModel.createDefaults(), first.state,
    settingsModel, transitionDedupe, Date.parse(fixture.now));
  const loaded = stateModel.parseStateText(JSON.stringify(persisted), Date.parse(fixture.now) + 1,
    settingsModel, transitionDedupe);
  const replay = transitionDedupe.acceptEvents(loaded.transitionDedupe, [event],
    Date.parse(fixture.now) + 1);
  assert.equal(first.events.length, 1);
  assert.equal(replay.events.length, 0);
});

test("close-game policy admits only an opted-in favorite entering a one-score margin", () => {
  const fixture = readCloseGameFixture();
  const previous = games.normalizeGame(fixture.eligible.previous);
  const current = games.normalizeGame(fixture.eligible.current);
  const settings = settingsModel.normalizeSettings({
    schemaVersion: 1,
    enabledLeagues: ["nhl"],
    favoriteTeamIds: fixture.settings.favoriteTeamIds,
    notifications: fixture.settings.notifications
  }).settings;
  const events = closeGame.eligibleEvents([previous], [current], settings,
    fixture.todayDateKey);
  assert.deepEqual(events, [fixture.expectedEvent]);

  const delivery = notificationModel.buildDelivery(events[0], current);
  assert.deepEqual(delivery.argv, fixture.expectedArgv);
  assert.equal(delivery.description.includes("nhl:m6-6-eligible"), false);
  assert.equal(delivery.description.length <= 320, true);

  const disabled = settingsModel.normalizeSettings({
    schemaVersion: 1,
    enabledLeagues: ["nhl"],
    favoriteTeamIds: fixture.disabled.favoriteTeamIds,
    notifications: fixture.disabled.notifications
  }).settings;
  assert.deepEqual(closeGame.eligibleEvents([previous], [current], disabled,
    fixture.todayDateKey), []);

  const nonFavorite = games.normalizeGame(fixture.nonFavorite);
  assert.deepEqual(closeGame.eligibleEvents([], [nonFavorite], settings,
    fixture.todayDateKey), []);

  const notApplicable = fixture.notApplicable.map((game) => games.normalizeGame(game));
  assert.deepEqual(closeGame.eligibleEvents([], notApplicable, settings,
    fixture.todayDateKey), []);
});

test("close-game alerts use one persisted fingerprint across reloads", () => {
  const fixture = readCloseGameFixture();
  const event = fixture.expectedEvent;
  assert.equal(notificationModel.eventKey(event), "nhl:m6-6-eligible:close");
  assert.equal(transitionDedupe.fingerprintForEvent(event), "nhl:m6-6-eligible:close");

  const now = Date.parse("2026-10-10T23:31:00Z");
  const first = transitionDedupe.acceptEvents(
    transitionDedupe.createDefaults(), [event], now);
  const persisted = stateModel.createState(settingsModel.createDefaults(), first.state,
    settingsModel, transitionDedupe, now);
  const loaded = stateModel.parseStateText(JSON.stringify(persisted), now + 1,
    settingsModel, transitionDedupe);
  const replay = transitionDedupe.acceptEvents(loaded.transitionDedupe, [event], now + 1);
  assert.equal(first.events.length, 1);
  assert.equal(replay.events.length, 0);
});

test("panel explicitly refreshes derived presentation on settings changes", () => {
  const source = readSource("Panel.qml");
  assert.equal(source.includes("property int presentationRevision: 0"), true);
  assert.equal(source.includes("function copyStringList(value, fallback)"), true);
  assert.equal(source.includes("root.copyStringList(root.settingsStore"), true);
  assert.equal(source.includes("target: root.settingsStore"), true);
  assert.equal(source.includes("function onSettingsChanged()"), true);
  assert.equal(source.includes("FavoritePresentation.isFavoriteGame, root.presentationRevision"), true);
});

test("panel keeps the host settings property and injects its distinct settings store", () => {
  const fixture = readSettingsBoundaryFixture();
  const panel = readSource("Panel.qml");
  const barWidget = readSource("BarWidget.qml");

  assert.equal((panel.match(new RegExp(fixture.panel.declaration, "g")) || []).length, 1);
  assert.equal((panel.match(new RegExp(fixture.panel.forbiddenDeclaration, "g")) || []).length, 0);
  fixture.panel.consumerTokens.forEach((token) => assert.equal(panel.includes(token), true));
  fixture.barWidget.consumerTokens.forEach((token) => assert.equal(barWidget.includes(token), true));
  assert.equal((panel.match(/\broot\.settings\b/g) || []).length, 0);
  assert.equal((barWidget.match(/target\.settings\b/g) || []).length, 0);
  assert.equal(panel.includes("readonly property var notificationService: root.service"), true);
  assert.equal(panel.includes("notificationService: root.notificationService"), true);
  assert.equal(readSource("services/SportrayService.qml").includes(
    "readonly property var notificationService: notificationServiceImpl"), true);
});

test("settings are unified behind one hub with a deep-linkable favorite destination", () => {
  const panel = readSource("Panel.qml");
  const hub = readSource("components/SettingsHub.qml");
  const picker = readSource("components/TeamPicker.qml");
  assert.equal(panel.includes('id: settingsButton'), true);
  assert.equal(panel.includes('SettingsHub {'), true);
  assert.equal(panel.includes('root.openUtility("teams")'), true);
  assert.equal(panel.includes("property bool pickerOpen"), false);
  assert.equal(hub.includes('"Sports & leagues"'), true);
  assert.equal(hub.includes('"Favorite teams"'), true);
  assert.equal(hub.includes('"Notifications"'), true);
  assert.equal(hub.includes("id: sectionTabs"), true);
  assert.equal(hub.includes("id: sectionTabBlock"), true);
  assert.equal(hub.includes("radius: 0"), true);
  assert.equal(hub.includes("PathArc.Clockwise"), true);
  assert.equal(hub.includes("y: sectionTabs.height"), true);
  assert.equal(hub.includes("selected: false"), true);
  assert.equal(hub.includes("color: root.destination === tabButton.modelData.id ? Color.accent : \"transparent\""), true);
  assert.equal(hub.includes("color: Color.popups.border"), true);
  assert.equal(hub.includes("function reset(destination)"), true);
  assert.equal(readSource("components/SportsSettings.qml").includes('text: "Sports & leagues"'), false);
  assert.equal(readSource("components/TeamPicker.qml").includes('text: "Favorite teams"'), false);
  assert.equal(readSource("components/SettingsView.qml").includes('text: "Notification preferences"'), false);
  assert.equal(readSource("components/SportsSettings.qml").includes('text: "Enable the scoreboards you want in the sport chooser."'), false);
  assert.equal(picker.includes('text: root.selectedCount + " selected · selected teams stay at the top"'), true);
  assert.equal(readSource("components/SettingsView.qml").includes('text: "↑/↓ or j/k to move · Enter/Space to toggle · n to open"'), true);
  assert.equal(picker.includes("filterAndOrderTeams"), true);
  assert.equal(picker.includes("ListView"), true);
  assert.equal(picker.includes("logo.status"), true);
  assert.equal(picker.includes("if (!root.visible) searchInput.focus = false"), true);
});

test("U2.4 keeps semantic icons local and maps every active league", () => {
  const expected = {
    following: "neutral",
    nhl: "hockey",
    nfl: "football",
    mlb: "baseball",
    nba: "basketball",
    "college-football": "football",
    "eng.1": "soccerField",
    "usa.1": "soccerField",
    "mens-college-basketball": "basketball"
  };
  Object.entries(expected).forEach(([league, iconName]) => {
    assert.equal(iconography.iconNameForLeague(league), iconName, league);
    assert.equal(iconography.glyph(iconName).length > 0, true, iconName);
    assert.equal(iconography.fallback(iconName).length > 0, true, iconName);
  });
  assert.equal(iconography.glyph("soccerField").codePointAt(0), 0xf04b8);
  assert.equal(iconography.glyph("neutral").codePointAt(0), 0xf0a1d);
  assert.equal(iconography.glyph("undo").codePointAt(0), 0xf054c);
  assert.equal(iconography.glyph("calendar").codePointAt(0), 0xf00ed);
  assert.equal(iconography.displayText("settings", "JetBrainsMono Nerd Font").length > 0, true);
  assert.equal(iconography.displayText("settings", "monospace").codePointAt(0), 0xf0493);
  assert.equal(iconography.displayText("settings", "Sans").includes("[ ]"), true);

  assert.equal(presentation.isLiveFavoriteState({kind: "neutral", game: null}), false);
  assert.equal(presentation.isLiveFavoriteState({kind: "live-favorite", game: {}}), true);
  assert.equal(presentation.isLiveFavoriteState({kind: "live-favorite-count", count: 2}), true);
  assert.equal(presentation.isLiveFavoriteState({kind: "live-favorite-count", count: 0}), false);

  const panel = readSource("Panel.qml");
  const hub = readSource("components/SettingsHub.qml");
  const picker = readSource("components/TeamPicker.qml");
  const gameRow = readSource("components/GameRow.qml");
  const icon = readSource("components/SemanticIcon.qml");
  const action = readSource("components/SemanticActionButton.qml");
  const atmosphere = readSource("components/SportAtmosphere.qml");
  const bar = readSource("BarWidget.qml");
  assert.equal(panel.includes('import "model/Iconography.js" as Iconography'), true);
  assert.equal(panel.includes("SemanticActionButton {"), true);
  assert.equal(panel.includes("SportAtmosphere {"), true);
  assert.equal(panel.includes(
    'root.settingsOpen ? "settings" : root.detailOpen ? "scores" : "calendar"'), true);
  assert.equal(panel.includes('root.settingsOpen ? "  Settings"'), true);
  assert.equal(panel.includes('iconName: "refresh"'), true);
  assert.equal(panel.includes('iconName: fetchService.loading ? "overflow" : "refresh"'), false);
  assert.equal(panel.includes('iconName: root.settingsOpen ? "close" : "settings"'), true);
  assert.equal(panel.includes('fallbackText: root.settingsOpen ? "X" : "[ ]"'), true);
  assert.equal(panel.includes('tooltipText: root.settingsOpen ? "Close settings" : "Sportray settings"'), true);
  assert.equal(panel.includes("Iconography.displayText"), true);
  assert.equal(hub.includes('text: "Settings"'), false);
  assert.equal(hub.includes('text: "Choose a settings area, then use Back or Escape to return to scores."'), false);
  assert.equal(picker.includes('iconName: root.isFavorite(modelData) ? "star" : "starOutline"'), true);
  assert.equal(gameRow.includes('iconName: "star"'), true);
  assert.equal(icon.includes("Iconography.displayText"), true);
  assert.equal(action.includes("Accessible.name: root.tooltipText"), true);
  assert.equal(action.includes('property string text: ""'), true);
  assert.equal(action.includes("property bool textBold: false"), true);
  assert.equal(action.includes("font.bold: root.textBold"), true);
  assert.equal(atmosphere.includes("clip: true"), true);
  assert.equal(atmosphere.includes("Util.alpha(Color.accent"), true);
  ["hockeyRink", "baseballDiamond", "footballField", "basketballKey", "soccerField"].forEach((shape) => {
    assert.equal(atmosphere.includes("id: " + shape), true, shape);
  });
  assert.equal(atmosphere.includes("property bool reducedMotion: false"), true);
  assert.equal(atmosphere.includes("Behavior on opacity"), false);
  assert.equal(bar.includes("BarIconButton {"), true);
  assert.equal(bar.includes("Iconography.displayText(root.barIconName"), true);
  assert.equal(bar.includes("tooltipText: root.barTooltipText"), true);
  assert.equal(bar.includes("Accessible.name: root.barTooltipText"), true);
  assert.equal(bar.includes("root.barHasLiveFavorite"), true);
  assert.equal(panel.includes("SemanticIcon {"), true);
  assert.equal(panel.includes("iconName: Iconography.iconNameForLeague(root.activeDestination)"), true);
  assert.equal(panel.includes('return "Live favorite · " + text'), true);
  assert.equal(bar.includes("root.scoreText"), false);
  assert.equal(bar.includes("root.verticalScoreLines"), false);
  assert.equal(panel.includes('readonly property string barIconName: barIconNameForState()'), true);
  assert.equal(panel.includes('if (root.opened && !root.settingsOpen && root.activeDestination !== "following")'), true);
  assert.equal(panel.includes('return Iconography.iconNameForLeague(root.activeDestination)'), true);
  assert.equal(panel.includes('return "soccerField"'), true);
});

test("date navigation stays provider-neutral and refresh controls live in the header", () => {
  const panel = readSource("Panel.qml");
  const carousel = readSource("components/DateCarousel.qml");
  const fetchService = readSource("services/FetchService.qml");
  const leagueFetch = readSource("services/LeagueFetch.qml");
  assert.equal(panel.includes('id: refreshButton'), true);
  assert.equal(panel.includes('DateCarousel {'), true);
  assert.equal(panel.includes('selectedDateKey: root.selectedDateKey'), true);
  assert.equal(panel.includes('text: fetchService.stale ? "Some updates are stale" : "Today"'), false);
  assert.equal(panel.includes('text: "Sports"'), false);
  assert.equal(panel.includes('id: sportsLabel'), false);
  assert.equal(panel.includes('root.activeView.title || root.activeView.displayName || "Scores"'), false);
  assert.equal(panel.includes('"Your teams on " + root.selectedDateLabel'), false);
  assert.equal(panel.includes('"Live scores · refreshing"'), false);
  assert.equal(panel.includes('"Live scores"'), false);
  assert.equal(panel.includes('text === "[" || text === "{"'), true);
  assert.equal(panel.includes('text === "]" || text === "}"'), true);
  assert.equal(carousel.includes('signal dateSelected(string dateKey)'), true);
  assert.equal(panel.includes('id: todayButton'), true);
  assert.equal(panel.includes('visible: !root.settingsOpen && !root.detailOpen'), true);
  assert.equal(panel.includes('text: "Show Today"'), true);
  assert.equal(panel.includes('iconName: ""'), true);
  assert.equal(panel.includes('textBold: true'), true);
  assert.equal(panel.includes('textFontSize: Style.font.caption'), true);
  assert.equal(panel.includes('textVerticalPadding: Style.spacing.controlPaddingY / 2'), true);
  assert.equal(panel.includes('iconText: Iconography.displayText("undo", Style.font.family)'), false);
  assert.equal(panel.includes('horizontalPadding: Style.spacing.controlPaddingX'), false);
  assert.equal(panel.includes('verticalPadding: Style.spacing.controlPaddingY / 2'), false);
  assert.equal(panel.includes('height: refreshButton.implicitHeight'), true);
  assert.equal(panel.includes('fontSize: Style.font.caption'), false);
  assert.equal(carousel.includes('id: todayButton'), false);
  assert.equal(carousel.includes('id: dateTagLabel'), false);
  assert.equal(carousel.includes('id: dateLabel'), false);
  assert.equal(carousel.includes('root.isToday ? "CURRENT" : "SELECTED"'), false);
  assert.equal(carousel.includes('tooltipText: "Previous day"'), true);
  assert.equal(carousel.includes('tooltipText: "Next day"'), true);
  assert.equal(panel.includes('tooltipText: "Return to today"'), true);
  assert.equal(fetchService.includes('property string selectedDateKey'), true);
  assert.equal((fetchService.match(/dateKey: root\.selectedDateKey/g) || []).length, 8);
  assert.equal(leagueFetch.includes('NhlProvider.buildScoreUrl(root.dateKey)'), true);
  assert.equal(leagueFetch.includes('root.dateKey.replace(/-/g, "")'), true);
});

test("date cache admission preserves same-date restore and rejects stale snapshots", () => {
  const fixture = readDateCacheFixture();
  fixture.scenarios.forEach((scenario) => {
    assert.equal(
      dateCachePolicy.canRestoreLastKnown(
        scenario.snapshotDateKey,
        scenario.selectedDateKey,
        scenario.lastKnownGames,
        scenario.currentGames),
      scenario.expectedRestore,
      scenario.name);
  });
  assert.equal(dateCachePolicy.snapshotMatchesDate("2026-08-19", "2026-08-19"), true);
  assert.equal(dateCachePolicy.snapshotMatchesDate("2026-08-19", "2026-08-20"), false);
  assert.equal(dateCachePolicy.snapshotMatchesDate("not-a-date", "not-a-date"), false);
});

test("panel presentation keeps canonical favorites when its QML import has no require", () => {
  assert.deepEqual(panelPresentation.normalizeFavoriteIds([
    "NHL:6", "nhl:6", "not-an-id"
  ]), ["nhl:6"]);
});

test("featured game cards use a readable theme-aware selected fill", () => {
  const source = readSource("components/GameRow.qml");
  assert.match(source,
    /color: root\.featured \? Style\.selectedFillFor\(Color\.popups\.text, Color\.accent\)/);
  assert.doesNotMatch(source, /color: root\.featured \? Style\.selectedStateColor/);
});

test("game cards use a bounded home-team tint and expose venue text", () => {
  const source = readSource("components/GameRow.qml");
  assert.match(source, /root\.game\.homeTeam\.primaryColor/);
  assert.match(source, /root\.hasHomeTint \? \(root\.featured \? 0\.07 : 0\.11\) : 0/);
  assert.match(source, /readonly property string venueLabel: root\.venueName \? "At " \+ root\.venueName : ""/);
  assert.match(source, /id: venueText/);
  assert.match(source, /text: root\.venueLabel/);
  assert.match(source, /wrapMode: Text\.Wrap/);
  assert.match(source,
    /implicitHeight: Math\.max\(footerDetails\.implicitHeight, sourceLink\.implicitHeight\)/);
  assert.match(source, /anchors\.verticalCenter: parent\.verticalCenter/);
  assert.match(source, /root\.venueName \? "At " \+ root\.venueName/);
});

test("game cards show local start dates for every known game state", () => {
  const source = readSource("components/GameRow.qml");
  assert.match(source, /Qt\.formatDateTime\(date, "MMM d, h:mm AP"\)/);
  assert.match(source, /includeStartTime: true/);
  assert.match(source, /startTimeText: root\.localStartDateTime\(root\.game\.startTime\)/);
});

test("game cards expose normalized provider source links", () => {
  const gameRow = readSource("components/GameRow.qml");
  const nextGameCard = readSource("components/NextGameCard.qml");
  const sourceButton = readSource("components/SourceLinkButton.qml");
  assert.equal(gameRow.includes("SourceLinkButton {"), true);
  assert.equal(nextGameCard.includes("SourceLinkButton {"), true);
  assert.equal(sourceButton.includes("root.game.link"), true);
  assert.equal(sourceButton.includes("omarchy-launch-browser"), true);
  assert.equal(sourceButton.includes('tooltipText: "Open " + root.sourceName + " game page"'), true);
  assert.match(nextGameCard, /root\.game\.homeTeam\.primaryColor/);
  assert.match(nextGameCard, /root\.venueName \? "   ·   " \+ root\.venueName/);

  const direct = games.normalizeGame({
    league: "nhl", providerGameId: "unsafe-link", status: "scheduled",
    link: "https://attacker.example/?next=www.nhl.com"
  });
  assert.equal(direct.link, null);

  const espnPayload = JSON.parse(JSON.stringify(readEspnFixture("nfl-scheduled")));
  espnPayload.events[0].links = [{rel: ["event"], href: "https://attacker.example/espn.com"}];
  assert.equal(espn.parseScoreboardResponse(espnPayload, "nfl").games[0].link,
    "https://www.espn.com/nfl/game/_/gameId/401772901");

  const nhlPayload = JSON.parse(JSON.stringify(readRawFixture("scheduled")));
  nhlPayload.games[0].gameCenterLink = "https://attacker.example/nhl.com";
  assert.equal(nhl.parseScoreResponse(nhlPayload).games[0].link,
    "https://www.nhl.com/gamecenter/2026020003");
});

test("malformed fixture fails safely and never exposes raw fields", () => {
  const normalized = normalizeFixtureGames(readFixture("malformed"));
  assert.equal(normalized[0].status, "malformed");
  assert.equal(normalized[0].isValid, false);
  assert.equal(normalized[1].status, "malformed");
  assert.equal(normalized[2].status, "unknown");
  assert.equal(normalized[2].awayScore, null);
  assert.equal(normalized[2].homeScore, 1);
  assert.equal(normalized[2].awayTeam.id, "other-league:one");
  assert.equal(Object.prototype.hasOwnProperty.call(normalized[2], "statusProviderObject"), false);
  assert.equal(games.normalizeGame({ league: "nhl", providerGameId: "safe" }).status, "unknown");
});

test("default game is safe and empty", () => {
  assert.deepEqual(games.createDefaultGame(), {
    id: null,
    league: null,
    providerGameId: null,
    startTime: null,
    endTime: null,
    status: "unknown",
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
  });
});

test("formatters keep presentation out of QML", () => {
  const [game] = normalizeFixtureGames(readFixture("live"));
  assert.equal(formatters.formatMatchup(game), "BOS vs TOR");
  assert.equal(formatters.formatScore(game), "3–2");
  assert.equal(formatters.formatStatus(game), "2nd · 08:42");
  assert.equal(formatters.formatGameStateLabel(game), "LIVE · 2nd · 08:42");
  assert.equal(formatters.formatGameStateLabel(game, {
    includeStartTime: true,
    startTimeText: "Aug 16, 4:10 PM"
  }), "Aug 16, 4:10 PM · LIVE · 2nd · 08:42");
  assert.equal(formatters.formatGameStateLabel({status: "intermission", periodLabel: "Halftime"}),
    "INTERMISSION · Halftime");
  assert.equal(formatters.formatGameStateLabel({status: "final"}), "FINAL");
  assert.equal(formatters.formatGameStateLabel({
    status: "final", startTime: "2026-08-16T20:10:00.000Z"
  }, {includeStartTime: true, startTimeText: "Aug 16, 4:10 PM"}),
    "Aug 16, 4:10 PM · FINAL");
  assert.equal(formatters.formatGameStateLabel({
    status: "scheduled", startTime: "2026-08-20T23:00:00.000Z"
  }, {startTimeText: "Aug 20, 7:00 PM"}), "SCHEDULED · Aug 20, 7:00 PM");
  assert.equal(formatters.formatGameStateLabel({status: "postponed"}), "POSTPONED");
  assert.equal(formatters.formatStatus({ status: "final" }), "Final");
  assert.equal(formatters.formatMatchup({}), "TBD vs TBD");
  assert.equal(formatters.formatScore({ awayScore: null, homeScore: null }), "—");
  assert.equal(formatters.formatStartTime("2026-10-08T00:00:00.000Z"), "Oct 8, 12:00 AM");
  assert.equal(formatters.formatStartTime("bad-time"), "Time unavailable");
});

test("league formatters use normalized NFL, MLB, and NBA fields", () => {
  const nflScheduled = espn.parseScoreboardResponse(readEspnFixture("nfl-scheduled"), "nfl").games[0];
  const nflLive = espn.parseScoreboardResponse(readEspnFixture("nfl-live"), "nfl").games[0];
  const nflHalftime = espn.parseScoreboardResponse(readEspnFixture("nfl-halftime"), "nfl").games[0];
  const mlbLive = espn.parseScoreboardResponse(readEspnFixture("mlb-live"), "mlb").games[0];
  const mlbFinal = espn.parseScoreboardResponse(readEspnFixture("mlb-final"), "mlb").games[0];
  const nbaLive = espn.parseScoreboardResponse(readEspnFixture("nba-live"), "nba").games[0];
  const nbaHalftime = espn.parseScoreboardResponse(readEspnFixture("nba-halftime"), "nba").games[0];
  const ncaafScheduled = espn.parseScoreboardResponse(
    readEspnFixture("ncaaf-scheduled"), "college-football").games[0];
  const ncaafLive = espn.parseScoreboardResponse(
    readEspnFixture("ncaaf-live"), "college-football").games[0];
  const ncaafIntermission = espn.parseScoreboardResponse(
    readEspnFixture("ncaaf-intermission"), "college-football").games[0];
  const eplScheduled = espn.parseScoreboardResponse(
    readEspnFixture("epl-scheduled"), "eng.1").games[0];
  const eplLive = espn.parseScoreboardResponse(readEspnFixture("epl-live"), "eng.1").games[0];
  const eplIntermission = espn.parseScoreboardResponse(
    readEspnFixture("epl-intermission"), "eng.1").games[0];
  const eplFinal = espn.parseScoreboardResponse(readEspnFixture("epl-final"), "eng.1").games[0];
  const mlsScheduled = espn.parseScoreboardResponse(
    readEspnFixture("mls-scheduled"), "usa.1").games[0];
  const mlsLive = espn.parseScoreboardResponse(readEspnFixture("mls-live"), "usa.1").games[0];
  const mlsIntermission = espn.parseScoreboardResponse(
    readEspnFixture("mls-intermission"), "usa.1").games[0];
  const mlsFinal = espn.parseScoreboardResponse(readEspnFixture("mls-final"), "usa.1").games[0];

  assert.equal(
    formatters.formatCompactGame(nflScheduled, {timeZone: "America/New_York"}),
    "BUF vs NE · 1:00 PM"
  );
  assert.equal(formatters.formatPanelStatus(nflScheduled, {timeZone: "America/New_York"}),
    "Scheduled · Sep 13, 1:00 PM");
  assert.equal(formatters.formatCompactGame(nflLive), "ARI 14–17 KC");
  assert.equal(formatters.formatPanelStatus(nflLive), "3rd · 6:42");
  assert.equal(formatters.formatPanelStatus(nflHalftime), "Halftime · 0:00");

  assert.equal(formatters.formatCompactGame(mlbLive), "SD 5–4 LAD");
  assert.equal(formatters.formatPanelStatus(mlbLive), "Bottom 7th · 0:00");
  assert.deepEqual(formatters.formatPanelGame(mlbFinal), {
    awayLabel: "TEX",
    homeLabel: "HOU",
    matchup: "TEX vs HOU",
    score: "6–2",
    status: "Final"
  });

  assert.equal(formatters.formatCompactGame(nbaLive), "OKC 91–88 DEN");
  assert.equal(formatters.formatPanelStatus(nbaLive), "3rd Quarter · 4:37");
  assert.equal(formatters.formatPanelStatus(nbaHalftime), "Halftime · 0:00");

  assert.equal(formatters.formatCompactGame(ncaafScheduled, {timeZone: "America/New_York"}),
    "UNC vs TCU · 12:00 PM");
  assert.equal(formatters.formatPanelStatus(ncaafScheduled, {timeZone: "America/New_York"}),
    "Scheduled · Aug 29, 12:00 PM");
  assert.equal(formatters.formatCompactGame(ncaafLive), "SJSU 14–17 USC");
  assert.equal(formatters.formatPanelStatus(ncaafLive), "3rd · 6:42");
  assert.equal(formatters.formatPanelStatus(ncaafIntermission), "Halftime · 0:00");

  assert.equal(formatters.formatCompactGame(eplScheduled, {timeZone: "America/New_York"}),
    "COV vs ARS · 3:00 PM");
  assert.equal(formatters.formatPanelStatus(eplLive), "78'");
  assert.equal(formatters.formatPanelStatus(eplIntermission), "Halftime · 45:00");
  assert.equal(formatters.formatCompactGame(eplFinal), "CHE 1–1 ARS");
  assert.equal(formatters.formatPanelStatus(eplFinal), "Final");
  assert.equal(formatters.formatCompactGame(mlsScheduled, {timeZone: "America/New_York"}),
    "NE vs DC · 7:30 PM");
  assert.equal(formatters.formatPanelStatus(mlsLive), "72'");
  assert.equal(formatters.formatPanelStatus(mlsIntermission), "Halftime · 45:00");
  assert.equal(formatters.formatCompactGame(mlsFinal), "NSH 2–2 RBNY");
  assert.equal(formatters.formatPanelStatus(mlsFinal), "Final");
});

test("league period fallbacks remain provider-neutral", () => {
  assert.equal(formatters.formatPeriodClock({league: "nfl", status: "live", period: 4, clock: "2:10"}),
    "4th · 2:10");
  assert.equal(formatters.formatPeriodClock({league: "mlb", status: "live", period: 11, clock: "0:00"}),
    "11th inning · 0:00");
  assert.equal(formatters.formatPeriodClock({league: "nba", status: "live", period: 2, clock: "5:00"}),
    "2nd Quarter · 5:00");
  assert.equal(formatters.formatPeriodClock({league: "college-football", status: "live", period: 4, clock: "2:10"}),
    "4th · 2:10");
  assert.equal(formatters.formatPeriodClock({league: "eng.1", status: "live", period: 2, clock: "12'"}),
    "2nd half · 12'");
  assert.equal(formatters.formatPeriodClock({league: "mens-college-basketball", status: "live", period: 1, clock: "12:34"}),
    "1st half · 12:34");
  assert.equal(formatters.formatPeriodClock({league: "mens-college-basketball", status: "live", period: 2, clock: "4:21"}),
    "2nd half · 4:21");
  assert.equal(formatters.formatStatus({league: "eng.1", status: "final", statusDetail: "AET"}), "AET");
});

test("NHL provider builds the verified no-key score URLs", () => {
  assert.equal(nhl.ENDPOINT, "https://api-web.nhle.com/v1/score/now");
  assert.equal(nhl.buildScoreUrl(), nhl.ENDPOINT);
  assert.equal(nhl.buildScoreUrl("2026-09-29"), "https://api-web.nhle.com/v1/score/2026-09-29");
  assert.equal(nhl.buildScoreUrl("2026/09/29"), null);
  assert.equal(nhl.buildGameUrl("2026020010"),
    "https://www.nhl.com/gamecenter/2026020010");
  assert.equal(nhl.buildGameUrl(""), null);
});

test("ESPN provider exposes controlled no-key scoreboard URLs and metadata", () => {
  assert.equal(espn.metadataFor("NFL").sport, "football");
  assert.equal(espn.buildScoreUrl("nfl"), "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard");
  assert.equal(espn.buildScoreUrl("mlb", "20260816"), "https://site.api.espn.com/apis/site/v2/sports/baseball/mlb/scoreboard?dates=20260816");
  assert.equal(espn.metadataFor("college-football").displayName, "NCAA Football");
  assert.equal(espn.buildScoreUrl("college-football", "20260829"),
    "https://site.api.espn.com/apis/site/v2/sports/football/college-football/scoreboard?dates=20260829");
  assert.equal(espn.metadataFor("ENG.1").displayName, "Premier League");
  assert.equal(espn.buildScoreUrl("eng.1"),
    "https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/scoreboard");
  assert.equal(espn.metadataFor("USA.1").displayName, "MLS");
  assert.equal(espn.buildScoreUrl("usa.1"),
    "https://site.api.espn.com/apis/site/v2/sports/soccer/usa.1/scoreboard");
  assert.equal(espn.metadataFor("MENS-COLLEGE-BASKETBALL").displayName,
    "NCAA Men's Basketball");
  assert.equal(espn.buildScoreUrl("mens-college-basketball"),
    "https://site.api.espn.com/apis/site/v2/sports/basketball/mens-college-basketball/scoreboard");
  assert.equal(espn.buildScoreUrl("nba", "2026-08-16"), null);
  assert.equal(espn.buildScoreUrl("nhl"), null);
  assert.equal(espn.buildNextGamesUrl("eng.1", "2026-08-20", "2026-09-24"),
    "https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/scoreboard?dates=20260820-20260924");
  assert.equal(espn.buildNextGamesUrl("eng.1", "20260820", "20260924"), null);
  assert.equal(espn.buildGameUrl("mlb", "401816587"),
    "https://www.espn.com/mlb/game/_/gameId/401816587");
  assert.equal(espn.buildGameUrl("nhl", "401816587"), null);
});

test("ESPN standings fixture normalizes grouped rows, ordering, and missing fields", () => {
  assert.equal(espn.buildStandingsUrl("nfl"),
    "https://site.api.espn.com/apis/site/v2/sports/football/nfl/standings");
  assert.equal(espn.buildStandingsUrl("nhl"), null);
  const result = espn.parseStandingsResponse(readStandingsFixture(), "nfl");
  assert.equal(result.errors.length, 0);
  assert.deepEqual(result.groups.map((group) => group.label), ["AFC East", "AFC North"]);
  assert.deepEqual(result.rows.map((row) => row.team.id), ["nfl:17", "nfl:2", "nfl:8", "nfl:33"]);
  assert.equal(result.rows[0].rank, 1);
  assert.equal(result.rows[0].wins, 13);
  assert.equal(result.rows[0].team.logoUrl, null);
  assert.equal(result.rows[3].rank, null);
  assert.equal(result.rows[3].team.name, null);
  assert.equal(result.rows[3].team.abbreviation, "CLE");
  assert.equal(JSON.stringify(result).includes("stats"), false);
  assert.equal(JSON.stringify(result).includes('"logos"'), false);
});

test("standings model preserves null fields, deterministic rank ordering, and safe empties", () => {
  const normalized = standingsModel.normalizeGroups([{
    id: "division-a",
    label: "Division A",
    entries: [
      {rank: 2, team: {id: "2", name: "Beta"}, wins: 3},
      {rank: 1, team: {id: "1", name: "Alpha"}, losses: 1},
      {team: {id: "3", abbreviation: "GAM"}}
    ]
  }], "test-league");
  assert.deepEqual(normalized.rows.map((row) => row.team.id), [
    "test-league:1", "test-league:2", "test-league:3"
  ]);
  assert.equal(normalized.rows[0].wins, null);
  assert.equal(normalized.rows[0].losses, 1);
  assert.equal(normalized.rows[2].rank, null);
  assert.deepEqual(standingsModel.normalizeGroups([], "test-league"), {
    leagueId: "test-league", groups: [], rows: [], errors: []
  });
});

test("standings provider rejects malformed input while keeping valid sibling groups", () => {
  const malformed = espn.parseStandingsResponse({standings: [{id: "broken"}]}, "nfl");
  assert.equal(malformed.rows.length, 0);
  assert.equal(malformed.errors[0].code, "invalid-standings-group");
  const mixed = espn.parseStandingsResponse({standings: [
    {id: "bad", entries: [{team: null}]},
    {id: "good", displayName: "Good", entries: [
      {rank: 1, team: {id: "99", displayName: "Valid", abbreviation: "VAL"}, stats: []}
    ]}
  ]}, "nfl");
  assert.equal(mixed.rows.length, 1);
  assert.equal(mixed.rows[0].team.id, "nfl:99");
  assert.ok(mixed.errors.length >= 1);
  assert.deepEqual(espn.parseStandingsResponse({standings: []}, "nfl"), {
    leagueId: "nfl", groups: [], rows: [], errors: []
  });
  assert.equal(espn.parseStandingsResponse({}, "nfl").errors[0].code,
    "invalid-standings-response");
});

test("standings rows keep existing favorite routing and expose bounded actions", () => {
  const result = espn.parseStandingsResponse(readStandingsFixture(), "nfl");
  const rows = standingsRows.flatten(result, ["nfl:17"]);
  assert.deepEqual(rows.map((row) => row.kind), [
    "standings-section", "standings", "standings", "standings-section", "standings", "standings"
  ]);
  assert.equal(rows[1].favorite, true);
  assert.deepEqual(rows[1].action,
    {type: "toggle-favorite-team", label: "Remove favorite", enabled: true});
  assert.deepEqual(rows[2].action,
    {type: "toggle-favorite-team", label: "Add favorite", enabled: true});
  const source = readSource("components/StandingsRow.qml");
  assert.equal(source.includes("root.settings.toggleFavoriteTeam(root.standing.team.id)"), true);
  const nhlRows = standingsRows.flatten(nhl.parseStandingsResponse(readNhlStandingsFixture()), ["nhl:12"]);
  assert.equal(nhlRows[1].favorite, true);
  assert.deepEqual(nhlRows[1].action,
    {type: "toggle-favorite-team", label: "Remove favorite", enabled: true});
  const fetch = readSource("services/StandingsFetch.qml");
  assert.equal(fetch.includes('import "../providers/NhlProvider.js" as NhlProvider'), true);
  assert.equal(fetch.includes('import "../model/StandingsModel.js" as StandingsModel'), true);
  assert.equal(fetch.includes('? NhlProvider.parseStandingsResponse(payload)'), true);
  assert.equal(fetch.includes("return StandingsModel.normalizeGroups(groups, targetLeague, parsed.errors)"), true);
  assert.equal(fetch.includes('? NhlProvider.buildStandingsUrl()'), true);
});

test("generic game details normalize ESPN games into ordered provider-neutral fields", () => {
  const result = espn.parseGameDetailResponse(readGameDetailFixture(), "nfl");
  assert.deepEqual(result.details.map((detail) => detail.id), [
    "nfl:detail-final", "nfl:detail-scheduled", "nfl:detail-missing"
  ]);
  assert.deepEqual(result.errors, [{
    provider: "espn",
    league: "nfl",
    endpoint: "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard",
    index: 2,
    code: "invalid-event"
  }]);

  const final = result.details[0];
  assert.equal(final.league, "nfl");
  assert.equal(final.providerGameId, "detail-final");
  assert.deepEqual(final.participants.map((participant) => participant.side), ["away", "home"]);
  assert.equal(final.participants[0].team.id, "nfl:8");
  assert.equal(final.participants[1].team.abbreviation, "CLE");
  assert.deepEqual(final.participants.map((participant) => participant.score), [14, 17]);
  assert.deepEqual(final.status, {
    state: "final", detail: "Final", period: 4, periodLabel: null, clock: "0:00"
  });
  assert.deepEqual(final.timing, {
    startTime: "2026-08-14T19:00:00.000Z", endTime: null, lastUpdated: null
  });
  assert.equal(final.venue, "Final Field");
  assert.deepEqual(final.source, {
    provider: "espn", label: "ESPN",
    url: "https://www.espn.com/nfl/game/_/gameId/detail-final"
  });
  assert.equal(final.isValid, true);
  assert.deepEqual(final.errors, []);
  assert.equal(JSON.stringify(final).includes("competitions"), false);
  assert.equal(JSON.stringify(final).includes("STATUS_FINAL"), false);
});

test("generic game details preserve explicit nulls for omitted normalized fields", () => {
  const detail = espn.parseGameDetailResponse(readGameDetailFixture(), "nfl").details
    .find((value) => value.providerGameId === "detail-missing");
  assert.equal(detail.participants[0].team.name, null);
  assert.equal(detail.participants[0].team.shortName, null);
  assert.equal(detail.participants[0].score, null);
  assert.equal(detail.participants[0].team.abbreviation, "IND");
  assert.equal(detail.participants[1].team.abbreviation, "JAX");
  assert.equal(detail.status.detail, null);
  assert.equal(detail.status.period, null);
  assert.equal(detail.status.periodLabel, null);
  assert.equal(detail.status.clock, null);
  assert.equal(detail.timing.startTime, null);
  assert.equal(detail.timing.endTime, null);
  assert.equal(detail.timing.lastUpdated, null);
  assert.equal(detail.venue, null);
  assert.equal(detail.source.provider, "espn");
  assert.equal(detail.source.label, "ESPN");
  assert.equal(detail.source.url, "https://www.espn.com/nfl/game/_/gameId/detail-missing");
});

test("generic game-detail model bounds malformed input without raw payload fields", () => {
  const invalid = gameDetails.normalizeDetail(games.createDefaultGame(), {
    provider: "espn", label: "ESPN"
  });
  assert.equal(invalid.isValid, false);
  assert.deepEqual(invalid.participants, [
    {side: "away", team: null, score: null},
    {side: "home", team: null, score: null}
  ]);
  assert.deepEqual(invalid.errors, [{code: "invalid-game"}]);

  const validGame = espn.parseScoreboardResponse(readEspnFixture("nfl-final"), "nfl").games[0];
  assert.deepEqual(gameDetails.normalizeDetails("not-an-array", {}).errors,
    [{index: null, code: "invalid-games"}]);
  const overLimit = gameDetails.normalizeDetails(
    Array.from({length: gameDetails.MAX_DETAILS + 1}, () => validGame), {});
  assert.deepEqual(overLimit, {
    details: [], errors: [{index: null, code: "too-many-games"}]
  });
  assert.equal(JSON.stringify(invalid).includes("raw"), false);
});

test("optional game outcomes project bounded final scores without provider fields", () => {
  const result = espn.parseGameDetailResponse(readEspnFixture("game-detail-outcome"), "nfl");
  assert.deepEqual(result.errors, []);

  const details = Object.fromEntries(result.details.map((detail) => [detail.providerGameId, detail]));
  assert.deepEqual(details["outcome-home"].outcome, {winner: "home", margin: 3});
  assert.equal(details["outcome-missing"].outcome, null);
  assert.equal(details["outcome-malformed"].outcome, null);
  assert.equal(details["outcome-bounded"].outcome, null);
  assert.equal(gameDetails.MAX_OUTCOME_SCORE, 9999);
  assert.equal(JSON.stringify(details["outcome-home"].outcome).includes("providerGameId"), false);
});

test("optional game lines project bounded per-side period scores without provider fields", () => {
  const result = espn.parseGameDetailResponse(readEspnFixture("game-detail-lines"), "nfl");
  assert.deepEqual(result.errors, []);

  const details = Object.fromEntries(result.details.map((detail) => [detail.providerGameId, detail]));
  assert.deepEqual(details["lines-final"].lines, {
    away: [
      {period: 1, value: 0}, {period: 2, value: 7},
      {period: 3, value: 7}, {period: 4, value: 7}
    ],
    home: [
      {period: 1, value: 7}, {period: 2, value: 3},
      {period: 3, value: 7}, {period: 4, value: 7}
    ]
  });
  assert.deepEqual(details["lines-out-of-order"].lines, {
    away: [{period: 1, value: 0}, {period: 2, value: 7}],
    home: [{period: 1, value: 0}, {period: 2, value: 10}]
  });
  assert.equal(details["lines-missing"].lines, null);

  const rejected = ["lines-malformed-entry", "lines-side-mismatch",
    "lines-over-bound", "lines-duplicate-period"];
  rejected.forEach((id) => assert.equal(details[id].lines, null, id));

  assert.equal(gameDetails.MAX_LINE_PERIODS, 12);
  assert.equal(gameDetails.MAX_LINE_PERIOD_NUMBER, 99);
  assert.equal(
    gameDetails.normalizeLineSide(
      Array.from({length: gameDetails.MAX_LINE_PERIODS + 1},
        (_, index) => ({value: 0, period: index + 1}))),
    null);
  assert.equal(JSON.stringify(details["lines-final"].lines).includes("displayValue"), false);
});

test("loaded game rows route to local detail while keeping the safe source action", () => {
  const fixture = readGameDetailRouteFixture();
  const game = espn.parseScoreboardResponse(readEspnFixture("nfl-final"), "nfl").games[0];
  const row = resultRows.flatten({
    kind: "league", leagueId: "nfl", displayName: "NFL", pinnedGames: [game], otherGames: [],
    loading: false, stale: false, errorCode: "", availability: "ready"
  }, "nfl").find((value) => value.kind === "game");
  assert.deepEqual(row.action, Object.assign({}, fixture.rowAction, {enabled: true}));
  assert.equal(resultRows.flatten({
    kind: "league", leagueId: "nfl", displayName: "NFL",
    pinnedGames: [Object.assign({}, game, {isValid: false})], otherGames: [],
    loading: false, stale: false, errorCode: "", availability: "ready"
  }, "nfl").find((value) => value.kind === "game").action.enabled, false);

  const panel = readSource("Panel.qml");
  const gameRow = readSource("components/GameRow.qml");
  const detail = readSource("components/GameDetailView.qml");
  const source = readSource("components/SourceLinkButton.qml");
  assert.match(panel, /function openGameDetail\(game\)/);
  assert.match(panel, /onPrimaryActionRequested: root\.openGameDetail\(gameValue\)/);
  assert.match(gameRow, /if \(root\.game && root\.game\.isValid === true\) root\.primaryActionRequested\(\)/);
  assert.match(detail, /GameDetailModel\.normalizeDetail\(root\.game, root\.sourceMetadata\)/);
  assert.match(detail, /SourceLinkButton \{/);
  assert.match(source, /Quickshell\.execDetached\(\["omarchy-launch-browser", root\.sourceUrl\]\)/);
});

test("game detail presentation keeps sparse fields as neutral placeholders", () => {
  const fixture = readGameDetailRouteFixture();
  const detail = readSource("components/GameDetailView.qml");
  fixture.sparsePlaceholders.forEach((placeholder) => assert.equal(detail.includes(placeholder), true));
  assert.match(detail, /function valueOrDash\(value\)/);
  assert.match(detail, /root\.scoreLabel\(root\.detail\.participants\[0\]\)/);
  assert.match(detail, /root\.scoreLabel\(root\.detail\.participants\[1\]\)/);
  assert.match(detail, /root\.detail\.status/);
  assert.match(detail, /root\.detail\.timing\.startTime/);
  assert.match(detail, /root\.detail\.venue/);
});

test("game detail renders optional outcome and bounded lines with null placeholders", () => {
  const detail = readSource("components/GameDetailView.qml");
  const gameDetail = readSource("model/GameDetailModel.js");
  const panel = readSource("Panel.qml");

  assert.equal(panel.includes("property bool detailOpen"), true);
  assert.match(detail, /function outcomeLabel\(\)/);
  assert.match(detail, /root\.valueOrDash\(root\.outcomeLabel\(\)\)/);
  assert.match(detail, /readonly property var linesData: root\.detail\.lines/);
  assert.match(detail, /visible: !root\.linesData/);
  assert.match(detail, /text: "—"/);
  assert.match(detail, /root\.linePeriods\(\)/);
  assert.match(detail, /root\.lineValues\(linesSideRow\.modelData\)/);
  assert.match(gameDetail, /MAX_LINE_PERIODS = 12/);

  const final = espn.parseGameDetailResponse(readEspnFixture("game-detail-lines"), "nfl")
    .details.find((value) => value.providerGameId === "lines-final");
  assert.equal(final.outcome.winner, "home");
  assert.equal(final.outcome.margin, 3);
  assert.equal(final.lines.away.length, 4);
  assert.equal(final.lines.home.length, 4);

  const sparse = espn.parseGameDetailResponse(readEspnFixture("game-detail-lines"), "nfl")
    .details.find((value) => value.providerGameId === "lines-missing");
  assert.equal(sparse.lines, null);
});

test("game detail back and Escape close only the local detail route first", () => {
  const fixture = readGameDetailRouteFixture();
  const panel = readSource("Panel.qml");
  const detail = readSource("components/GameDetailView.qml");
  assert.equal(fixture.detailActions.back, "close-detail");
  assert.equal(fixture.detailActions.escapeWhileOpen, "close-detail");
  assert.equal(fixture.detailActions.escapeFromScores, "close-panel");
  assert.match(panel, /onCloseRequested: root\.detailOpen \? root\.closeDetail\(\)/);
  assert.match(panel, /function closeDetail\(\)/);
  assert.match(panel, /root\.detailOpen = false/);
  assert.match(panel, /onBackRequested: root\.closeDetail\(\)/);
  assert.match(detail, /onClicked: root\.backRequested\(\)/);
  assert.match(detail, /function activateCursor\(\)/);
});

test("NHL next-game lookup uses the schedule endpoint and keeps normalized games", () => {
  assert.equal(nhl.buildNextGamesUrl("2026-10-01"),
    "https://api-web.nhle.com/v1/schedule/2026-10-01");
  assert.equal(nhl.buildNextGamesUrl("20261001"), null);
  const result = nhl.parseScheduleResponse({gameWeek: [], nextStartDate: "2026-10-08"});
  assert.deepEqual(result, {games: [], errors: [], nextDateKey: "2026-10-08"});
});

test("NHL lookahead requires progress and caches a bounded safe outcome", () => {
  const selected = "2026-08-19";
  const requested = "2026-08-20";
  const parsed = (name) => nhl.parseScheduleResponse(readLookaheadFixture(name));

  assert.deepEqual(lookahead.decideNextDate(selected, requested,
    parsed("repeated").nextDateKey, 1), {kind: "finish", reason: "non-progressing-date"});
  assert.deepEqual(lookahead.decideNextDate(selected, requested,
    parsed("earlier").nextDateKey, 1), {kind: "finish", reason: "non-progressing-date"});
  assert.deepEqual(lookahead.decideNextDate(selected, requested,
    parsed("malformed").nextDateKey, 1), {kind: "finish", reason: "invalid-date"});
  assert.deepEqual(lookahead.decideNextDate(selected, requested,
    parsed("malformed-response").nextDateKey, 1), {kind: "finish", reason: "invalid-date"});
  assert.deepEqual(lookahead.decideNextDate(selected, requested,
    parsed("valid-later").nextDateKey, 1), {
    kind: "request", dateKey: "2026-08-21", hopCount: 2
  });
  const next = nextEvent.findNext(parsed("valid-later").games, selected);
  assert.equal(next.dateKey, "2026-08-21");
  assert.equal(next.game.providerGameId, "2026020099");
  assert.deepEqual(lookahead.decideNextDate(selected, requested,
    parsed("over-limit").nextDateKey, lookahead.MAX_HOPS), {
    kind: "finish", reason: "hop-limit"
  });
});

test("date model provides a stable local carousel and provider query keys", () => {
  assert.equal(dateModel.isDateKey("2026-08-19"), true);
  assert.equal(dateModel.isDateKey("2026-02-30"), false);
  assert.equal(dateModel.addDays("2026-08-19", -1), "2026-08-18");
  assert.equal(dateModel.addDays("2026-08-19", 1), "2026-08-20");
  assert.equal(dateModel.providerDateKey("2026-08-19"), "20260819");
  assert.equal(dateModel.displayLabel("2026-08-19", "2026-08-19"), "Today");
  assert.equal(dateModel.displayLabel("2026-08-18", "2026-08-19"), "Yesterday");
  assert.equal(dateModel.displayLabel("2026-08-20", "2026-08-19"), "Tomorrow");
  assert.equal(dateModel.displayLabel("2026-08-15", "2026-08-19"), "4 days ago");
  assert.equal(dateModel.displayLabel("2026-08-25", "2026-08-19"), "6 days from now");
  assert.equal(dateModel.shortDateLabel("2026-08-22"), "Sat, Aug 22");
  assert.equal(dateModel.calendarDistance("2026-08-22", "2026-08-19"), 3);
  assert.deepEqual(dateModel.carouselDates("2026-08-19", 2).map((day) => day.key), [
    "2026-08-17", "2026-08-18", "2026-08-19", "2026-08-20", "2026-08-21"
  ]);
  assert.equal(dateModel.dateKeyFromTimestamp("2026-08-19T23:00:00.000Z").length, 10);
});

test("next-event model chooses the first future active date and ignores canceled games", () => {
  const makeGame = (id, startTime, status = "scheduled") => ({
    id, startTime, status, isValid: true
  });
  const result = nextEvent.findNext([
    makeGame("same-day", "2026-08-19T08:00:00.000Z"),
    makeGame("canceled", "2026-08-20T08:00:00.000Z", "canceled"),
    makeGame("later", "2026-08-22T12:00:00.000Z"),
    makeGame("first", "2026-08-21T12:00:00.000Z")
  ], "2026-08-19");
  assert.equal(result.dateKey, "2026-08-21");
  assert.equal(result.game.id, "first");
  assert.equal(nextEvent.findNext([], "2026-08-19"), null);
});

test("scoreboard composition only exposes games for the selected date", () => {
  const makeGame = (id, startTime) => ({
    id, providerGameId: id, league: "nhl", startTime, isValid: true,
    status: "scheduled", awayTeam: {id: "nhl:1", abbreviation: "A"},
    homeTeam: {id: "nhl:2", abbreviation: "H"}
  });
  const states = [{
    leagueId: "nhl", displayName: "NHL", hasData: true,
    games: [
      makeGame("yesterday", "2026-08-18T18:00:00.000Z"),
      makeGame("today", "2026-08-19T18:00:00.000Z"),
      makeGame("tomorrow", "2026-08-20T18:00:00.000Z")
    ]
  }];
  assert.deepEqual(scoreboard.compose(states, ["nhl"], [], null, "2026-08-19")
    .games.map((game) => game.id), ["today"]);
  assert.deepEqual(scoreboard.compose(states, ["nhl"], [], null, "2026-08-20")
    .games.map((game) => game.id), ["tomorrow"]);
});

function assertEspnNormalizedGame(game, league) {
  assert.equal(game.isValid, true);
  assert.equal(game.league, league);
  assert.deepEqual(Object.keys(game).sort(), [
    "awayScore", "awayTeam", "clock", "endTime", "homeScore", "homeTeam",
    "id", "isValid", "lastUpdated", "league", "link", "period", "periodLabel",
    "providerGameId", "startTime", "status", "statusDetail", "venue"
  ].sort());
  assert.equal(JSON.stringify(game).includes("competitions"), false);
  assert.equal(JSON.stringify(game).includes("STATUS_"), false);
}

test("ESPN provider maps scheduled events and nested team fields", () => {
  const result = espn.parseScoreboardResponse(readEspnFixture("scheduled"), "nfl");
  assert.equal(result.errors.length, 0);
  assert.equal(result.games.length, 1);
  const [game] = result.games;
  assertEspnNormalizedGame(game, "nfl");
  assert.equal(game.status, "scheduled");
  assert.equal(game.providerGameId, "401873272");
  assert.equal(game.startTime, "2026-08-13T23:00:00.000Z");
  assert.equal(game.awayTeam.id, "nfl:8");
  assert.equal(game.homeTeam.abbreviation, "CIN");
  assert.equal(game.clock, null);
  assert.equal(game.link, "https://www.espn.com/nfl/game/_/gameId/401873272");
});

test("NFL scheduled fixture preserves identity and null score state", () => {
  const game = espn.parseScoreboardResponse(readEspnFixture("nfl-scheduled"), "nfl").games[0];
  assertEspnNormalizedGame(game, "nfl");
  assert.equal(game.providerGameId, "401772901");
  assert.equal(game.startTime, "2026-09-13T17:00:00.000Z");
  assert.equal(game.status, "scheduled");
  assert.equal(game.statusDetail, "Sun, Sep 13 at 1:00 PM EDT");
  assert.equal(game.period, null);
  assert.equal(game.clock, null);
  assert.equal(game.awayTeam.id, "nfl:2");
  assert.equal(game.homeTeam.id, "nfl:17");
  assert.equal(game.awayScore, null);
  assert.equal(game.homeScore, null);
});

test("NFL live fixture maps football period, clock, and score", () => {
  const game = espn.parseScoreboardResponse(readEspnFixture("nfl-live"), "nfl").games[0];
  assertEspnNormalizedGame(game, "nfl");
  assert.equal(game.providerGameId, "401772902");
  assert.equal(game.status, "live");
  assert.equal(game.statusDetail, "3rd");
  assert.equal(game.period, 3);
  assert.equal(game.periodLabel, "3rd");
  assert.equal(game.clock, "6:42");
  assert.equal(game.awayScore, 14);
  assert.equal(game.homeScore, 17);
  assert.equal(game.awayTeam.id, "nfl:33");
  assert.equal(game.homeTeam.id, "nfl:12");
});

test("NCAA Football fixtures normalize all required states and provider extras", () => {
  const scheduled = espn.parseScoreboardResponse(
    readEspnFixture("ncaaf-scheduled"), "college-football").games[0];
  assertEspnNormalizedGame(scheduled, "college-football");
  assert.equal(scheduled.id, "college-football:401856766");
  assert.equal(scheduled.status, "scheduled");
  assert.equal(scheduled.awayTeam.id, "college-football:153");
  assert.equal(scheduled.homeTeam.id, "college-football:2628");
  assert.equal(scheduled.awayScore, null);
  assert.equal(scheduled.homeScore, null);
  assert.equal(scheduled.venue, "Aviva Stadium");
  assert.equal(JSON.stringify(scheduled).includes("curatedRank"), false);
  assert.equal(JSON.stringify(scheduled).includes("neutralSite"), false);

  const live = espn.parseScoreboardResponse(readEspnFixture("ncaaf-live"), "college-football").games[0];
  assert.equal(live.status, "live");
  assert.equal(live.period, 3);
  assert.equal(live.periodLabel, "3rd");
  assert.equal(live.clock, "6:42");
  assert.equal(live.awayScore, 14);
  assert.equal(live.homeScore, 17);

  const intermission = espn.parseScoreboardResponse(
    readEspnFixture("ncaaf-intermission"), "college-football").games[0];
  assert.equal(intermission.status, "intermission");
  assert.equal(intermission.period, 2);
  assert.equal(intermission.periodLabel, "Halftime");

  const final = espn.parseScoreboardResponse(readEspnFixture("ncaaf-final"), "college-football").games[0];
  assert.equal(final.status, "final");
  assert.equal(final.period, 4);
  assert.equal(final.awayScore, 27);
  assert.equal(final.homeScore, 9);

  assert.deepEqual(espn.parseScoreboardResponse(readEspnFixture("ncaaf-empty"), "college-football"), {
    games: [], errors: []
  });
  assert.equal(espn.parseScoreboardResponse(
    readEspnFixture("ncaaf-malformed"), "college-football").games.length, 0);
  const mixed = espn.parseScoreboardResponse(readEspnFixture("ncaaf-mixed"), "college-football");
  assert.equal(mixed.games.length, 1);
  assert.deepEqual(mixed.errors, [{
    provider: "espn",
    league: "college-football",
    endpoint: "https://site.api.espn.com/apis/site/v2/sports/football/college-football/scoreboard",
    index: 1,
    code: "invalid-event"
  }]);
});

test("Premier League fixtures normalize soccer states, draws, and bounded extras", () => {
  const scheduled = espn.parseScoreboardResponse(
    readEspnFixture("epl-scheduled"), "eng.1").games[0];
  assertEspnNormalizedGame(scheduled, "eng.1");
  assert.equal(scheduled.id, "eng.1:401879301");
  assert.equal(scheduled.status, "scheduled");
  assert.equal(scheduled.awayTeam.id, "eng.1:388");
  assert.equal(scheduled.homeTeam.id, "eng.1:359");
  assert.equal(scheduled.awayScore, null);
  assert.equal(scheduled.homeScore, null);
  assert.equal(scheduled.venue, "Emirates Stadium");

  const live = espn.parseScoreboardResponse(readEspnFixture("epl-live"), "eng.1").games[0];
  assert.equal(live.status, "live");
  assert.equal(live.period, 2);
  assert.equal(live.periodLabel, "78'");
  assert.equal(live.clock, "78'");
  assert.equal(live.awayScore, 0);
  assert.equal(live.homeScore, 2);

  const intermission = espn.parseScoreboardResponse(
    readEspnFixture("epl-intermission"), "eng.1").games[0];
  assert.equal(intermission.status, "intermission");
  assert.equal(intermission.period, 1);
  assert.equal(intermission.periodLabel, "Halftime");

  const final = espn.parseScoreboardResponse(readEspnFixture("epl-final"), "eng.1").games[0];
  assert.equal(final.status, "final");
  assert.equal(final.awayScore, 1);
  assert.equal(final.homeScore, 1);
  assert.equal(final.statusDetail, "FT");

  assert.equal(espn.parseScoreboardResponse(
    readEspnFixture("epl-postponed"), "eng.1").games[0].status, "postponed");
  assert.equal(espn.parseScoreboardResponse(
    readEspnFixture("epl-canceled"), "eng.1").games[0].status, "canceled");
  assert.deepEqual(espn.parseScoreboardResponse(readEspnFixture("epl-empty"), "eng.1"), {
    games: [], errors: []
  });
  assert.equal(espn.parseScoreboardResponse(
    readEspnFixture("epl-malformed"), "eng.1").games.length, 0);

  const mixed = espn.parseScoreboardResponse(readEspnFixture("epl-mixed"), "eng.1");
  assert.deepEqual(mixed.games.map((game) => game.status), ["final", "postponed", "canceled"]);
  assert.deepEqual(mixed.errors, [{
    provider: "espn",
    league: "eng.1",
    endpoint: "https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/scoreboard",
    index: 3,
    code: "invalid-event"
  }]);
  assert.equal(JSON.stringify(mixed).includes("STATUS_"), false);
});

test("MLS fixtures normalize soccer states, draws, and isolated edge responses", () => {
  const scheduled = espn.parseScoreboardResponse(
    readEspnFixture("mls-scheduled"), "usa.1").games[0];
  assertEspnNormalizedGame(scheduled, "usa.1");
  assert.equal(scheduled.id, "usa.1:761725");
  assert.equal(scheduled.status, "scheduled");
  assert.equal(scheduled.awayTeam.id, "usa.1:189");
  assert.equal(scheduled.homeTeam.id, "usa.1:193");
  assert.equal(scheduled.venue, "Audi Field");
  assert.equal(scheduled.awayScore, null);
  assert.equal(scheduled.homeScore, null);

  const live = espn.parseScoreboardResponse(readEspnFixture("mls-live"), "usa.1").games[0];
  assert.equal(live.status, "live");
  assert.equal(live.period, 2);
  assert.equal(live.periodLabel, "72'");
  assert.equal(live.clock, "72'");
  assert.equal(live.awayScore, 1);
  assert.equal(live.homeScore, 2);

  const intermission = espn.parseScoreboardResponse(
    readEspnFixture("mls-intermission"), "usa.1").games[0];
  assert.equal(intermission.status, "intermission");
  assert.equal(intermission.period, 1);
  assert.equal(intermission.periodLabel, "Halftime");

  const final = espn.parseScoreboardResponse(readEspnFixture("mls-final"), "usa.1").games[0];
  assert.equal(final.status, "final");
  assert.equal(final.awayScore, 2);
  assert.equal(final.homeScore, 2);
  assert.equal(final.statusDetail, "FT");

  assert.equal(espn.parseScoreboardResponse(
    readEspnFixture("mls-postponed"), "usa.1").games[0].status, "postponed");
  assert.equal(espn.parseScoreboardResponse(
    readEspnFixture("mls-canceled"), "usa.1").games[0].status, "canceled");
  assert.deepEqual(espn.parseScoreboardResponse(readEspnFixture("mls-empty"), "usa.1"), {
    games: [], errors: []
  });
  assert.equal(espn.parseScoreboardResponse(
    readEspnFixture("mls-malformed"), "usa.1").games.length, 0);

  const mixed = espn.parseScoreboardResponse(readEspnFixture("mls-mixed"), "usa.1");
  assert.deepEqual(mixed.games.map((game) => game.status), ["final", "postponed", "canceled"]);
  assert.deepEqual(mixed.errors, [{
    provider: "espn",
    league: "usa.1",
    endpoint: "https://site.api.espn.com/apis/site/v2/sports/soccer/usa.1/scoreboard",
    index: 3,
    code: "invalid-event"
  }]);
  assert.equal(JSON.stringify(mixed).includes("STATUS_"), false);
});

test("NCAA Men's Basketball fixtures normalize halves, final, empty, and malformed states", () => {
  const scheduled = espn.parseScoreboardResponse(
    readEspnFixture("ncaab-scheduled"), "mens-college-basketball").games[0];
  assertEspnNormalizedGame(scheduled, "mens-college-basketball");
  assert.equal(scheduled.id, "mens-college-basketball:401912207");
  assert.equal(scheduled.status, "scheduled");
  assert.equal(scheduled.awayTeam.id, "mens-college-basketball:44");
  assert.equal(scheduled.homeTeam.id, "mens-college-basketball:2132");
  assert.equal(scheduled.awayScore, null);
  assert.equal(scheduled.homeScore, null);
  assert.equal(scheduled.venue, "Fifth Third Arena");

  const live = espn.parseScoreboardResponse(
    readEspnFixture("ncaab-live"), "mens-college-basketball").games[0];
  assert.equal(live.status, "live");
  assert.equal(live.period, 1);
  assert.equal(live.periodLabel, "1st Half");
  assert.equal(live.clock, "12:34");
  assert.equal(live.awayScore, 31);
  assert.equal(live.homeScore, 38);

  const halftime = espn.parseScoreboardResponse(
    readEspnFixture("ncaab-intermission"), "mens-college-basketball").games[0];
  assert.equal(halftime.status, "intermission");
  assert.equal(halftime.period, 1);
  assert.equal(halftime.periodLabel, "Halftime");

  const final = espn.parseScoreboardResponse(
    readEspnFixture("ncaab-final"), "mens-college-basketball").games[0];
  assert.equal(final.status, "final");
  assert.equal(final.period, 2);
  assert.equal(final.awayScore, 78);
  assert.equal(final.homeScore, 82);
  assert.equal(final.statusDetail, "Final");

  assert.deepEqual(espn.parseScoreboardResponse(readEspnFixture("ncaab-empty"),
    "mens-college-basketball"), {games: [], errors: []});
  assert.equal(espn.parseScoreboardResponse(readEspnFixture("ncaab-malformed"),
    "mens-college-basketball").games.length, 0);
  const mixed = espn.parseScoreboardResponse(readEspnFixture("ncaab-mixed"),
    "mens-college-basketball");
  assert.equal(mixed.games.length, 1);
  assert.deepEqual(mixed.errors, [{
    provider: "espn",
    league: "mens-college-basketball",
    endpoint: "https://site.api.espn.com/apis/site/v2/sports/basketball/mens-college-basketball/scoreboard",
    index: 1,
    code: "invalid-event"
  }]);
  assert.equal(JSON.stringify(mixed).includes("STATUS_"), false);
  assert.equal(JSON.stringify(live).includes("competitions"), false);
});

test("NFL halftime fixture maps to canonical intermission", () => {
  const game = espn.parseScoreboardResponse(readEspnFixture("nfl-halftime"), "nfl").games[0];
  assertEspnNormalizedGame(game, "nfl");
  assert.equal(game.providerGameId, "401772903");
  assert.equal(game.status, "intermission");
  assert.equal(game.statusDetail, "Halftime");
  assert.equal(game.period, 2);
  assert.equal(game.periodLabel, "Halftime");
  assert.equal(game.clock, "0:00");
  assert.equal(game.awayScore, 13);
  assert.equal(game.homeScore, 10);
});

test("NFL final fixture maps completed score and preserves bounded link/venue", () => {
  const game = espn.parseScoreboardResponse(readEspnFixture("nfl-final"), "nfl").games[0];
  assertEspnNormalizedGame(game, "nfl");
  assert.equal(game.providerGameId, "401772904");
  assert.equal(game.status, "final");
  assert.equal(game.statusDetail, "Final");
  assert.equal(game.period, 4);
  assert.equal(game.clock, "0:00");
  assert.equal(game.awayScore, 21);
  assert.equal(game.homeScore, 24);
  assert.equal(game.venue, "Lumen Field");
  assert.equal(game.link, "https://www.espn.com/nfl/game/_/gameId/401772904");
});

test("NFL malformed sibling stays isolated with bounded provider context", () => {
  const result = espn.parseScoreboardResponse(readEspnFixture("nfl-mixed"), "nfl");
  assert.equal(result.games.length, 1);
  assert.equal(result.games[0].providerGameId, "401772905");
  assert.equal(result.games[0].league, "nfl");
  assert.deepEqual(result.errors, [{
    provider: "espn",
    league: "nfl",
    endpoint: "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard",
    index: 1,
    code: "invalid-event"
  }]);
  assert.equal(JSON.stringify(result).includes("Incomplete Away"), false);
  assert.equal(JSON.stringify(result).includes("competitions"), false);
});

test("MLB scheduled fixture preserves identity, start time, and null score state", () => {
  const game = espn.parseScoreboardResponse(readEspnFixture("mlb-scheduled"), "mlb").games[0];
  assertEspnNormalizedGame(game, "mlb");
  assert.equal(game.providerGameId, "401810001");
  assert.equal(game.startTime, "2026-08-17T23:10:00.000Z");
  assert.equal(game.status, "scheduled");
  assert.equal(game.statusDetail, "Mon, Aug 17 at 7:10 PM EDT");
  assert.equal(game.period, null);
  assert.equal(game.periodLabel, null);
  assert.equal(game.clock, null);
  assert.equal(game.awayTeam.id, "mlb:10");
  assert.equal(game.homeTeam.id, "mlb:2");
  assert.equal(game.awayScore, null);
  assert.equal(game.homeScore, null);
  assert.equal(game.venue, "Fenway Park");
  assert.equal(game.homeTeam.primaryColor, "#bd3039");
  assert.equal(game.link, "https://www.espn.com/mlb/game/_/gameId/401810001");
});

test("MLB live fixture maps bottom-inning detail, period, clock, and score", () => {
  const game = espn.parseScoreboardResponse(readEspnFixture("mlb-live"), "mlb").games[0];
  assertEspnNormalizedGame(game, "mlb");
  assert.equal(game.providerGameId, "401810002");
  assert.equal(game.startTime, "2026-08-16T20:10:00.000Z");
  assert.equal(game.status, "live");
  assert.equal(game.statusDetail, "Bottom 7th");
  assert.equal(game.period, 7);
  assert.equal(game.periodLabel, "Bottom 7th");
  assert.equal(game.clock, "0:00");
  assert.equal(game.awayTeam.id, "mlb:25");
  assert.equal(game.homeTeam.id, "mlb:19");
  assert.equal(game.awayScore, 5);
  assert.equal(game.homeScore, 4);
  assert.equal(game.venue, "Dodger Stadium");
  assert.equal(game.link, "https://www.espn.com/mlb/game/_/gameId/401810002");
});

test("MLB final fixture maps completed score and bounded venue/link", () => {
  const game = espn.parseScoreboardResponse(readEspnFixture("mlb-final"), "mlb").games[0];
  assertEspnNormalizedGame(game, "mlb");
  assert.equal(game.providerGameId, "401810003");
  assert.equal(game.startTime, "2026-08-15T20:10:00.000Z");
  assert.equal(game.status, "final");
  assert.equal(game.statusDetail, "Final");
  assert.equal(game.period, 9);
  assert.equal(game.periodLabel, null);
  assert.equal(game.clock, "0:00");
  assert.equal(game.awayTeam.id, "mlb:13");
  assert.equal(game.homeTeam.id, "mlb:18");
  assert.equal(game.awayScore, 6);
  assert.equal(game.homeScore, 2);
  assert.equal(game.venue, "Daikin Park");
  assert.equal(game.link, "https://www.espn.com/mlb/game/_/gameId/401810003");
});

test("MLB malformed sibling stays isolated with bounded provider context", () => {
  const result = espn.parseScoreboardResponse(readEspnFixture("mlb-mixed"), "mlb");
  assert.equal(result.games.length, 1);
  assertEspnNormalizedGame(result.games[0], "mlb");
  assert.equal(result.games[0].providerGameId, "401810004");
  assert.equal(result.games[0].statusDetail, "Top 9th");
  assert.deepEqual(result.errors, [{
    provider: "espn",
    league: "mlb",
    endpoint: "https://site.api.espn.com/apis/site/v2/sports/baseball/mlb/scoreboard",
    index: 1,
    code: "invalid-event"
  }]);
  assert.equal(JSON.stringify(result).includes("Incomplete MLB Away"), false);
  assert.equal(JSON.stringify(result).includes("competitions"), false);
  assert.equal(JSON.stringify(result).includes("STATUS_"), false);
});

test("NBA scheduled fixture preserves identity, start time, and null score state", () => {
  const game = espn.parseScoreboardResponse(readEspnFixture("nba-scheduled"), "nba").games[0];
  assertEspnNormalizedGame(game, "nba");
  assert.equal(game.providerGameId, "401810101");
  assert.equal(game.startTime, "2026-10-22T23:00:00.000Z");
  assert.equal(game.status, "scheduled");
  assert.equal(game.statusDetail, "Thu, Oct 22 at 7:00 PM EDT");
  assert.equal(game.period, null);
  assert.equal(game.periodLabel, null);
  assert.equal(game.clock, null);
  assert.equal(game.awayTeam.id, "nba:13");
  assert.equal(game.homeTeam.id, "nba:2");
  assert.equal(game.awayScore, null);
  assert.equal(game.homeScore, null);
  assert.equal(game.venue, "TD Garden");
  assert.equal(game.link, "https://www.espn.com/nba/game/_/gameId/401810101");
});

test("NBA live fixture maps quarter, clock, detail, and score", () => {
  const game = espn.parseScoreboardResponse(readEspnFixture("nba-live"), "nba").games[0];
  assertEspnNormalizedGame(game, "nba");
  assert.equal(game.providerGameId, "401810102");
  assert.equal(game.startTime, "2026-10-23T23:00:00.000Z");
  assert.equal(game.status, "live");
  assert.equal(game.statusDetail, "3rd Quarter");
  assert.equal(game.period, 3);
  assert.equal(game.periodLabel, "3rd Quarter");
  assert.equal(game.clock, "4:37");
  assert.equal(game.awayTeam.id, "nba:25");
  assert.equal(game.homeTeam.id, "nba:7");
  assert.equal(game.awayScore, 91);
  assert.equal(game.homeScore, 88);
  assert.equal(game.venue, "Ball Arena");
  assert.equal(game.link, "https://www.espn.com/nba/game/_/gameId/401810102");
});

test("NBA halftime fixture maps to canonical intermission", () => {
  const game = espn.parseScoreboardResponse(readEspnFixture("nba-halftime"), "nba").games[0];
  assertEspnNormalizedGame(game, "nba");
  assert.equal(game.providerGameId, "401810103");
  assert.equal(game.status, "intermission");
  assert.equal(game.statusDetail, "Halftime");
  assert.equal(game.period, 2);
  assert.equal(game.periodLabel, "Halftime");
  assert.equal(game.clock, "0:00");
  assert.equal(game.awayTeam.id, "nba:28");
  assert.equal(game.homeTeam.id, "nba:20");
  assert.equal(game.awayScore, 49);
  assert.equal(game.homeScore, 54);
  assert.equal(game.venue, null);
  assert.equal(game.link, "https://www.espn.com/nba/game/_/gameId/401810103");
});

test("NBA final fixture maps completed score and bounded venue/link", () => {
  const game = espn.parseScoreboardResponse(readEspnFixture("nba-final"), "nba").games[0];
  assertEspnNormalizedGame(game, "nba");
  assert.equal(game.providerGameId, "401810104");
  assert.equal(game.startTime, "2026-10-21T23:00:00.000Z");
  assert.equal(game.status, "final");
  assert.equal(game.statusDetail, "Final");
  assert.equal(game.period, 4);
  assert.equal(game.periodLabel, null);
  assert.equal(game.clock, "0:00");
  assert.equal(game.awayTeam.id, "nba:9");
  assert.equal(game.homeTeam.id, "nba:4");
  assert.equal(game.awayScore, 118);
  assert.equal(game.homeScore, 112);
  assert.equal(game.venue, "United Center");
  assert.equal(game.link, "https://www.espn.com/nba/game/_/gameId/401810104");
});

test("NBA malformed sibling stays isolated with bounded provider context", () => {
  const result = espn.parseScoreboardResponse(readEspnFixture("nba-mixed"), "nba");
  assert.equal(result.games.length, 1);
  assertEspnNormalizedGame(result.games[0], "nba");
  assert.equal(result.games[0].providerGameId, "401810105");
  assert.equal(result.games[0].statusDetail, "4th Quarter");
  assert.deepEqual(result.errors, [{
    provider: "espn",
    league: "nba",
    endpoint: "https://site.api.espn.com/apis/site/v2/sports/basketball/nba/scoreboard",
    index: 1,
    code: "invalid-event"
  }]);
  assert.equal(JSON.stringify(result).includes("Incomplete NBA Away"), false);
  assert.equal(JSON.stringify(result).includes("competitions"), false);
  assert.equal(JSON.stringify(result).includes("STATUS_"), false);
});

test("ESPN provider maps live clock, period, inning detail, and NBA halftime", () => {
  const live = espn.parseScoreboardResponse(readEspnFixture("live"), "mlb").games[0];
  assertEspnNormalizedGame(live, "mlb");
  assert.equal(live.status, "live");
  assert.equal(live.period, 8);
  assert.equal(live.periodLabel, "Top 8th");
  assert.equal(live.clock, "0:00");
  assert.equal(live.awayScore, 3);

  const halftime = espn.parseScoreboardResponse(readEspnFixture("halftime"), "nba").games[0];
  assertEspnNormalizedGame(halftime, "nba");
  assert.equal(halftime.status, "intermission");
  assert.equal(halftime.period, 2);
  assert.equal(halftime.periodLabel, "Halftime");
  assert.equal(halftime.homeScore, 54);
});

test("ESPN provider maps final state and retains bounded venue data", () => {
  const game = espn.parseScoreboardResponse(readEspnFixture("final"), "nfl").games[0];
  assertEspnNormalizedGame(game, "nfl");
  assert.equal(game.status, "final");
  assert.equal(game.statusDetail, "Final");
  assert.equal(game.awayScore, 9);
  assert.equal(game.homeScore, 28);
});

test("ESPN provider tolerates missing optional fields", () => {
  const game = espn.parseScoreboardResponse(readEspnFixture("missing-optional"), "nba").games[0];
  assertEspnNormalizedGame(game, "nba");
  assert.equal(game.startTime, null);
  assert.equal(game.awayTeam.name, null);
  assert.equal(game.homeTeam.logoUrl, null);
  assert.equal(game.venue, null);
  assert.equal(game.period, null);
  assert.equal(game.clock, null);
  assert.equal(game.link, "https://www.espn.com/nba/game/_/gameId/missing-fields");
});

test("ESPN provider preserves unknown states without exposing provider fields", () => {
  const game = espn.parseScoreboardResponse(readEspnFixture("unknown"), "nfl").games[0];
  assertEspnNormalizedGame(game, "nfl");
  assert.equal(game.status, "unknown");
  assert.equal(game.period, 1);
  assert.equal(game.statusDetail, "Provider update");
});

test("ESPN provider isolates malformed sibling events with provider context", () => {
  const result = espn.parseScoreboardResponse(readEspnFixture("mixed"), "mlb");
  assert.equal(result.games.length, 1);
  assert.equal(result.games[0].providerGameId, "valid-sibling");
  assert.deepEqual(result.errors, [{
    provider: "espn",
    league: "mlb",
    endpoint: "https://site.api.espn.com/apis/site/v2/sports/baseball/mlb/scoreboard",
    index: 1,
    code: "invalid-event"
  }]);

  const invalid = espn.parseScoreboardResponse({events: "not-an-array"}, "nba");
  assert.deepEqual(invalid.errors, [{
    provider: "espn",
    league: "nba",
    endpoint: "https://site.api.espn.com/apis/site/v2/sports/basketball/nba/scoreboard",
    index: null,
    code: "invalid-scoreboard-response"
  }]);
});

test("provider response and event bounds reject oversized input before normalization", () => {
  const fixture = readResponseBoundsFixture();
  assert.equal(responsePolicy.MAX_RESPONSE_BYTES, 2 * 1024 * 1024);
  assert.equal(responsePolicy.MAX_EVENTS, fixture.events.overLimitCount - 1);
  assert.equal(responsePolicy.bodyWithinLimit(fixture.response.normalBody), true);
  assert.equal(responsePolicy.bodyWithinLimit(
    "x".repeat(responsePolicy.MAX_RESPONSE_CHARS + fixture.response.oversizedExtraChars)), false);
  assert.equal(responsePolicy.canAppend("x".repeat(responsePolicy.MAX_RESPONSE_CHARS - 1), "xx"), false);

  const espnPayload = readEspnFixture("nfl-scheduled");
  assert.equal(espnPayload.events.length, fixture.events.normalCount);
  assert.equal(espn.parseScoreboardResponse(espnPayload, "nfl").games.length, 1);
  const espnOverLimit = {events: Array.from({length: fixture.events.overLimitCount},
    () => espnPayload.events[0])};
  assert.deepEqual(espn.parseScoreboardResponse(espnOverLimit, "nfl"), {
    games: [],
    errors: [{
      provider: "espn",
      league: "nfl",
      endpoint: "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard",
      index: null,
      code: "too-many-events"
    }]
  });
  assert.deepEqual(espn.parseNextGamesResponse(espnOverLimit, "nfl").games, []);

  const nhlPayload = readRawFixture("scheduled");
  assert.equal(nhl.parseScoreResponse(nhlPayload).games.length, 1);
  const nhlOverLimit = {games: Array.from({length: fixture.events.overLimitCount},
    () => nhlPayload.games[0])};
  assert.deepEqual(nhl.parseScoreResponse(nhlOverLimit), {
    games: [], errors: [{index: null, code: "too-many-events"}]
  });
  const scheduleOverLimit = {gameWeek: [{games: nhlOverLimit.games}]};
  assert.deepEqual(nhl.parseScheduleResponse(scheduleOverLimit), {
    games: [], errors: [{index: null, code: "too-many-events"}], nextDateKey: ""
  });

  const healthyNhl = nhl.parseScoreResponse(nhlPayload).games[0];
  const healthyMlb = espn.parseScoreboardResponse(readEspnFixture("mlb-live"), "mlb").games[0];
  const failedNhl = freshness.applyFailure({
    games: [healthyNhl], hasData: true, lastSuccessAt: "2026-08-17T12:00:00.000Z"
  }, "invalid-data");
  const composed = scoreboard.compose([
    Object.assign({leagueId: "nhl", displayName: "NHL"}, failedNhl),
    {leagueId: "mlb", displayName: "MLB", games: [healthyMlb], hasData: true}
  ], ["nhl", "mlb"], []);
  assert.equal(composed.games.some((game) => game.league === "nhl"), true);
  assert.equal(composed.games.some((game) => game.league === "mlb"), true);
  assert.equal(composed.sections.find((section) => section.leagueId === "nhl").stale, true);
  assert.equal(composed.sections.find((section) => section.leagueId === "mlb").stale, false);
});

function assertNormalizedGame(game) {
  assert.equal(game.isValid, true);
  assert.deepEqual(Object.keys(game).sort(), [
    "awayScore", "awayTeam", "clock", "endTime", "homeScore", "homeTeam",
    "id", "isValid", "lastUpdated", "league", "link", "period", "periodLabel",
    "providerGameId", "startTime", "status", "statusDetail", "venue"
  ].sort());
  for (const team of [game.awayTeam, game.homeTeam]) {
    assert.ok(team);
    assert.deepEqual(Object.keys(team).sort(), [
      "abbreviation", "id", "league", "link", "logoUrl", "name", "primaryColor",
      "providerTeamId", "shortName"
    ].sort());
  }
  assert.equal(JSON.stringify(game).includes("gameState"), false);
  assert.equal(JSON.stringify(game).includes("gameScheduleState"), false);
}

test("NHL provider maps scheduled games and provider team identity", () => {
  const result = nhl.parseScoreResponse(readRawFixture("scheduled"));
  assert.equal(result.errors.length, 0);
  assert.equal(result.games.length, 1);
  const [game] = result.games;
  assertNormalizedGame(game);
  assert.equal(game.status, "scheduled");
  assert.equal(game.providerGameId, "2026020003");
  assert.equal(game.awayTeam.id, "nhl:3");
  assert.equal(game.homeTeam.abbreviation, "BOS");
  assert.equal(game.homeTeam.primaryColor, "#231f20");
  assert.equal(game.link, "https://www.nhl.com/gamecenter/nyr-vs-bos/2026/09/29/2026020003");
});

test("NHL provider maps live and intermission clock states", () => {
  const live = nhl.parseScoreResponse(readRawFixture("live")).games[0];
  assertNormalizedGame(live);
  assert.equal(live.status, "live");
  assert.equal(live.period, 2);
  assert.equal(live.periodLabel, "2nd");
  assert.equal(live.clock, "08:42");
  assert.equal(live.awayScore, 3);

  const intermission = nhl.parseScoreResponse(readRawFixture("intermission")).games[0];
  assertNormalizedGame(intermission);
  assert.equal(intermission.status, "intermission");
  assert.equal(intermission.periodLabel, "1st");
  assert.equal(intermission.clock, "00:00");
});

test("NHL provider maps final, postponed, and canceled schedule states", () => {
  const final = nhl.parseScoreResponse(readRawFixture("final")).games[0];
  assertNormalizedGame(final);
  assert.equal(final.status, "final");
  assert.equal(final.endTime, "2026-09-30T01:42:00.000Z");
  assert.equal(final.awayScore, 4);
  assert.equal(final.homeScore, 3);

  assert.equal(nhl.parseScoreResponse(readRawFixture("postponed")).games[0].status, "postponed");
  assert.equal(nhl.parseScoreResponse(readRawFixture("canceled")).games[0].status, "canceled");
});

test("NHL provider preserves unknown state and tolerates omitted optional fields", () => {
  const unknown = nhl.parseScoreResponse(readRawFixture("unknown")).games[0];
  assertNormalizedGame(unknown);
  assert.equal(unknown.status, "unknown");

  const missing = nhl.parseScoreResponse(readRawFixture("missing-optional")).games[0];
  assertNormalizedGame(missing);
  assert.equal(missing.status, "scheduled");
  assert.equal(missing.startTime, null);
  assert.equal(missing.venue, null);
  assert.equal(missing.awayTeam.name, null);
  assert.equal(missing.awayTeam.logoUrl, null);
  assert.equal(missing.period, null);
  assert.equal(missing.clock, null);
  assert.equal(missing.link, "https://www.nhl.com/gamecenter/2026020016");
});

test("NHL provider drops malformed events without erasing valid siblings", () => {
  const result = nhl.parseScoreResponse(readRawFixture("mixed"));
  assert.equal(result.games.length, 2);
  assert.equal(result.errors.length, 1);
  assert.deepEqual(result.errors[0], {index: 1, code: "invalid-game"});
  assert.deepEqual(result.games.map((game) => game.providerGameId), ["2026020017", "2026020018"]);
  result.games.forEach(assertNormalizedGame);

  const malformed = nhl.parseScoreResponse(readRawFixture("malformed"));
  assert.equal(malformed.games.length, 0);
  assert.equal(malformed.errors.length, 1);
  assert.equal(malformed.errors[0].code, "invalid-score-response");
});

test("settings defaults are versioned and safe", () => {
  assert.deepEqual(settingsModel.createDefaults(), {
    schemaVersion: 1,
    enabledLeagues: ["nhl"],
    favoriteTeamIds: [],
    notifications: {
      enabled: false,
      gameStart: false,
      scoreChange: false,
      gameFinal: false,
      pregameReminder: false,
      closeGame: false
    }
  });
  const result = settingsModel.parseSettingsText("");
  assert.equal(result.status, "missing");
  assert.equal(result.recovered, true);
  assert.equal(result.needsWrite, true);
  assert.deepEqual(result.settings, settingsModel.createDefaults());
});

test("settings permission repair uses owner-only state paths and safe admission", () => {
  const fixture = readSettingsPermissionFixture();
  const commands = settingsPermissionPolicy.commands(fixture.statePath);
  assert.deepEqual(settingsPermissionPolicy.paths(fixture.statePath), {
    statePath: fixture.statePath,
    stateDirectory: "/tmp/sportray-settings-test/state/omarchy/settings"
  });
  assert.deepEqual(commands.makeDirectory,
    ["/usr/bin/mkdir", "-p", "--", "/tmp/sportray-settings-test/state/omarchy/settings"]);
  assert.deepEqual(commands.hardenDirectory,
    ["/usr/bin/chmod", "700", "--", "/tmp/sportray-settings-test/state/omarchy/settings"]);
  assert.deepEqual(commands.hardenFile,
    ["/usr/bin/chmod", "--no-dereference", "600", "--", fixture.statePath]);
  assert.deepEqual(settingsPermissionPolicy.repairResult(
    fixture.newFile.parentExitCode,
    fixture.newFile.fileCheckExitCode,
    fixture.newFile.fileExitCode
  ), {parentReady: true, fileExists: false, fileReady: true, ready: true});
  assert.deepEqual(settingsPermissionPolicy.repairResult(
    fixture.existingOverlyPermissiveFile.parentExitCode,
    fixture.existingOverlyPermissiveFile.fileCheckExitCode,
    fixture.existingOverlyPermissiveFile.fileExitCode
  ), {parentReady: true, fileExists: true, fileReady: true, ready: true});
  assert.equal(settingsPermissionPolicy.DIRECTORY_MODE, fixture.parentDirectoryRepair.directoryMode);
  assert.equal(settingsPermissionPolicy.FILE_MODE, fixture.parentDirectoryRepair.fileMode);
  assert.equal(settingsPermissionPolicy.repairResult(
    fixture.permissionFailure.parentExitCode,
    fixture.permissionFailure.fileCheckExitCode,
    fixture.permissionFailure.fileExitCode
  ).ready, false);
  assert.equal(settingsPermissionPolicy.repairResult(0, 2, null).ready, false);
  assert.equal(settingsPermissionPolicy.writeResult(0), true);
  assert.equal(settingsPermissionPolicy.writeResult(1), false);
});

test("SettingsStore gates FileView writes on permission repair and hardens saved files", () => {
  const source = readSource("services/SettingsStore.qml");
  assert.equal(source.includes("SettingsPermissionPolicy.js"), true);
  assert.equal(source.includes("path: root.loadStarted ? root.statePath : \"\""), true);
  assert.equal(source.includes("if (!root.permissionsReady || permissionProcess.running) return false"), true);
  assert.equal(source.includes("permissionProcess.exec(commands.makeDirectory)"), true);
  assert.equal(source.includes("permissionProcess.exec(commands.hardenDirectory)"), true);
  assert.equal(source.includes("permissionProcess.exec(commands.hardenFile)"), true);
  assert.equal(source.includes("onSaved: root.repairWrittenFile()"), true);
  assert.equal(source.includes("property string preservedRawStateText: \"\""), true);
  assert.equal(source.includes("root.preservedRawStateText = result.preservedRawText || \"\""), true);
  assert.equal(source.includes("if (root.preservedRawStateText.length > 0) return false"), true);
  assert.equal(source.includes("console.warn(\"Sportray settings permission repair failed\""), true);
  assert.equal(source.includes("JSON.stringify(state"), true);
  assert.equal(source.includes("rawResponse"), false);
});

test("notification preferences toggle independently and round-trip", () => {
  const base = settingsModel.createDefaults();
  const keys = ["enabled", "gameStart", "scoreChange", "gameFinal", "pregameReminder", "closeGame"];
  let selected = base;

  keys.forEach((key) => {
    selected = settingsModel.toggleNotification(selected, key);
    assert.equal(selected.notifications[key], true);
  });
  assert.deepEqual(selected.notifications, {
    enabled: true,
    gameStart: true,
    scoreChange: true,
    gameFinal: true,
    pregameReminder: true,
    closeGame: true
  });

  keys.forEach((key) => {
    selected = settingsModel.toggleNotification(selected, key);
    assert.equal(selected.notifications[key], false);
  });
  assert.deepEqual(selected, base);
  assert.deepEqual(settingsModel.toggleNotification(base, "unknown"), base);
});

test("global notification off preserves event choices and blocks deliveries", () => {
  const keys = ["enabled", "gameStart", "scoreChange", "gameFinal", "pregameReminder", "closeGame"];
  let settings = settingsModel.createDefaults();
  keys.forEach((key) => { settings = settingsModel.toggleNotification(settings, key); });

  const globalOff = settingsModel.toggleNotification(settings, "enabled");
  assert.equal(globalOff.notifications.enabled, false);
  assert.deepEqual(globalOff.notifications, {
    enabled: false,
    gameStart: true,
    scoreChange: true,
    gameFinal: true,
    pregameReminder: true,
    closeGame: true
  });

  const fixture = readNotificationFixture();
  const favorite = games.normalizeGame(fixture.favoriteGame);
  assert.deepEqual(notificationModel.buildDeliveries(
    fixture.events.slice(0, 3), [favorite], globalOff
  ), []);

  assert.equal(readSource("components/SettingsView.qml").includes(
    'key: "pregameReminder"'), true);
  assert.equal(readSource("components/SettingsView.qml").includes(
    'key: "closeGame"'), true);
  assert.equal(readSource("services/NotificationService.qml").includes(
    "PregameReminderPolicy.eligibleEvents"), true);
  assert.equal(readSource("services/NotificationService.qml").includes(
    "CloseGamePolicy.eligibleEvents"), true);
});

test("notification preferences persist through the schema-1 state serializer", () => {
  const keys = ["enabled", "gameStart", "scoreChange", "gameFinal", "pregameReminder", "closeGame"];
  let settings = settingsModel.createDefaults();
  keys.forEach((key) => { settings = settingsModel.toggleNotification(settings, key); });

  const state = stateModel.createState(settings, transitionDedupe.createDefaults(),
    settingsModel, transitionDedupe, 1700000000000);
  const loaded = stateModel.parseStateText(JSON.stringify(state), 1700000001000,
    settingsModel, transitionDedupe);
  assert.deepEqual(loaded.settings.notifications, settings.notifications);
  assert.deepEqual(loaded.settings.enabledLeagues, ["nhl"]);
  assert.equal(loaded.status, "valid");
  assert.deepEqual(JSON.parse(JSON.stringify(state)).notifications, {
    enabled: true,
    gameStart: true,
    scoreChange: true,
    gameFinal: true,
    pregameReminder: true,
    closeGame: true
  });
});

test("valid schema 1 settings round-trip without provider or raw response fields", () => {
  const input = {
    schemaVersion: 1,
    enabledLeagues: ["nhl"],
    favoriteTeamIds: ["nhl:3", "nhl:10"],
    notifications: {
      enabled: true,
      gameStart: true,
      scoreChange: false,
      gameFinal: true,
      pregameReminder: false,
      closeGame: false
    }
  };
  const result = settingsModel.parseSettingsText(JSON.stringify(input));
  assert.equal(result.status, "valid");
  assert.equal(result.recovered, false);
  assert.equal(result.needsWrite, false);
  assert.deepEqual(result.settings, input);
  assert.equal(JSON.stringify(result.settings).includes("gameState"), false);
  assert.equal(JSON.stringify(result.settings).includes("games"), false);
});

test("schema 1 admits required leagues while keeping NHL as the default", () => {
  const input = {
    schemaVersion: 1,
    enabledLeagues: ["NHL", "nfl", "MLB", "nba", "college-football", "eng.1", "usa.1",
      "mens-college-basketball", "soccer", "nfl"],
    favoriteTeamIds: ["nfl:17", "mlb:2", "nba:2", "college-football:153", "eng.1:359",
      "usa.1:20232", "mens-college-basketball:44", "soccer:1"],
    notifications: settingsModel.createDefaults().notifications
  };
  const result = settingsModel.parseSettingsText(JSON.stringify(input));
  assert.deepEqual(result.settings.enabledLeagues,
    ["nhl", "nfl", "mlb", "nba", "college-football", "eng.1", "usa.1",
      "mens-college-basketball"]);
  assert.deepEqual(result.settings.favoriteTeamIds,
    ["nfl:17", "mlb:2", "nba:2", "college-football:153", "eng.1:359", "usa.1:20232",
      "mens-college-basketball:44"]);
  assert.deepEqual(settingsModel.toggleLeague(settingsModel.createDefaults(), "nfl").enabledLeagues,
    ["nhl", "nfl"]);
  assert.deepEqual(settingsModel.toggleLeague({
    schemaVersion: 1,
    enabledLeagues: ["nhl", "nfl"],
    favoriteTeamIds: [],
    notifications: settingsModel.createDefaults().notifications
  }, "NFL").enabledLeagues, ["nhl"]);
});

test("NCAA Football settings reject aliases and preserve canonical favorites", () => {
  const selected = settingsModel.toggleLeague(settingsModel.createDefaults(), "college-football");
  assert.deepEqual(selected.enabledLeagues, ["nhl", "college-football"]);
  assert.deepEqual(settingsModel.toggleLeague(selected, "ncaaf").enabledLeagues,
    ["nhl", "college-football"]);
  assert.deepEqual(settingsModel.toggleFavoriteTeam(selected, "college-football:153").favoriteTeamIds,
    ["college-football:153"]);
});

test("Premier League settings preserve the dotted canonical league ID", () => {
  const selected = settingsModel.toggleLeague(settingsModel.createDefaults(), "ENG.1");
  assert.deepEqual(selected.enabledLeagues, ["nhl", "eng.1"]);
  assert.deepEqual(settingsModel.toggleLeague(selected, "epl").enabledLeagues,
    ["nhl", "eng.1"]);
  assert.deepEqual(settingsModel.toggleFavoriteTeam(selected, "ENG.1:359").favoriteTeamIds,
    ["eng.1:359"]);
  assert.deepEqual(presentation.normalizeFavoriteIds(["ENG.1:359", "eng.1:359", "eng.1:bad id"]),
    ["eng.1:359"]);
});

test("MLS settings preserve the dotted canonical league ID", () => {
  const selected = settingsModel.toggleLeague(settingsModel.createDefaults(), "USA.1");
  assert.deepEqual(selected.enabledLeagues, ["nhl", "usa.1"]);
  assert.deepEqual(settingsModel.toggleLeague(selected, "mls").enabledLeagues,
    ["nhl", "usa.1"]);
  assert.deepEqual(settingsModel.toggleFavoriteTeam(selected, "USA.1:20232").favoriteTeamIds,
    ["usa.1:20232"]);
});

test("NCAA Men's Basketball settings reject aliases and preserve canonical favorites", () => {
  const selected = settingsModel.toggleLeague(settingsModel.createDefaults(),
    "mens-college-basketball");
  assert.deepEqual(selected.enabledLeagues, ["nhl", "mens-college-basketball"]);
  assert.deepEqual(settingsModel.toggleLeague(selected, "ncaab").enabledLeagues,
    ["nhl", "mens-college-basketball"]);
  assert.deepEqual(settingsModel.toggleFavoriteTeam(selected,
    "MENS-COLLEGE-BASKETBALL:44").favoriteTeamIds,
    ["mens-college-basketball:44"]);
  assert.deepEqual(presentation.normalizeFavoriteIds([
    "mens-college-basketball:44", "mens-college-basketball:44"
  ]), ["mens-college-basketball:44"]);
});

test("missing schema 1 fields recover independently to defaults", () => {
  const result = settingsModel.parseSettingsText(JSON.stringify({
    schemaVersion: 1,
    enabledLeagues: ["nhl"]
  }));
  assert.equal(result.status, "field-recovered");
  assert.deepEqual(result.missingFields, ["favoriteTeamIds", "notifications"]);
  assert.deepEqual(result.settings.favoriteTeamIds, []);
  assert.deepEqual(result.settings.notifications, settingsModel.createDefaults().notifications);
});

test("corrupt JSON and unsupported schema recover to defaults", () => {
  const corrupt = settingsModel.parseSettingsText("{not-json");
  assert.equal(corrupt.status, "invalid-json");
  assert.deepEqual(corrupt.settings, settingsModel.createDefaults());

  const future = settingsModel.parseSettingsText(JSON.stringify({schemaVersion: 2}));
  assert.equal(future.status, "unsupported-schema");
  assert.equal(future.recovered, true);
  assert.equal(future.needsWrite, false);
  assert.deepEqual(future.settings, settingsModel.createDefaults());
});

test("invalid types and bounded values never escape the schema", () => {
  const tooManyFavorites = Array.from({length: 40}, (_, index) => `nhl:${index}`);
  const result = settingsModel.parseSettingsText(JSON.stringify({
    schemaVersion: 1,
    enabledLeagues: "nhl",
    favoriteTeamIds: tooManyFavorites.concat(["not-canonical", "NHL:3"]),
    notifications: {
      enabled: "yes",
      gameStart: true,
      scoreChange: 1,
      gameFinal: false,
      pregameReminder: false,
      closeGame: false
    },
    rawResponse: {games: [{gameState: "LIVE"}]}
  }));
  assert.equal(result.status, "field-recovered");
  assert.ok(result.invalidFields.includes("enabledLeagues"));
  assert.ok(result.invalidFields.includes("notifications.enabled"));
  assert.ok(result.invalidFields.includes("notifications.scoreChange"));
  assert.deepEqual(result.settings.enabledLeagues, ["nhl"]);
  assert.equal(result.settings.favoriteTeamIds.length, settingsModel.MAX_FAVORITE_TEAM_IDS);
  assert.equal(result.settings.favoriteTeamIds.includes("not-canonical"), false);
  assert.equal(result.settings.favoriteTeamIds.includes("nhl:0"), true);
  assert.deepEqual(result.settings.notifications, {
    enabled: false,
    gameStart: true,
    scoreChange: false,
    gameFinal: false,
    pregameReminder: false,
    closeGame: false
  });
  assert.ok(result.unknownFields.includes("rawResponse"));
  assert.equal(JSON.stringify(result.settings).includes("gameState"), false);
});

test("picker favorite updates preserve the exact schema-1 store shape", () => {
  const base = settingsModel.createDefaults();
  const selected = settingsModel.toggleFavoriteTeam(base, "nhl:6");
  assert.deepEqual(selected, {
    schemaVersion: 1,
    enabledLeagues: ["nhl"],
    favoriteTeamIds: ["nhl:6"],
    notifications: {
      enabled: false,
      gameStart: false,
      scoreChange: false,
      gameFinal: false,
      pregameReminder: false,
      closeGame: false
    }
  });
  assert.deepEqual(settingsModel.toggleFavoriteTeam(selected, "nhl:6"), base);
  assert.deepEqual(settingsModel.toggleFavoriteTeam(base, "not-canonical"), base);
});

test("favorite presentation orders live, favorite, upcoming, final, and unknown games", () => {
  const fixture = readPresentationFixture();
  const normalized = normalizeFixtureGames(fixture);
  const ordered = presentation.orderGames(normalized, ["nhl:6", "nhl:24", "nhl:13"]);
  assert.deepEqual(ordered.map((game) => game.providerGameId), [
    "102", "101", "104", "103", "105", "106", "109", "107", "108"
  ]);
  assert.equal(presentation.isFavoriteGame(ordered[0], ["NHL:24"]), true);
  assert.equal(presentation.isFavoriteGame(ordered[8], ["nhl:6", "not-canonical", null]), false);
  assert.doesNotThrow(() => presentation.orderGames([null, undefined, {status: "unknown"}], ["bad"]));
});

test("favorite presentation accepts canonical favorites across required leagues", () => {
  const nflGame = espn.parseScoreboardResponse(readEspnFixture("nfl-live"), "nfl").games[0];
  assert.equal(presentation.isFavoriteGame(nflGame, ["nfl:12"]), true);
  assert.equal(presentation.isFavoriteGame(nflGame, ["nhl:12"]), false);
  assert.deepEqual(presentation.normalizeFavoriteIds(["NFL:12", "mlb:2", "soccer:1"]), ["nfl:12", "mlb:2", "soccer:1"]);
});

test("multi-league composition renders each healthy league through normalized games", () => {
  const states = [
    {leagueId: "nhl", displayName: "NHL", games: [nhl.parseScoreResponse(readRawFixture("scheduled")).games[0],], hasData: true},
    {leagueId: "nfl", displayName: "NFL", games: [espn.parseScoreboardResponse(readEspnFixture("nfl-live"), "nfl").games[0]], hasData: true},
    {leagueId: "mlb", displayName: "MLB", games: [espn.parseScoreboardResponse(readEspnFixture("mlb-live"), "mlb").games[0]], hasData: true},
    {leagueId: "nba", displayName: "NBA", games: [espn.parseScoreboardResponse(readEspnFixture("nba-halftime"), "nba").games[0]], hasData: true}
  ];
  const result = scoreboard.compose(states, ["nhl", "nfl", "mlb", "nba"], ["nfl:12"]);
  assert.deepEqual(result.sections.map((section) => section.leagueId), ["nhl", "nfl", "mlb", "nba"]);
  assert.equal(result.sections.length, 4);
  assert.equal(result.games[0].league, "nfl");
  assert.equal(result.games.every((game) => game.isValid === true), true);
});

test("empty leagues have no heading and disabled leagues stop composing without changing favorites", () => {
  const nhlGame = nhl.parseScoreResponse(readRawFixture("scheduled")).games[0];
  const result = scoreboard.compose([
    {leagueId: "nhl", displayName: "NHL", games: [nhlGame], hasData: true},
    {leagueId: "mlb", displayName: "MLB", games: [], hasData: true},
    {leagueId: "nba", displayName: "NBA", games: [], hasData: true}
  ], ["nhl", "mlb", "nba"], ["nba:2"]);
  assert.deepEqual(result.sections.map((section) => section.leagueId), ["nhl"]);
  assert.deepEqual(result.statuses, []);

  const disabled = scoreboard.compose([
    {leagueId: "nhl", displayName: "NHL", games: [nhlGame], hasData: true},
    {leagueId: "nfl", displayName: "NFL", games: [nhlGame], hasData: true}
  ], ["nhl"], ["nfl:12"]);
  assert.deepEqual(disabled.sections.map((section) => section.leagueId), ["nhl"]);
  assert.deepEqual(disabled.enabledLeagues, ["nhl"]);
});

test("HTTP and malformed league failures are isolated from healthy siblings", () => {
  const nhlGame = nhl.parseScoreResponse(readRawFixture("scheduled")).games[0];
  const mlbGame = espn.parseScoreboardResponse(readEspnFixture("mlb-live"), "mlb").games[0];
  const nbaGame = espn.parseScoreboardResponse(readEspnFixture("nba-live"), "nba").games[0];
  const malformed = espn.parseScoreboardResponse({events: [{id: "bad", competitions: []}]}, "nfl");
  assert.equal(malformed.games.length, 0);
  assert.equal(malformed.errors.length, 1);

  const result = scoreboard.compose([
    {leagueId: "nhl", displayName: "NHL", games: [nhlGame], hasData: true},
    {leagueId: "nfl", displayName: "NFL", games: [], hasData: false, errorCode: "unavailable"},
    {leagueId: "mlb", displayName: "MLB", games: [mlbGame], hasData: true},
    {leagueId: "nba", displayName: "NBA", games: [nbaGame], hasData: true, stale: true, errorCode: "partial-data", partialErrorCount: 1}
  ], ["nhl", "nfl", "mlb", "nba"], []);
  assert.deepEqual(result.sections.map((section) => section.leagueId), ["nhl", "mlb", "nba"]);
  assert.equal(result.sections.find((section) => section.leagueId === "nba").stale, true);
  assert.deepEqual(result.statuses.map((status) => status.leagueId), ["nfl"]);
  assert.equal(result.statuses[0].errorCode, "unavailable");
  assert.equal(result.games.some((game) => game.league === "nhl"), true);
  assert.equal(result.games.some((game) => game.league === "mlb"), true);
});

test("U1.1 builds Following and stable league destinations from composed state", () => {
  const nhlGames = normalizeFixtureGames(readPresentationFixture());
  const nflGame = espn.parseScoreboardResponse(readEspnFixture("nfl-live"), "nfl").games[0];
  const mlbGame = espn.parseScoreboardResponse(readEspnFixture("mlb-live"), "mlb").games[0];
  const states = [
    {leagueId: "nhl", displayName: "NHL", games: nhlGames.concat(nhlGames[0]), hasData: true},
    {leagueId: "nfl", displayName: "NFL", games: [nflGame], hasData: true},
    {leagueId: "mlb", displayName: "MLB", games: [], hasData: true},
    {leagueId: "nba", displayName: "NBA", games: [], hasData: false, loading: true},
    {leagueId: "nhl-disabled", displayName: "Disabled", games: [nhlGames[0]], hasData: true}
  ];
  const favorites = ["nhl:6", "nhl:10", "nhl:13", "nhl:68", "nfl:12"];
  const composed = scoreboard.compose(states, ["nhl", "nfl", "mlb", "nba"], favorites);
  const model = panelPresentation.build(composed, favorites);

  assert.deepEqual(model.enabledLeagues, ["nhl", "nfl", "mlb", "nba"]);
  assert.deepEqual(model.leagues.map((view) => view.leagueId), ["nhl", "nfl", "mlb", "nba"]);
  assert.equal(model.leagues.some((view) => view.leagueId === "nhl-disabled"), false);
  assert.equal(model.following.games.filter((game) => game.id === nhlGames[0].id).length, 1);
  assert.equal(model.following.games.every((game) => game.presentation.isFavorite), true);
  assert.equal(model.leagues[0].pinnedGames.length, 4);
  assert.equal(model.leagues[0].otherGames.length, 5);
  assert.equal(model.leagues[0].games.length, 9);
  assert.equal(model.leagues[0].pinnedGames.every((game) => game.presentation.isPinned), true);
  assert.equal(model.leagues[0].otherGames.some((game) => game.presentation.isPinned), false);
  assert.equal(model.leagues[2].availability, "empty");
  assert.equal(model.leagues[3].availability, "loading");
});

test("U1.1 state matrix distinguishes zero favorites and no favorite games", () => {
  const gamesForOneLeague = normalizeFixtureGames(readPresentationFixture());
  const composed = scoreboard.compose([
    {leagueId: "nhl", displayName: "NHL", games: gamesForOneLeague, hasData: true},
    {leagueId: "nfl", displayName: "NFL", games: [], hasData: true, stale: true,
      errorCode: "partial-data", partialErrorCount: 1},
    {leagueId: "mlb", displayName: "MLB", games: [], hasData: false, errorCode: "unavailable"},
    {leagueId: "nba", displayName: "NBA", games: [], hasData: false, loading: true}
  ], ["nhl", "nfl", "mlb", "nba"], []);
  const noFavorites = panelPresentation.build(composed, []);
  assert.equal(noFavorites.following.hasFavorites, false);
  assert.equal(noFavorites.following.emptyState, "no-favorites");
  assert.equal(noFavorites.leagues[1].availability, "stale");
  assert.equal(noFavorites.leagues[2].availability, "error");
  assert.equal(noFavorites.leagues[3].availability, "loading");

  const noGames = panelPresentation.build(composed, ["nhl:999"]);
  assert.equal(noGames.following.hasFavorites, true);
  assert.equal(noGames.following.emptyState, "no-favorite-games");
  assert.equal(noGames.following.games.length, 0);
});

test("U2.1 flattens provider-neutral section, game, status, and empty rows", () => {
  const game = Object.assign({}, normalizeFixtureGames(readPresentationFixture())[0], {
    link: "https://www.espn.com/nhl/game/_/gameId/123"
  });
  const ready = {
    kind: "league", leagueId: "nhl", displayName: "NHL", availability: "ready",
    loading: false, errorCode: "", stale: false, pinnedGames: [game], otherGames: [],
    hasFavoriteGames: true
  };
  const rows = resultRows.flatten(ready, "nhl");
  assert.deepEqual(rows.map((row) => row.kind), ["section-header", "game"]);
  assert.equal(rows[1].rowId, "game:nhl:" + game.providerGameId);
  assert.equal(rows[1].game, game);

  const status = Object.assign({}, ready, {
    pinnedGames: [], otherGames: [], availability: "error", errorCode: "unavailable",
    errorSummary: "Scores are temporarily unavailable"
  });
  const statusRows = resultRows.flatten(status, "nhl");
  assert.deepEqual(statusRows.map((row) => row.kind), ["status"]);
  assert.equal(statusRows[0].status.errorSummary, "Scores are temporarily unavailable");

  const empty = Object.assign({}, ready, {pinnedGames: [], availability: "empty"});
  assert.deepEqual(resultRows.flatten(empty, "nhl").map((row) => row.kind), ["empty"]);
  const next = Object.assign({}, empty, {
    nextGameStatus: "ready",
    nextGameDateKey: "2026-08-22",
    nextGame: game
  });
  assert.deepEqual(resultRows.flatten(next, "nhl").map((row) => row.kind), ["empty", "next-game"]);
  assert.equal(resultRows.flatten(next, "nhl")[0].text, "Nothing scheduled on this day");
  assert.equal(resultRows.flatten(next, "nhl")[1].dateKey, "2026-08-22");
  const searching = Object.assign({}, empty, {nextGameStatus: "loading"});
  assert.deepEqual(resultRows.flatten(searching, "nhl").map((row) => row.kind), ["empty", "empty"]);
  const following = resultRows.flatten({kind: "following", hasFavorites: false, hasGames: false}, "following");
  assert.equal(following.length, 1);
  assert.equal(following[0].title, "Follow teams to pin their games here");
  assert.equal(following[0].supportingText, "8 leagues available.");
  assert.deepEqual(following[0].action,
    {type: "choose-teams", label: "Choose favorite teams", enabled: true});
});

test("U3.1 gives actionable rows typed primary actions and safe fallbacks", () => {
  const game = Object.assign({}, normalizeFixtureGames(readPresentationFixture())[0], {
    link: "https://www.espn.com/nhl/game/_/gameId/123"
  });
  const view = {
    kind: "league", leagueId: "nhl", displayName: "NHL", availability: "ready",
    loading: false, errorCode: "", stale: false, pinnedGames: [game], otherGames: []
  };
  const rows = resultRows.flatten(view, "nhl");
  assert.equal(rows[1].action.type, "open-detail");
  assert.equal(rows[1].action.enabled, true);
  assert.equal(resultRows.flatten(Object.assign({}, view, {
    pinnedGames: [Object.assign({}, game, {isValid: false})]
  }), "nhl")[1].action.enabled, false);
  assert.equal(resultRows.flatten(Object.assign({}, view, {
    pinnedGames: [], availability: "error", errorCode: "offline"
  }), "nhl")[0].action.type, "retry");
  const next = resultRows.flatten(Object.assign({}, view, {
    pinnedGames: [], availability: "empty", nextGameStatus: "ready",
    nextGame: game, nextGameDateKey: "2026-08-22"
  }), "nhl");
  assert.equal(next[1].action.type, "view-day");

  const panel = readSource("Panel.qml");
  const gameRow = readSource("components/GameRow.qml");
  const status = readSource("components/LeagueStatus.qml");
  const nextCard = readSource("components/NextGameCard.qml");
  const picker = readSource("components/TeamPicker.qml");
  assert.equal(panel.includes("function activateRow(index)"), true);
  assert.equal(panel.includes("else root.activateRow(root.selectedRowIndex)"), true);
  assert.equal(panel.includes("root.activateRow(index)"), true);
  assert.equal(panel.includes("root.toggleStandings()"), true);
  assert.equal(panel.includes('text === "s" || text === "S"'), true);
  assert.equal(panel.includes("readonly property var standingsRows: StandingsRows.flatten"), true);
  assert.equal(panel.includes("StandingsRow {"), true);
  assert.equal(gameRow.includes(
    "Accessible.role: root.game && root.game.isValid === true ? Accessible.Button : Accessible.StaticText"), true);
  assert.equal(gameRow.includes("External game page unavailable."), true);
  assert.equal(status.includes("Accessible.role: root.status.loading ? Accessible.StaticText : Accessible.Button"), true);
  assert.equal(nextCard.includes("Accessible.name: \"Next game: \""), true);
  assert.equal(picker.includes("Accessible.role: Accessible.CheckBox"), true);
  assert.equal(picker.includes("Accessible.checked: root.isFavorite(modelData)"), true);
});

test("U3.5 maps assistive press/toggle actions to one existing route", () => {
  const fixture = readAccessibilityActionsFixture();
  const sourceByPath = {};
  fixture.pressActions.concat(fixture.toggleActions, fixture.disabledGuards).forEach((entry) => {
    sourceByPath[entry.source] = readSource(entry.source);
  });

  fixture.pressActions.forEach((entry) => {
    const source = sourceByPath[entry.source];
    assert.equal(source.split(entry.signal).length - 1, 1,
      entry.control + " declares one " + entry.signal);
    assert.equal(source.split(entry.route).length - 1, 1,
      entry.control + " routes to one existing callback");
  });

  fixture.toggleActions.forEach((entry) => {
    const source = sourceByPath[entry.source];
    assert.equal(source.split(entry.signal).length - 1, 1,
      entry.control + " declares one " + entry.signal);
    assert.equal(source.split(entry.route).length - 1, 1,
      entry.control + " routes to one existing callback");
    assert.equal(source.includes(entry.checked), true,
      entry.control + " exposes current checked state");
    assert.equal(source.includes(entry.checkable), true,
      entry.control + " exposes checkbox semantics");
  });

  fixture.disabledGuards.forEach((entry) => {
    assert.equal(sourceByPath[entry.source].includes(entry.guard), true,
      entry.control + " remains non-activatable when unavailable");
  });

  const sourceButton = sourceByPath["components/SourceLinkButton.qml"];
  assert.equal(sourceButton.includes('onClicked: root.openSource()'), true,
    "source assistive press reaches the existing source callback through the shared button");
  const panel = readSource("Panel.qml");
  assert.equal(panel.includes("onClicked: root.activateRow(index)"), true,
    "empty-state utility action keeps the existing row callback");
  assert.equal(panel.includes("root.setSelectedRow(index)"), true,
    "whole-row pointer/keyboard selection remains unchanged");
});

test("nested pointer actions keep their tap out of the enclosing result row", () => {
  function activate(sourcePressed, retryPressed, nextGamePressed, emptyActionPressed) {
    const childPressed = pointerInteraction.childActionPressed(
      sourcePressed, retryPressed, nextGamePressed, emptyActionPressed);
    const calls = {child: childPressed ? 1 : 0, row: 0};
    if (pointerInteraction.allowsRowActivation(childPressed)) calls.row += 1;
    return calls;
  }

  assert.deepEqual(activate(true, false, false, false), {child: 1, row: 0}, "provider source");
  assert.deepEqual(activate(false, true, false, false), {child: 1, row: 0}, "retry");
  assert.deepEqual(activate(false, false, true, false), {child: 1, row: 0}, "next-game action");
  assert.deepEqual(activate(false, false, false, true), {child: 1, row: 0}, "empty-row action");
  assert.deepEqual(activate(false, false, false, false), {child: 0, row: 1}, "whole row");

  const panel = readSource("Panel.qml");
  const action = readSource("components/SemanticActionButton.qml");
  const source = readSource("components/SourceLinkButton.qml");
  const gameRow = readSource("components/GameRow.qml");
  const status = readSource("components/LeagueStatus.qml");
  const nextCard = readSource("components/NextGameCard.qml");
  assert.match(panel, /enabled: PointerInteractionPolicy\.allowsRowActivation\(parent\.nestedActionPressed\)/);
  assert.match(panel, /if \(!PointerInteractionPolicy\.allowsRowActivation\(parent\.nestedActionPressed\)\) return/);
  assert.match(action, /readonly property bool pointerPressed: actionMouse\.pressed/);
  assert.match(source, /readonly property bool pointerPressed: action\.pointerPressed/);
  assert.match(gameRow, /readonly property bool childActionPressed: sourceLink\.pointerPressed/);
  assert.match(status, /readonly property bool pointerPressed: retryMouse\.pressed/);
  assert.match(nextCard, /sourceLink\.pointerPressed \|\| jumpButton\.pointerPressed/);
});

test("active editors own catcher shortcuts while Escape and navigation stay routed", () => {
  ["h", "j", "k", "l", "x"].forEach((text) => {
    assert.equal(keyboardRouting.targetForKey("", text, true, false), "editor", text);
  });
  assert.equal(keyboardRouting.targetForKey("Space", " ", true, false), "editor", "space");
  assert.equal(keyboardRouting.targetForKey("Escape", "", true, false), "editor", "editor escape");
  assert.equal(keyboardRouting.targetForKey("Escape", "", false, false), "catcher-close", "panel escape");
  assert.equal(keyboardRouting.targetForKey("j", "j", false, false), "catcher-navigation", "panel navigation");
  assert.equal(keyboardRouting.targetForKey("", "a", false, false), "catcher-text", "panel text key");
  assert.equal(keyboardRouting.targetForKey("j", "j", false, true), "editor", "popup-owned key");

  const panel = readSource("Panel.qml");
  const hub = readSource("components/SettingsHub.qml");
  const picker = readSource("components/TeamPicker.qml");
  assert.match(panel, /blocked: KeyboardRoutingPolicy\.catcherBlocked\(/);
  assert.match(panel, /settingsHub\.inputActive, sportsPicker\.popupOpen/);
  assert.match(hub, /onEscapeRequested: root\.escapeRequested\(\)/);
  assert.match(picker, /if \(event\.key === Qt\.Key_Escape\)/);
});

test("calendar filter is reachable through the panel text-key routing policy", () => {
  const fixture = JSON.parse(fs.readFileSync(
    path.join(root, "fixtures/keyboard-routing/filter-shortcut.json"), "utf8"));
  fixture.cases.forEach((testCase) => {
    assert.equal(
      keyboardRouting.calendarFilterAction(testCase.text, testCase.calendarOpen,
        testCase.settingsOpen, testCase.detailOpen),
      testCase.expected,
      `${testCase.text} with calendar=${testCase.calendarOpen} settings=${testCase.settingsOpen} detail=${testCase.detailOpen}`);
  });

  const panel = readSource("Panel.qml");
  assert.match(panel,
    /KeyboardRoutingPolicy\.calendarFilterAction\(text, root\.calendarOpen,\s*\n\s*root\.settingsOpen, root\.detailOpen\)/);
  assert.match(panel,
    /=== "toggle-calendar-filter"\)\s*\n\s*root\.toggleCalendarFilter\(\)/);
  // The route lives inside the catcher's text-key path only; no second
  // interaction surface or pointer-only behavior was added.
  const textKeyIndex = panel.indexOf("onTextKey: function(text) {");
  const filterRouteIndex = panel.indexOf('KeyboardRoutingPolicy.calendarFilterAction(text');
  const extraKeysIndex = panel.indexOf("Keys.onPressed: function(event) {");
  assert.ok(textKeyIndex !== -1 && filterRouteIndex > textKeyIndex
    && filterRouteIndex < extraKeysIndex, "filter route stays in onTextKey");
});

test("deferred callbacks run for live owners and reject destroyed owners", () => {
  const owner = lifecycle.createOwnerState();
  const generation = lifecycle.captureGeneration(owner);
  let runs = 0;
  if (lifecycle.canRun(owner, generation)) runs += 1;
  assert.equal(runs, 1, "live callback executes");
  assert.equal(lifecycle.invalidate(owner), true, "owner invalidates once");
  assert.equal(lifecycle.canRun(owner, generation), false, "destroyed callback is rejected");
  assert.equal(lifecycle.invalidate(owner), false, "owner stays invalidated");

  const nextGeneration = lifecycle.captureGeneration(owner);
  assert.equal(lifecycle.canRun(owner, nextGeneration), false, "new generation cannot revive owner");
  const panel = readSource("Panel.qml");
  const widget = readSource("BarWidget.qml");
  const hub = readSource("components/SettingsHub.qml");
  const picker = readSource("components/TeamPicker.qml");
  assert.match(panel, /function deferPanelCallback\(callback\)/);
  assert.match(panel, /function deferResultListCallback\(callback\)/);
  assert.match(panel, /LifecyclePolicy\.invalidate\(root\.callbackOwner\)/);
  assert.match(panel, /Component\.onDestruction: LifecyclePolicy\.invalidate\(callbackOwner\)/);
  assert.match(panel, /panelHeightSettleTimer\.stop\(\)/);
  assert.match(widget, /function deferCallback\(callback\)/);
  assert.match(widget, /Component\.onDestruction: LifecyclePolicy\.invalidate\(root\.callbackOwner\)/);
  assert.match(hub, /root\.deferCallback\(root\.focusContent\)/);
  assert.match(picker, /root\.deferCallback\(root\.ensureCursorVisible\)/);
});

test("U2.1 result row identity stays canonical and Panel uses one virtualized result list", () => {
  assert.equal(resultRows.gameIdentity({id: "NHL:123"}), "nhl:123");
  assert.equal(resultRows.gameIdentity({providerGameId: "GAME-9"}), "game-9");
  assert.equal(resultRows.gameIdentity({}), "");
  const panel = readSource("Panel.qml");
  assert.equal(panel.includes("readonly property var resultRows: ResultRows.flatten"), true);
  assert.equal(panel.includes("ListView {\n                id: resultList"), true);
  assert.equal(panel.includes("Repeater {\n            model: root.activeDestination"), false);
  assert.equal(panel.includes("ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }"), true);
  assert.equal(panel.includes("positionViewAtIndex(index, ListView.Contain)"), true);
  assert.equal(panel.includes("Qt.Key_PageDown"), true);
  assert.equal(panel.includes("Qt.Key_PageUp"), true);
  assert.equal(panel.includes("Qt.Key_Home"), true);
  assert.equal(panel.includes("Qt.Key_End"), true);
  assert.equal(readSource("services/SportrayService.qml").includes("lookaheadLeagueId"), true);
  const nextCard = readSource("components/NextGameCard.qml");
  assert.equal(nextCard.includes('text: "NEXT GAME"'), true);
  assert.equal(nextCard.includes('text: "View day"'), true);
  assert.equal(nextCard.includes('import "SemanticActionButton.qml"'), false);
  assert.equal(nextCard.includes('import "SemanticIcon.qml"'), false);
  assert.equal(panel.includes("onJumpRequested: root.selectDate(modelData.dateKey)"), true);
});

test("U2.1 uses a compact vertical sport chooser instead of a clipped tab strip", () => {
  const panel = readSource("Panel.qml");
  assert.equal(panel.includes("readonly property var sportOptions: buildSportOptions()"), true);
  assert.equal(panel.includes("Dropdown {"), true);
  assert.equal(panel.includes("id: sportsPicker"), true);
  assert.equal(panel.includes("options: root.sportOptions"), true);
  assert.equal(panel.includes("settingsHub.inputActive, sportsPicker.popupOpen"), true);
  assert.equal(panel.includes("orientation: ListView.Horizontal"), false);
  assert.equal(panel.includes("text: tabList.contentWidth > tabList.width"), false);
});

test("U2.1 section headers avoid a QQuickText implicit-height binding loop", () => {
  const panel = readSource("Panel.qml");
  assert.equal(panel.includes("height: visible ? font.pixelSize : 0"), true);
  assert.equal(panel.includes("height: visible ? implicitHeight : 0\n                      visible: modelData && modelData.kind === \"section-header\""), false);
});

test("overlay opens directly below the configured bar region with no gap", () => {
  const panel = readSource("Panel.qml");
  assert.equal(panel.includes("centerOnBar: root.barRegion === \"center\""), true);
  assert.equal(panel.includes("margin: 0"), true);
  assert.equal(panel.includes("gap: 0"), true);
});

test("horizontal overlay anchors to its button and clamps at the screen edge", () => {
  const widget = readSource("BarWidget.qml");
  const panel = readSource("Panel.qml");
  assert.equal(widget.includes('property string barRegion: ""'), true);
  assert.equal(widget.includes("readonly property string barPosition"), true);
  assert.equal(widget.includes("function resolveBarRegion()"), true);
  assert.equal(widget.includes("slot.activeItem === root"), true);
  assert.equal(widget.includes("slot.moduleName === root.moduleName"), true);
  assert.equal(widget.includes("function onModuleSlotsChanged()"), true);
  assert.equal(widget.includes(
    "readonly property var panelAnchorItem: root.fullMode ? fullButton : compactButton"), true);
  assert.equal(widget.includes("panelEdgeAnchor"), false);
  assert.equal(widget.includes("root.mapFromItem(root.bar, edgeX, edgeY)"), false);
  assert.equal(widget.includes("target.barRegion = root.barRegion"), true);
  assert.equal(widget.includes("target.anchorItem = root.panelAnchorItem"), true);
  assert.equal(panel.includes("centerOnBar: root.barRegion === \"center\""), true);
});

test("U2.2 groups every normalized game state into a provider-neutral slate", () => {
  const fixture = readPresentationFixture();
  const games = normalizeFixtureGames(fixture).concat([
    {id: "nhl:postponed", status: "postponed", awayTeam: {abbreviation: "A"}, homeTeam: {abbreviation: "B"}},
    {id: "nhl:canceled", status: "canceled", awayTeam: {abbreviation: "C"}, homeTeam: {abbreviation: "D"}},
    {id: "nhl:malformed", status: "malformed", awayTeam: null, homeTeam: null},
    {id: "nhl:unknown", status: "unknown", awayTeam: null, homeTeam: null}
  ]);
  const view = {
    kind: "league", leagueId: "nhl", displayName: "NHL", loading: false,
    errorCode: "", stale: true, availability: "stale",
    pinnedGames: [games[0], games[0], games[2]],
    otherGames: games.slice(1)
  };
  const rows = resultRows.flatten(view, "nhl");
  assert.deepEqual(rows.filter((row) => row.kind === "section-header").map((row) => row.label),
    ["Live", "Upcoming", "Final", "Unavailable"]);
  assert.equal(rows.filter((row) => row.kind === "game").length, games.length);
  assert.equal(rows.filter((row) => row.kind === "game")[0].game.id, games[0].id);
  assert.equal(rows.filter((row) => row.kind === "game").every((row) => row.stale), true);
  assert.equal(resultRows.slateBucket({status: "intermission"}), "live");
  assert.equal(resultRows.slateBucket({status: "postponed"}), "upcoming");
  assert.equal(resultRows.slateBucket({status: "canceled"}), "upcoming");
  assert.equal(resultRows.slateBucket({status: "final"}), "final");
  assert.equal(resultRows.slateBucket({status: "unknown"}), "unavailable");

  const denseMlb = {
    id: "mlb:dense-1", league: "mlb", status: "live", awayScore: 123, homeScore: 98,
    awayTeam: {name: "A very long baseball away team name"},
    homeTeam: {name: "A very long baseball home team name"},
    presentation: {isFavorite: true}
  };
  const denseNcaa = {
    id: "mens-college-basketball:dense-2", league: "mens-college-basketball",
    status: "scheduled", awayScore: 0, homeScore: 0,
    awayTeam: {name: "A very long college basketball away team name"},
    homeTeam: {name: "A very long college basketball home team name"},
    presentation: {isFavorite: true}
  };
  const denseRows = resultRows.flatten({kind: "league", leagueId: "mlb", availability: "ready",
    pinnedGames: [denseMlb], otherGames: [denseNcaa]}, "mlb");
  assert.equal(denseRows.filter((row) => row.kind === "game").length, 2);
  assert.equal(formatters.teamLabel(denseMlb.awayTeam).length <= 18, true);
  assert.equal(formatters.formatScoreboardTeamScore(denseMlb, "away"), "123");
  assert.equal(formatters.formatScoreboardTeamScore(denseNcaa, "away"), "VS");
});

test("U2.2 scoreboard formatters avoid pregame scores and mark stale state", () => {
  assert.equal(formatters.formatScoreboardTeamScore({status: "scheduled", awayScore: 0, homeScore: 0}, "away"), "VS");
  assert.equal(formatters.formatScoreboardTeamScore({status: "scheduled", awayScore: 0, homeScore: 0}, "home"), "");
  assert.equal(formatters.formatScoreboardScore({status: "scheduled", awayScore: 0, homeScore: 0}), "VS");
  assert.equal(formatters.formatGameStateLabel({status: "scheduled", startTime: "bad-time"}), "SCHEDULED");
  assert.equal(formatters.formatGameStateLabel({status: "live", periodLabel: "2nd"}, {stale: true}),
    "STALE · age unavailable · LIVE · 2nd");
  assert.equal(formatters.formatGameStateLabel({status: "malformed"}), "DATA UNAVAILABLE");
  assert.equal(formatters.isWinningTeam({status: "final", awayScore: 123, homeScore: 7}, "away"), true);
  assert.equal(formatters.isWinningTeam({status: "final", awayScore: 123, homeScore: 7}, "home"), false);
  assert.equal(formatters.isWinningTeam({status: "final", awayScore: 1, homeScore: 1}, "away"), false);
});

test("U2.2 GameRow keeps logos optional while reserving stable team and score columns", () => {
  const source = readSource("components/GameRow.qml");
  assert.equal(source.includes("readonly property real scoreColumnWidth"), true);
  assert.equal(source.includes("horizontalAlignment: Text.AlignRight"), true);
  assert.equal(source.includes("Formatters.formatScoreboardTeamScore"), true);
  assert.equal(source.includes("visible: !awayLogo.visible"), true);
  assert.equal(source.includes("visible: !homeLogo.visible"), true);
  assert.equal(source.includes("Formatters.isWinningTeam"), true);
  assert.equal(source.includes("STALE"), false);
  assert.equal(source.includes("provider"), false);
});

test("U3.2 annotates each followed side and adds league context only to mixed Following", () => {
  const fixtureGames = readU3ScoreCardFixture().games.map((game) => games.normalizeGame(game));
  const away = fixtureGames[0];
  const home = fixtureGames[1];
  const both = fixtureGames[2];
  const mlb = Object.assign({}, home, {
    id: "mlb:u3-mixed",
    league: "mlb",
    awayTeam: Object.assign({}, home.awayTeam, {id: "mlb:2", league: "mlb"}),
    homeTeam: Object.assign({}, home.homeTeam, {id: "mlb:10", league: "mlb"})
  });
  const composed = {
    leagueStates: [
      {leagueId: "nhl", displayName: "NHL", sport: "hockey", games: [away, home, both]},
      {leagueId: "mlb", displayName: "MLB", sport: "baseball", games: [mlb]}
    ]
  };
  const mixed = panelPresentation.build(composed, ["nhl:6", "nhl:22", "nhl:18", "nhl:20", "mlb:2"]);
  const mixedGames = mixed.following.games;
  assert.equal(mixedGames.length, 4);
  assert.equal(mixedGames.find((game) => game.id === away.id).presentation.awayIsFavorite, true);
  assert.equal(mixedGames.find((game) => game.id === away.id).presentation.homeIsFavorite, false);
  assert.equal(mixedGames.find((game) => game.id === home.id).presentation.awayIsFavorite, false);
  assert.equal(mixedGames.find((game) => game.id === home.id).presentation.homeIsFavorite, true);
  assert.equal(mixedGames.find((game) => game.id === both.id).presentation.awayIsFavorite, true);
  assert.equal(mixedGames.find((game) => game.id === both.id).presentation.homeIsFavorite, true);
  assert.equal(mixedGames.every((game) => game.presentation.showLeagueContext), true);
  assert.equal(mixedGames.find((game) => game.id === mlb.id).presentation.leagueLabel, "MLB");

  const single = panelPresentation.build({leagueStates: [
    {leagueId: "nhl", displayName: "NHL", sport: "hockey", games: [away]}
  ]}, ["nhl:6"]);
  assert.equal(single.following.games[0].presentation.showLeagueContext, false);
});

test("U3.4 reserves a reachable trailing source action in mixed Following rows", () => {
  const fixture = readMixedFollowingLayoutFixture();
  const source = readSource("components/GameRow.qml");
  const sourceButton = readSource("components/SourceLinkButton.qml");
  const fixtureGames = readU3ScoreCardFixture().games.map((game) => games.normalizeGame(game));
  const away = Object.assign({}, fixtureGames[0], {link: "https://www.nhl.com/game/away"});
  const home = Object.assign({}, fixtureGames[1], {link: "https://www.nhl.com/game/home"});
  const both = Object.assign({}, fixtureGames[2], {link: "https://www.nhl.com/game/both"});
  const mlb = Object.assign({}, home, {
    id: "mlb:u3-mixed",
    league: "mlb",
    link: "https://www.espn.com/mlb/game/mixed",
    awayTeam: Object.assign({}, home.awayTeam, {id: "mlb:2", league: "mlb"}),
    homeTeam: Object.assign({}, home.homeTeam, {id: "mlb:10", league: "mlb"})
  });
  const composed = {
    leagueStates: [
      {leagueId: "nhl", displayName: "NHL", sport: "hockey", games: [away, home, both]},
      {leagueId: "mlb", displayName: "MLB", sport: "baseball", games: [mlb]}
    ]
  };
  const presentationView = panelPresentation.build(composed,
    ["nhl:6", "nhl:22", "nhl:18", "nhl:20", "mlb:2"]);
  const rows = resultRows.flatten(presentationView.following, "following")
    .filter((row) => row.kind === "game");
  assert.deepEqual(rows.map((row) => row.rowId), fixture.rows.map((row) => row.rowId));
  assert.equal(rows.every((row) => row.game.presentation.showLeagueContext), true);

  fixture.panelWidths.forEach((panelWidth) => {
    const rowWidth = panelWidth.panelWidth - fixture.cardInset * 2;
    fixture.rows.forEach((row) => {
      const layout = gameRowLayout.footerLayout(rowWidth, row.contextNaturalWidth,
        row.favoriteWidth, row.sourceWidth, fixture.spacing, fixture.minimumDetailWidth);
      assert.equal(layout.sourceReachable, true,
        `${panelWidth.name} source action must remain reachable for ${row.rowId}`);
      assert.equal(layout.sourceWidth > 0, true);
      assert.equal(layout.detailWidth >= fixture.minimumDetailWidth, true,
        `${panelWidth.name} detail must retain a budget for ${row.rowId}`);
      assert.equal(layout.nonOverlapping, true,
        `${panelWidth.name} metadata must not overlap source for ${row.rowId}`);
    });
  });

  assert.match(source, /GameRowLayout\.footerLayout/);
  assert.match(source, /anchors\.right: parent\.right/);
  assert.match(source, /anchors\.right: sourceLink\.visible \? sourceLink\.left : parent\.right/);
  assert.match(sourceButton, /focusable: true/);
});

test("U3.2 keeps every scoreboard state textual and separates stale age from status", () => {
  const fixtureGames = readU3ScoreCardFixture().games.map((game) => games.normalizeGame(game));
  assert.deepEqual(fixtureGames.map((game) => game.status),
    ["live", "final", "final", "live", "postponed", "canceled", "unknown"]);
  assert.equal(formatters.formatGameStateLabel(fixtureGames[0]), "LIVE · 2nd · 08:42");
  assert.equal(formatters.formatGameStateLabel(fixtureGames[1]), "FINAL");
  assert.equal(formatters.formatGameStateLabel(fixtureGames[4]), "POSTPONED");
  assert.equal(formatters.formatGameStateLabel(fixtureGames[5]), "CANCELED");
  assert.equal(formatters.formatGameStateLabel(fixtureGames[6]), "DATA UNAVAILABLE");
  assert.equal(formatters.formatGameStateLabel(fixtureGames[3], {
    stale: true, now: Date.parse("2026-08-19T15:00:00.000Z")
  }), "STALE · 60m ago · LIVE · In progress");
  assert.equal(formatters.formatScoreboardTeamScore(fixtureGames[0], "away"), "123");

  const source = readSource("components/GameRow.qml");
  assert.equal(source.includes("awayIsFavorite"), true);
  assert.equal(source.includes("homeIsFavorite"), true);
  assert.equal(source.includes('text: root.awayIsFavorite ? "★" : ""'), true);
  assert.equal(source.includes('text: root.homeIsFavorite ? "★" : ""'), true);
  assert.equal(source.includes("font.underline: root.awayIsFavorite"), true);
  assert.equal(source.includes("showLeagueContext"), true);
  assert.equal(source.includes("root.stateLabel"), true);
});

test("U3.3 keeps sparse states compact while dense and utility views stay bounded", () => {
  const tokens = {
    compactMinimum: 280, maximum: 640, scoreChrome: 112,
    section: 22, game: 88, status: 42, loading: 170,
    nextGame: 250, empty: 104, rowGap: 12,
    settings: 440, teams: 640, notifications: 520
  };
  const sparse = panelLayout.contentRequest([
    {kind: "empty"}
  ], "sports", false, tokens);
  const oneGame = panelLayout.contentRequest([
    {kind: "section-header"}, {kind: "game"}
  ], "sports", false, tokens);
  const dense = panelLayout.contentRequest(Array.from({length: 12}, () => ({kind: "game"})),
    "sports", false, tokens);
  assert.equal(sparse, 280);
  assert.ok(oneGame >= sparse);
  assert.equal(dense, 640);
  assert.equal(panelLayout.contentRequest([{kind: "empty"}], "teams", true, tokens), 640);
  assert.equal(panelLayout.dateRadius(359, 360), 1);
  assert.equal(panelLayout.dateRadius(360, 360), 2);
  assert.equal(panelLayout.compactTabLabel("notifications", true), "Alerts");

  const noGames = resultRows.flatten({
    kind: "following", hasFavorites: true, hasGames: false, loading: false
  }, "following");
  assert.equal(noGames[0].action.type, "browse-leagues");
  assert.equal(noGames[0].supportingText, "Browse a league for the full slate.");
  const loading = resultRows.flatten({
    kind: "following", hasFavorites: true, hasGames: false, loading: true
  }, "following");
  assert.deepEqual(loading.map((row) => row.kind), ["loading"]);

  const retainedGame = normalizeFixtureGames(readPresentationFixture())[0];
  const retained = resultRows.flatten({
    kind: "league", leagueId: "nhl", displayName: "NHL", loading: true,
    errorCode: "", stale: false, pinnedGames: [retainedGame], otherGames: []
  }, "nhl");
  assert.equal(retained[0].kind, "section-header");
  assert.equal(retained.filter((row) => row.kind === "game").length, 1);
  assert.equal(retained.some((row) => row.kind === "status"), false);
  const retainedFollowing = resultRows.flatten({
    kind: "following", hasFavorites: true, hasGames: true, loading: true,
    games: [retainedGame]
  }, "following");
  assert.equal(retainedFollowing.some((row) => row.kind === "status"), false);
  assert.equal(retainedFollowing.filter((row) => row.kind === "game").length, 1);

  const panel = readSource("Panel.qml");
  const carousel = readSource("components/DateCarousel.qml");
  const hub = readSource("components/SettingsHub.qml");
  const picker = readSource("components/TeamPicker.qml");
  const loadingState = readSource("components/LoadingState.qml");
  assert.equal(panel.includes("property int panelContentHeightRequest"), true);
  assert.equal(panel.includes("property bool panelHeightRecalculationPending"), true);
  assert.equal(panel.includes("PanelLayout.contentRequest"), true);
  assert.equal(panel.includes("function queuePanelHeightRecalculation()"), true);
  assert.equal(panel.includes("root.queuePanelHeightRecalculation()"), true);
  assert.equal(panel.includes('row.kind === "loading"'), true);
  assert.equal(panel.includes("onResultRowsChanged: {"), true);
  assert.equal(panel.includes("id: panelHeightSettleTimer"), true);
  assert.equal(panel.includes("root.activeView && root.activeView.loading === true"), true);
  assert.equal(panel.includes("root.deferPanelCallback(root.recalculatePanelHeight)"), true);
  assert.equal(panel.includes("fittedContentHeight(Style.space(560)"), false);
  assert.equal(panel.includes("interactive: root.settingsDestination !== \"teams\""), true);
  assert.equal(carousel.includes("root.compact ? 1 : root.radius"), true);
  assert.equal(hub.includes("shortLabel: \"Alerts\""), true);
  assert.equal(hub.includes("contentBoundsRequested"), true);
  assert.equal(picker.includes("function cursorBounds()"), true);
  assert.equal(loadingState.includes("model: 2"), true);
  assert.equal(loadingState.includes("Behavior on opacity"), false);
  assert.equal(panel.includes("id: refreshToast"), true);
  assert.equal(panel.includes('text: "Refreshing scores…"'), true);
  assert.equal(panel.includes("root.resultRows.some(function(row) { return row.kind === \"game\" })"), true);
});

test("U3.5 release assets and listing copy describe the current candidate", () => {
  function pngSize(relativePath) {
    const bytes = fs.readFileSync(path.join(root, relativePath));
    assert.equal(bytes.toString("ascii", 1, 4), "PNG");
    return [bytes.readUInt32BE(16), bytes.readUInt32BE(20)];
  }

  assert.deepEqual(pngSize("preview.png"), [834, 962]);
  const readme = readSource("README.md");
  const manifest = JSON.parse(readSource("manifest.json"));
  const changelog = readSource("CHANGELOG.md");
  assert.equal(readme.includes("**Favorite-first**"), true);
  assert.equal(readme.includes("**Eight leagues**"), true);
  assert.equal(readme.includes("**No account or API key**"), true);
  assert.equal(readme.includes("Select **View day**"), true);
  assert.equal(readme.includes("Proposed category: **Widgets**"), true);
  assert.equal(readme.includes("View <date>"), false);
  assert.equal(manifest.version, "1.0.0-rc.8");
  assert.match(manifest.description, /favorite teams.*daily schedules.*alerts/);
  assert.match(changelog, /## 1\.0\.0-rc\.7/);
});

test("bar priority handles one live favorite, multiple live favorites, and starting soon", () => {
  const fixture = readPresentationFixture();
  const normalized = normalizeFixtureGames(fixture);
  const now = fixture.now;

  const oneLive = presentation.selectBarState(normalized, ["nhl:6"], now);
  assert.equal(oneLive.kind, "live-favorite");
  assert.equal(oneLive.game.providerGameId, "101");

  const multipleLive = presentation.selectBarState(normalized, ["nhl:6", "nhl:24"], now);
  assert.deepEqual(multipleLive, {kind: "live-favorite-count", game: null, count: 2});

  const startingSoon = presentation.selectBarState(normalized, ["nhl:13"], now);
  assert.equal(startingSoon.kind, "favorite-starting-soon");
  assert.equal(startingSoon.game.providerGameId, "103");
});

test("bar priority selects the next scheduled favorite before neutral games", () => {
  const fixture = readPresentationFixture();
  const normalized = normalizeFixtureGames(fixture);
  const state = presentation.selectBarState(normalized, ["nhl:22"], fixture.now);
  assert.equal(state.kind, "favorite-upcoming");
  assert.equal(state.game.providerGameId, "109");

  const earlierNeutral = Object.assign({}, normalized.find((game) => game.providerGameId === "106"), {
    startTime: "2026-10-08T10:10:00Z"
  });
  const withEarlierNeutral = normalized.concat([earlierNeutral]);
  const prioritized = presentation.selectBarState(withEarlierNeutral, ["nhl:22"], fixture.now);
  assert.equal(prioritized.game.providerGameId, "109");
});

test("adaptive polling prioritizes live favorites and open-panel live games", () => {
  const fixture = readPresentationFixture();
  const normalized = normalizeFixtureGames(fixture);
  const now = Date.parse(fixture.now);
  const liveFavorite = pollPolicy.selectCadence(normalized, ["nhl:6"], false, now, 0);
  assert.deepEqual(liveFavorite, {kind: "live-favorite", intervalMs: 30000});

  const visibleLiveFavorite = pollPolicy.selectCadence(normalized, ["nhl:6"], true, now, 0);
  assert.deepEqual(visibleLiveFavorite, {kind: "panel-live", intervalMs: 20000});

  const panelLive = pollPolicy.selectCadence(normalized, [], true, now, 0);
  assert.deepEqual(panelLive, {kind: "panel-live", intervalMs: 20000});
});

test("adaptive polling selects starting-soon, pregame, and final cadences", () => {
  const fixture = readPresentationFixture();
  const normalized = normalizeFixtureGames(fixture);
  const now = Date.parse(fixture.now);
  const soonGame = normalized.filter((game) => game.providerGameId === "103");
  const nearGame = [Object.assign({}, soonGame[0], {
    startTime: new Date(now + 5 * 60 * 1000).toISOString()
  })];
  const startingSoon = pollPolicy.selectCadence(nearGame, ["nhl:13"], false, now, 0);
  assert.deepEqual(startingSoon, {kind: "favorite-starting-soon", intervalMs: 120000});

  const pregame = pollPolicy.selectCadence(nearGame, [], false, now, 0);
  assert.deepEqual(pregame, {kind: "pregame", intervalMs: 600000});

  const finals = normalized.filter((game) => game.status === "final");
  const finalCadence = pollPolicy.selectCadence(finals, [], false, now, 1234);
  assert.equal(finalCadence.kind, "final");
  assert.equal(finalCadence.intervalMs,
    pollPolicy.FINAL_BASE_INTERVAL_MS + pollPolicy.finalJitterMs(1234));
  assert.ok(finalCadence.intervalMs >= pollPolicy.FINAL_MIN_INTERVAL_MS);
  assert.ok(finalCadence.intervalMs <= pollPolicy.FINAL_MAX_INTERVAL_MS);
});

test("far scheduled slates stay cached until the pregame boundary", () => {
  const now = Date.parse("2026-08-19T10:00:00.000Z");
  const twelveHoursAway = [{
    id: "nhl:future", status: "scheduled", startTime: "2026-08-19T22:00:00.000Z"
  }];
  assert.deepEqual(pollPolicy.selectCadence(
    twelveHoursAway, [], false, now, 0, "2026-08-19", "2026-08-19"), {
    kind: "scheduled-cached",
    intervalMs: (11 * 60 + 50) * 60 * 1000
  });

  const thirtyHoursAway = [{
    id: "nhl:later", status: "scheduled", startTime: "2026-08-20T16:00:00.000Z"
  }];
  assert.deepEqual(pollPolicy.selectCadence(
    thirtyHoursAway, [], false, now, 0, "2026-08-20", "2026-08-19"), {
    kind: "scheduled-cached",
    intervalMs: pollPolicy.SCHEDULE_RECHECK_MAX_INTERVAL_MS
  });
});

test("empty, completed, and historical slates use long cache windows", () => {
  const now = Date.parse("2026-08-19T10:00:00.000Z");
  assert.deepEqual(pollPolicy.selectCadence(
    [], [], false, now, 0, "2026-08-19", "2026-08-19"), {
    kind: "empty", intervalMs: 6 * 60 * 60 * 1000
  });
  assert.deepEqual(pollPolicy.selectCadence(
    [{id: "done", status: "final"}], [], false, now, 0, "2026-08-19", "2026-08-19"), {
    kind: "final", intervalMs: 6 * 60 * 60 * 1000
  });
  assert.deepEqual(pollPolicy.selectCadence(
    [{id: "old", status: "final"}], [], true, now, 0, "2026-08-18", "2026-08-19"), {
    kind: "historical", intervalMs: 24 * 60 * 60 * 1000
  });
});

test("background live polling is isolated and slower than visible live polling", () => {
  const game = [{id: "nhl:live", status: "live"}];
  assert.deepEqual(pollPolicy.selectCadence(game, [], false, 0, 0), {
    kind: "background-live", intervalMs: 2 * 60 * 1000
  });
});

test("final cadence jitter remains deterministic and bounded", () => {
  assert.equal(pollPolicy.finalJitterMs(0), 0);
  assert.equal(pollPolicy.finalJitterMs(30001), 0);
  assert.ok(pollPolicy.finalJitterMs(0xffffffff) <= pollPolicy.FINAL_JITTER_MS);
  assert.ok(pollPolicy.FINAL_BASE_INTERVAL_MS + pollPolicy.FINAL_JITTER_MS
    <= pollPolicy.FINAL_MAX_INTERVAL_MS);
});

test("scheduler immediate refresh triggers are explicit", () => {
  ["initialization", "manual", "enabled-leagues-changed", "date-changed"]
    .forEach((reason) => assert.equal(pollPolicy.isImmediateRefreshTrigger(reason), true));
  ["timer", "panel-open", "panel-close", "favorites-changed", "games-changed", "", null]
    .forEach((reason) =>
    assert.equal(pollPolicy.isImmediateRefreshTrigger(reason), false));
});

test("provider failures back off exponentially with a bounded randomized spread", () => {
  assert.deepEqual([1, 2, 3, 4, 5, 6, 20].map(pollPolicy.retryDelayMs),
    [60000, 120000, 240000, 480000, 960000, 1800000, 1800000]);
  assert.equal(pollPolicy.spreadIntervalMs(60000, 0), 60000);
  assert.equal(pollPolicy.spreadIntervalMs(60000, 1), 66000);
  assert.equal(pollPolicy.spreadIntervalMs(60000, -1), 60000);
  assert.equal(pollPolicy.spreadIntervalMs(60000, 2), 66000);
  assert.equal(pollPolicy.spreadIntervalMs(12 * 60 * 60 * 1000, 1),
    12 * 60 * 60 * 1000 + pollPolicy.MAX_JITTER_MS);
});

test("scheduler deadlines retain the earliest retry across healthy cadence updates", () => {
  const now = 100000;
  const retryDueAt = now + pollPolicy.retryDelayMs(1);
  const healthyCadenceDueAt = now + 6 * 60 * 60 * 1000;
  assert.equal(pollPolicy.earliestDeadline(retryDueAt, healthyCadenceDueAt), retryDueAt);
  assert.equal(pollPolicy.delayUntil(retryDueAt, now), pollPolicy.retryDelayMs(1));
  assert.equal(pollPolicy.earliestDeadline(healthyCadenceDueAt, retryDueAt), retryDueAt);
  assert.equal(pollPolicy.earliestDeadline(0, healthyCadenceDueAt), healthyCadenceDueAt);
  assert.equal(pollPolicy.delayUntil(now - 1, now), 1);
  assert.equal(pollPolicy.isRequestDue({consecutiveFailures: 1,
    retryNotBeforeMs: retryDueAt}, "manual", now), true);
});

test("request admission reuses fresh league/date snapshots and honors manual refresh", () => {
  const now = Date.parse("2026-08-19T10:00:00.000Z");
  const nextEligible = now + (11 * 60 + 50) * 60 * 1000;
  const cached = {
    hasData: true,
    lastSuccessMs: now,
    nextEligibleAtMs: nextEligible,
    consecutiveFailures: 0,
    games: [{id: "nhl:future", status: "scheduled", startTime: "2026-08-19T22:00:00.000Z"}],
    favoriteTeamIds: [],
    panelOpen: true,
    selectedDateKey: "2026-08-19",
    todayDateKey: "2026-08-19",
    jitterUnit: 0
  };
  assert.equal(pollPolicy.isRequestDue(cached, "panel-open", now + 60 * 60 * 1000), false);
  assert.equal(pollPolicy.isRequestDue(cached, "timer", nextEligible - 1), false);
  assert.equal(pollPolicy.isRequestDue(cached, "timer", nextEligible), true);
  assert.equal(pollPolicy.isRequestDue(cached, "manual", now + 1000), true);
});

test("request admission shortens live visibility cadence and gates failed retries", () => {
  const now = Date.parse("2026-08-19T10:00:00.000Z");
  const live = {
    hasData: true,
    lastSuccessMs: now,
    nextEligibleAtMs: now + pollPolicy.BACKGROUND_LIVE_INTERVAL_MS,
    games: [{id: "nhl:live", status: "live"}],
    panelOpen: true,
    selectedDateKey: "2026-08-19",
    todayDateKey: "2026-08-19",
    jitterUnit: 0
  };
  assert.equal(pollPolicy.isRequestDue(live, "timer", now + 19999), false);
  assert.equal(pollPolicy.isRequestDue(live, "timer", now + 20000), true);

  const failed = {
    hasData: false,
    consecutiveFailures: 3,
    retryNotBeforeMs: now + 240000
  };
  assert.equal(pollPolicy.isRequestDue(failed, "timer", now + 239999), false);
  assert.equal(pollPolicy.isRequestDue(failed, "timer", now + 240000), true);
});

test("freshness thresholds are bounded and follow the active cadence", () => {
  assert.equal(freshness.staleThresholdMs(20 * 1000), 5 * 60 * 1000);
  assert.equal(freshness.staleThresholdMs(2 * 60 * 1000), 5 * 60 * 1000);
  assert.equal(freshness.staleThresholdMs(10 * 60 * 1000), 20 * 60 * 1000);
  assert.equal(freshness.staleThresholdMs(12 * 60 * 1000 + 30 * 1000), 24 * 60 * 1000 + 60 * 1000);
  assert.equal(freshness.staleThresholdMs(60 * 60 * 1000), freshness.MAX_STALE_THRESHOLD_MS);
  const successAt = "2026-08-17T12:00:00.000Z";
  assert.equal(freshness.isPastStaleThreshold(successAt, "2026-08-17T12:20:00.000Z", 10 * 60 * 1000), false);
  assert.equal(freshness.isPastStaleThreshold(successAt, "2026-08-17T12:20:00.001Z", 10 * 60 * 1000), true);
});

test("freshness state tracks attempts, preserves last success, and recovers", () => {
  const first = freshness.applySuccess(
    freshness.beginAttempt({games: [], hasData: false}, "2026-08-17T12:00:00.000Z"),
    [{id: "nhl-1"}],
    "2026-08-17T12:00:01.000Z");
  assert.equal(first.lastAttemptAt, "2026-08-17T12:00:00.000Z");
  assert.equal(first.lastSuccessAt, "2026-08-17T12:00:01.000Z");
  assert.equal(first.stale, false);

  const timedOut = freshness.applyFailure(
    freshness.beginAttempt(first, "2026-08-17T12:10:00.000Z"), "timeout");
  assert.deepEqual(timedOut.games, first.games);
  assert.equal(timedOut.lastAttemptAt, "2026-08-17T12:10:00.000Z");
  assert.equal(timedOut.lastSuccessAt, first.lastSuccessAt);
  assert.equal(timedOut.errorSummary, "Scores are temporarily unavailable");
  assert.equal(timedOut.stale, true);

  const recovered = freshness.applySuccess(timedOut, [{id: "nhl-2"}], "2026-08-17T12:10:02.000Z");
  assert.deepEqual(recovered.games, [{id: "nhl-2"}]);
  assert.equal(recovered.lastSuccessAt, "2026-08-17T12:10:02.000Z");
  assert.equal(recovered.errorCode, "");
  assert.equal(recovered.stale, false);
});

test("timeout, no-connection, and malformed recovery returns to healthy state", () => {
  const good = freshness.applySuccess(
    freshness.beginAttempt({games: [], hasData: false}, "2026-08-17T12:00:00.000Z"),
    [{id: "nhl-healthy"}], "2026-08-17T12:00:01.000Z");

  ["timeout", "unavailable", "invalid-data"].forEach((code, index) => {
    const failed = freshness.applyFailure(
      freshness.beginAttempt(good, `2026-08-17T12:0${index + 1}:00.000Z`), code);
    assert.deepEqual(failed.games, good.games);
    assert.equal(failed.lastSuccessAt, good.lastSuccessAt);
    assert.equal(failed.stale, true);

    const recovered = freshness.applySuccess(
      failed, [{id: `nhl-recovered-${code}`}], `2026-08-17T13:0${index}:00.000Z`);
    assert.deepEqual(recovered.games, [{id: `nhl-recovered-${code}`}]);
    assert.equal(recovered.errorCode, "");
    assert.equal(recovered.stale, false);
  });
});

test("lifecycle owner topology remains singular and destruction-safe", () => {
  const scheduler = readSource("services/PollScheduler.qml");
  const leagueFetch = readSource("services/LeagueFetch.qml");
  const responsePolicySource = readSource("model/ResponsePolicy.js");
  assert.equal((scheduler.match(/\bTimer\s*\{/g) || []).length, 1);
  assert.equal((scheduler.match(/\bProcess\s*\{/g) || []).length, 0);
  assert.equal((leagueFetch.match(/\bProcess\s*\{/g) || []).length, 2);
  assert.match(leagueFetch, /id: lookaheadProcess/);
  assert.match(scheduler, /Component\.onDestruction:\s*pollTimer\.stop\(\)/);
  assert.match(leagueFetch, /property int requestGeneration/);
  assert.match(leagueFetch, /Component\.onDestruction/);
  assert.match(leagueFetch, /if \(requestProcess\.running\) requestProcess\.running = false/);
  assert.match(leagueFetch, /property var dateCache: \(\{\}\)/);
  assert.match(leagueFetch, /readonly property int dateCacheLimit: 5/);
  assert.match(leagueFetch, /import "\.\.\/model\/DateCachePolicy\.js" as DateCachePolicy/);
  assert.match(leagueFetch, /DateCachePolicy\.canRestoreLastKnown/);
  assert.match(leagueFetch, /root\.snapshotDateKey = root\.dateKey/);
  assert.match(leagueFetch, /if \(!root\.initialized\) return/);
  assert.match(leagueFetch, /property int lookaheadHopCount: 0/);
  assert.match(leagueFetch, /LookaheadPolicy\.decideNextDate/);
  assert.match(leagueFetch, /root\.finishLookahead\("unavailable", PollPolicy\.EMPTY_INTERVAL_MS\)/);
  assert.match(leagueFetch, /function requestDue\(reason, nowMs\)/);
  assert.match(leagueFetch, /PollPolicy\.retryDelayMs\(root\.consecutiveFailures\)/);
  assert.match(leagueFetch, /"cache-hit"/);
  assert.match(leagueFetch, /signal retryRequested\(int delayMs\)/);
  assert.match(scheduler, /function scheduleRetry\(delayMs\)/);
  assert.match(scheduler, /PollPolicy\.earliestDeadline\(root\.timerDueAtMs, requestedDueAt\)/);
  assert.match(scheduler, /PollPolicy\.delayUntil\(dueAt, now\)/);
  assert.match(responsePolicySource, /MAX_RESPONSE_BYTES = 2 \* 1024 \* 1024/);
  assert.match(responsePolicySource, /MAX_EVENTS = 256/);
  assert.match(leagueFetch, /--max-filesize/);
  assert.equal((leagueFetch.match(/stdout: SplitParser/g) || []).length, 2);
  assert.equal((leagueFetch.match(/StdioCollector/g) || []).length, 0);
  assert.match(leagueFetch, /ResponsePolicy\.canAppend/);
  assert.match(leagueFetch, /requestProcess\.signal\(9\)/);
  assert.match(leagueFetch, /lookaheadProcess\.signal\(9\)/);
});

test("multi-monitor panels share one polling, notification, and settings owner", () => {
  let contexts = monitorOwnership.emptyContexts();
  contexts = monitorOwnership.updateContext(contexts, "panel-1", true, "nhl");
  contexts = monitorOwnership.updateContext(contexts, "panel-2", true, "nba");
  assert.equal(monitorOwnership.anyPanelOpen(contexts), true);
  assert.equal(monitorOwnership.lookaheadLeagueId(contexts), "nba");

  contexts = monitorOwnership.updateContext(contexts, "panel-2", false, "");
  assert.equal(monitorOwnership.anyPanelOpen(contexts), true);
  assert.equal(monitorOwnership.lookaheadLeagueId(contexts), "nhl");
  contexts = monitorOwnership.removeContext(contexts, "panel-1");
  assert.equal(monitorOwnership.anyPanelOpen(contexts), false);
  assert.equal(monitorOwnership.lookaheadLeagueId(contexts), "");

  const service = readSource("services/SportrayService.qml");
  const barWidget = readSource("BarWidget.qml");
  const panel = readSource("Panel.qml");
  assert.equal((service.match(/\bFetchService\s*\{/g) || []).length, 1);
  assert.equal((service.match(/\bNotificationService\s*\{/g) || []).length, 1);
  assert.equal((service.match(/\bSettingsStore\s*\{/g) || []).length, 1);
  assert.equal((panel.match(/\bFetchService\s*\{/g) || []).length, 0);
  assert.equal((panel.match(/\bNotificationService\s*\{/g) || []).length, 0);
  assert.equal((barWidget.match(/\bSettingsStore\s*\{/g) || []).length, 0);
  assert.match(barWidget, /Services\.SportrayService/);
  assert.match(panel, /root\.service\.updatePanel/);
  assert.match(panel, /root\.service\.unregisterPanel/);
});

test("NCAA Football owns one isolated fetch state in the existing scheduler", () => {
  const fetchService = readSource("services/FetchService.qml");
  assert.match(fetchService, /id: ncaafFetch/);
  assert.match(fetchService, /leagueId: "college-football"/);
  assert.match(fetchService, /ncaafFetch\.refresh\(refreshReason\)/);
  assert.match(fetchService, /ncaafFetch\.snapshot\(\)/);
  assert.match(fetchService, /target: ncaafFetch/);
  assert.equal((fetchService.match(/\bLeagueFetch\s*\{/g) || []).length, 8);
});

test("Premier League owns one isolated fetch state in the existing scheduler", () => {
  const fetchService = readSource("services/FetchService.qml");
  assert.match(fetchService, /id: eplFetch/);
  assert.match(fetchService, /leagueId: "eng\.1"/);
  assert.match(fetchService, /eplFetch\.refresh\(refreshReason\)/);
  assert.match(fetchService, /eplFetch\.snapshot\(\)/);
  assert.match(fetchService, /target: eplFetch/);
  assert.equal((fetchService.match(/\bLeagueFetch\s*\{/g) || []).length, 8);
});

test("MLS owns one isolated fetch state in the existing scheduler", () => {
  const fetchService = readSource("services/FetchService.qml");
  assert.match(fetchService, /id: mlsFetch/);
  assert.match(fetchService, /leagueId: "usa\.1"/);
  assert.match(fetchService, /mlsFetch\.refresh\(refreshReason\)/);
  assert.match(fetchService, /mlsFetch\.snapshot\(\)/);
  assert.match(fetchService, /target: mlsFetch/);
  assert.equal((fetchService.match(/\bLeagueFetch\s*\{/g) || []).length, 8);
});

test("NCAA Men's Basketball owns one isolated fetch state in the existing scheduler", () => {
  const fetchService = readSource("services/FetchService.qml");
  assert.match(fetchService, /id: ncaabFetch/);
  assert.match(fetchService, /leagueId: "mens-college-basketball"/);
  assert.match(fetchService, /ncaabFetch\.refresh\(refreshReason\)/);
  assert.match(fetchService, /ncaabFetch\.snapshot\(\)/);
  assert.match(fetchService, /target: ncaabFetch/);
  assert.equal((fetchService.match(/\bLeagueFetch\s*\{/g) || []).length, 8);
});

test("malformed and partial responses retain safe data until recovery", () => {
  const good = freshness.applySuccess(
    freshness.beginAttempt({games: [], hasData: false}, "2026-08-17T12:00:00.000Z"),
    [{id: "nba-1"}, {id: "nba-2"}],
    "2026-08-17T12:00:01.000Z");
  const malformed = freshness.applyFailure(
    freshness.beginAttempt(good, "2026-08-17T12:05:00.000Z"), "invalid-data");
  assert.deepEqual(malformed.games, good.games);
  assert.equal(malformed.lastSuccessAt, good.lastSuccessAt);
  assert.equal(malformed.errorSummary, "Scores could not be read");

  const partial = freshness.applyPartial(
    freshness.beginAttempt(malformed, "2026-08-17T12:06:00.000Z"), [{id: "nba-new"}], 1);
  assert.deepEqual(partial.games, good.games);
  assert.deepEqual(partial.lastKnownGames, good.lastKnownGames);
  assert.equal(partial.lastSuccessAt, good.lastSuccessAt);
  assert.equal(partial.errorCode, "partial-data");
  assert.equal(partial.stale, true);
});

test("failed league state retains its data while healthy sibling remains renderable", () => {
  const failedNhl = freshness.applyFailure({
    leagueId: "nhl",
    games: [{id: "nhl-1", league: "nhl", isValid: true}],
    hasData: true,
    lastSuccessAt: "2026-08-17T12:00:00.000Z"
  }, "unavailable");
  const result = scoreboard.compose([
    Object.assign({leagueId: "nhl", displayName: "NHL"}, failedNhl),
    {leagueId: "mlb", displayName: "MLB", games: [{id: "mlb-1", league: "mlb", isValid: true}], hasData: true}
  ], ["nhl", "mlb"], []);
  assert.deepEqual(result.sections.map((section) => section.leagueId), ["nhl", "mlb"]);
  assert.equal(result.sections.find((section) => section.leagueId === "nhl").stale, true);
  assert.equal(result.sections.find((section) => section.leagueId === "mlb").stale, false);
  assert.equal(result.games.some((game) => game.league === "mlb"), true);
});

test("NCAA Football failure and recovery stay isolated from NHL", () => {
  const nhlGame = nhl.parseScoreResponse(readRawFixture("scheduled")).games[0];
  const ncaafGame = espn.parseScoreboardResponse(
    readEspnFixture("ncaaf-live"), "college-football").games[0];
  const failed = scoreboard.compose([
    {leagueId: "nhl", displayName: "NHL", games: [nhlGame], hasData: true},
    {leagueId: "college-football", displayName: "NCAA Football", games: [ncaafGame],
      hasData: true, stale: true, errorCode: "unavailable"}
  ], ["nhl", "college-football"], ["college-football:153"]);
  assert.deepEqual(failed.sections.map((section) => section.leagueId), ["nhl", "college-football"]);
  assert.equal(failed.sections.find((section) => section.leagueId === "college-football").stale, true);
  assert.equal(failed.games.some((game) => game.league === "nhl"), true);

  const recovered = scoreboard.compose([
    {leagueId: "nhl", displayName: "NHL", games: [nhlGame], hasData: true},
    {leagueId: "college-football", displayName: "NCAA Football", games: [ncaafGame],
      hasData: true, stale: false, errorCode: ""}
  ], ["nhl", "college-football"], ["college-football:153"]);
  assert.equal(recovered.sections.find((section) => section.leagueId === "college-football").stale, false);
  assert.equal(recovered.statuses.length, 0);
});

test("Premier League failure and recovery stay isolated from NHL", () => {
  const nhlGame = nhl.parseScoreResponse(readRawFixture("scheduled")).games[0];
  const eplGame = espn.parseScoreboardResponse(
    readEspnFixture("epl-live"), "eng.1").games[0];
  const failed = scoreboard.compose([
    {leagueId: "nhl", displayName: "NHL", games: [nhlGame], hasData: true},
    {leagueId: "eng.1", displayName: "Premier League", games: [eplGame],
      hasData: true, stale: true, errorCode: "unavailable"}
  ], ["nhl", "eng.1"], ["eng.1:359"]);
  assert.deepEqual(failed.sections.map((section) => section.leagueId), ["nhl", "eng.1"]);
  assert.equal(failed.sections.find((section) => section.leagueId === "eng.1").stale, true);
  assert.equal(failed.games.some((game) => game.league === "nhl"), true);

  const recovered = scoreboard.compose([
    {leagueId: "nhl", displayName: "NHL", games: [nhlGame], hasData: true},
    {leagueId: "eng.1", displayName: "Premier League", games: [eplGame],
      hasData: true, stale: false, errorCode: ""}
  ], ["nhl", "eng.1"], ["eng.1:359"]);
  assert.equal(recovered.sections.find((section) => section.leagueId === "eng.1").stale, false);
  assert.equal(recovered.statuses.length, 0);
});

test("MLS failure and recovery stay isolated from NHL", () => {
  const nhlGame = nhl.parseScoreResponse(readRawFixture("scheduled")).games[0];
  const mlsGame = espn.parseScoreboardResponse(
    readEspnFixture("mls-live"), "usa.1").games[0];
  const failed = scoreboard.compose([
    {leagueId: "nhl", displayName: "NHL", games: [nhlGame], hasData: true},
    {leagueId: "usa.1", displayName: "MLS", games: [mlsGame],
      hasData: true, stale: true, errorCode: "unavailable"}
  ], ["nhl", "usa.1"], ["usa.1:20232"]);
  assert.deepEqual(failed.sections.map((section) => section.leagueId), ["nhl", "usa.1"]);
  assert.equal(failed.sections.find((section) => section.leagueId === "usa.1").stale, true);
  assert.equal(failed.games.some((game) => game.league === "nhl"), true);

  const recovered = scoreboard.compose([
    {leagueId: "nhl", displayName: "NHL", games: [nhlGame], hasData: true},
    {leagueId: "usa.1", displayName: "MLS", games: [mlsGame],
      hasData: true, stale: false, errorCode: ""}
  ], ["nhl", "usa.1"], ["usa.1:20232"]);
  assert.equal(recovered.sections.find((section) => section.leagueId === "usa.1").stale, false);
  assert.equal(recovered.statuses.length, 0);
});

test("NCAA Men's Basketball failure and recovery stay isolated from NHL", () => {
  const nhlGame = nhl.parseScoreResponse(readRawFixture("scheduled")).games[0];
  const ncaabGame = espn.parseScoreboardResponse(
    readEspnFixture("ncaab-live"), "mens-college-basketball").games[0];
  const failed = scoreboard.compose([
    {leagueId: "nhl", displayName: "NHL", games: [nhlGame], hasData: true},
    {leagueId: "mens-college-basketball", displayName: "NCAA Men's Basketball",
      games: [ncaabGame], hasData: true, stale: true, errorCode: "unavailable"}
  ], ["nhl", "mens-college-basketball"], ["mens-college-basketball:44"]);
  assert.deepEqual(failed.sections.map((section) => section.leagueId),
    ["nhl", "mens-college-basketball"]);
  assert.equal(failed.sections.find((section) => section.leagueId === "mens-college-basketball").stale,
    true);
  assert.equal(failed.games.some((game) => game.league === "nhl"), true);

  const recovered = scoreboard.compose([
    {leagueId: "nhl", displayName: "NHL", games: [nhlGame], hasData: true},
    {leagueId: "mens-college-basketball", displayName: "NCAA Men's Basketball",
      games: [ncaabGame], hasData: true, stale: false, errorCode: ""}
  ], ["nhl", "mens-college-basketball"], ["mens-college-basketball:44"]);
  assert.equal(recovered.sections.find((section) => section.leagueId === "mens-college-basketball").stale,
    false);
  assert.equal(recovered.statuses.length, 0);
});

test("empty and malformed favorites preserve the neutral FLA vs CAR bar fallback", () => {
  const fixture = readPresentationFixture();
  const game = normalizeFixtureGames(fixture).find((value) => value.providerGameId === "109");
  const state = presentation.selectBarState([game], [], fixture.now);
  assert.equal(state.kind, "neutral");
  assert.equal(formatters.formatBarText(state, {timeZone: "America/New_York"}), "FLA vs CAR · 5:00 PM");

  const malformed = presentation.selectBarState([game], [null, "", "NHL", "nhl:bad id", "nhl:999"], fixture.now);
  assert.equal(malformed.kind, "neutral");
  assert.deepEqual(presentation.normalizeFavoriteIds(["NHL:6", "not-canonical", "nhl:6", 6, "nhl:"]), ["nhl:6"]);
});

test("compact bar text and tooltip summaries stay bounded", () => {
  const countText = formatters.formatBarText({kind: "live-favorite-count", count: 32}, {leagueLabel: "NHL"});
  assert.equal(countText, "NHL · 32 live favorites");
  assert.ok(formatters.formatBarTooltip({kind: "live-favorite-count", count: 32}, {maxLength: 24}).length <= 24);

  const longGame = {
    status: "live",
    awayTeam: {abbreviation: "A".repeat(100)},
    homeTeam: {abbreviation: "B".repeat(100)},
    awayScore: 1,
    homeScore: 0
  };
  const tooltip = formatters.formatBarTooltip({kind: "live-favorite", game: longGame}, {maxLength: 32});
  assert.ok(tooltip.length <= 32);
  assert.equal(tooltip.endsWith("…"), true);
});

test("degraded presentation bounds long labels and never exposes provider errors", () => {
  const longGame = {
    status: "live",
    awayTeam: {name: "A very long away team name that must elide"},
    homeTeam: {name: "A very long home team name that must elide"},
    awayScore: 123456,
    homeScore: 987654
  };
  const bar = formatters.formatBarText({kind: "live-favorite", game: longGame}, {maxLength: 32});
  assert.ok(bar.length <= 32);
  assert.ok(formatters.formatPanelGame(longGame).awayLabel.length <= 18);
  assert.equal(formatters.formatScore(longGame), "1234…–9876…");

  const healthy = normalizeFixtureGames(readFixture("live"))[0];
  const mlbHealthy = espn.parseScoreboardResponse(readEspnFixture("mlb-live"), "mlb").games[0];
  const nbaHealthy = espn.parseScoreboardResponse(readEspnFixture("nba-live"), "nba").games[0];
  const dense = scoreboard.compose([
    {leagueId: "nhl", displayName: "NHL", games: [healthy, healthy, healthy], hasData: true},
    {leagueId: "nfl", displayName: "NFL", games: [], hasData: false, errorCode: "invalid-data",
      errorSummary: "raw provider payload: secret endpoint details"},
    {leagueId: "mlb", displayName: "MLB", games: [mlbHealthy], hasData: true, stale: true,
      errorCode: "unavailable", errorSummary: "raw provider payload: secret endpoint details"},
    {leagueId: "nba", displayName: "NBA", games: [nbaHealthy], hasData: true, stale: true,
      errorCode: "partial-data", errorSummary: "raw provider payload: stack trace"}
  ], ["nhl", "nfl", "mlb", "nba"], []);
  assert.equal(dense.sections.length, 3);
  assert.equal(dense.statuses[0].errorSummary, "Scores could not be read");
  assert.equal(dense.sections.find((section) => section.leagueId === "nba").errorSummary,
    "Some scores could not be updated");
  assert.equal(JSON.stringify(dense).includes("raw provider payload"), false);
});

test("ambient bar policy selects bounded modes from the installed bar orientation", () => {
  const fixture = readBarPresentationFixture();
  fixture.modeCases.forEach((modeCase) => {
    const input = {vertical: modeCase.vertical, mode: modeCase.mode};
    assert.equal(barPresentation.build(input).mode, modeCase.expectedMode, modeCase.name);
  });

  const barWidget = readSource("BarWidget.qml");
  assert.equal(barWidget.includes('import "model/BarPresentation.js" as BarPresentation'), true);
  assert.equal(barWidget.includes("BarPresentation.modeForBar(root.bar)"), true);
  assert.equal(barWidget.includes("BarIconButton {"), true);
  assert.equal(barWidget.includes("text: Iconography.displayText(root.barIconName, fullButton.fontFamily)"), true);
  assert.equal(barWidget.includes("visible: !root.fullMode"), true);
  assert.equal(barWidget.includes("visible: root.fullMode"), true);
});

test("ambient bar policy bounds long labels and keeps compact text in the tooltip", () => {
  const fixture = readBarPresentationFixture();
  const result = barPresentation.build(fixture.longLabel);
  assert.equal(result.mode, "full");
  assert.equal(result.label.length <= barPresentation.FULL_LABEL_MAX_LENGTH, true);
  assert.equal(result.tooltipText.length <= barPresentation.TOOLTIP_MAX_LENGTH, true);
  assert.equal(result.label.endsWith("…"), true);

  const compact = barPresentation.build(Object.assign({}, fixture.longLabel, {mode: "compact"}));
  assert.equal(compact.label, "");
  assert.equal(compact.tooltipText.length <= barPresentation.TOOLTIP_MAX_LENGTH, true);
});

test("ambient bar policy preserves neutral empty/offline fallbacks", () => {
  const fixture = readBarPresentationFixture();
  fixture.fallbackCases.forEach((fallbackCase) => {
    const result = barPresentation.build(fallbackCase);
    assert.equal(result.fullText, fallbackCase.expectedText, fallbackCase.name);
    assert.equal(result.state.kind, "neutral", fallbackCase.name);
  });
});

test("ambient bar policy preserves live favorite priority and today input", () => {
  const fixture = readBarPresentationFixture();
  const result = barPresentation.build(fixture.priority);
  assert.equal(result.state.kind, fixture.priority.expectedKind);
  assert.equal(result.state.game.id, fixture.priority.expectedGameId);
  assert.equal(result.hasLiveFavorite, true);
});

test("ambient bar rotation replaces only the multi-live favorite presentation", () => {
  const fixture = readLiveFavoriteRotationFixture();
  const policy = readBarPresentationFixture().rotationPresentation;
  const normalized = fixture.games.map((game) => games.normalizeGame(game));
  const rotation = liveFavoriteRotation.select({
    todayDateKey: fixture.todayDateKey,
    selectedDateKey: fixture.selectedDateKey,
    nowMs: Date.parse(fixture.now),
    cadenceMs: fixture.cadenceMs,
    favoriteTeamIds: fixture.favoriteTeamIds,
    hasData: true,
    games: normalized
  });

  const rotated = barPresentation.applyLiveFavoriteRotation(policy.baseState, rotation);
  assert.equal(rotated.kind, "live-favorite");
  assert.equal(rotated.game.id, fixture.expectedBoundedIds[0]);
  assert.equal(rotated.count, policy.baseState.count);
  assert.deepEqual(
    barPresentation.applyLiveFavoriteRotation(policy.countdownState, rotation),
    policy.countdownState);
  assert.deepEqual(
    barPresentation.applyLiveFavoriteRotation(policy.singleState, rotation),
    policy.singleState);

  const panel = readSource("Panel.qml");
  const barWidget = readSource("BarWidget.qml");
  assert.equal(panel.includes('import "model/BarPresentation.js" as BarPresentation'), true);
  assert.equal(panel.includes('import "model/LiveFavoriteRotationPolicy.js" as LiveFavoriteRotationPolicy'), true);
  assert.equal(panel.includes("BarPresentation.applyLiveFavoriteRotation("), true);
  assert.equal(panel.includes("ambientRotationCadenceMs: 60 * 1000"), true);
  assert.equal(barWidget.includes("new Timer"), false);
});

test("ambient bar rotation keeps empty, offline, and non-today states safe", () => {
  const fixture = readLiveFavoriteRotationFixture();
  const policy = readBarPresentationFixture().rotationPresentation;
  const base = {
    todayDateKey: fixture.todayDateKey,
    selectedDateKey: fixture.selectedDateKey,
    nowMs: Date.parse(fixture.now),
    cadenceMs: fixture.cadenceMs,
    favoriteTeamIds: fixture.favoriteTeamIds
  };
  [fixture.empty, fixture.offline, fixture.notToday].forEach((scenario) => {
    const rotation = liveFavoriteRotation.select(Object.assign({}, base, scenario));
    assert.notEqual(rotation.kind, "rotation");
    assert.deepEqual(
      barPresentation.applyLiveFavoriteRotation(policy.baseState, rotation),
      policy.baseState,
      rotation.kind);
  });
});

test("ambient priority transitions preserve rotation cadence and countdown fallback", () => {
  const fixture = readLiveFavoriteRotationFixture();
  const transitions = fixture.transitionMatrix;
  const normalized = (values) => values.map((game) => games.normalizeGame(game));
  const selectAmbient = (values, now) => {
    const normalizedGames = normalized(values);
    const baseState = presentation.selectBarState(
      normalizedGames, fixture.favoriteTeamIds, now);
    const rotation = liveFavoriteRotation.select({
      todayDateKey: fixture.todayDateKey,
      selectedDateKey: fixture.selectedDateKey,
      nowMs: now,
      cadenceMs: fixture.cadenceMs,
      favoriteTeamIds: fixture.favoriteTeamIds,
      hasData: true,
      games: normalizedGames
    });
    return {
      baseState,
      rotation,
      state: barPresentation.applyLiveFavoriteRotation(baseState, rotation)
    };
  };

  const before = selectAmbient(fixture.games, Date.parse(transitions.cadenceBoundary.before));
  const after = selectAmbient(fixture.games, Date.parse(transitions.cadenceBoundary.after));
  assert.equal(before.baseState.kind, "live-favorite-count");
  assert.equal(after.baseState.kind, "live-favorite-count");
  assert.equal(before.state.game.id, transitions.cadenceBoundary.expectedBeforeId);
  assert.equal(after.state.game.id, transitions.cadenceBoundary.expectedAfterId);
  assert.equal(after.rotation.index, before.rotation.index + 1);

  const scheduled = selectAmbient(
    transitions.liveRemoved.games, Date.parse(fixture.now));
  assert.equal(scheduled.rotation.kind, "empty");
  assert.equal(scheduled.state.kind, transitions.liveRemoved.expectedKind);
  assert.equal(scheduled.state.game.id, transitions.liveRemoved.expectedGameId);
  const countdown = countdownProjection.project({
    todayDateKey: fixture.todayDateKey,
    selectedDateKey: fixture.selectedDateKey,
    nowMs: Date.parse(fixture.now),
    favoriteTeamIds: fixture.favoriteTeamIds,
    hasData: true,
    game: scheduled.state.game
  });
  assert.deepEqual(countdown, Object.assign({}, transitions.liveRemoved.expectedCountdown, {
    todayDateKey: fixture.todayDateKey,
    selectedDateKey: fixture.selectedDateKey,
    game: scheduled.state.game,
    startTimeMs: Date.parse("2026-10-08T17:30:00Z"),
    nowMs: Date.parse(fixture.now),
    remainingMs: 3.5 * 60 * 60 * 1000
  }));

  const neutral = selectAmbient(
    transitions.neutralAfterRemoval.games, Date.parse(fixture.now));
  assert.equal(neutral.rotation.kind, "empty");
  assert.equal(neutral.state.kind, transitions.neutralAfterRemoval.expectedKind);
  assert.equal(neutral.state.game.id, transitions.neutralAfterRemoval.expectedGameId);
});

test("ambient bar policy keeps countdowns out of the tray and exposes status indicators", () => {
  const fixture = readBarPresentationFixture().countdownPresentation;
  const withCountdown = (countdown, mode = "full") => barPresentation.build({
    mode,
    state: fixture.state,
    fullText: fixture.sourceText,
    tooltipText: fixture.sourceText,
    countdown
  });

  const future = withCountdown(fixture.future);
  assert.equal(future.countdown.kind, "future");
  assert.equal(future.fullText, fixture.sourceText);
  assert.equal(future.label, fixture.sourceText);
  assert.equal(future.tooltipText, fixture.sourceText);
  assert.equal(future.hasUpcomingFavorite, true);

  const due = withCountdown(fixture.due, "compact");
  assert.equal(due.mode, "compact");
  assert.equal(due.fullText, fixture.sourceText);
  assert.equal(due.label, "");
  assert.equal(due.tooltipText, fixture.sourceText);

  [fixture.empty, fixture.offline].forEach((countdown) => {
    const safe = withCountdown(countdown);
    assert.equal(safe.fullText, fixture.sourceText);
    assert.equal(safe.tooltipText, fixture.sourceText);
  });

  const live = barPresentation.build({
    mode: "full",
    state: readBarPresentationFixture().priority.games
      ? presentation.selectBarState(readBarPresentationFixture().priority.games,
        readBarPresentationFixture().priority.favoriteTeamIds,
        Date.parse(readBarPresentationFixture().priority.now)) : null,
    fullText: fixture.sourceText,
    countdown: fixture.future
  });
  assert.equal(live.state.kind, "live-favorite");
  assert.equal(live.fullText, fixture.sourceText);
  assert.equal(live.hasUpcomingFavorite, false);

  const indicator = readBarPresentationFixture().indicatorPresentation;
  const upcoming = barPresentation.build({
    mode: "full",
    state: indicator.upcomingState,
    fullText: fixture.sourceText,
    tooltipText: fixture.sourceText
  });
  assert.equal(upcoming.hasUpcomingFavorite, indicator.expectedUpcoming);
  assert.equal(upcoming.hasLiveFavorite, indicator.expectedLive);

  const barWidget = readSource("BarWidget.qml");
  assert.equal(barWidget.includes("barHasUpcomingFavorite"), true);
  assert.equal(barWidget.includes("root.barHasLiveFavorite ? Color.urgent : Color.accent"), true);
  assert.equal(barWidget.includes("text: root.barLabelText"), false);
});

test("ambient countdown wiring keeps caller time and existing ownership boundaries", () => {
  const barWidget = readSource("BarWidget.qml");
  const panel = readSource("Panel.qml");
  const service = readSource("services/SportrayService.qml");
  assert.equal(barWidget.includes('import "model/CountdownProjectionPolicy.js" as CountdownProjectionPolicy'), true);
  assert.equal(barWidget.includes("CountdownProjectionPolicy.project({"), true);
  assert.equal(barWidget.includes("nowMs: panelLoader.item.ambientNowMs"), true);
  assert.equal(barWidget.includes('kind === "favorite-upcoming"'), true);
  assert.equal(panel.includes("ambientNowMs"), true);
  assert.equal(panel.includes("ambientTodayDateKey"), true);
  assert.equal(service.includes("property double nowMs: Date.now()"), true);
  assert.equal(service.includes("root.nowMs = Date.now()"), true);
  assert.equal(barWidget.includes("new Timer"), false);
});

test("live favorite rotation orders normalized today games deterministically", () => {
  const fixture = readLiveFavoriteRotationFixture();
  const normalized = fixture.games.map((game) => games.normalizeGame(game));
  const input = {
    todayDateKey: fixture.todayDateKey,
    selectedDateKey: fixture.selectedDateKey,
    nowMs: Date.parse(fixture.now),
    cadenceMs: fixture.cadenceMs,
    maxItems: 3,
    favoriteTeamIds: fixture.favoriteTeamIds,
    hasData: true,
    games: normalized
  };
  const result = liveFavoriteRotation.select(input);
  assert.equal(result.kind, "rotation");
  assert.deepEqual(result.rotationGames.map((game) => game.id), fixture.expectedBoundedIds);
  assert.equal(result.game.id, "nhl:104");
  assert.equal(result.index, 0);
  assert.equal(result.nextAtMs, input.nowMs + fixture.cadenceMs);
});

test("live favorite rotation keeps today's identity and cadence index stable", () => {
  const fixture = readLiveFavoriteRotationFixture();
  const normalized = fixture.games.map((game) => games.normalizeGame(game));
  const input = {
    todayDateKey: fixture.todayDateKey,
    selectedDateKey: fixture.selectedDateKey,
    nowMs: Date.parse(fixture.now) + fixture.cadenceMs,
    cadenceMs: fixture.cadenceMs,
    maxItems: 99,
    favoriteTeamIds: fixture.favoriteTeamIds,
    hasData: true,
    games: normalized
  };
  const first = liveFavoriteRotation.select(input);
  const reordered = liveFavoriteRotation.select(Object.assign({}, input, {
    games: normalized.slice().reverse()
  }));
  assert.equal(first.todayDateKey, fixture.todayDateKey);
  assert.equal(first.selectedDateKey, fixture.todayDateKey);
  assert.deepEqual(reordered.rotationGames.map((game) => game.id), first.rotationGames.map((game) => game.id));
  assert.equal(reordered.index, first.index);
  assert.equal(reordered.game.id, first.game.id);
  assert.equal(first.rotationGames.length, liveFavoriteRotation.MAX_ROTATION_ITEMS);
  assert.equal(first.index < first.rotationGames.length, true);
});

test("live favorite rotation returns bounded empty, offline, and non-today states", () => {
  const fixture = readLiveFavoriteRotationFixture();
  const base = {
    todayDateKey: fixture.todayDateKey,
    selectedDateKey: fixture.selectedDateKey,
    nowMs: Date.parse(fixture.now),
    cadenceMs: fixture.cadenceMs,
    favoriteTeamIds: fixture.favoriteTeamIds
  };
  const empty = liveFavoriteRotation.select(Object.assign({}, base, fixture.empty));
  assert.deepEqual(empty, {
    kind: "empty",
    reason: "no-live-favorite",
    todayDateKey: fixture.todayDateKey,
    selectedDateKey: fixture.selectedDateKey,
    rotationGames: [],
    index: 0,
    game: null,
    count: 0,
    cadenceMs: null,
    nextAtMs: null
  });
  const offline = liveFavoriteRotation.select(Object.assign({}, base, fixture.offline));
  assert.equal(offline.kind, "offline");
  assert.equal(offline.rotationGames.length, 0);
  assert.equal(offline.index, 0);
  const notToday = liveFavoriteRotation.select(Object.assign({}, base, fixture.notToday));
  assert.equal(notToday.kind, "not-today");
  assert.equal(notToday.reason, "today-scope");
  assert.equal(notToday.index, 0);
  assert.equal(notToday.rotationGames.length, 0);
});

test("live favorite rotation clamps cadence and never leaks an unbounded index", () => {
  const fixture = readLiveFavoriteRotationFixture();
  const normalized = fixture.games.map((game) => games.normalizeGame(game));
  const result = liveFavoriteRotation.select({
    todayDateKey: fixture.todayDateKey,
    selectedDateKey: fixture.selectedDateKey,
    nowMs: Date.parse(fixture.now),
    cadenceMs: Number.MAX_SAFE_INTEGER,
    maxItems: Number.MAX_SAFE_INTEGER,
    favoriteTeamIds: fixture.favoriteTeamIds,
    hasData: true,
    games: normalized
  });
  assert.equal(result.cadenceMs, liveFavoriteRotation.MAX_CADENCE_MS);
  assert.equal(result.rotationGames.length, liveFavoriteRotation.MAX_ROTATION_ITEMS);
  assert.equal(result.index >= 0, true);
  assert.equal(result.index < result.rotationGames.length, true);
  assert.equal(result.count <= liveFavoriteRotation.MAX_ROTATION_ITEMS, true);
});

test("countdown projection returns future and due states for normalized favorite games", () => {
  const fixture = readCountdownFixture();
  const normalized = fixture.games.map((game) => games.normalizeGame(game));
  const base = {
    todayDateKey: fixture.todayDateKey,
    selectedDateKey: fixture.selectedDateKey,
    nowMs: Date.parse(fixture.now),
    favoriteTeamIds: fixture.favoriteTeamIds,
    hasData: true
  };
  const future = countdownProjection.project(Object.assign({}, base, {
    game: normalized[0]
  }));
  assert.equal(future.kind, "future");
  assert.equal(future.reason, "favorite-upcoming");
  assert.equal(future.game.id, "nhl:201");
  assert.equal(future.todayDateKey, fixture.todayDateKey);
  assert.equal(future.selectedDateKey, fixture.todayDateKey);
  assert.equal(future.remainingMs, 3.5 * 60 * 60 * 1000);
  assert.equal(future.label, "Starts in 3h 30m");

  const due = countdownProjection.project(Object.assign({}, base, {
    game: normalized[1],
    startTimeMs: Date.parse("2026-10-08T14:00:00Z")
  }));
  assert.equal(due.kind, "due");
  assert.equal(due.remainingMs, 0);
  assert.equal(due.label, "Starting now");
});

test("countdown projection fails closed for invalid, non-favorite, and non-today inputs", () => {
  const fixture = readCountdownFixture();
  const normalized = fixture.games.map((game) => games.normalizeGame(game));
  const base = {
    todayDateKey: fixture.todayDateKey,
    selectedDateKey: fixture.selectedDateKey,
    nowMs: Date.parse(fixture.now),
    favoriteTeamIds: fixture.favoriteTeamIds,
    hasData: true
  };
  const invalid = countdownProjection.project(Object.assign({}, base, {
    game: normalized[2]
  }));
  assert.equal(invalid.kind, "invalid");
  assert.equal(invalid.reason, "invalid-start-time");
  assert.equal(invalid.game, null);

  const nonFavorite = countdownProjection.project(Object.assign({}, base, {
    game: normalized[3],
    favoriteTeamIds: ["nhl:6"]
  }));
  assert.equal(nonFavorite.kind, "empty");
  assert.equal(nonFavorite.reason, "no-upcoming-favorite");

  const nonToday = countdownProjection.project(Object.assign({}, base, {
    selectedDateKey: "2026-10-07",
    game: normalized[0]
  }));
  assert.equal(nonToday.kind, "not-today");
  assert.equal(nonToday.reason, "today-scope");
  assert.equal(nonToday.todayDateKey, fixture.todayDateKey);
  assert.equal(nonToday.selectedDateKey, "2026-10-07");
});

test("countdown projection preserves bounded empty and offline states", () => {
  const fixture = readCountdownFixture();
  const base = {
    todayDateKey: fixture.todayDateKey,
    selectedDateKey: fixture.selectedDateKey,
    nowMs: Date.parse(fixture.now),
    favoriteTeamIds: fixture.favoriteTeamIds
  };
  const empty = countdownProjection.project(Object.assign({}, base, fixture.empty));
  assert.equal(empty.kind, "empty");
  assert.equal(empty.reason, "no-upcoming-favorite");
  assert.equal(empty.todayDateKey, fixture.todayDateKey);
  assert.equal(empty.label.length <= countdownProjection.MAX_LABEL_LENGTH, true);

  const offline = countdownProjection.project(Object.assign({}, base, fixture.offline));
  assert.equal(offline.kind, "offline");
  assert.equal(offline.reason, "unavailable");
  assert.equal(offline.todayDateKey, fixture.todayDateKey);
  assert.equal(offline.label, "Scores offline");
});

test("countdown projection bounds caller-visible text and uses supplied timestamps", () => {
  const fixture = readCountdownFixture();
  const normalized = fixture.games.map((game) => games.normalizeGame(game));
  const result = countdownProjection.project({
    todayDateKey: fixture.todayDateKey,
    selectedDateKey: fixture.selectedDateKey,
    nowMs: Date.parse(fixture.now),
    startTimeMs: Date.parse("2026-10-08T17:30:00Z"),
    maxLabelLength: Number.MAX_SAFE_INTEGER,
    favoriteTeamIds: fixture.favoriteTeamIds,
    hasData: true,
    game: normalized[0]
  });
  assert.equal(result.startTimeMs, Date.parse("2026-10-08T17:30:00Z"));
  assert.equal(result.nowMs, Date.parse(fixture.now));
  assert.equal(result.label.length <= countdownProjection.MAX_LABEL_LENGTH, true);
  assert.equal(result.label, "Starts in 3h 30m");

  const shortened = countdownProjection.project({
    todayDateKey: fixture.todayDateKey,
    selectedDateKey: fixture.selectedDateKey,
    nowMs: Date.parse(fixture.now),
    maxLabelLength: 8,
    favoriteTeamIds: fixture.favoriteTeamIds,
    hasData: true,
    game: normalized[0]
  });
  assert.equal(shortened.label, "Starts…");
  assert.equal(shortened.label.length <= 8, true);
});

test("calendar composes the bounded date window and filters enabled leagues", () => {
  const fixture = readCalendarFixture();
  const calendar = calendarModel.compose(fixture.windows, {
    enabledLeagues: fixture.enabledLeagues,
    favoriteTeamIds: fixture.favoriteTeamIds,
    centerDateKey: fixture.centerDateKey,
    halfWidth: fixture.halfWidth,
    orderer: presentation.orderGames,
    matcher: presentation.isFavoriteGame
  });

  assert.equal(calendar.kind, "calendar");
  assert.deepEqual(calendar.days.map((day) => day.dateKey), fixture.expected.dayKeys);
  assert.equal(calendar.days.every((day) => typeof day.label === "string" && day.label !== ""), true);
  assert.equal(calendar.gameCount, 5);
  assert.equal(calendar.hasGames, true);

  const day24 = calendar.days.find((day) => day.dateKey === "2026-08-24");
  assert.deepEqual(day24.games.map((game) => game.id), fixture.expected.orderedDay24Ids);

  // The disabled NFL window, outside-window dates, malformed day keys, and
  // invalid records never widen the projection.
  const allIds = calendar.days.flatMap((day) => day.games.map((game) => game.id));
  assert.equal(allIds.includes("nfl:cal-disabled-league"), false);
  assert.equal(allIds.includes("nhl:cal-outside-window"), false);
  assert.equal(allIds.includes("nhl:cal-malformed-day"), false);
  assert.equal(allIds.includes("mlb:cal-empty-league-id"), false);
});

test("calendar followed-team filter keeps only favorite games", () => {
  const fixture = readCalendarFixture();
  const base = {
    enabledLeagues: fixture.enabledLeagues,
    favoriteTeamIds: fixture.favoriteTeamIds,
    centerDateKey: fixture.centerDateKey,
    halfWidth: fixture.halfWidth,
    favoritesOnly: true,
    orderer: presentation.orderGames,
    matcher: presentation.isFavoriteGame
  };
  const filtered = calendarModel.compose(fixture.windows, base);
  assert.equal(filtered.favoritesOnly, true);
  assert.deepEqual(
    ["2026-08-22", "2026-08-24", "2026-08-26"].map((dateKey) => {
      return filtered.days.find((day) => day.dateKey === dateKey).games.map((game) => game.id);
    }),
    fixture.expected.favoritesOnlyDay22And24And26Ids
  );
  assert.equal(filtered.gameCount, 3);
  assert.equal(filtered.hasGames, true);
});

test("calendar chronological fallback, clamps, and malformed input fail closed", () => {
  const fixture = readCalendarFixture();
  const chronological = calendarModel.compose(fixture.windows, {
    enabledLeagues: fixture.enabledLeagues,
    favoriteTeamIds: [],
    centerDateKey: fixture.centerDateKey,
    halfWidth: fixture.halfWidth
  });
  const day24 = chronological.days.find((day) => day.dateKey === "2026-08-24");
  assert.deepEqual(day24.games.map((game) => game.id), fixture.expected.chronologicalDay24Ids);

  const clamped = calendarModel.compose([{
    leagueId: "nhl",
    displayName: "NHL",
    days: [{dateKey: "2026-08-17", games: []}, {dateKey: "2026-08-31", games: []}]
  }], {
    enabledLeagues: ["nhl"],
    favoriteTeamIds: [],
    centerDateKey: "2026-08-24",
    halfWidth: 30
  });
  assert.equal(clamped.halfWidth, calendarModel.MAX_HALF_WIDTH_DAYS);
  assert.deepEqual(clamped.days[0].dateKey, "2026-08-17");
  assert.deepEqual(clamped.days[clamped.days.length - 1].dateKey, "2026-08-31");

  const invalidCenter = calendarModel.compose(fixture.windows, {
    enabledLeagues: fixture.enabledLeagues,
    favoriteTeamIds: [],
    centerDateKey: "not-a-date"
  });
  assert.deepEqual(invalidCenter.days, []);
  assert.equal(invalidCenter.hasGames, false);

  [null, undefined, "calendar", 42].forEach((input) => {
    const safe = calendarModel.compose(input, {centerDateKey: "2026-08-24"});
    assert.equal(safe.hasGames, false);
  });

  const oversized = Array.from({length: calendarModel.MAX_GAMES_PER_DAY + 8}, (_, index) => ({
    id: "nhl:bulk-" + index,
    league: "nhl",
    isValid: true,
    status: "scheduled",
    startTime: "2026-08-24T18:" + String(index % 60).padStart(2, "0")
      + ":" + String(index % 60).padStart(2, "0") + ".000Z",
    awayTeam: {id: "nhl:6"},
    homeTeam: {id: "nhl:10"}
  }));
  const bounded = calendarModel.compose([{
    leagueId: "nhl",
    days: [{dateKey: "2026-08-24", games: oversized}]
  }], {enabledLeagues: ["nhl"], favoriteTeamIds: [], centerDateKey: "2026-08-24"});
  assert.equal(bounded.days.find((day) => day.dateKey === "2026-08-24").games.length,
    calendarModel.MAX_GAMES_PER_DAY);
});

test("calendar flatten reuses scoreboard row vocabulary for the panel list", () => {
  const fixture = readCalendarFixture();
  const rows = calendarModel.flatten(calendarModel.compose(fixture.windows, {
    enabledLeagues: fixture.enabledLeagues,
    favoriteTeamIds: fixture.favoriteTeamIds,
    centerDateKey: fixture.centerDateKey,
    halfWidth: fixture.halfWidth,
    orderer: presentation.orderGames,
    matcher: presentation.isFavoriteGame
  }));

  const headerRows = rows.filter((row) => row.kind === "section-header");
  assert.equal(headerRows.length, 5);
  assert.equal(headerRows.every((row) => row.rowId.startsWith("section:calendar:")), true);
  const emptyRows = rows.filter((row) => row.kind === "empty" && row.text === "No games");
  assert.equal(emptyRows.length, 2);
  const gameRows = rows.filter((row) => row.kind === "game");
  assert.equal(gameRows.length, 5);
  assert.equal(gameRows.every((row) => row.action.type === "open-detail"
    && row.action.enabled === true), true);
  assert.equal(new Set(rows.map((row) => row.rowId)).size, rows.length);
  assert.equal(gameRows.every((row) => row.game.presentation
    && typeof row.game.presentation.leagueLabel === "string"), false);

  assert.deepEqual(calendarModel.flatten(null), []);
  assert.deepEqual(calendarModel.flatten({}), []);
});

test("calendar projection adds no new fetch ownership or provider parsing", () => {
  const fetchService = readSource("services/FetchService.qml");
  const leagueFetch = readSource("services/LeagueFetch.qml");
  const panel = readSource("Panel.qml");
  const model = readSource("model/CalendarModel.js");

  // The calendar path reads existing caches only: no new curl invocations,
  // no new Process objects, and no new polling owner.
  assert.equal(fetchService.includes("function buildCalendarStates()"), true);
  assert.equal(fetchService.includes("calendarSnapshot()"), true);
  assert.equal((leagueFetch.match(/Process \{/g) || []).length, 2);
  assert.equal((fetchService.match(/curl/g) || []).length, 0);
  assert.equal(model.includes("curl"), false);
  assert.equal(model.includes("Process"), false);
  assert.equal(model.includes("Timer"), false);
  assert.equal(model.includes("JSON.parse"), false);

  // Panel mounts it behind a minimal entry point without touching the
  // ambient bar state or notification graph.
  assert.equal(panel.includes("readonly property var calendarRows: CalendarModel.flatten(root.calendarState)"), true);
  assert.equal(panel.includes("root.calendarOpen ? root.calendarRows : root.resultRows"), true);
  assert.equal(panel.includes("root.fetchService ? root.fetchService.calendarStates : []"), true);
  assert.equal(panel.includes(": root.calendarOpen ? root.closeCalendar() : root.close()"), true);
  assert.equal(panel.includes('root.toggleCalendar()'), true);
  assert.equal(panel.includes('root.toggleCalendarFilter()'), true);
});

test("provider fallback retains a healthy primary for its league chain", () => {
  const fixture = readProviderFallbackFixture();
  const result = providerFallback.evaluate({
    leagueId: fixture.leagueId,
    candidates: fixture.candidates,
    nowMs: Date.parse(fixture.now),
    health: fixture.healthyPrimary.health,
    currentProviderId: fixture.healthyPrimary.currentProviderId
  });
  assert.equal(result.kind, "primary");
  assert.equal(result.reason, "next-healthy");
  assert.equal(result.providerId, "espn");
  assert.equal(result.index, 0);
  assert.deepEqual(result.attempted, []);
  assert.equal(result.leagueId, "nhl");
  assert.deepEqual(providerFallback.evaluate(null).kind, "invalid");
});

test("provider fallback advances past a failed primary within its cooldown", () => {
  const fixture = readProviderFallbackFixture();
  const nowMs = Date.parse(fixture.now);
  const result = providerFallback.evaluate({
    leagueId: fixture.leagueId,
    candidates: fixture.candidates,
    nowMs: nowMs,
    health: fixture.failingPrimary.health,
    currentProviderId: fixture.failingPrimary.currentProviderId
  });
  assert.equal(result.kind, "fallback");
  assert.equal(result.providerId, "nhl");
  assert.equal(result.index, 1);
  assert.deepEqual(result.attempted, ["espn"]);

  const state = fixture.failingPrimary.health.espn;
  assert.equal(providerFallback.isCoolingDown(state, nowMs), true);
  assert.equal(
    providerFallback.isCoolingDown(
      {consecutiveFailures: providerFallback.FAILURE_THRESHOLD - 1,
        lastFailureAtMs: Date.parse(state.lastFailureAtMs)}, nowMs),
    false);
});

test("provider fallback recovers to the primary after success or cooldown expiry", () => {
  const fixture = readProviderFallbackFixture();
  const nowMs = Date.parse(fixture.now);

  // Caller-supplied success bookkeeping clears the primary's failures.
  let health = {};
  for (let i = 0; i < providerFallback.FAILURE_THRESHOLD + 2; i++)
    health = providerFallback.recordFailure(health, "espn", nowMs);
  assert.equal(health.espn.consecutiveFailures, providerFallback.FAILURE_THRESHOLD);
  health = providerFallback.recordSuccess(health, "espn");
  assert.equal(health.espn, undefined);

  const recovered = providerFallback.evaluate({
    leagueId: fixture.leagueId,
    candidates: fixture.candidates,
    nowMs: nowMs,
    health: fixture.recoveredPrimary.health,
    currentProviderId: fixture.recoveredPrimary.currentProviderId
  });
  assert.equal(recovered.kind, "current");
  assert.equal(recovered.reason, "current-healthy");
  assert.equal(recovered.providerId, "espn");

  // A cooled-down primary becomes retryable ahead of the fallback again.
  const expired = providerFallback.evaluate({
    leagueId: fixture.leagueId,
    candidates: fixture.candidates,
    nowMs: nowMs,
    health: fixture.coolingExpired.health,
    currentProviderId: fixture.coolingExpired.currentProviderId
  });
  assert.equal(expired.kind, "fallback");
  assert.equal(expired.providerId, "espn");
  assert.equal(expired.index, 0);
});

test("provider fallback fails closed on malformed chains and unknown callers", () => {
  const fixture = readProviderFallbackFixture();
  const cases = [
    [fixture.malformed.badLeague, "league-id"],
    [fixture.malformed.emptyCandidates, "candidates"],
    [fixture.malformed.duplicateCandidates, "candidates"],
    [fixture.malformed.overBoundCandidates, "candidates"],
    [fixture.malformed.nonStringCandidate, "candidates"],
    [Object.assign({nowMs: Date.parse(fixture.now)},
      fixture.malformed.unknownCurrent), "current-provider-id"],
    [{leagueId: fixture.leagueId, candidates: fixture.candidates}, "now-ms"],
    [{leagueId: fixture.leagueId, candidates: fixture.candidates,
      nowMs: Number.NaN}, "now-ms"]
  ];
  cases.forEach(([input, reason]) => {
    const result = providerFallback.evaluate(input);
    assert.equal(result.kind, "invalid");
    assert.equal(result.reason, reason);
    assert.equal(result.providerId, null);
    assert.equal(result.index, -1);
  });
});

test("provider fallback reports bounded exhaustion when every candidate cools", () => {
  const fixture = readProviderFallbackFixture();
  const result = providerFallback.evaluate({
    leagueId: fixture.leagueId,
    candidates: fixture.candidates,
    nowMs: Date.parse(fixture.now),
    health: fixture.exhausted.health,
    currentProviderId: fixture.exhausted.currentProviderId
  });
  assert.equal(result.kind, "exhausted");
  assert.equal(result.reason, "all-providers-cooling");
  assert.equal(result.providerId, null);
  assert.equal(result.index, -1);
  assert.deepEqual(result.attempted, ["espn", "nhl"]);
  assert.equal(result.cooldownMs, providerFallback.COOLDOWN_MS);

  // The pure policy stays free of timers, requests, and provider parsing.
  const source = readSource("model/ProviderFallbackPolicy.js");
  assert.equal(source.includes("Timer"), false);
  assert.equal(source.includes("curl"), false);
  assert.equal(source.includes("Date.now"), false);
  assert.equal(source.includes("JSON.parse"), false);
  assert.equal(source.includes("require("), false);
});

process.stdout.write("M2.1, M2.2, M3.1, M3.2, M3.3, M4.1, M4.2, M4.3, M5.1, M5.2, M5.3, M6.1, M6.2, M6.3, M10.1, M10.2, M10.3, and M10.4 JavaScript fixtures passed.\n");

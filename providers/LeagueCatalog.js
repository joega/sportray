var NHL = {
  id: "nhl",
  name: "NHL",
  displayName: "NHL",
  enabledByDefault: true,
  provider: "nhl",
  standingsSupported: true
};

var ESPN_LEAGUE_METADATA = {
  nfl: {id: "nfl", name: "NFL", displayName: "NFL", enabledByDefault: false,
    provider: "espn", sport: "football", slug: "nfl", standingsSupported: true},
  mlb: {id: "mlb", name: "MLB", displayName: "MLB", enabledByDefault: false,
    provider: "espn", sport: "baseball", slug: "mlb", standingsSupported: true},
  nba: {id: "nba", name: "NBA", displayName: "NBA", enabledByDefault: false,
    provider: "espn", sport: "basketball", slug: "nba", standingsSupported: true},
  "college-football": {id: "college-football", name: "NCAA Football",
    displayName: "NCAA Football", enabledByDefault: false,
    provider: "espn", sport: "football", slug: "college-football", standingsSupported: true},
  "eng.1": {id: "eng.1", name: "Premier League",
    displayName: "Premier League", enabledByDefault: false,
    provider: "espn", sport: "soccer", slug: "eng.1", standingsSupported: true},
  "usa.1": {id: "usa.1", name: "MLS", displayName: "MLS", enabledByDefault: false,
    provider: "espn", sport: "soccer", slug: "usa.1", standingsSupported: true},
  "mens-college-basketball": {id: "mens-college-basketball", name: "NCAA Men's Basketball",
    displayName: "NCAA Men's Basketball", enabledByDefault: false,
    provider: "espn", sport: "basketball", slug: "mens-college-basketball", standingsSupported: true}
};

var NFL = ESPN_LEAGUE_METADATA.nfl;
var MLB = ESPN_LEAGUE_METADATA.mlb;
var NBA = ESPN_LEAGUE_METADATA.nba;
var NCAA_FOOTBALL = ESPN_LEAGUE_METADATA["college-football"];
var PREMIER_LEAGUE = ESPN_LEAGUE_METADATA["eng.1"];
var MLS = ESPN_LEAGUE_METADATA["usa.1"];
var NCAA_MENS_BASKETBALL = ESPN_LEAGUE_METADATA["mens-college-basketball"];

var LEAGUES = {
  nhl: NHL,
  nfl: NFL,
  mlb: MLB,
  nba: NBA,
  "college-football": NCAA_FOOTBALL,
  "eng.1": PREMIER_LEAGUE,
  "usa.1": MLS,
  "mens-college-basketball": NCAA_MENS_BASKETBALL
};

var ALL_LEAGUES = [NHL, NFL, MLB, NBA, NCAA_FOOTBALL, PREMIER_LEAGUE, MLS,
  NCAA_MENS_BASKETBALL];

function listLeagues() {
  return ALL_LEAGUES.slice();
}

function getLeague(leagueId) {
  var normalized = normalizeLeagueId(leagueId);
  return normalized && LEAGUES[normalized] ? LEAGUES[normalized] : null;
}

function normalizeLeagueId(leagueId) {
  if (typeof leagueId !== "string") return null;
  var value = leagueId.trim().toLowerCase();
  return value || null;
}

function defaultLeagueIds() {
  return listLeagues().filter(function(league) {
    return league.enabledByDefault;
  }).map(function(league) {
    return league.id;
  });
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    NHL: NHL,
    NFL: NFL,
    MLB: MLB,
    NBA: NBA,
    NCAA_FOOTBALL: NCAA_FOOTBALL,
    PREMIER_LEAGUE: PREMIER_LEAGUE,
    MLS: MLS,
    NCAA_MENS_BASKETBALL: NCAA_MENS_BASKETBALL,
    ESPN_LEAGUE_METADATA: ESPN_LEAGUE_METADATA,
    LEAGUES: LEAGUES,
    ALL_LEAGUES: ALL_LEAGUES,
    listLeagues: listLeagues,
    getLeague: getLeague,
    normalizeLeagueId: normalizeLeagueId,
    defaultLeagueIds: defaultLeagueIds
  };
}

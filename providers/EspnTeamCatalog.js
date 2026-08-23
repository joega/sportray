// ESPN has no versioned team-catalog contract. Keep bounded reviewed snapshots
// here, and use the scoreboard payload only as a source of provider IDs for
// normalized games. Logos stay optional so the picker remains usable offline.
var TeamModel = requireTeamModel();
var AssetUrlPolicy = null;
if (typeof require === "function") AssetUrlPolicy = require("../model/AssetUrlPolicy.js");
var ESPN_TEAM_BASE_URL = "https://site.api.espn.com/apis/site/v2/sports";

var CURRENT_TEAMS = {
  nfl: [
    [1, "ATL", "Atlanta Falcons"], [2, "BUF", "Buffalo Bills"],
    [3, "CIN", "Cincinnati Bengals"], [4, "CLE", "Cleveland Browns"],
    [5, "DAL", "Dallas Cowboys"], [6, "CHI", "Chicago Bears"],
    [7, "SEA", "Seattle Seahawks"], [8, "DET", "Detroit Lions"],
    [9, "GB", "Green Bay Packers"], [10, "TEN", "Tennessee Titans"],
    [11, "IND", "Indianapolis Colts"], [12, "KC", "Kansas City Chiefs"],
    [13, "LV", "Las Vegas Raiders"], [14, "LAC", "Los Angeles Chargers"],
    [15, "MIA", "Miami Dolphins"], [16, "MIN", "Minnesota Vikings"],
    [17, "NE", "New England Patriots"], [18, "NO", "New Orleans Saints"],
    [19, "LAR", "Los Angeles Rams"], [20, "DEN", "Denver Broncos"],
    [21, "TB", "Tampa Bay Buccaneers"], [22, "ARI", "Arizona Cardinals"],
    [23, "PIT", "Pittsburgh Steelers"], [24, "SF", "San Francisco 49ers"],
    [25, "NYG", "New York Giants"], [26, "NYJ", "New York Jets"],
    [27, "PHI", "Philadelphia Eagles"], [28, "WSH", "Washington Commanders"],
    [29, "CAR", "Carolina Panthers"], [30, "JAX", "Jacksonville Jaguars"],
    [33, "BAL", "Baltimore Ravens"], [34, "HOU", "Houston Texans"]
  ],
  mlb: [
    [29, "ARI", "Arizona Diamondbacks"], [11, "ATH", "Athletics"],
    [8, "ATL", "Atlanta Braves"], [1, "BAL", "Baltimore Orioles"],
    [2, "BOS", "Boston Red Sox"], [16, "CHC", "Chicago Cubs"],
    [4, "CHW", "Chicago White Sox"], [17, "CIN", "Cincinnati Reds"],
    [5, "CLE", "Cleveland Guardians"], [27, "COL", "Colorado Rockies"],
    [3, "DET", "Detroit Tigers"], [18, "HOU", "Houston Astros"],
    [7, "KC", "Kansas City Royals"], [22, "LAA", "Los Angeles Angels"],
    [19, "LAD", "Los Angeles Dodgers"], [6, "MIA", "Miami Marlins"],
    [15, "MIL", "Milwaukee Brewers"], [24, "MIN", "Minnesota Twins"],
    [21, "NYM", "New York Mets"], [10, "NYY", "New York Yankees"],
    [26, "PHI", "Philadelphia Phillies"], [23, "PIT", "Pittsburgh Pirates"],
    [25, "SD", "San Diego Padres"], [12, "SEA", "Seattle Mariners"],
    [30, "SF", "San Francisco Giants"], [28, "STL", "St. Louis Cardinals"],
    [9, "TB", "Tampa Bay Rays"], [13, "TEX", "Texas Rangers"],
    [14, "TOR", "Toronto Blue Jays"], [20, "WSH", "Washington Nationals"]
  ],
  nba: [
    [30, "CHA", "Charlotte Hornets"], [2, "BOS", "Boston Celtics"],
    [4, "CHI", "Chicago Bulls"], [5, "CLE", "Cleveland Cavaliers"],
    [6, "DAL", "Dallas Mavericks"], [7, "DEN", "Denver Nuggets"],
    [8, "DET", "Detroit Pistons"], [1, "ATL", "Atlanta Hawks"],
    [10, "HOU", "Houston Rockets"], [11, "IND", "Indiana Pacers"],
    [12, "LAC", "Los Angeles Clippers"], [13, "LAL", "Los Angeles Lakers"],
    [14, "MIA", "Miami Heat"], [15, "MIL", "Milwaukee Bucks"],
    [16, "MIN", "Minnesota Timberwolves"], [17, "BKN", "Brooklyn Nets"],
    [18, "ORL", "Orlando Magic"], [19, "PHI", "Philadelphia 76ers"],
    [20, "NY", "New York Knicks"], [21, "PHX", "Phoenix Suns"],
    [22, "POR", "Portland Trail Blazers"], [23, "SAC", "Sacramento Kings"],
    [25, "OKC", "Oklahoma City Thunder"],
    [26, "UTA", "Utah Jazz"], [27, "WAS", "Washington Wizards"],
    [28, "TOR", "Toronto Raptors"], [29, "MEM", "Memphis Grizzlies"],
    [9, "GS", "Golden State Warriors"], [3, "NOP", "New Orleans Pelicans"],
    [24, "SAS", "San Antonio Spurs"]
  ],
  // ESPN exposes 759 NCAA records, including lower-division and historical
  // entries. Keep the picker bounded to a reviewed FBS-focused catalog and
  // retain the endpoint parser below for future catalog refreshes.
  "college-football": [
    [333, "ALA", "Alabama Crimson Tide"], [8, "ARK", "Arkansas Razorbacks"],
    [2, "AUB", "Auburn Tigers"], [239, "BAY", "Baylor Bears"],
    [103, "BC", "Boston College Eagles"], [228, "CLEM", "Clemson Tigers"],
    [38, "COLO", "Colorado Buffaloes"], [150, "DUKE", "Duke Blue Devils"],
    [57, "FLA", "Florida Gators"], [52, "FSU", "Florida State Seminoles"],
    [61, "UGA", "Georgia Bulldogs"], [2294, "IOWA", "Iowa Hawkeyes"],
    [2305, "KU", "Kansas Jayhawks"], [2306, "KSU", "Kansas State Wildcats"],
    [96, "UK", "Kentucky Wildcats"], [99, "LSU", "LSU Tigers"],
    [97, "LOU", "Louisville Cardinals"], [2390, "MIA", "Miami Hurricanes"],
    [130, "MICH", "Michigan Wolverines"], [142, "MIZ", "Missouri Tigers"],
    [152, "NCSU", "NC State Wolfpack"], [153, "UNC", "North Carolina Tar Heels"],
    [87, "ND", "Notre Dame Fighting Irish"], [194, "OSU", "Ohio State Buckeyes"],
    [201, "OU", "Oklahoma Sooners"], [197, "OKST", "Oklahoma State Cowboys"],
    [2483, "ORE", "Oregon Ducks"], [213, "PSU", "Penn State Nittany Lions"],
    [221, "PITT", "Pittsburgh Panthers"], [2579, "SC", "South Carolina Gamecocks"],
    [183, "SYR", "Syracuse Orange"], [2628, "TCU", "TCU Horned Frogs"],
    [2633, "TENN", "Tennessee Volunteers"], [245, "TA&M", "Texas A&M Aggies"],
    [251, "TEX", "Texas Longhorns"], [2641, "TTU", "Texas Tech Red Raiders"],
    [26, "UCLA", "UCLA Bruins"], [30, "USC", "USC Trojans"],
    [254, "UTAH", "Utah Utes"], [258, "UVA", "Virginia Cavaliers"],
    [259, "VT", "Virginia Tech Hokies"], [154, "WAKE", "Wake Forest Demon Deacons"],
    [264, "WASH", "Washington Huskies"], [277, "WVU", "West Virginia Mountaineers"],
    [275, "WIS", "Wisconsin Badgers"]
  ],
  // The current no-key ESPN team endpoint returns 20 records for the 2026-27
  // route. Keep that bounded current-season snapshot provider-owned; endpoint
  // records are filtered through it before any normalized team reaches QML.
  "eng.1": [
    [349, "BOU", "AFC Bournemouth"], [359, "ARS", "Arsenal"],
    [362, "AVL", "Aston Villa"], [337, "BRE", "Brentford"],
    [331, "BHA", "Brighton & Hove Albion"], [363, "CHE", "Chelsea"],
    [388, "COV", "Coventry City"], [384, "CRY", "Crystal Palace"],
    [368, "EVE", "Everton"], [370, "FUL", "Fulham"],
    [306, "HUL", "Hull City"], [373, "IPS", "Ipswich Town"],
    [357, "LEE", "Leeds United"], [364, "LIV", "Liverpool"],
    [382, "MNC", "Manchester City"], [360, "MAN", "Manchester United"],
    [361, "NEW", "Newcastle United"], [393, "NFO", "Nottingham Forest"],
    [366, "SUN", "Sunderland"], [367, "TOT", "Tottenham Hotspur"]
  ],
  // The current no-key MLS endpoint returns 30 records. Keep this reviewed
  // roster provider-owned so favorite identities remain stable when ESPN's
  // undocumented catalog response changes.
  "usa.1": [
    [18418, "ATL", "Atlanta United FC"], [20906, "ATX", "Austin FC"],
    [9720, "MTL", "CF Montréal"], [21300, "CLT", "Charlotte FC"],
    [182, "CHI", "Chicago Fire FC"], [184, "COL", "Colorado Rapids"],
    [183, "CLB", "Columbus Crew"], [193, "DC", "D.C. United"],
    [18267, "CIN", "FC Cincinnati"], [185, "DAL", "FC Dallas"],
    [6077, "HOU", "Houston Dynamo FC"], [20232, "MIA", "Inter Miami CF"],
    [187, "LA", "LA Galaxy"], [18966, "LAFC", "LAFC"],
    [17362, "MIN", "Minnesota United FC"], [18986, "NSH", "Nashville SC"],
    [189, "NE", "New England Revolution"], [17606, "NYC", "New York City FC"],
    [12011, "ORL", "Orlando City SC"], [10739, "PHI", "Philadelphia Union"],
    [9723, "POR", "Portland Timbers"], [4771, "RSL", "Real Salt Lake"],
    [190, "RBNY", "Red Bull New York"], [22529, "SD", "San Diego FC"],
    [191, "SJ", "San Jose Earthquakes"], [9726, "SEA", "Seattle Sounders FC"],
    [186, "SKC", "Sporting Kansas City"], [21812, "STL", "St. Louis CITY SC"],
    [7318, "TOR", "Toronto FC"], [9727, "VAN", "Vancouver Whitecaps"]
  ],
  // The 2026-08-18 no-key route returned 50 current records during the
  // off-season. Keep that reviewed snapshot provider-owned so the picker is
  // bounded and canonical favorite IDs remain stable between refreshes.
  "mens-college-basketball": [
    [44, "AMER", "American University Eagles"], [9, "ASU", "Arizona State Sun Devils"],
    [12, "ARIZ", "Arizona Wildcats"], [8, "ARK", "Arkansas Razorbacks"],
    [2, "AUB", "Auburn Tigers"], [91, "BELL", "Bellarmine Knights"],
    [68, "BOIS", "Boise State Broncos"], [71, "BRAD", "Bradley Braves"],
    [13, "CP", "Cal Poly Mustangs"], [25, "CAL", "California Golden Bears"],
    [38, "COLO", "Colorado Buffaloes"], [36, "CSU", "Colorado State Rams"],
    [48, "DEL", "Delaware Blue Hens"], [50, "FAMU", "Florida A&M Rattlers"],
    [57, "FLA", "Florida Gators"], [52, "FSU", "Florida State Seminoles"],
    [45, "GW", "George Washington Revolutionaries"], [46, "GTWN", "Georgetown Hoyas"],
    [61, "UGA", "Georgia Bulldogs"], [59, "GT", "Georgia Tech Yellow Jackets"],
    [62, "HAW", "Hawai'i Rainbow Warriors"], [47, "HOW", "Howard Bison"],
    [85, "IUIN", "IU Indianapolis Jaguars"], [70, "IDHO", "Idaho Vandals"],
    [84, "IU", "Indiana Hoosiers"], [66, "ISU", "Iowa State Cyclones"],
    [55, "JXST", "Jacksonville State Gamecocks"], [96, "UK", "Kentucky Wildcats"],
    [97, "LOU", "Louisville Cardinals"], [93, "MUR", "Murray State Racers"],
    [94, "NKU", "Northern Kentucky Norse"], [77, "NU", "Northwestern Wildcats"],
    [87, "ND", "Notre Dame Fighting Irish"], [16, "SAC", "Sacramento State Hornets"],
    [21, "SDSU", "San Diego State Aztecs"], [23, "SJSU", "San José State Spartans"],
    [6, "USA", "South Alabama Jaguars"], [58, "USF", "South Florida Bulls"],
    [79, "SIU", "Southern Illinois Salukis"], [24, "STAN", "Stanford Cardinal"],
    [56, "STET", "Stetson Hatters"], [5, "UAB", "UAB Blazers"],
    [27, "UCR", "UC Riverside Highlanders"], [28, "UCSD", "UC San Diego Tritons"],
    [26, "UCLA", "UCLA Bruins"], [41, "CONN", "UConn Huskies"],
    [82, "UIC", "UIC Flames"], [30, "USC", "USC Trojans"],
    [98, "WKU", "Western Kentucky Hilltoppers"], [43, "YALE", "Yale Bulldogs"]
  ]
};

function buildTeamCatalogUrl(leagueId) {
  var league = normalizeLeague(leagueId);
  if (!league) return null;
  var sport = league === "eng.1" || league === "usa.1" ? "soccer"
    : league === "mlb" ? "baseball"
    : league === "nfl" || league === "college-football" ? "football" : "basketball";
  var slug = league;
  return ESPN_TEAM_BASE_URL + "/" + sport + "/" + slug + "/teams";
}

function requireTeamModel() {
  if (typeof module !== "undefined" && module.require)
    return module.require("../model/TeamModel.js");
  return {normalizeTeam: normalizeTeamFallback};
}

function normalizeTeamFallback(input) {
  if (!input || typeof input !== "object" || Array.isArray(input)) return null;
  var league = typeof input.league === "string" ? input.league.trim().toLowerCase() : "";
  var providerTeamId = input.providerTeamId === undefined || input.providerTeamId === null
    ? "" : String(input.providerTeamId).trim();
  if (!league || !providerTeamId) return null;
  function clean(value) {
    if (typeof value !== "string") return null;
    var result = value.trim();
    return result || null;
  }
  function url(value) {
    var result = clean(value);
    return result && /^https?:\/\//i.test(result) ? result : null;
  }
  function logoUrl(value) {
    if (AssetUrlPolicy) return AssetUrlPolicy.safeLogoUrl(value);

    var result = clean(value);
    if (!result || !/^https:\/\//i.test(result)) return null;
    var match = /^https:\/\/([^/?#]+)(?:[/?#]|$)/i.exec(result);
    if (!match || match[1].toLowerCase() !== "a.espncdn.com") return null;
    return result;
  }
  return {
    id: league + ":" + providerTeamId,
    league: league,
    providerTeamId: providerTeamId,
    name: clean(input.name),
    shortName: clean(input.shortName),
    abbreviation: clean(input.abbreviation),
    primaryColor: null,
    logoUrl: logoUrl(input.logoUrl),
    link: url(input.link)
  };
}

function normalizeLeague(leagueId) {
  if (typeof leagueId !== "string") return null;
  var value = leagueId.trim().toLowerCase();
  return CURRENT_TEAMS[value] ? value : null;
}

function sortTeams(left, right) {
  return String(left.name || left.abbreviation || left.id)
    .localeCompare(String(right.name || right.abbreviation || right.id));
}

function teamFromRecord(record, leagueId) {
  if (!record || typeof record !== "object" || Array.isArray(record)) return null;
  var league = normalizeLeague(leagueId);
  if (!league) return null;
  var team = record.team && typeof record.team === "object" ? record.team : record;
  var id = team.id === undefined || team.id === null ? "" : String(team.id).trim();
  if (!id || !CURRENT_TEAMS[league].some(function(entry) { return String(entry[0]) === id; }))
    return null;
  var name = team.displayName || team.name;
  var abbreviation = team.abbreviation;
  if (typeof name !== "string" || !name.trim()
      || typeof abbreviation !== "string" || !abbreviation.trim()) return null;
  return TeamModel.normalizeTeam({
    league: league,
    providerTeamId: id,
    name: name,
    shortName: team.shortDisplayName || name,
    abbreviation: abbreviation,
    primaryColor: team.color,
    logoUrl: team.logo,
    link: null
  });
}

function listTeams(leagueId) {
  var league = normalizeLeague(leagueId);
  if (!league) return [];
  return CURRENT_TEAMS[league].map(function(entry) {
    return TeamModel.normalizeTeam({
      league: league,
      providerTeamId: String(entry[0]),
      name: entry[2],
      shortName: entry[2],
      abbreviation: entry[1],
      logoUrl: null,
      link: null
    });
  }).sort(sortTeams);
}

function listTeamsForLeagues(leagueIds) {
  if (!Array.isArray(leagueIds)) return [];
  var out = [];
  for (var i = 0; i < leagueIds.length; i++) out = out.concat(listTeams(leagueIds[i]));
  return out;
}

function responseRecords(payload) {
  if (!payload || typeof payload !== "object" || Array.isArray(payload)) return null;
  if (Array.isArray(payload.teams)) return payload.teams;
  if (!Array.isArray(payload.sports) || !payload.sports[0]
      || !Array.isArray(payload.sports[0].leagues)
      || !payload.sports[0].leagues[0]
      || !Array.isArray(payload.sports[0].leagues[0].teams)) return null;
  return payload.sports[0].leagues[0].teams;
}

function parseTeamCatalogResponse(payload, leagueId) {
  var league = normalizeLeague(leagueId);
  var records = responseRecords(payload);
  if (!league || !records) return {teams: [], errors: [{code: "invalid-team-response"}]};

  var teams = [];
  var seen = {};
  var errors = [];
  for (var i = 0; i < records.length; i++) {
    var team = teamFromRecord(records[i], league);
    if (!team) {
      errors.push({index: i, code: "invalid-team"});
      continue;
    }
    if (seen[team.id]) continue;
    seen[team.id] = true;
    teams.push(team);
  }
  teams.sort(sortTeams);
  return {teams: teams, errors: errors.slice(0, 8)};
}

var exported = {
  CURRENT_TEAMS: CURRENT_TEAMS,
  ESPN_TEAM_BASE_URL: ESPN_TEAM_BASE_URL,
  buildTeamCatalogUrl: buildTeamCatalogUrl,
  listTeams: listTeams,
  listTeamsForLeagues: listTeamsForLeagues,
  normalizeTeamRecord: teamFromRecord,
  parseTeamCatalogResponse: parseTeamCatalogResponse
};

if (typeof module !== "undefined" && module.exports) module.exports = exported;

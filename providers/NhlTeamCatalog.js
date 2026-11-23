var TeamModel = requireTeamModel();
var AssetUrlPolicy = null;
if (typeof require === "function") AssetUrlPolicy = require("../model/AssetUrlPolicy.js");

var TEAM_SOURCE = "https://api.nhle.com/stats/rest/en/team?limit=-1";

// The stats endpoint also returns historical franchises. Keep the current
// roster boundary explicit so provider changes cannot silently add retired or
// placeholder teams to the picker. The last column is the reviewed ESPN PNG
// suffix for that NHL ID, not an ESPN numeric team ID. Keep NhlProvider in sync.
var CURRENT_TEAMS = [
  [24, "ANA", "Anaheim Ducks", "ana"],
  [6, "BOS", "Boston Bruins", "bos"],
  [7, "BUF", "Buffalo Sabres", "buf"],
  [12, "CAR", "Carolina Hurricanes", "car"],
  [29, "CBJ", "Columbus Blue Jackets", "cbj"],
  [20, "CGY", "Calgary Flames", "cgy"],
  [16, "CHI", "Chicago Blackhawks", "chi"],
  [21, "COL", "Colorado Avalanche", "col"],
  [25, "DAL", "Dallas Stars", "dal"],
  [17, "DET", "Detroit Red Wings", "det"],
  [22, "EDM", "Edmonton Oilers", "edm"],
  [13, "FLA", "Florida Panthers", "fla"],
  [26, "LAK", "Los Angeles Kings", "la"],
  [30, "MIN", "Minnesota Wild", "min"],
  [8, "MTL", "Montréal Canadiens", "mtl"],
  [1, "NJD", "New Jersey Devils", "nj"],
  [18, "NSH", "Nashville Predators", "nsh"],
  [2, "NYI", "New York Islanders", "nyi"],
  [3, "NYR", "New York Rangers", "nyr"],
  [9, "OTT", "Ottawa Senators", "ott"],
  [4, "PHI", "Philadelphia Flyers", "phi"],
  [5, "PIT", "Pittsburgh Penguins", "pit"],
  [55, "SEA", "Seattle Kraken", "sea"],
  [28, "SJS", "San Jose Sharks", "sj"],
  [19, "STL", "St. Louis Blues", "stl"],
  [14, "TBL", "Tampa Bay Lightning", "tb"],
  [10, "TOR", "Toronto Maple Leafs", "tor"],
  [68, "UTA", "Utah Mammoth", "utah"],
  [23, "VAN", "Vancouver Canucks", "van"],
  [54, "VGK", "Vegas Golden Knights", "vgk"],
  [52, "WPG", "Winnipeg Jets", "wpg"],
  [15, "WSH", "Washington Capitals", "wsh"]
];

var CURRENT_BY_ID = {};
for (var i = 0; i < CURRENT_TEAMS.length; i++) {
  var entry = CURRENT_TEAMS[i];
  CURRENT_BY_ID[String(entry[0])] = entry;
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
    if (!match) return null;
    var host = match[1].toLowerCase();
    if (host !== "assets.nhle.com" && host !== "a.espncdn.com") return null;
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

function normalizeTeamRecord(record) {
  if (!record || typeof record !== "object" || Array.isArray(record)) return null;
  if (typeof record.id !== "string" && typeof record.id !== "number") return null;
  if (typeof record.id === "number" && !isFinite(record.id)) return null;
  var id = String(record.id).trim();
  var known = CURRENT_BY_ID[id];
  if (!Array.isArray(known)) return null;
  if (typeof record.fullName !== "string" || !record.fullName.trim()
      || typeof record.triCode !== "string" || !record.triCode.trim()) return null;

  var team = {
    league: "nhl",
    providerTeamId: id,
    name: record.fullName,
    shortName: record.fullName,
    abbreviation: record.triCode,
    logoUrl: "https://a.espncdn.com/i/teamlogos/nhl/500/" + known[3] + ".png",
    link: null
  };
  return TeamModel.normalizeTeam(team);
}

function sortTeams(left, right) {
  return String(left.name || left.abbreviation || left.id)
    .localeCompare(String(right.name || right.abbreviation || right.id));
}

function listTeams() {
  return CURRENT_TEAMS.map(function(entry) {
    return TeamModel.normalizeTeam({
      league: "nhl",
      providerTeamId: String(entry[0]),
      name: entry[2],
      shortName: entry[2],
      abbreviation: entry[1],
      logoUrl: "https://a.espncdn.com/i/teamlogos/nhl/500/" + entry[3] + ".png",
      link: null
    });
  }).sort(sortTeams);
}

function parseTeamCatalogResponse(payload) {
  if (!payload || typeof payload !== "object" || Array.isArray(payload)
      || !Array.isArray(payload.data)) {
    return {teams: [], errors: [{code: "invalid-team-response"}]};
  }

  var teams = [];
  var seen = {};
  var errors = [];
  for (var i = 0; i < payload.data.length; i++) {
    var record = payload.data[i];
    var normalized = normalizeTeamRecord(record);
    if (!normalized) {
      if (record && typeof record === "object" && CURRENT_BY_ID[String(record.id)])
        errors.push({index: i, code: "invalid-team"});
      continue;
    }
    if (seen[normalized.id]) continue;
    seen[normalized.id] = true;
    teams.push(normalized);
  }
  teams.sort(sortTeams);
  return {teams: teams, errors: errors.slice(0, 8)};
}

var exported = {
  TEAM_SOURCE: TEAM_SOURCE,
  CURRENT_TEAMS: CURRENT_TEAMS,
  listTeams: listTeams,
  normalizeTeamRecord: normalizeTeamRecord,
  parseTeamCatalogResponse: parseTeamCatalogResponse
};

if (typeof module !== "undefined" && module.exports) module.exports = exported;

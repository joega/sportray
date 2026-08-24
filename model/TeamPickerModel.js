// Bounded discovery inputs: the search query and the returned result list are
// capped so a broad cross-league search can never flood the picker view.
var MAX_QUERY_LENGTH = 48;
var MAX_RESULTS = 60;

function text(value) {
  return typeof value === "string" ? value.trim() : "";
}

function normalizeQuery(value) {
  return text(value).toLowerCase().slice(0, MAX_QUERY_LENGTH);
}

function normalizeLeague(value) {
  return text(value).toLowerCase();
}

function normalizeFavoriteIds(value) {
  if (!Array.isArray(value)) return [];
  return value.filter(function(id) {
    return typeof id === "string" && id.trim() !== "";
  }).map(function(id) {
    return id.trim().toLowerCase();
  });
}

function teamSearchText(team) {
  if (!team || typeof team !== "object") return "";
  return [team.name, team.shortName, team.abbreviation, team.id]
    .map(text).join(" ").toLowerCase();
}

function teamName(team) {
  if (!team || typeof team !== "object") return "";
  return text(team.name) || text(team.shortName) || text(team.abbreviation) || text(team.id);
}

function compareTeams(left, right, favorites, query) {
  var leftFavorite = left && favorites.indexOf(left.id) !== -1;
  var rightFavorite = right && favorites.indexOf(right.id) !== -1;
  if (leftFavorite !== rightFavorite) return leftFavorite ? -1 : 1;

  var byTier = matchTier(left, query) - matchTier(right, query);
  if (byTier !== 0) return byTier;

  var byName = teamName(left).localeCompare(teamName(right));
  if (byName !== 0) return byName;
  return String(left && left.id || "").localeCompare(String(right && right.id || ""));
}

// Discovery ranking: exact abbreviation/id hits first, then names starting
// with the query, then any remaining substring or league-name match. The tier
// only applies while a non-empty query is active.
function matchTier(team, query) {
  if (!team || typeof team !== "object" || !query) return 0;
  var abbreviation = text(team.abbreviation).toLowerCase();
  if ((abbreviation && abbreviation === query)
      || text(team.id).toLowerCase() === query) return 0;
  var name = text(team.name).toLowerCase();
  var shortName = text(team.shortName).toLowerCase();
  if ((name && name.indexOf(query) === 0)
      || (shortName && shortName.indexOf(query) === 0)
      || (abbreviation && abbreviation.indexOf(query) === 0)) return 1;
  return 2;
}

function leagueLabels(leagues) {
  if (!Array.isArray(leagues)) return [];
  var labels = {};
  leagues.forEach(function(league) {
    if (!league || typeof league !== "object") return;
    var id = text(league.id).toLowerCase();
    if (!id || labels[id]) return;
    labels[id] = [league.displayName, league.name, id]
      .map(text).join(" ").toLowerCase();
  });
  return labels;
}

function matchedLeagueIds(query, leagues) {
  var matched = {};
  if (!query) return matched;
  var labels = leagueLabels(leagues);
  Object.keys(labels).forEach(function(id) {
    if (labels[id].indexOf(query) !== -1) matched[id] = true;
  });
  return matched;
}

function filterAndOrderTeams(teams, query, leagueFilter, favoriteIds, leagues) {
  var normalizedQuery = normalizeQuery(query);
  var normalizedLeague = normalizeLeague(leagueFilter);
  var favorites = normalizeFavoriteIds(favoriteIds);
  var leagueMatches = matchedLeagueIds(normalizedQuery, leagues);
  var results = (Array.isArray(teams) ? teams : []).filter(function(team) {
    if (!team || typeof team !== "object") return false;
    if (normalizedLeague && normalizedLeague !== "all"
        && normalizeLeague(team.league) !== normalizedLeague) return false;
    if (!normalizedQuery) return true;
    return teamSearchText(team).indexOf(normalizedQuery) !== -1
      || (team.league && leagueMatches[normalizeLeague(team.league)]);
  }).slice().sort(function(left, right) {
    return compareTeams(left, right, favorites, normalizedQuery);
  });
  // Only bounded search results are capped; unfiltered catalog browsing keeps
  // the complete static list so no league becomes undiscoverable.
  if (normalizedQuery) results = results.slice(0, MAX_RESULTS);
  return results;
}

function selectedCount(teams, favoriteIds) {
  var favorites = normalizeFavoriteIds(favoriteIds);
  var seen = {};
  var count = 0;
  favorites.forEach(function(id) { seen[id] = true; });
  (Array.isArray(teams) ? teams : []).forEach(function(team) {
    if (team && typeof team.id === "string" && seen[team.id.toLowerCase()]) count++;
  });
  return count;
}

var exported = {
  MAX_QUERY_LENGTH: MAX_QUERY_LENGTH,
  MAX_RESULTS: MAX_RESULTS,
  normalizeQuery: normalizeQuery,
  filterAndOrderTeams: filterAndOrderTeams,
  selectedCount: selectedCount,
  clampCursor: clampCursor,
  teamAt: teamAt
};

function clampCursor(index, delta, length) {
  var count = Number(length);
  if (!isFinite(count) || count <= 0) return -1;
  var current = Number(index);
  if (!isFinite(current)) current = 0;
  var movement = Number(delta);
  if (!isFinite(movement)) movement = 0;
  return Math.max(0, Math.min(count - 1, Math.floor(current + movement)));
}

function teamAt(teams, index) {
  if (!Array.isArray(teams) || index < 0 || index >= teams.length) return null;
  return teams[index] || null;
}

if (typeof module !== "undefined" && module.exports) module.exports = exported;

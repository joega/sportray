function text(value) {
  return typeof value === "string" ? value.trim() : "";
}

function normalizeQuery(value) {
  return text(value).toLowerCase();
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

function compareTeams(left, right, favorites) {
  var leftFavorite = left && favorites.indexOf(left.id) !== -1;
  var rightFavorite = right && favorites.indexOf(right.id) !== -1;
  if (leftFavorite !== rightFavorite) return leftFavorite ? -1 : 1;

  var byName = teamName(left).localeCompare(teamName(right));
  if (byName !== 0) return byName;
  return String(left && left.id || "").localeCompare(String(right && right.id || ""));
}

function filterAndOrderTeams(teams, query, leagueFilter, favoriteIds) {
  var normalizedQuery = normalizeQuery(query);
  var normalizedLeague = normalizeLeague(leagueFilter);
  var favorites = normalizeFavoriteIds(favoriteIds);
  return (Array.isArray(teams) ? teams : []).filter(function(team) {
    if (!team || typeof team !== "object") return false;
    if (normalizedLeague && normalizedLeague !== "all"
        && normalizeLeague(team.league) !== normalizedLeague) return false;
    return !normalizedQuery || teamSearchText(team).indexOf(normalizedQuery) !== -1;
  }).slice().sort(function(left, right) {
    return compareTeams(left, right, favorites);
  });
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

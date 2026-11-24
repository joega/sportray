// A view over the existing Following union. This owns no fetch or preference.
var FILTERS = ["all", "live", "favorites"];

function normalizeFilter(value) { return FILTERS.indexOf(value) !== -1 ? value : "all"; }
function nextFilter(value) { return FILTERS[(FILTERS.indexOf(normalizeFilter(value)) + 1) % FILTERS.length]; }
function project(view, filterId) {
  var source = view && typeof view === "object" ? view : {};
  var filter = normalizeFilter(filterId), seen = Object.create(null);
  var games = (Array.isArray(source.games) ? source.games : []).filter(function(game) {
    if (!game || typeof game.id !== "string" || !game.id || seen[game.id]) return false;
    seen[game.id] = true;
    return true;
  });
  var counts = {all: games.length, live: 0, favorites: 0, upcoming: 0, final: 0, changes: 0};
  games.forEach(function(game) {
    if (game.status === "live" || game.status === "intermission") counts.live++;
    if (game.presentation && game.presentation.isFavorite === true) counts.favorites++;
    if (game.status === "scheduled") counts.upcoming++;
    if (game.status === "final") counts.final++;
    if (game.status === "postponed" || game.status === "canceled") counts.changes++;
  });
  var filtered = games.filter(function(game) {
    return filter === "all" || (filter === "live" && (game.status === "live" || game.status === "intermission"))
      || (filter === "favorites" && game.presentation && game.presentation.isFavorite === true);
  });
  var leagues = [];
  filtered.forEach(function(game) { if (leagues.indexOf(game.league) === -1) leagues.push(game.league); });
  filtered = filtered.map(function(game) {
    return Object.assign({}, game, {presentation: Object.assign({}, game.presentation || {}, {
      showLeagueContext: leagues.length > 1
    })});
  });
  var limited = (Array.isArray(source.leagueStates) ? source.leagueStates : []).some(function(state) {
    return state.loading === true || state.stale === true || !!state.errorCode || state.hasData !== true;
  });
  var parts = [];
  if (counts.live) parts.push(counts.live + " live");
  if (counts.upcoming) parts.push(counts.upcoming + " upcoming");
  if (counts.final) parts.push(counts.final + " final");
  if (counts.changes) parts.push(counts.changes + (counts.changes === 1 ? " schedule change" : " schedule changes"));
  var summary = parts.length ? parts.join(" · ") : games.length ? games.length + " listed games" : "Your followed games";
  return {filterId: filter, counts: counts, limited: limited,
    summary: summary + (limited && games.length ? " · loaded games" : ""),
    view: Object.assign({}, source, {games: filtered, hasGames: filtered.length > 0,
      compactNotices: true, interactiveNotice: true,
      followingFilterId: filter, filteredEmpty: filter !== "all" && filtered.length === 0,
      unfilteredHasGames: games.length > 0})};
}

if (typeof module !== "undefined" && module.exports)
  module.exports = {FILTERS: FILTERS, normalizeFilter: normalizeFilter, nextFilter: nextFilter, project: project};

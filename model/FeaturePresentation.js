// Session-local presentation of one favorite game. No provider or preference I/O.
function identity(value) { return typeof value === "string" ? value.trim().toLowerCase() : ""; }
function choose(games) {
  var best = "", bestRank = 99;
  (Array.isArray(games) ? games : []).forEach(function(game) {
    if (!game || !identity(game.id) || game.isValid !== true || !game.presentation
        || game.presentation.isFavorite !== true) return;
    var rank = game.status === "live" || game.status === "intermission" ? 0
      : game.status === "scheduled" ? 1 : game.status === "final" ? 2 : 99;
    if (rank < bestRank) { best = identity(game.id); bestRank = rank; }
  });
  return best;
}
function rows(values, featuredId) {
  var source = Array.isArray(values) ? values : [], wanted = identity(featuredId), feature = null;
  if (!wanted) return source;
  var remainder = source.filter(function(row) {
    if (row.kind !== "game" || identity(row.game && row.game.id) !== wanted) return true;
    if (!feature) feature = Object.assign({}, row, {featured: true});
    return false;
  });
  if (!feature) return source;
  remainder = remainder.filter(function(row, index) {
    if (row.kind !== "section-header") return true;
    for (var i = index + 1; i < remainder.length && remainder[i].kind !== "section-header"; i++)
      if (remainder[i].kind === "game") return true;
    return false;
  });
  var index = 0;
  while (index < remainder.length && (remainder[index].kind === "status" || remainder[index].kind === "loading")) index++;
  remainder.splice(index, 0, feature);
  return remainder;
}
if (typeof module !== "undefined" && module.exports) module.exports = {choose: choose, rows: rows};

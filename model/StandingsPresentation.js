// Presentation of normalized standings only; provider ordering stays intact.
function columnsForLeague(leagueId) {
  var league = String(leagueId || "").toLowerCase();
  if (league === "nhl") return [
    {key: "played", label: "GP"}, {key: "wins", label: "W"},
    {key: "losses", label: "L"}, {key: "points", label: "PTS"}
  ];
  if (league === "eng.1" || league === "usa.1") return [
    {key: "played", label: "GP"}, {key: "wins", label: "W"},
    {key: "draws", label: "D"}, {key: "losses", label: "L"},
    {key: "points", label: "PTS"}
  ];
  if (league === "nfl") return [
    {key: "wins", label: "W"}, {key: "losses", label: "L"}, {key: "ties", label: "T"}
  ];
  return [{key: "wins", label: "W"}, {key: "losses", label: "L"}];
}

function layout(width, scale, leagueId) {
  var unit = Number(scale) > 0 ? Number(scale) : 1;
  var available = Math.max(0, Number(width) || 0);
  var padding = 4 * unit, gap = 8 * unit;
  var rankWidth = 20 * unit, favoriteWidth = 28 * unit;
  var metricsWidth = Math.min(available * 0.43, columnsForLeague(leagueId).length * 30 * unit);
  return {padding: padding, gap: gap, rankWidth: rankWidth,
    favoriteWidth: favoriteWidth, metricsWidth: metricsWidth,
    teamWidth: Math.max(0, available - padding * 2 - gap * 3 - rankWidth - favoriteWidth - metricsWidth)};
}

function metricValue(standing, key) {
  var value = standing ? standing[key] : null;
  return typeof value === "number" && isFinite(value) ? String(value) : "—";
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {columnsForLeague: columnsForLeague, layout: layout, metricValue: metricValue};
}

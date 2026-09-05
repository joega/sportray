var MAX_TEXT_LENGTH = 48;

function record(value) { return value !== null && typeof value === "object" && !Array.isArray(value); }
function text(value, fallback) {
  return typeof value === "string" && value.trim() ? value.trim() : fallback;
}
function cap(value, limit) {
  var result = text(value, "");
  var max = Math.max(1, Math.min(MAX_TEXT_LENGTH, Number(limit) || MAX_TEXT_LENGTH));
  return result.length <= max ? result : (max === 1 ? "…" : result.slice(0, max - 1).replace(/\s+$/, "") + "…");
}
function teamLabel(team) {
  return cap(team && (team.abbreviation || team.shortName || team.name), "TBD");
}
function project(input) {
  var source = record(input) ? input : {};
  var game = record(source.game) ? source.game : null;
  var state = text(source.state || (game && game.status), "unknown").toLowerCase();
  var kind = source.kind === "offline" || source.errorCode ? "offline" : game ? state : "empty";
  var away = teamLabel(game && game.awayTeam);
  var home = teamLabel(game && game.homeTeam);
  var score = game && typeof game.awayScore === "number" && typeof game.homeScore === "number"
    ? String(game.awayScore) + "–" + String(game.homeScore) : "VS";
  return {kind: kind, game: game, league: cap(source.league || (game && game.league), ""),
    away: away, home: home, score: cap(score), label: cap(source.label || (away + " vs " + home)),
    status: cap(source.status || state)};
}

if (typeof module !== "undefined" && module.exports) module.exports = {
  MAX_TEXT_LENGTH: MAX_TEXT_LENGTH, cap: cap, project: project, teamLabel: teamLabel
};

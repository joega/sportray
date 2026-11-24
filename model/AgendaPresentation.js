// Calendar-entry presentation only. No provider parsing, request or preference state.
var WEEKDAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
var MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

function dateParts(key) {
  if (typeof key !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(key)) return null;
  var y = Number(key.slice(0, 4)), m = Number(key.slice(5, 7)), d = Number(key.slice(8, 10));
  var date = new Date(Date.UTC(y, m - 1, d));
  if (date.getUTCFullYear() !== y || date.getUTCMonth() !== m - 1 || date.getUTCDate() !== d) return null;
  return {key: key, year: y, month: m, day: d, weekday: WEEKDAYS[date.getUTCDay()],
    monthLabel: MONTHS[m - 1], ordinal: Math.floor(date.getTime() / 86400000), weekDay: date.getUTCDay()};
}

function weekStart(key) {
  var parts = dateParts(key);
  return parts ? parts.ordinal - (parts.weekDay + 6) % 7 : null;
}

function weekLabel(key, todayKey) {
  var start = weekStart(key), today = weekStart(todayKey), parts = dateParts(key);
  if (start === null || !parts) return "Upcoming games";
  if (today !== null && start === today) return "This week";
  if (today !== null && start === today + 7) return "Next week";
  var first = new Date(start * 86400000), reference = dateParts(todayKey);
  return "Week of " + MONTHS[first.getUTCMonth()] + " " + first.getUTCDate()
    + (reference && first.getUTCFullYear() !== reference.year ? ", " + first.getUTCFullYear() : "");
}

function sectionLabels(entries, todayKey) {
  if (!Array.isArray(entries) || entries.length > 256) return [];
  var previous = null;
  return entries.map(function(entry) {
    var start = entry ? weekStart(entry.dateKey) : null;
    var label = start !== null && start !== previous ? weekLabel(entry.dateKey, todayKey) : "";
    previous = start;
    return label;
  });
}

function teamLabel(team) {
  return team ? team.shortName || team.name || team.abbreviation || "Team unavailable" : "Team unavailable";
}

function opponent(entry, teamId) {
  var game = entry && entry.game;
  if (!game) return null;
  if (game.awayTeam && game.awayTeam.id === teamId) return {team: game.homeTeam, prefix: "at"};
  if (game.homeTeam && game.homeTeam.id === teamId) return {team: game.awayTeam, prefix: "vs"};
  return null;
}

function score(entry) {
  var game = entry && entry.game;
  if (!game || ["live", "intermission", "final"].indexOf(game.status) < 0
      || typeof game.awayScore !== "number" || !isFinite(game.awayScore)
      || typeof game.homeScore !== "number" || !isFinite(game.homeScore)) return "";
  return game.awayScore + "–" + game.homeScore;
}

if (typeof module !== "undefined" && module.exports) module.exports = {
  dateParts: dateParts, weekStart: weekStart, weekLabel: weekLabel,
  sectionLabels: sectionLabels, teamLabel: teamLabel, opponent: opponent, score: score
};

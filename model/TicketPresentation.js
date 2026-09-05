var MAX_GAMES = 24;
var MAX_SEGMENT_LENGTH = 96;
var FINAL_WINDOW_MS = 12 * 60 * 60 * 1000;
var SCHEDULE_GRACE_MS = 15 * 60 * 1000;

function record(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function text(value, fallback) {
  return typeof value === "string" && value.trim() ? value.trim() : fallback;
}

function cap(value, limit) {
  var result = text(value, "");
  var max = Math.max(1, Math.min(MAX_SEGMENT_LENGTH,
    Number(limit) || MAX_SEGMENT_LENGTH));
  return result.length <= max ? result
    : result.slice(0, max - 3).replace(/\s+$/, "") + "...";
}

function timestamp(value) {
  var parsed = typeof value === "number" ? value : Date.parse(value);
  return isFinite(parsed) ? parsed : null;
}

function teamLabel(team) {
  return cap(team && (team.abbreviation || team.shortName || team.name), 18) || "TBD";
}

function teamId(team) {
  return text(team && team.id, "").toLowerCase();
}

function isFavorite(game, favoriteTeamIds) {
  var values = Array.isArray(favoriteTeamIds) ? favoriteTeamIds : [];
  return values.indexOf(teamId(game && game.awayTeam)) !== -1
    || values.indexOf(teamId(game && game.homeTeam)) !== -1;
}

function statusRank(game, nowMs) {
  var status = text(game && game.status, "unknown").toLowerCase();
  if (status === "live" || status === "intermission") return 0;
  var start = timestamp(game && game.startTime);
  if (status === "scheduled")
    return start !== null && start >= nowMs - SCHEDULE_GRACE_MS ? 1 : -1;
  if (status !== "final") return -1;
  var completed = timestamp(game && game.endTime);
  if (completed === null) completed = start;
  return completed !== null && completed >= nowMs - FINAL_WINDOW_MS ? 2 : -1;
}

function gameTime(game) {
  return timestamp(game && (game.endTime || game.startTime)) || 0;
}

function compare(left, right) {
  if (left.rank !== right.rank) return left.rank - right.rank;
  if (left.leagueOrder !== right.leagueOrder)
    return left.leagueOrder - right.leagueOrder;
  if (left.favorite !== right.favorite) return left.favorite ? -1 : 1;
  if (left.rank === 2 && left.time !== right.time) return right.time - left.time;
  if (left.time !== right.time) return left.time - right.time;
  return left.index - right.index;
}

function liveStatus(game, sport) {
  var fields = [game && game.periodLabel, game && game.statusDetail];
  if (text(sport, "").toLowerCase() !== "baseball") fields.push(game && game.clock);
  var details = [];
  fields.forEach(function(value) {
    var label = cap(value, 24);
    if (label && details.indexOf(label) === -1) details.push(label);
  });
  return details.length > 0 ? details.join(" ") : "LIVE";
}

function sportEmoji(sport) {
  switch (text(sport, "").toLowerCase()) {
  case "baseball": return "⚾";
  case "basketball": return "🏀";
  case "football": return "🏈";
  case "hockey": return "🏒";
  case "soccer": return "⚽";
  default: return "🏆";
  }
}

function leagueContext(game, describeLeague) {
  var leagueId = text(game && game.league, "sport").toLowerCase();
  var description = typeof describeLeague === "function"
    ? describeLeague(leagueId) : null;
  return {
    id: leagueId,
    label: cap(description && description.label, 24).toUpperCase()
      || leagueId.toUpperCase(),
    emoji: sportEmoji(description && description.sport),
    sport: text(description && description.sport, "").toLowerCase()
  };
}

function segment(entry, formatStartTime, sport) {
  var game = entry.game;
  var away = teamLabel(game.awayTeam);
  var home = teamLabel(game.homeTeam);
  var status = text(game.status, "unknown").toLowerCase();
  var matchup;
  var detail;
  if (status === "scheduled") {
    matchup = away + " @ " + home;
    detail = typeof formatStartTime === "function"
      ? text(formatStartTime(game.startTime), "UPCOMING") : "UPCOMING";
  } else {
    var awayScore = typeof game.awayScore === "number" ? String(game.awayScore) : "-";
    var homeScore = typeof game.homeScore === "number" ? String(game.homeScore) : "-";
    matchup = away + " " + awayScore + "-" + homeScore + " " + home;
    detail = status === "final" ? "FINAL" : liveStatus(game, sport);
  }
  return {
    away: away,
    home: home,
    awayLogoUrl: text(game.awayTeam && game.awayTeam.logoUrl, ""),
    homeLogoUrl: text(game.homeTeam && game.homeTeam.logoUrl, ""),
    awayScore: status === "scheduled" ? "" : awayScore,
    homeScore: status === "scheduled" ? "" : homeScore,
    divider: status === "scheduled" ? "@" : "-",
    detail: detail,
    text: cap(matchup + "   " + detail)
  };
}

function build(input) {
  var source = record(input) ? input : {};
  var nowMs = timestamp(source.nowMs);
  if (nowMs === null) nowMs = Date.now();
  var state = text(source.state, "empty").toLowerCase();
  if (state === "loading")
    return {state: state, entries: [], items: [], text: "UPDATING SCORES"};
  if (state === "offline")
    return {state: state, entries: [], items: [], text: "SCORES UNAVAILABLE"};

  var games = Array.isArray(source.games) ? source.games : [];
  var entries = [];
  var leagueOrders = {};
  var nextLeagueOrder = 0;
  for (var i = 0; i < games.length; i++) {
    if (!record(games[i])) continue;
    var rank = statusRank(games[i], nowMs);
    if (rank < 0) continue;
    var leagueId = text(games[i].league, "sport").toLowerCase();
    if (leagueOrders[leagueId] === undefined)
      leagueOrders[leagueId] = nextLeagueOrder++;
    entries.push({game: games[i], rank: rank,
      favorite: isFavorite(games[i], source.favoriteTeamIds),
      leagueOrder: leagueOrders[leagueId], time: gameTime(games[i]), index: i});
  }
  entries.sort(compare);
  entries = entries.slice(0, MAX_GAMES);
  var segments = [];
  var items = [];
  var previousLeague = "";
  entries.forEach(function(entry) {
    var league = leagueContext(entry.game, source.leagueInfo);
    var groupStart = league.id !== previousLeague;
    var prefix = !groupStart ? "   " + league.emoji + "   "
      : (segments.length > 0 ? "     " : "")
        + league.emoji + "  " + league.label + "   ";
    var game = segment(entry, source.formatStartTime, league.sport);
    segments.push(prefix + game.text);
    game.groupStart = groupStart;
    game.leagueEmoji = league.emoji;
    game.leagueLabel = league.label;
    game.separatorEmoji = league.emoji;
    items.push(game);
    previousLeague = league.id;
  });
  return {state: segments.length > 0 ? "ready" : "empty", entries: entries,
    items: items,
    text: segments.length > 0
      ? segments.join("") : "NO LIVE OR UPCOMING GAMES"};
}

if (typeof module !== "undefined" && module.exports) module.exports = {
  MAX_GAMES: MAX_GAMES,
  MAX_SEGMENT_LENGTH: MAX_SEGMENT_LENGTH,
  FINAL_WINDOW_MS: FINAL_WINDOW_MS,
  SCHEDULE_GRACE_MS: SCHEDULE_GRACE_MS,
  build: build,
  cap: cap,
  teamLabel: teamLabel
};

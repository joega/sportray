function textOr(value, fallback) {
  return typeof value === "string" && value.trim() ? value.trim() : fallback;
}

function teamLabel(team) {
  if (!team) return "TBD";
  return capText(textOr(team.abbreviation, textOr(team.shortName, textOr(team.name, "TBD"))), 18);
}

function formatMatchup(game) {
  if (!game) return "TBD vs TBD";
  return teamLabel(game.awayTeam) + " vs " + teamLabel(game.homeTeam);
}

function ordinal(value) {
  if (typeof value !== "number" || !isFinite(value) || value < 1 || Math.floor(value) !== value)
    return null;
  var suffix = "th";
  if (value % 100 < 11 || value % 100 > 13) {
    if (value % 10 === 1) suffix = "st";
    else if (value % 10 === 2) suffix = "nd";
    else if (value % 10 === 3) suffix = "rd";
  }
  return String(value) + suffix;
}

function sportPeriodFallback(game) {
  if (!game || typeof game.period !== "number") return null;
  var value = ordinal(game.period);
  if (!value) return null;

  switch (typeof game.league === "string" ? game.league.toLowerCase() : "") {
  case "nfl":
  case "college-football": return value;
  case "mlb": return value + " inning";
  case "nba": return value + " Quarter";
  case "eng.1":
  case "usa.1":
    if (game.period === 1) return "1st half";
    if (game.period === 2) return "2nd half";
    return "Period " + String(game.period);
  case "mens-college-basketball":
    if (game.period === 1) return "1st half";
    if (game.period === 2) return "2nd half";
    return "Period " + String(game.period);
  default: return "Period " + String(game.period);
  }
}

function soccerFinalLabel(game) {
  if (!game || typeof game.league !== "string"
      || ["eng.1", "usa.1"].indexOf(game.league.toLowerCase()) === -1)
    return "Final";
  var detail = textOr(game && game.statusDetail, null);
  if (detail && /(?:AET|EXTRA|PENAL)/i.test(detail)) return detail;
  return "Final";
}

function formatPeriodLabel(game) {
  if (!game) return null;
  var label = textOr(game.periodLabel, null);
  if (label) return label;
  if ((game.status === "live" || game.status === "intermission")
      && textOr(game.statusDetail, null)) {
    return textOr(game.statusDetail, null);
  }
  return sportPeriodFallback(game);
}

function formatScore(game) {
  if (!game) return "—";
  var away = typeof game.awayScore === "number" ? capText(String(game.awayScore), 5) : "—";
  var home = typeof game.homeScore === "number" ? capText(String(game.homeScore), 5) : "—";
  if (away === "—" && home === "—") return "—";
  return away + "–" + home;
}

function formatScoreboardTeamScore(game, side) {
  if (!game || typeof side !== "string") return "";
  if (game.status === "scheduled") return side === "away" ? "VS" : "";
  if (game.status === "postponed" || game.status === "canceled"
      || game.status === "malformed" || game.status === "unknown") return "—";
  var value = side === "away" ? game.awayScore : game.homeScore;
  return typeof value === "number" ? capText(String(value), 5) : "—";
}

function formatScoreboardScore(game) {
  if (!game) return "—";
  if (game.status === "scheduled") return "VS";
  if (game.status === "postponed" || game.status === "canceled"
      || game.status === "malformed" || game.status === "unknown") return "—";
  return formatScore(game);
}

function isWinningTeam(game, side) {
  if (!game || game.status !== "final" || typeof side !== "string") return false;
  var away = game.awayScore;
  var home = game.homeScore;
  if (typeof away !== "number" || typeof home !== "number" || away === home) return false;
  return side === "away" ? away > home : home > away;
}

function formatPeriodClock(game) {
  if (!game) return null;
  var period = formatPeriodLabel(game);
  var clock = textOr(game.clock, null);
  if (period && clock && period === clock) return period;
  if (period && clock) return period + " · " + clock;
  return period || clock;
}

function formatStatus(game) {
  if (!game || typeof game.status !== "string") return "Status unavailable";
  switch (game.status) {
  case "scheduled": return "Scheduled";
  case "live": return textOr(formatPeriodClock(game), "Live");
  case "intermission": return textOr(formatPeriodClock(game), "Intermission");
  case "final": return soccerFinalLabel(game);
  case "postponed": return "Postponed";
  case "canceled": return "Canceled";
  case "malformed": return "Data unavailable";
  default: return "Status unavailable";
  }
}

function formatGameStateLabel(game, options) {
  if (!game || typeof game.status !== "string") return "STATUS UNAVAILABLE";
  var config = options || {};
  var label = "STATUS UNAVAILABLE";
  switch (game.status) {
  case "live": label = "LIVE · " + textOr(formatPeriodClock(game), "In progress"); break;
  case "intermission": label = "INTERMISSION · " + textOr(formatPeriodClock(game), "Break"); break;
  case "final": label = "FINAL"; break;
  case "scheduled": label = "SCHEDULED"; break;
  case "postponed": label = "POSTPONED"; break;
  case "canceled": label = "CANCELED"; break;
  case "malformed":
  case "unknown": label = "DATA UNAVAILABLE"; break;
  }

  var startTimeText = typeof config.startTimeText === "string" && config.startTimeText.trim()
    ? config.startTimeText.trim() : formatStartTime(game.startTime, config.startTimeOptions);
  var result;
  if (game.status === "scheduled") {
    result = startTimeText === "Time unavailable" ? label : label + " · " + startTimeText;
  } else if (config.includeStartTime === true && startTimeText !== "Time unavailable") {
    result = startTimeText + " · " + label;
  } else {
    result = label;
  }
  if (config.stale !== true) return result;
  var updated = game.lastUpdated ? new Date(game.lastUpdated) : null;
  var now = typeof config.now === "number" ? config.now : Date.now();
  var age = updated && !isNaN(updated.getTime()) ? Math.max(0, now - updated.getTime()) : null;
  var ageLabel = age === null ? "age unavailable"
    : age < 60 * 1000 ? "just now"
    : String(Math.floor(age / (60 * 1000))) + "m ago";
  return "STALE · " + ageLabel + " · " + result;
}

function formatPanelStatus(game, options) {
  if (!game || typeof game.status !== "string") return "Status unavailable";
  if (game.status !== "scheduled") return formatStatus(game);

  var config = options || {};
  var startOptions = config.startTimeOptions;
  if (!startOptions && typeof config.timeZone === "string" && config.timeZone.trim())
    startOptions = {
      month: "short",
      day: "numeric",
      hour: "numeric",
      minute: "2-digit",
      timeZone: config.timeZone
    };
  return "Scheduled · " + formatStartTime(game.startTime, startOptions);
}

function formatStartTime(value, options) {
  if (typeof value !== "string") return "Time unavailable";
  var date = new Date(value);
  if (isNaN(date.getTime())) return "Time unavailable";

  var formatOptions = options || {
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
    timeZone: "UTC"
  };
  try {
    return new Intl.DateTimeFormat("en-US", formatOptions).format(date);
  } catch (error) {
    return "Time unavailable";
  }
}

function capText(value, maxLength) {
  var text = typeof value === "string" ? value.trim() : "";
  var limit = typeof maxLength === "number" && isFinite(maxLength) && maxLength > 0
    ? Math.floor(maxLength) : 64;
  if (text.length <= limit) return text;
  if (limit === 1) return "…";
  return text.slice(0, limit - 1).replace(/\s+$/, "") + "…";
}

function formatBarStartTime(value, timeZone) {
  var options = {hour: "numeric", minute: "2-digit"};
  if (typeof timeZone === "string" && timeZone.trim()) options.timeZone = timeZone;
  return formatStartTime(value, options);
}

function formatCompactGame(game, options) {
  if (!game) return "";
  var config = options || {};
  var matchup = formatMatchup(game);
  if (game.status === "scheduled") {
    var startTime = typeof config.startTimeText === "string" && config.startTimeText.trim()
      ? config.startTimeText.trim() : formatBarStartTime(game.startTime, config.timeZone);
    return matchup + " · " + startTime;
  }
  if (game.status === "postponed" || game.status === "canceled" || game.status === "malformed"
      || game.status === "unknown") {
    return matchup + " · " + formatStatus(game);
  }
  return teamLabel(game.awayTeam) + " " + formatScore(game) + " " + teamLabel(game.homeTeam);
}

function formatPanelGame(game, options) {
  if (!game) return null;
  return {
    awayLabel: teamLabel(game.awayTeam),
    homeLabel: teamLabel(game.homeTeam),
    matchup: formatMatchup(game),
    score: formatScore(game),
    status: formatPanelStatus(game, options)
  };
}

function formatBarText(state, options) {
  var config = options || {};
  var leagueLabel = textOr(config.leagueLabel, "NHL");
  if (!state || typeof state !== "object") return "";

  if (state.kind === "live-favorite-count")
    return capText(leagueLabel + " · " + String(state.count) + " live favorites", config.maxLength);

  var game = state.game;
  if (!game) return "";

  var matchup = formatMatchup(game);
  if (state.kind === "favorite-starting-soon" || game.status === "scheduled") {
    var startTime = typeof config.startTimeText === "string" && config.startTimeText.trim()
      ? config.startTimeText.trim() : formatBarStartTime(game.startTime, config.timeZone);
    return capText(matchup + " · " + startTime, config.maxLength);
  }
  return capText(teamLabel(game.awayTeam) + " " + formatScore(game) + " "
    + teamLabel(game.homeTeam), config.maxLength);
}

function formatBarTooltip(state, options) {
  var config = options || {};
  return capText(formatBarText(state, config), config.maxLength);
}

function formatBarVerticalLines(state, options) {
  var config = options || {};
  if (!state || typeof state !== "object") return [];
  if (state.kind === "live-favorite-count") {
    return [textOr(config.leagueLabel, "NHL"), String(state.count), "LIVE"];
  }
  if (!state.game) return [];
  return [teamLabel(state.game.awayTeam), formatScore(state.game), teamLabel(state.game.homeTeam)];
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    teamLabel: teamLabel,
    formatMatchup: formatMatchup,
    formatPeriodLabel: formatPeriodLabel,
    formatScore: formatScore,
    formatPeriodClock: formatPeriodClock,
    formatStatus: formatStatus,
    formatGameStateLabel: formatGameStateLabel,
    formatPanelStatus: formatPanelStatus,
    formatCompactGame: formatCompactGame,
    formatPanelGame: formatPanelGame,
    formatScoreboardTeamScore: formatScoreboardTeamScore,
    formatScoreboardScore: formatScoreboardScore,
    isWinningTeam: isWinningTeam,
    formatStartTime: formatStartTime,
    capText: capText,
    formatBarText: formatBarText,
    formatBarTooltip: formatBarTooltip,
    formatBarVerticalLines: formatBarVerticalLines
  };
}

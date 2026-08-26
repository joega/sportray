// Pure provider-neutral calendar projection. Composes already-fetched,
// date-keyed league snapshots into a bounded day-list with followed-team and
// enabled-league filters. This module owns no fetching, polling, or timers;
// its input is the existing bounded per-league date caches only.
var DateModel = null;
if (typeof require === "function") DateModel = require("./DateModel.js");
var FavoritePresentation = null;
if (typeof require === "function") FavoritePresentation = require("./FavoritePresentation.js");

// QML imports cannot require other model files, so the date helpers below
// mirror the DateModel boundary for that path. Node tests keep exercising the
// shared DateModel implementations.
var WEEKDAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
var MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
var FULL_MONTHS = ["January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"];

function pad(value) {
  return String(value).length < 2 ? "0" + value : String(value);
}

function localDateKey(value) {
  if (DateModel) return DateModel.localDateKey(value);
  var date = value instanceof Date ? value : new Date(value);
  if (isNaN(date.getTime())) return "";
  return date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate());
}

function isDateKey(value) {
  if (DateModel) return DateModel.isDateKey(value);
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  var parts = value.split("-").map(Number);
  var date = new Date(parts[0], parts[1] - 1, parts[2]);
  return !isNaN(date.getTime())
    && date.getFullYear() === parts[0] && date.getMonth() === parts[1] - 1
    && date.getDate() === parts[2];
}

function addDays(value, delta) {
  if (DateModel) return DateModel.addDays(value, delta);
  if (!isDateKey(value)) return "";
  var parts = value.split("-").map(Number);
  var date = new Date(parts[0], parts[1] - 1, parts[2]);
  date.setDate(date.getDate() + Number(delta || 0));
  return localDateKey(date);
}

function shortDateLabel(value) {
  if (DateModel) return DateModel.shortDateLabel(value);
  if (!isDateKey(value)) return "Date unavailable";
  var parts = value.split("-").map(Number);
  var date = new Date(parts[0], parts[1] - 1, parts[2]);
  return WEEKDAYS[date.getDay()] + ", " + MONTHS[date.getMonth()] + " " + date.getDate();
}

function monthKey(value) {
  if (!isDateKey(value)) return "";
  return value.slice(0, 7) + "-01";
}

function addMonths(value, delta) {
  if (DateModel && typeof DateModel.addMonths === "function")
    return DateModel.addMonths(value, delta);
  var base = monthKey(value);
  if (!base || !isFinite(Number(delta))) return "";
  var parts = base.split("-").map(Number);
  var date = new Date(parts[0], parts[1] - 1, 1);
  date.setMonth(date.getMonth() + Math.trunc(Number(delta)));
  return date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-01";
}

var DEFAULT_HALF_WIDTH_DAYS = 2;
var MAX_HALF_WIDTH_DAYS = 7;
var MAX_GAMES_PER_DAY = 64;
var MAX_TIME_LABEL_LENGTH = 24;
var MAX_LEAGUES_PER_DAY_SUMMARY = 4;
var MAX_MONTH_CELLS = 42;

// Weekday and month names for the week-strip cells. QML imports cannot
// require other model files, so these mirror the DateModel label boundary.
function weekdayLabel(value) {
  if (!isDateKey(value)) return "";
  var parts = value.split("-").map(Number);
  return WEEKDAYS[new Date(parts[0], parts[1] - 1, parts[2]).getDay()] || "";
}

function dayOfMonthLabel(value) {
  if (!isDateKey(value)) return "";
  return String(Number(value.split("-")[2]));
}

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function gameDateKey(game) {
  if (!isRecord(game) || typeof game.startTime !== "string") return "";
  return localDateKey(game.startTime);
}

function gameIdentity(game) {
  if (!isRecord(game)) return "";
  if (typeof game.id === "string" && game.id.trim()) return game.id.trim().toLowerCase();
  if (typeof game.providerGameId === "string" && game.providerGameId.trim())
    return game.providerGameId.trim().toLowerCase();
  return "";
}

function timestamp(value) {
  if (typeof value !== "string") return Number.POSITIVE_INFINITY;
  var parsed = Date.parse(value);
  return isFinite(parsed) ? parsed : Number.POSITIVE_INFINITY;
}

function normalizeLeagueId(value) {
  if (typeof value !== "string") return "";
  return value.trim().toLowerCase();
}

function normalizeEnabledLeagueIds(value) {
  if (!Array.isArray(value)) return [];
  var ids = [];
  for (var i = 0; i < value.length; i++) {
    var id = normalizeLeagueId(value[i]);
    if (id && ids.indexOf(id) === -1) ids.push(id);
  }
  return ids;
}

function favoriteIds(options) {
  if (FavoritePresentation) return FavoritePresentation.normalizeFavoriteIds(options.favoriteTeamIds);
  var result = [];
  if (!Array.isArray(options.favoriteTeamIds)) return result;
  for (var i = 0; i < options.favoriteTeamIds.length; i++) {
    if (typeof options.favoriteTeamIds[i] === "string")
      result.push(options.favoriteTeamIds[i].trim().toLowerCase());
  }
  return result;
}

function isFavoriteGame(game, ids, matcher) {
  if (typeof matcher === "function") return matcher(game, ids) === true;
  if (FavoritePresentation) return FavoritePresentation.isFavoriteGame(game, ids);
  return false;
}

function defaultOrder(games) {
  var values = Array.isArray(games) ? games : [];
  var entries = [];
  for (var i = 0; i < values.length; i++) {
    if (isRecord(values[i])) entries.push({game: values[i], index: i});
  }
  entries.sort(function(left, right) {
    var leftTime = timestamp(left.game.startTime);
    var rightTime = timestamp(right.game.startTime);
    if (leftTime !== rightTime) return leftTime - rightTime;
    var leftIdentity = gameIdentity(left.game);
    var rightIdentity = gameIdentity(right.game);
    if (leftIdentity < rightIdentity) return -1;
    if (leftIdentity > rightIdentity) return 1;
    return left.index - right.index;
  });
  return entries.map(function(entry) { return entry.game; });
}

// Explicit local-time rendering choice for calendar game rows. The label is
// derived from the normalized startTime in the viewer's local timezone and is
// bounded; missing or malformed times fail closed to an empty label so the
// row keeps its existing neutral presentation.
function localTimeLabel(value) {
  if (typeof value !== "string") return "";
  var date = new Date(value);
  if (isNaN(date.getTime())) return "";
  var hours = date.getHours();
  var minutes = date.getMinutes();
  var meridiem = hours < 12 ? "AM" : "PM";
  var twelveHour = hours % 12 === 0 ? 12 : hours % 12;
  var label = twelveHour + ":" + pad(minutes) + " " + meridiem + " local";
  if (label.length > MAX_TIME_LABEL_LENGTH) return "";
  return label;
}

function windowKeys(centerDateKey, halfWidth) {
  if (!isDateKey(centerDateKey)) return [];
  var keys = [];
  for (var offset = -halfWidth; offset <= halfWidth; offset++) {
    var key = addDays(centerDateKey, offset);
    if (isDateKey(key)) keys.push(key);
  }
  return keys;
}

function monthDateKeys(value) {
  var first = monthKey(value);
  if (!first) return [];
  var parts = first.split("-").map(Number);
  var date = new Date(parts[0], parts[1] - 1, 1);
  // Monday is column zero, matching the conventional schedule layout.
  var leading = (date.getDay() + 6) % 7;
  var keys = [];
  for (var i = 0; i < MAX_MONTH_CELLS; i++) {
    var key = addDays(first, i - leading);
    if (!isDateKey(key)) return [];
    keys.push(key);
  }
  return keys;
}

// leagueWindows: [{leagueId, displayName, days: [{dateKey, games}]}] drawn
// from already-fetched date caches. Days outside the requested window and all
// malformed records fail closed instead of widening the projection.
function compose(leagueWindows, options) {
  var config = isRecord(options) ? options : {};
  var center = typeof config.centerDateKey === "string" ? config.centerDateKey : "";
  var halfWidthNumber = Number(config.halfWidth);
  var halfWidth = isFinite(halfWidthNumber)
    ? Math.max(0, Math.min(MAX_HALF_WIDTH_DAYS, Math.floor(halfWidthNumber)))
    : DEFAULT_HALF_WIDTH_DAYS;
  var favoritesOnly = config.favoritesOnly === true;
  var favorites = favoriteIds(config);
  var enabled = normalizeEnabledLeagueIds(config.enabledLeagues);
  var knownLeagues = normalizeEnabledLeagueIds(
    Array.isArray(config.knownLeagueIds) ? config.knownLeagueIds : enabled);
  var keys = windowKeys(center, halfWidth);
  if (Array.isArray(config.dateKeys)) {
    keys = config.dateKeys.filter(function(value, index, values) {
      return isDateKey(value) && values.indexOf(value) === index;
    }).slice(0, MAX_MONTH_CELLS);
  }

  var calendar = {
    kind: "calendar",
    centerDateKey: center,
    halfWidth: halfWidth,
    favoritesOnly: favoritesOnly,
    hasGames: false,
    gameCount: 0,
    days: []
  };
  if (keys.length === 0) return calendar;

  var byDate = {};
  var leagueNames = {};
  keys.forEach(function(dateKey) {
    var day = {
      dateKey: dateKey,
      label: shortDateLabel(dateKey),
      hasGames: false,
      known: false,
      partial: false,
      unavailable: false,
      stale: false,
      completeLeagueCount: 0,
      games: []
    };
    byDate[dateKey] = day;
    calendar.days.push(day);
  });

  var seenByDate = {};
  var completeByDate = {};
  keys.forEach(function(dateKey) { seenByDate[dateKey] = {}; });
  keys.forEach(function(dateKey) { completeByDate[dateKey] = {}; });

  (Array.isArray(leagueWindows) ? leagueWindows : []).forEach(function(windowRecord) {
    if (!isRecord(windowRecord)) return;
    var leagueId = normalizeLeagueId(windowRecord.leagueId);
    if (!leagueId || enabled.indexOf(leagueId) === -1) return;
    if (!Array.isArray(windowRecord.days)) return;
    if (typeof windowRecord.displayName === "string" && windowRecord.displayName.trim())
      leagueNames[leagueId] = windowRecord.displayName.trim();

    windowRecord.days.forEach(function(day) {
      if (!isRecord(day) || !isDateKey(day.dateKey)) return;
      var target = byDate[day.dateKey];
      if (!target || !Array.isArray(day.games)) return;
      var legacyComplete = day.complete === undefined && !day.state;
    if (knownLeagues.indexOf(leagueId) !== -1
        && (day.complete === true || legacyComplete)
        && !completeByDate[day.dateKey][leagueId]) {
        completeByDate[day.dateKey][leagueId] = true;
        target.completeLeagueCount++;
      }
      target.partial = target.partial || day.state === "partial";
      target.unavailable = target.unavailable || day.state === "unavailable";
      target.stale = target.stale || day.stale === true;
      day.games.forEach(function(game) {
        if (!isRecord(game) || game.isValid !== true) return;
        if (normalizeLeagueId(game.league) !== leagueId) return;
        if (gameDateKey(game) !== day.dateKey) return;
        var identity = gameIdentity(game);
        if (!identity || seenByDate[day.dateKey][identity]) return;
        if (favoritesOnly && !isFavoriteGame(game, favorites, config.matcher)) return;
        seenByDate[day.dateKey][identity] = true;
        target.games.push(game);
      });
    });
  });

  calendar.days.forEach(function(day) {
    var ordered = typeof config.orderer === "function"
      ? config.orderer(day.games, favorites) : defaultOrder(day.games);
    if (!Array.isArray(ordered)) ordered = [];
    if (ordered.length > MAX_GAMES_PER_DAY) ordered = ordered.slice(0, MAX_GAMES_PER_DAY);
    if (ordered.length > 0) day.hasGames = true;
    day.games = ordered.map(function(game) {
      if (typeof config.annotate !== "function") return game;
      var leagueId = normalizeLeagueId(game.league);
      return config.annotate(game, {
        leagueId: leagueId,
        displayName: leagueNames[leagueId] || ""
      });
    });
    if (day.hasGames) calendar.gameCount += day.games.length;
    day.known = knownLeagues.length > 0 && day.completeLeagueCount === knownLeagues.length
      && !day.partial && !day.unavailable;
    delete day.completeLeagueCount;
  });
  calendar.hasGames = calendar.gameCount > 0;
  return calendar;
}

function monthGrid(leagueWindows, options) {
  var config = isRecord(options) ? options : {};
  var requestedMonth = monthKey(config.monthKey || config.selectedDateKey || "");
  if (!requestedMonth) requestedMonth = monthKey(localDateKey(new Date()));
  var keys = monthDateKeys(requestedMonth);
  var selectedLeague = normalizeLeagueId(config.leagueId);
  var enabledLeagues = normalizeEnabledLeagueIds(config.enabledLeagues);
  if (selectedLeague && enabledLeagues.indexOf(selectedLeague) !== -1)
    enabledLeagues = [selectedLeague];
  var calendar = compose(leagueWindows, Object.assign({}, config, {
    centerDateKey: requestedMonth,
    dateKeys: keys,
    enabledLeagues: enabledLeagues
  }));
  var selected = isDateKey(config.selectedDateKey) ? config.selectedDateKey : "";
  var today = isDateKey(config.todayDateKey) ? config.todayDateKey : "";
  var inMonthPrefix = requestedMonth.slice(0, 7);
  var cells = calendar.days.map(function(day) {
    var games = Array.isArray(day.games) ? day.games : [];
    var favorite = games.some(function(game) {
      return isRecord(game.presentation) && game.presentation.isFavorite === true;
    });
    var state = day.unavailable ? "unavailable"
      : day.partial ? "partial"
      : day.stale ? "stale"
      : day.known ? (games.length > 0 ? "known" : "empty") : "unknown";
    return {
      dateKey: day.dateKey,
      dayOfMonth: dayOfMonthLabel(day.dateKey),
      weekday: weekdayLabel(day.dateKey),
      month: MONTHS[Number(day.dateKey.split("-")[1]) - 1] || "",
      inMonth: day.dateKey.slice(0, 7) === inMonthPrefix,
      isToday: day.dateKey === today,
      isSelected: day.dateKey === selected,
      known: day.known === true,
      loading: day.dateKey === selected && config.selectedLoading === true,
      partial: day.partial === true || (day.dateKey === selected && config.selectedPartial === true),
      unavailable: day.unavailable === true
        || (day.dateKey === selected && config.selectedUnavailable === true),
      stale: day.stale === true || (day.known === true && Array.isArray(config.staleDateKeys)
        && config.staleDateKeys.indexOf(day.dateKey) !== -1),
      state: state,
      gameCount: Math.min(MAX_GAMES_PER_DAY, games.length),
      hasGames: games.length > 0,
      hasFavoriteGames: favorite,
      leagueIds: games.reduce(function(ids, game) {
        var leagueId = normalizeLeagueId(game && game.league);
        if (leagueId && ids.indexOf(leagueId) === -1
            && ids.length < MAX_LEAGUES_PER_DAY_SUMMARY) ids.push(leagueId);
        return ids;
      }, [])
    };
  });
  return {
    kind: "month-grid",
    monthKey: requestedMonth,
    monthLabel: FULL_MONTHS[Number(requestedMonth.slice(5, 7)) - 1]
      + " " + requestedMonth.slice(0, 4),
    selectedDateKey: selected,
    todayDateKey: today,
    days: calendar.days,
    cells: cells,
    gameCount: calendar.gameCount,
    hasGames: calendar.hasGames,
    favoritesOnly: calendar.favoritesOnly
  };
}

// Direct date jump target: the first cached calendar day strictly after the
// given date that has games. Empty days are skipped, and every malformed or
// non-later input fails closed to an empty result so the caller never jumps
// outside the already-fetched cache window.
function nextGamesDateKey(calendar, fromDateKey) {
  if (!isRecord(calendar) || !Array.isArray(calendar.days)) return "";
  if (!isDateKey(fromDateKey)) return "";
  var best = "";
  for (var i = 0; i < calendar.days.length; i++) {
    var day = calendar.days[i];
    if (!isRecord(day) || !isDateKey(day.dateKey)) continue;
    if (day.hasGames !== true || day.dateKey <= fromDateKey) continue;
    if (best === "" || day.dateKey < best) best = day.dateKey;
  }
  return best;
}

// Day-list row projection reusing the existing scoreboard row vocabulary
// (same shapes as model/ResultRows.js) so the panel list, keyboard routing,
// and detail drill-down stay unchanged. Kept self-contained because QML
// imports cannot require other model files.
function sectionRow(id, label) {
  return {
    kind: "section-header",
    rowId: "section:" + id,
    label: label,
    favorite: false
  };
}

function gameRow(game) {
  var identity = gameIdentity(game);
  if (!identity) return null;
  return {
    kind: "game",
    rowId: "game:" + identity,
    game: game,
    timeLabel: localTimeLabel(game.startTime),
    stale: false,
    action: {
      type: "open-detail",
      label: "View game details",
      enabled: game.isValid === true
    }
  };
}

function emptyDayRow(dateKey) {
  return {
    kind: "empty",
    rowId: "empty:calendar:" + dateKey + ":empty",
    text: "No games",
    title: "",
    supportingText: "",
    action: null
  };
}

// Shared per-day flattening used by both the full day list and the selected
// single-day list so the row vocabulary and identity stay identical.
function appendDayRows(rows, day) {
  if (!isRecord(day) || !isDateKey(day.dateKey)) return;
  rows.push(sectionRow("calendar:" + day.dateKey, day.label || day.dateKey));
  if (day.hasGames !== true) {
    rows.push({kind: "empty", rowId: "unknown:calendar:" + day.dateKey,
      text: day.known === true ? "No games" : (day.state === "unavailable"
        ? "Schedule unavailable" : day.state === "partial" ? "Schedule incomplete" : "Games not checked"),
      title: "", supportingText: "", action: null});
    return;
  }
  (Array.isArray(day.games) ? day.games : []).forEach(function(game) {
    var row = gameRow(game);
    if (row) rows.push(row);
  });
}

function flatten(calendar) {
  var rows = [];
  if (!isRecord(calendar) || !Array.isArray(calendar.days)) return rows;
  calendar.days.forEach(function(day) {
    appendDayRows(rows, day);
  });
  return rows;
}

// Selected-day drill-down: the same row vocabulary as flatten but bounded to
// one cached date. Unknown or malformed dates fail closed to no rows so the
// panel never renders a day outside the composed window.
function flattenDay(calendar, dateKey) {
  var rows = [];
  if (!isRecord(calendar) || !Array.isArray(calendar.days) || !isDateKey(dateKey))
    return rows;
  for (var i = 0; i < calendar.days.length; i++) {
    var day = calendar.days[i];
    if (!isRecord(day) || day.dateKey !== dateKey) continue;
    appendDayRows(rows, day);
    var options = arguments[2] || {};
    if (options.showUnknown === true && day.known !== true && day.hasGames !== true) {
      rows.pop();
      if (options.loading === true) {
        rows.push({kind: "loading", rowId: "loading:calendar:" + dateKey,
          retained: false, label: "Loading scores…", action: null});
      } else if (options.unavailable === true) {
        rows.push({kind: "status", rowId: "status:calendar:" + dateKey,
          status: {displayName: "Calendar", loading: false,
            errorCode: options.errorCode || "unavailable",
            errorSummary: options.errorSummary || "Scores unavailable",
            stale: false, partialErrorCount: 0, lastSuccessAt: null},
          action: {type: "retry", label: "Retry scores", enabled: true}});
      } else {
        rows.push({kind: "empty", rowId: "unknown:calendar:" + dateKey,
          text: "Games not checked", title: "", supportingText: "",
          action: null});
      }
    }
    break;
  }
  return rows;
}

// Bounded per-day overview for the calendar week strip. Summaries project the
// already-composed state only: counts come from the admitted games, league
// dots from first-seen normalized game leagues (capped), favorite highlights
// from explicit annotated presentation flags, and today/center marks from the
// caller-supplied keys. Malformed input fails closed to an empty list.
function daySummaries(calendar, options) {
  var result = [];
  if (!isRecord(calendar) || !Array.isArray(calendar.days)) return result;
  var config = isRecord(options) ? options : {};
  var today = typeof config.todayDateKey === "string" ? config.todayDateKey : "";
  calendar.days.forEach(function(day) {
    if (!isRecord(day) || !isDateKey(day.dateKey)) return;
    var games = Array.isArray(day.games) ? day.games : [];
    var leagueIds = [];
    var favoriteCount = 0;
    games.forEach(function(game) {
      if (!isRecord(game)) return;
      var leagueId = normalizeLeagueId(game.league);
      if (leagueId && leagueIds.indexOf(leagueId) === -1
          && leagueIds.length < MAX_LEAGUES_PER_DAY_SUMMARY) leagueIds.push(leagueId);
      if (isRecord(game.presentation) && game.presentation.isFavorite === true)
        favoriteCount++;
    });
    result.push({
      dateKey: day.dateKey,
      label: typeof day.label === "string" && day.label ? day.label : shortDateLabel(day.dateKey),
      weekday: weekdayLabel(day.dateKey),
      month: MONTHS[Number(day.dateKey.split("-")[1]) - 1] || "",
      dayOfMonth: dayOfMonthLabel(day.dateKey),
      gameCount: games.length,
      hasGames: games.length > 0,
      known: day.known === true,
      state: day.unavailable ? "unavailable" : day.partial ? "partial" : day.stale ? "stale"
        : day.known === true ? (games.length > 0 ? "known" : "empty") : "unknown",
      leagueIds: leagueIds,
      hasFavoriteGames: favoriteCount > 0,
      isToday: today !== "" && day.dateKey === today,
      isCenter: day.dateKey === calendar.centerDateKey
    });
  });
  return result;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    DEFAULT_HALF_WIDTH_DAYS: DEFAULT_HALF_WIDTH_DAYS,
    MAX_HALF_WIDTH_DAYS: MAX_HALF_WIDTH_DAYS,
    MAX_GAMES_PER_DAY: MAX_GAMES_PER_DAY,
    MAX_TIME_LABEL_LENGTH: MAX_TIME_LABEL_LENGTH,
    MAX_LEAGUES_PER_DAY_SUMMARY: MAX_LEAGUES_PER_DAY_SUMMARY,
    MAX_MONTH_CELLS: MAX_MONTH_CELLS,
    addMonths: addMonths,
    compose: compose,
    flatten: flatten,
    flattenDay: flattenDay,
    daySummaries: daySummaries,
    monthDateKeys: monthDateKeys,
    monthGrid: monthGrid,
    monthKey: monthKey,
    nextGamesDateKey: nextGamesDateKey,
    localTimeLabel: localTimeLabel,
    gameDateKey: gameDateKey,
    gameIdentity: gameIdentity
  };
}

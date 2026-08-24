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

var DEFAULT_HALF_WIDTH_DAYS = 2;
var MAX_HALF_WIDTH_DAYS = 7;
var MAX_GAMES_PER_DAY = 64;

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

function windowKeys(centerDateKey, halfWidth) {
  if (!isDateKey(centerDateKey)) return [];
  var keys = [];
  for (var offset = -halfWidth; offset <= halfWidth; offset++) {
    var key = addDays(centerDateKey, offset);
    if (isDateKey(key)) keys.push(key);
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
  var keys = windowKeys(center, halfWidth);

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
      games: []
    };
    byDate[dateKey] = day;
    calendar.days.push(day);
  });

  var seenByDate = {};
  keys.forEach(function(dateKey) { seenByDate[dateKey] = {}; });

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
  });
  calendar.hasGames = calendar.gameCount > 0;
  return calendar;
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

function flatten(calendar) {
  var rows = [];
  if (!isRecord(calendar) || !Array.isArray(calendar.days)) return rows;
  calendar.days.forEach(function(day) {
    if (!isRecord(day)) return;
    rows.push(sectionRow("calendar:" + day.dateKey, day.label || day.dateKey));
    if (day.hasGames !== true) {
      rows.push(emptyDayRow(day.dateKey));
      return;
    }
    (Array.isArray(day.games) ? day.games : []).forEach(function(game) {
      var row = gameRow(game);
      if (row) rows.push(row);
    });
  });
  return rows;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    DEFAULT_HALF_WIDTH_DAYS: DEFAULT_HALF_WIDTH_DAYS,
    MAX_HALF_WIDTH_DAYS: MAX_HALF_WIDTH_DAYS,
    MAX_GAMES_PER_DAY: MAX_GAMES_PER_DAY,
    compose: compose,
    flatten: flatten,
    gameDateKey: gameDateKey,
    gameIdentity: gameIdentity
  };
}

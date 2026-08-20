var DateModel = null;
if (typeof require === "function") DateModel = require("./DateModel.js");

var MAX_LOOKAHEAD_DAYS = 35;

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function dateKeyFromGame(game) {
  if (!isRecord(game) || typeof game.startTime !== "string") return "";
  if (DateModel) return DateModel.dateKeyFromTimestamp(game.startTime);
  var date = new Date(game.startTime);
  if (isNaN(date.getTime())) return "";
  return date.getFullYear() + "-" + String(date.getMonth() + 1).padStart(2, "0")
    + "-" + String(date.getDate()).padStart(2, "0");
}

function validDateKey(value) {
  return typeof value === "string" && /^\d{4}-\d{2}-\d{2}$/.test(value);
}

function calendarDistanceFallback(value, referenceKey) {
  if (!validDateKey(value) || !validDateKey(referenceKey)) return null;
  var left = value.split("-").map(Number);
  var right = referenceKey.split("-").map(Number);
  var leftOrdinal = Date.UTC(left[0], left[1] - 1, left[2]);
  var rightOrdinal = Date.UTC(right[0], right[1] - 1, right[2]);
  return Math.round((leftOrdinal - rightOrdinal) / 86400000);
}

function findNext(games, selectedDateKey) {
  var isValidDate = DateModel ? DateModel.isDateKey : validDateKey;
  var distance = DateModel ? DateModel.calendarDistance : calendarDistanceFallback;
  if (!Array.isArray(games) || !isValidDate(selectedDateKey)) return null;
  var candidates = games.filter(function(game) {
    if (!isRecord(game) || game.isValid !== true || game.status === "canceled") return false;
    var dateKey = dateKeyFromGame(game);
    return isValidDate(dateKey) && distance(dateKey, selectedDateKey) > 0;
  });
  candidates.sort(function(left, right) {
    return new Date(left.startTime).getTime() - new Date(right.startTime).getTime();
  });
  if (candidates.length === 0) return null;
  return {dateKey: dateKeyFromGame(candidates[0]), game: candidates[0]};
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    MAX_LOOKAHEAD_DAYS: MAX_LOOKAHEAD_DAYS,
    dateKeyFromGame: dateKeyFromGame,
    findNext: findNext
  };
}

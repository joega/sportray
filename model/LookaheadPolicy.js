// Pure guards for provider schedule lookahead. A provider may return an empty
// page with a date that does not advance, so callers must validate each hop
// before starting another request.

var DateModel = null;
var NextEventModel = null;
if (typeof require === "function") {
  DateModel = require("./DateModel.js");
  NextEventModel = require("./NextEventModel.js");
}

var MAX_HOPS = 8;

function finish(reason) {
  return {kind: "finish", reason: reason};
}

function isValidDate(value) {
  return DateModel ? DateModel.isDateKey(value)
    : typeof value === "string" && /^\d{4}-\d{2}-\d{2}$/.test(value);
}

function calendarDistance(value, reference) {
  if (DateModel) return DateModel.calendarDistance(value, reference);
  var left = value.split("-").map(Number);
  var right = reference.split("-").map(Number);
  return Math.round((Date.UTC(left[0], left[1] - 1, left[2])
    - Date.UTC(right[0], right[1] - 1, right[2])) / 86400000);
}

function decideNextDate(selectedDateKey, requestedDateKey, nextDateKey, hopCount) {
  if (!isValidDate(selectedDateKey) || !isValidDate(requestedDateKey)
      || !isValidDate(nextDateKey))
    return finish("invalid-date");

  if (calendarDistance(nextDateKey, requestedDateKey) <= 0)
    return finish("non-progressing-date");

  if (calendarDistance(nextDateKey, selectedDateKey)
      > (NextEventModel ? NextEventModel.MAX_LOOKAHEAD_DAYS : 35))
    return finish("out-of-range");

  var hops = Number(hopCount);
  if (!isFinite(hops) || Math.floor(hops) !== hops || hops < 0 || hops >= MAX_HOPS)
    return finish("hop-limit");

  return {kind: "request", dateKey: nextDateKey, hopCount: hops + 1};
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    MAX_HOPS: MAX_HOPS,
    decideNextDate: decideNextDate
  };
}

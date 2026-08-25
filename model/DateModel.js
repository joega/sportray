// Pure local-date math for the scoreboard date carousel and provider query
// keys. Keep date selection independent from QML views and provider parsing.

var WEEKDAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
var MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

function pad(value) {
  return String(value).length < 2 ? "0" + value : String(value);
}

function isDateKeyShape(value) {
  return typeof value === "string" && /^\d{4}-\d{2}-\d{2}$/.test(value);
}

function parseDateKey(value) {
  if (!isDateKeyShape(value)) return new Date(NaN);
  var parts = value.split("-").map(Number);
  return new Date(parts[0], parts[1] - 1, parts[2]);
}

function dateKey(year, month, day) {
  return String(year) + "-" + pad(Number(month) + 1) + "-" + pad(day);
}

function isDateKey(value) {
  if (!isDateKeyShape(value)) return false;
  var date = parseDateKey(value);
  return !isNaN(date.getTime())
    && dateKey(date.getFullYear(), date.getMonth(), date.getDate()) === value;
}

function localDateKey(value) {
  var date = value instanceof Date ? value : new Date(value);
  if (isNaN(date.getTime())) return "";
  return dateKey(date.getFullYear(), date.getMonth(), date.getDate());
}

function dateKeyFromTimestamp(value) {
  return localDateKey(value);
}

function addDays(value, delta) {
  var date = parseDateKey(value);
  if (isNaN(date.getTime())) return "";
  date.setDate(date.getDate() + Number(delta || 0));
  return localDateKey(date);
}

function carouselDates(selectedKey, halfWidth) {
  var center = isDateKey(selectedKey) ? selectedKey : localDateKey(new Date());
  var radius = isFinite(Number(halfWidth)) ? Math.max(0, Number(halfWidth)) : 2;
  var dates = [];
  for (var offset = -radius; offset <= radius; offset++) {
    var key = addDays(center, offset);
    var date = parseDateKey(key);
    dates.push({
      key: key,
      weekday: WEEKDAYS[date.getDay()],
      day: date.getDate(),
      month: MONTHS[date.getMonth()],
      year: date.getFullYear()
    });
  }
  return dates;
}

function calendarDistance(value, referenceKey) {
  if (!isDateKey(value) || !isDateKey(referenceKey)) return null;
  var valueDate = parseDateKey(value);
  var referenceDate = parseDateKey(referenceKey);
  var valueOrdinal = Date.UTC(valueDate.getFullYear(), valueDate.getMonth(), valueDate.getDate());
  var referenceOrdinal = Date.UTC(
    referenceDate.getFullYear(), referenceDate.getMonth(), referenceDate.getDate());
  return Math.round((valueOrdinal - referenceOrdinal) / 86400000);
}

function relativeDayLabel(value, todayKey) {
  var distance = calendarDistance(value, todayKey);
  if (distance === null) return "Date unavailable";
  if (distance === 0) return "Today";
  if (distance === -1) return "Yesterday";
  if (distance === 1) return "Tomorrow";
  if (distance < 0) return Math.abs(distance) + " days ago";
  return distance + " days from now";
}

function displayLabel(value, todayKey) {
  return relativeDayLabel(value, todayKey);
}

function shortDateLabel(value) {
  if (!isDateKey(value)) return "Date unavailable";
  var date = parseDateKey(value);
  return WEEKDAYS[date.getDay()] + ", " + MONTHS[date.getMonth()] + " " + date.getDate();
}

function providerDateKey(value) {
  return isDateKey(value) ? value.replace(/-/g, "") : "";
}

function monthKey(value) {
  if (!isDateKey(value)) return "";
  return value.slice(0, 7) + "-01";
}

function addMonths(value, delta) {
  var base = monthKey(value);
  if (!base) return "";
  var parts = base.split("-").map(Number);
  var offset = Number(delta);
  if (!isFinite(offset)) return "";
  var date = new Date(parts[0], parts[1] - 1, 1);
  date.setMonth(date.getMonth() + Math.trunc(offset));
  return dateKey(date.getFullYear(), date.getMonth(), 1);
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    addDays: addDays,
    carouselDates: carouselDates,
    dateKey: dateKey,
    dateKeyFromTimestamp: dateKeyFromTimestamp,
    displayLabel: displayLabel,
    isDateKey: isDateKey,
    localDateKey: localDateKey,
    monthKey: monthKey,
    addMonths: addMonths,
    parseDateKey: parseDateKey,
    providerDateKey: providerDateKey,
    relativeDayLabel: relativeDayLabel,
    shortDateLabel: shortDateLabel,
    calendarDistance: calendarDistance
  };
}

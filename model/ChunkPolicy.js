// Pure planning and admission guards for a future bounded calendar range
// owner. This module deliberately owns no provider parsing, remote I/O,
// view, process, timer, cache, or polling state.

var DateModel = null;
var ResponsePolicy = null;
if (typeof require === "function") {
  DateModel = require("./DateModel.js");
  ResponsePolicy = require("./ResponsePolicy.js");
}

var MAX_REQUESTS = 8;
var MAX_CONCURRENCY = 1;
var MAX_RANGE_DAYS = 42;
var MAX_RESPONSE_BYTES = ResponsePolicy ? ResponsePolicy.MAX_RESPONSE_BYTES : 2 * 1024 * 1024;
var MAX_EVENTS = ResponsePolicy ? ResponsePolicy.MAX_EVENTS : 256;
var OBSERVED_ESPN_EVENT_CAP = 100;

// These are evidence-gated profiles, not provider request configuration. A
// false profile remains an honest unsupported result until new observations
// establish a safe shape.
var PROFILES = {
  "espn-nfl": {maxDays: 7, observedCap: OBSERVED_ESPN_EVENT_CAP},
  "espn-mlb": {maxDays: 1, observedCap: OBSERVED_ESPN_EVENT_CAP},
  "espn-nba": {maxDays: 7, observedCap: OBSERVED_ESPN_EVENT_CAP},
  "espn-epl": {maxDays: 7, observedCap: OBSERVED_ESPN_EVENT_CAP},
  "espn-mls": {maxDays: 7, observedCap: OBSERVED_ESPN_EVENT_CAP},
  "espn-cfb": {supported: false},
  "espn-ncaab": {supported: false},
  "nhl": {maxDays: 7, requiresContinuation: true},
  "mlb-stats": {supported: false}
};

function validDate(value) {
  return DateModel ? DateModel.isDateKey(value)
    : typeof value === "string" && /^\d{4}-\d{2}-\d{2}$/.test(value);
}

function distance(left, right) {
  return DateModel ? DateModel.calendarDistance(left, right)
    : Math.round((Date.parse(left) - Date.parse(right)) / 86400000);
}

function addDays(value, days) {
  return DateModel ? DateModel.addDays(value, days) : "";
}

function profileFor(providerId) {
  return typeof providerId === "string" ? PROFILES[providerId] || null : null;
}

function plan(providerId, startDate, endDate) {
  var profile = profileFor(providerId);
  if (!profile || profile.supported === false) return {kind: "reject", reason: "unsupported-provider"};
  if (!validDate(startDate) || !validDate(endDate)) return {kind: "reject", reason: "invalid-date"};
  var span = distance(endDate, startDate) + 1;
  if (span < 1 || span > MAX_RANGE_DAYS) return {kind: "reject", reason: "date-span"};

  var windows = [];
  var cursor = startDate;
  while (distance(endDate, cursor) >= 0) {
    if (windows.length >= MAX_REQUESTS) return {kind: "reject", reason: "request-count"};
    var days = Math.min(profile.maxDays, distance(endDate, cursor) + 1);
    var windowEnd = addDays(cursor, days - 1);
    windows.push({startDate: cursor, endDate: windowEnd, spanDays: days});
    cursor = addDays(windowEnd, 1);
  }
  return {kind: "plan", providerId: providerId, windows: windows,
    requestCount: windows.length, maxConcurrency: MAX_CONCURRENCY};
}

function admit(providerId, observation) {
  var profile = profileFor(providerId);
  if (!profile || profile.supported === false) return {kind: "reject", reason: "unsupported-provider"};
  if (!observation || observation.status !== 200) return {kind: "reject", reason: "status"};
  if (!Number.isInteger(observation.bytes) || observation.bytes < 0
      || observation.bytes > MAX_RESPONSE_BYTES) return {kind: "reject", reason: "bytes"};
  if (!Number.isInteger(observation.eventCount) || observation.eventCount < 0
      || observation.eventCount > MAX_EVENTS) return {kind: "reject", reason: "events"};
  if (!Number.isInteger(observation.dateSpanDays) || observation.dateSpanDays < 1
      || observation.dateSpanDays > profile.maxDays) return {kind: "reject", reason: "date-span"};
  if (observation.complete !== true) return {kind: "reject", reason: "incomplete"};
  if (profile.observedCap && observation.eventCount >= profile.observedCap)
    return {kind: "reject", reason: "provider-event-cap"};
  if (profile.requiresContinuation
      && typeof observation.nextDateKey !== "string")
    return {kind: "reject", reason: "missing-continuation"};
  return {kind: "accept", providerId: providerId};
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    MAX_REQUESTS: MAX_REQUESTS,
    MAX_CONCURRENCY: MAX_CONCURRENCY,
    MAX_RANGE_DAYS: MAX_RANGE_DAYS,
    MAX_RESPONSE_BYTES: MAX_RESPONSE_BYTES,
    MAX_EVENTS: MAX_EVENTS,
    OBSERVED_ESPN_EVENT_CAP: OBSERVED_ESPN_EVENT_CAP,
    profileFor: profileFor,
    plan: plan,
    admit: admit
  };
}

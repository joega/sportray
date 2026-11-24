// Transient action feedback and field-level reconciliation only. No provider
// objects, whole-settings Undo snapshots, or feedback enter persistent state.
var FEEDBACK_TTL_MS = 8000;
var MAX_WATCHES = 32;
var MAX_FAVORITES = 32;

function record(value) { return value !== null && typeof value === "object" && !Array.isArray(value); }
function same(left, right) { return JSON.stringify(left) === JSON.stringify(right); }
function cleanLabel(value) {
  return typeof value === "string" ? value.replace(/[\u0000-\u001f\u007f\u202a-\u202e\u2066-\u2069]/g, " ")
    .replace(/\s+/g, " ").trim().slice(0, 128) : "";
}
function action(id, kind, targetId, before, after, label, now) {
  var text = cleanLabel(label);
  return {id: id, kind: kind, targetId: targetId,
    before: record(before) ? Object.assign({}, before) : before,
    after: record(after) ? Object.assign({}, after) : after,
    label: text, summary: kind === "favorite" ? (text || "Team") + (after ? " added to favorites" : " removed from favorites")
      : (text ? text + " · " : "") + (after ? "Game alerts on" : "Game alerts off"),
    expiresAt: now + FEEDBACK_TTL_MS, undone: false, severity: "info"};
}
function watchFor(watches, id, watchApi) {
  if (!Array.isArray(watches) || !watchApi) return null;
  for (var i = 0; i < Math.min(watches.length, MAX_WATCHES); i++) {
    var watch = watchApi.normalizeEntry(watches[i]);
    if (watch && watch.gameId === id) return watch;
  }
  return null;
}
function matches(action, settings, watches, watchApi) {
  if (!record(action) || !record(settings)) return false;
  if (action.kind === "favorite") return Array.isArray(settings.favoriteTeamIds)
    && (settings.favoriteTeamIds.indexOf(action.targetId) !== -1) === action.after;
  if (action.kind === "watch") return same(watchFor(watches, action.targetId, watchApi), action.after);
  return false;
}
function canUndo(action, settings, watches, now, ready, shuttingDown, opaque, watchApi) {
  if (!ready || shuttingDown || opaque || !record(action) || action.undone
      || typeof action.expiresAt !== "number" || !isFinite(action.expiresAt)
      || typeof now !== "number" || !isFinite(now) || now >= action.expiresAt
      || !matches(action, settings, watches, watchApi)) return false;
  if (action.kind === "favorite") return typeof action.before === "boolean"
    && typeof action.after === "boolean" && action.before !== action.after
    && (!action.before || settings.favoriteTeamIds.length < MAX_FAVORITES);
  if (action.kind !== "watch" || !watchApi) return false;
  if (action.before === null) return action.after !== null;
  var before = watchApi.normalizeEntry(action.before);
  return before !== null && same(before, action.before)
    && before.gameId === action.targetId && watchApi.expiry(before, now) === "active"
    && Array.isArray(settings.enabledLeagues) && settings.enabledLeagues.indexOf(before.league) !== -1
    && watchApi.removeExpired(watches, now).length < MAX_WATCHES;
}

function patchIds(base, incoming, desired, preserveOrder) {
  var result = incoming.slice();
  for (var i = 0; i < base.length; i++) {
    if (desired.indexOf(base[i]) === -1) result = result.filter(function(id) { return id !== base[i]; });
  }
  for (var j = 0; j < desired.length; j++) {
    if (base.indexOf(desired[j]) === -1 && result.indexOf(desired[j]) === -1) result.push(desired[j]);
  }
  if (preserveOrder && !same(base, desired)) {
    var ordered = desired.filter(function(id) { return result.indexOf(id) !== -1; });
    result.forEach(function(id) { if (ordered.indexOf(id) === -1) ordered.push(id); });
    result = ordered;
  }
  return result;
}
// A helper read may complete after a local intent was queued. Rebase only
// explicitly changed fields, retaining unrelated external preference changes.
function mergeSettings(base, incoming, desired, settingsApi) {
  var before = settingsApi.normalizeSettings(base).settings;
  var current = settingsApi.normalizeSettings(incoming).settings;
  var pending = settingsApi.normalizeSettings(desired).settings;
  ["enabledLeagues", "followedLeagueIds", "favoriteTeamIds"].forEach(function(key) {
    current[key] = patchIds(before[key], current[key], pending[key], key === "followedLeagueIds");
  });
  ["notifications", "ticker"].forEach(function(group) {
    Object.keys(pending[group]).forEach(function(key) {
      if (before[group][key] !== pending[group][key]) current[group][key] = pending[group][key];
    });
  });
  return settingsApi.normalizeSettings(current).settings;
}
function mergeWatches(base, incoming, desired, now, watchApi, enabledLeagues) {
  var before = watchApi.removeExpired(base, now);
  var current = watchApi.removeExpired(incoming, now);
  var pending = watchApi.removeExpired(desired, now);
  var ids = [];
  before.concat(pending).forEach(function(entry) { if (ids.indexOf(entry.gameId) === -1) ids.push(entry.gameId); });
  ids.forEach(function(id) {
    var old = watchFor(before, id, watchApi), next = watchFor(pending, id, watchApi);
    var observed = watchFor(current, id, watchApi);
    if (same(old, next) || !same(observed, old) && !same(observed, next)) return;
    if (next && old === null && Array.isArray(enabledLeagues)
        && enabledLeagues.indexOf(next.league) === -1) return;
    var result = current.filter(function(entry) { return entry.gameId !== id; });
    if (next && result.length >= MAX_WATCHES) return;
    if (next) result.push(next);
    current = result;
  });
  return watchApi.normalizeWatches(current, now).watches;
}

if (typeof module !== "undefined" && module.exports) module.exports = {
  FEEDBACK_TTL_MS: FEEDBACK_TTL_MS, cleanLabel: cleanLabel, action: action,
  matches: matches, canUndo: canUndo, mergeSettings: mergeSettings, mergeWatches: mergeWatches
};

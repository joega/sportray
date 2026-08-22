// Pure ownership bookkeeping for the engine-wide Sportray service. Panel
// instances are views; only the shared service may own polling, notification
// transition baselines, or the persistent settings store.
function emptyContexts() {
  return {};
}

function updateContext(contexts, token, open, lookaheadLeagueId) {
  var key = typeof token === "string" ? token : "";
  if (!key) return contexts || emptyContexts();
  var next = {};
  var source = contexts && typeof contexts === "object" ? contexts : {};
  for (var existing in source) next[existing] = source[existing];
  next[key] = {
    open: open === true,
    lookaheadLeagueId: typeof lookaheadLeagueId === "string" ? lookaheadLeagueId : ""
  };
  return next;
}

function removeContext(contexts, token) {
  var key = typeof token === "string" ? token : "";
  var next = {};
  var source = contexts && typeof contexts === "object" ? contexts : {};
  for (var existing in source) {
    if (existing !== key) next[existing] = source[existing];
  }
  return next;
}

function anyPanelOpen(contexts) {
  var source = contexts && typeof contexts === "object" ? contexts : {};
  for (var token in source) {
    if (source[token] && source[token].open === true) return true;
  }
  return false;
}

function lookaheadLeagueId(contexts) {
  var source = contexts && typeof contexts === "object" ? contexts : {};
  var selected = "";
  for (var token in source) {
    var context = source[token];
    if (context && context.open === true && context.lookaheadLeagueId) selected = context.lookaheadLeagueId;
  }
  return selected;
}

if (typeof module !== "undefined") {
  module.exports = {
    emptyContexts: emptyContexts,
    updateContext: updateContext,
    removeContext: removeContext,
    anyPanelOpen: anyPanelOpen,
    lookaheadLeagueId: lookaheadLeagueId
  };
}

// Resolve an open detail from the existing league/day scoreboard. This model
// neither fetches data nor changes the selected game, date, or view position.
var DEFAULT_STALE_THRESHOLD_MS = 20 * 60 * 1000;

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function validGame(value) {
  return isRecord(value) && value.isValid === true
    && typeof value.id === "string" && value.id !== ""
    && typeof value.league === "string" && value.league !== "";
}

function timestamp(value) {
  if (typeof value !== "string" || value === "") return null;
  var parsed = Date.parse(value);
  return isFinite(parsed) ? parsed : null;
}

function ageLabel(lastSuccessAt, nowMs) {
  var updated = timestamp(lastSuccessAt);
  if (updated === null || typeof nowMs !== "number" || !isFinite(nowMs))
    return "update time unavailable";
  var minutes = Math.floor(Math.max(0, nowMs - updated) / 60000);
  return minutes < 1 ? "less than a minute ago" : minutes + " min ago";
}

function resolve(selection, leagueStates, selectedDateKey, nowMs) {
  var snapshot = isRecord(selection) && validGame(selection.game) ? selection.game : null;
  var result = {
    game: snapshot, stale: false, missing: false, loading: false,
    lastSuccessAt: snapshot && timestamp(selection.lastSuccessAt) !== null
      ? selection.lastSuccessAt : "", message: ""
  };
  if (!snapshot) return result;

  // A new selected slate cannot supply the health or identity of a detail
  // opened on a different date, even when the provider repeats an event ID.
  if (typeof selection.dateKey !== "string" || selection.dateKey === ""
      || selection.dateKey !== selectedDateKey) {
    result.stale = true;
    result.message = "Showing the game from the previously selected date";
    return result;
  }

  var states = Array.isArray(leagueStates) ? leagueStates : [];
  var state = null;
  for (var i = 0; i < states.length; i++) {
    if (isRecord(states[i]) && states[i].leagueId === snapshot.league) {
      state = states[i];
      break;
    }
  }
  if (!state) {
    result.stale = true;
    result.message = "Scores are unavailable for this league · showing last update";
    return result;
  }

  result.loading = state.loading === true;
  var games = Array.isArray(state.games) ? state.games : [];
  var current = null;
  for (var j = 0; j < games.length; j++) {
    if (validGame(games[j]) && games[j].id === snapshot.id
        && games[j].league === snapshot.league) {
      current = games[j];
      break;
    }
  }
  // On a failed refresh LeagueFetch retains its last-good games. Resolving
  // that retained identity prevents a failure from rewinding an open detail
  // to the score originally clicked. On disappearance the caller keeps this
  // returned game as its next fallback snapshot, without changing identity.
  if (current && state.hasData === true) {
    result.game = current;
    result.lastSuccessAt = timestamp(state.lastSuccessAt) === null ? "" : state.lastSuccessAt;
  }

  var failed = typeof state.errorCode === "string" && state.errorCode !== "";
  var success = timestamp(result.lastSuccessAt);
  var threshold = typeof state.staleThresholdMs === "number"
    && isFinite(state.staleThresholdMs) && state.staleThresholdMs > 0
      ? state.staleThresholdMs : DEFAULT_STALE_THRESHOLD_MS;
  var expired = success !== null && typeof nowMs === "number" && isFinite(nowMs)
    && nowMs > success + threshold;
  result.missing = !current && state.hasData === true && !result.loading && !failed;
  result.stale = state.stale === true || failed || expired || state.hasData !== true || !current;
  var age = ageLabel(result.lastSuccessAt, nowMs);

  if (result.missing)
    result.message = "Game is no longer in the latest scores · showing last update · " + age;
  else if (failed)
    result.message = (state.errorCode === "partial-data"
      ? "Some scores could not be updated" : "Scores are temporarily unavailable")
      + " · showing last update · " + age;
  else if (result.stale)
    result.message = "Showing last update · " + age + (result.loading ? " · refreshing…" : "");
  else if (result.loading)
    result.message = "Refreshing scores… · updated " + age;
  else if (result.lastSuccessAt)
    result.message = "Updated " + age;
  return result;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {resolve: resolve};
}

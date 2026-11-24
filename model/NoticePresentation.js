// Presentation only: consume normalized request/coverage state without changing
// freshness, admission, provider data, or retry policy.
var MAX_SOURCES = 8;
var MAX_TEXT = 512;

function record(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function clean(value, limit) {
  return typeof value === "string" ? value.replace(/[\u0000-\u001f\u007f\u202a-\u202e\u2066-\u2069]/g, " ")
    .replace(/\s+/g, " ").trim().slice(0, limit || MAX_TEXT) : "";
}

function ageFor(value, nowMs) {
  var timestamp = typeof value === "string" ? Date.parse(value) : NaN;
  var now = typeof nowMs === "number" ? nowMs : Date.now();
  if (!isFinite(timestamp) || !isFinite(now) || timestamp > now) return "age unavailable";
  var minutes = Math.floor((now - timestamp) / 60000);
  return minutes < 1 ? "less than a minute ago" : minutes + " min ago";
}

function nounFor(kind) {
  if (kind === "standings") return "standings";
  if (kind === "schedule" || kind === "calendar" || kind === "global") return "schedule";
  if (kind === "detail") return "game";
  return "scores";
}

function titleCase(value) { return value.slice(0, 1).toUpperCase() + value.slice(1); }

function sourcesFor(value) {
  var result = [], seen = Object.create(null);
  // Trusted QVariantList inputs may be array-like. Never traverse unbounded
  // collections or use provider text as an object prototype key.
  if (!value || typeof value !== "object" || typeof value.length !== "number"
      || value.length < 0 || Math.floor(value.length) !== value.length) return result;
  for (var i = 0; i < Math.min(value.length, MAX_SOURCES); i++) {
    var source = value[i], object = record(source) ? source : {};
    var name = clean(typeof source === "string" ? source
      : object.displayName || object.label || object.leagueId || object.id, 64);
    if (!name || seen[name]) continue;
    seen[name] = true;
    result.push({name: name, id: clean(object.leagueId || object.id || name, 64),
      lastSuccessAt: clean(object.lastSuccessAt, 64), stale: object.stale === true,
      loading: object.loading === true, partial: object.partial === true,
      failed: object.failed === true || Boolean(object.errorCode),
      errorSummary: clean(object.errorSummary)});
  }
  return result;
}

function noticeFor(input, nowMs) {
  var state = record(input) ? input : {};
  var kind = clean(state.kind, 32) || "scores";
  var noun = nounFor(kind), label = clean(state.displayName, 80);
  var loading = state.loading === true, stale = state.stale === true;
  var partial = state.partial === true || state.errorCode === "partial-data";
  var hasData = state.hasData === true || stale;
  var error = clean(state.errorSummary || state.message);
  var sources = sourcesFor(state.affectedLeagues);
  var names = sources.map(function(source) { return source.name; }).join(", ");
  var prefix = label && label.toLowerCase() !== noun ? label + " · " : "";
  var explicitFailure = state.failed === true || Boolean(state.errorCode)
    || (state.failed === undefined && error !== "" && !partial
      && state.emptySelection !== true && state.unloaded !== true && state.empty !== true);
  var sourceProblems = sources.some(function(source) {
    return source.stale || source.failed || source.partial;
  });
  // The aggregate caller may provide only affected names. Their presence is
  // sufficient to name the unavailable sources, without altering game state.
  if (sources.length && !loading) sourceProblems = true;
  var age = state.lastSuccessAt ? ageFor(state.lastSuccessAt, nowMs) : "";
  var summary = "", detail = "", severity = "info", canRetry = false;

  if (state.emptySelection === true) {
    summary = prefix + (clean(state.summary) || "Choose leagues to follow");
    detail = error || "Follow a league in Sports & leagues to see its games here.";
  } else if (state.unloaded === true && !loading && !hasData && !explicitFailure) {
    summary = prefix + (clean(state.summary) || "Select a day to load its games");
  } else if (state.empty === true && !loading && !explicitFailure && !partial) {
    summary = prefix + (clean(state.summary) || "No " + (noun === "standings" ? "standings available" : "games listed"));
    detail = clean(state.detail);
  } else if (sourceProblems) {
    summary = names + " · " + (hasData ? "updates delayed" : "unavailable");
    severity = hasData ? "warning" : "error";
    var ages = sources.filter(function(source) { return source.lastSuccessAt; }).map(function(source) {
      return {time: Date.parse(source.lastSuccessAt), text: ageFor(source.lastSuccessAt, nowMs)};
    }).filter(function(item) { return isFinite(item.time); }).sort(function(a, b) { return a.time - b.time; });
    if (ages.length) {
      age = ages[0].text;
      summary += " · " + (sources.length > 1 ? "oldest update " : "last update ") + age;
    } else if (stale) summary += " · age unavailable";
    if (loading) summary += " · updating…";
    detail = sources.map(function(source) {
      var text = source.errorSummary || (source.partial ? "Some results are unavailable."
        : source.stale ? "Showing the last available results." : "Results are unavailable.");
      if (source.lastSuccessAt) text += " Last update " + ageFor(source.lastSuccessAt, nowMs) + ".";
      return source.name + ": " + text;
    }).join("\n");
    canRetry = !loading;
  } else if (stale) {
    severity = "warning";
    summary = prefix + (state.lastSuccessAt ? "last update " + age : "limited " + noun);
    if (loading) summary += " · updating…";
    detail = error || "Showing the last available " + noun + (loading ? " while updating." : ".");
    canRetry = !loading;
  } else if (explicitFailure) {
    severity = hasData ? "warning" : "error";
    summary = prefix + (hasData ? "some " + noun + " unavailable" : titleCase(noun) + " unavailable");
    if (loading) summary += " · updating…";
    detail = error || "Try updating again.";
    canRetry = !loading;
  } else if (partial) {
    summary = prefix + (noun === "schedule" ? "Schedule incomplete" : "Some " + noun + " unavailable");
    severity = noun === "schedule" ? "info" : "warning";
    detail = error || (noun === "schedule"
      ? "Only listed games are shown. Unloaded or unpublished dates do not prove there are no games."
      : "Some results could not be updated. Available results are still shown.");
    if (loading) summary += " · updating…";
    canRetry = noun !== "schedule" && !loading;
  } else if (loading) {
    summary = prefix + (hasData ? "Updating " : "Loading ") + noun + "…";
  } else if (!hasData && error) {
    summary = prefix + error;
  }

  if (typeof state.canRetry === "boolean") canRetry = canRetry && state.canRetry;
  var visible = summary !== "";
  var accessibleSummary = [summary, detail].filter(function(text) { return text !== ""; }).join(". ");
  if (stale) accessibleSummary += ". Stale " + noun + ".";
  // Polling can add or recover an affected league without changing the
  // surrounding view. Keep an opened disclosure stable within that context.
  return {visible: visible, id: clean(state.id || state.contextKey, 128) || kind + ":" + label, summary: summary,
    detail: detail, severity: severity, canRetry: visible && canRetry,
    loading: loading, stale: stale, partial: partial, age: age,
    affectedLeagueIds: sources.map(function(source) { return source.id; }),
    accessibleSummary: accessibleSummary};
}

if (typeof module !== "undefined" && module.exports) module.exports = {
  noticeFor: noticeFor, ageFor: ageFor
};

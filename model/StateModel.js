var SettingsModel = null;
var TransitionDedupe = null;
var WatchPolicy = null;
if (typeof require === "function") {
  SettingsModel = require("./SettingsModel.js");
  TransitionDedupe = require("./TransitionDedupe.js");
  WatchPolicy = require("./WatchPolicy.js");
}

var SCHEMA_VERSION = 2;
var MIN_SUPPORTED_SCHEMA_VERSION = 1;
var SETTINGS_FIELDS = ["schemaVersion", "enabledLeagues", "followedLeagueIds", "favoriteTeamIds", "notifications"];
var STATE_FIELDS = SETTINGS_FIELDS.concat(["transitionDedupe", "watchedGames"]);

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function isFutureSchema(value) {
  return isRecord(value)
    && typeof value.schemaVersion === "number"
    && value.schemaVersion > SCHEMA_VERSION;
}

function copySettingsFields(value) {
  var source = isRecord(value) ? value : {};
  return {
    schemaVersion: source.schemaVersion,
    enabledLeagues: source.enabledLeagues,
    followedLeagueIds: source.followedLeagueIds,
    favoriteTeamIds: source.favoriteTeamIds,
    notifications: source.notifications
  };
}

function settingsModule(value) {
  return value || SettingsModel;
}

function dedupeModule(value) {
  return value || TransitionDedupe;
}

function createState(settings, dedupeState, settingsApi, dedupeApi, currentTime, watchedGames, watchApi) {
  var Settings = settingsModule(settingsApi);
  var Dedupe = dedupeModule(dedupeApi);
  var normalizedSettings = Settings.normalizeSettings(settings).settings;
  var normalizedDedupe = Dedupe.normalizeState(dedupeState, currentTime).state;
  var Watches = watchApi || WatchPolicy;
  var normalizedWatches = Watches.normalizeWatches(watchedGames, currentTime).watches;
  return {
    schemaVersion: SCHEMA_VERSION,
    enabledLeagues: normalizedSettings.enabledLeagues,
    followedLeagueIds: normalizedSettings.followedLeagueIds,
    favoriteTeamIds: normalizedSettings.favoriteTeamIds,
    notifications: normalizedSettings.notifications,
    transitionDedupe: normalizedDedupe,
    watchedGames: normalizedWatches
  };
}

function parseStateText(raw, currentTime, settingsApi, dedupeApi, watchApi) {
  var Settings = settingsModule(settingsApi);
  var Dedupe = dedupeModule(dedupeApi);
  var Watches = watchApi || WatchPolicy;
  var originalText = String(raw === undefined || raw === null ? "" : raw);
  var text = originalText.trim();
  if (!text) {
    var missing = createState(Settings.createDefaults(), Dedupe.createDefaults(), Settings, Dedupe, currentTime, [], Watches);
    return {
      settings: copySettingsFields(missing),
      transitionDedupe: missing.transitionDedupe,
      watchedGames: missing.watchedGames,
      status: "missing",
      recovered: true,
      needsWrite: true,
      unknownFields: [],
      preservedRawText: ""
    };
  }

  var value;
  try {
    value = JSON.parse(text);
  } catch (error) {
    var invalid = createState(Settings.createDefaults(), Dedupe.createDefaults(), Settings, Dedupe, currentTime, [], Watches);
    return {
      settings: copySettingsFields(invalid),
      transitionDedupe: invalid.transitionDedupe,
      watchedGames: invalid.watchedGames,
      status: "invalid-json",
      recovered: true,
      needsWrite: true,
      unknownFields: [],
      error: String(error),
      preservedRawText: ""
    };
  }

  if (!isRecord(value)
      || (value.schemaVersion !== SCHEMA_VERSION && value.schemaVersion !== MIN_SUPPORTED_SCHEMA_VERSION)) {
    var preserveFuture = isFutureSchema(value);
    var unsupported = createState(Settings.createDefaults(), Dedupe.createDefaults(), Settings, Dedupe, currentTime, [], Watches);
    return {
      settings: copySettingsFields(unsupported),
      transitionDedupe: unsupported.transitionDedupe,
      watchedGames: unsupported.watchedGames,
      status: "unsupported-schema",
      recovered: true,
      needsWrite: !preserveFuture,
      unknownFields: [],
      preservedRawText: preserveFuture ? originalText : ""
    };
  }

  var settingsResult = Settings.normalizeSettings(copySettingsFields(value));
  var dedupeResult = Dedupe.normalizeState(value.transitionDedupe, currentTime);
  var watchResult = Watches.normalizeWatches(value.watchedGames, currentTime);
  var unknownFields = [];
  for (var key in value) {
    if (STATE_FIELDS.indexOf(key) === -1) unknownFields.push(key);
  }

  var state = createState(settingsResult.settings, dedupeResult.state, Settings, Dedupe, currentTime, watchResult.watches, Watches);
  var recovered = settingsResult.invalidFields.length > 0
    || settingsResult.missingFields.length > 0 || dedupeResult.recovered || watchResult.recovered;
  var migrated = value.schemaVersion === MIN_SUPPORTED_SCHEMA_VERSION;
  var needsWrite = migrated || settingsResult.changed || dedupeResult.changed || watchResult.changed
    || unknownFields.length > 0;
  return {
    settings: copySettingsFields(state),
    transitionDedupe: state.transitionDedupe,
    watchedGames: state.watchedGames,
    status: migrated && !recovered ? "migrated" : (recovered ? "field-recovered" : (unknownFields.length ? "unknown-fields-dropped" : "valid")),
    recovered: recovered,
    needsWrite: needsWrite,
    invalidFields: settingsResult.invalidFields,
    missingFields: settingsResult.missingFields,
    unknownFields: unknownFields,
    error: null,
    preservedRawText: ""
  };
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    SCHEMA_VERSION: SCHEMA_VERSION,
    createState: createState,
    parseStateText: parseStateText
  };
}

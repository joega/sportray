var SettingsModel = null;
var TransitionDedupe = null;
if (typeof require === "function") {
  SettingsModel = require("./SettingsModel.js");
  TransitionDedupe = require("./TransitionDedupe.js");
}

var SCHEMA_VERSION = 1;
var SETTINGS_FIELDS = ["schemaVersion", "enabledLeagues", "favoriteTeamIds", "notifications"];
var STATE_FIELDS = SETTINGS_FIELDS.concat(["transitionDedupe"]);

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function copySettingsFields(value) {
  var source = isRecord(value) ? value : {};
  return {
    schemaVersion: source.schemaVersion,
    enabledLeagues: source.enabledLeagues,
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

function createState(settings, dedupeState, settingsApi, dedupeApi, currentTime) {
  var Settings = settingsModule(settingsApi);
  var Dedupe = dedupeModule(dedupeApi);
  var normalizedSettings = Settings.normalizeSettings(settings).settings;
  var normalizedDedupe = Dedupe.normalizeState(dedupeState, currentTime).state;
  return {
    schemaVersion: SCHEMA_VERSION,
    enabledLeagues: normalizedSettings.enabledLeagues,
    favoriteTeamIds: normalizedSettings.favoriteTeamIds,
    notifications: normalizedSettings.notifications,
    transitionDedupe: normalizedDedupe
  };
}

function parseStateText(raw, currentTime, settingsApi, dedupeApi) {
  var Settings = settingsModule(settingsApi);
  var Dedupe = dedupeModule(dedupeApi);
  var text = String(raw === undefined || raw === null ? "" : raw).trim();
  if (!text) {
    var missing = createState(Settings.createDefaults(), Dedupe.createDefaults(), Settings, Dedupe, currentTime);
    return {
      settings: copySettingsFields(missing),
      transitionDedupe: missing.transitionDedupe,
      status: "missing",
      recovered: true,
      needsWrite: true,
      unknownFields: []
    };
  }

  var value;
  try {
    value = JSON.parse(text);
  } catch (error) {
    var invalid = createState(Settings.createDefaults(), Dedupe.createDefaults(), Settings, Dedupe, currentTime);
    return {
      settings: copySettingsFields(invalid),
      transitionDedupe: invalid.transitionDedupe,
      status: "invalid-json",
      recovered: true,
      needsWrite: true,
      unknownFields: [],
      error: String(error)
    };
  }

  if (!isRecord(value) || value.schemaVersion !== SCHEMA_VERSION) {
    var unsupported = createState(Settings.createDefaults(), Dedupe.createDefaults(), Settings, Dedupe, currentTime);
    return {
      settings: copySettingsFields(unsupported),
      transitionDedupe: unsupported.transitionDedupe,
      status: "unsupported-schema",
      recovered: true,
      needsWrite: true,
      unknownFields: []
    };
  }

  var settingsResult = Settings.normalizeSettings(copySettingsFields(value));
  var dedupeResult = Dedupe.normalizeState(value.transitionDedupe, currentTime);
  var unknownFields = [];
  for (var key in value) {
    if (STATE_FIELDS.indexOf(key) === -1) unknownFields.push(key);
  }

  var state = createState(settingsResult.settings, dedupeResult.state, Settings, Dedupe, currentTime);
  var recovered = settingsResult.invalidFields.length > 0
    || settingsResult.missingFields.length > 0 || dedupeResult.recovered;
  var needsWrite = settingsResult.changed || dedupeResult.changed || unknownFields.length > 0;
  return {
    settings: copySettingsFields(state),
    transitionDedupe: state.transitionDedupe,
    status: recovered ? "field-recovered" : (unknownFields.length ? "unknown-fields-dropped" : "valid"),
    recovered: recovered,
    needsWrite: needsWrite,
    invalidFields: settingsResult.invalidFields,
    missingFields: settingsResult.missingFields,
    unknownFields: unknownFields,
    error: null
  };
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    SCHEMA_VERSION: SCHEMA_VERSION,
    createState: createState,
    parseStateText: parseStateText
  };
}

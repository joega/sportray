var SCHEMA_VERSION = 1;
var MAX_ENABLED_LEAGUES = 8;
var MAX_FOLLOWED_LEAGUES = 8;
var MAX_FAVORITE_TEAM_IDS = 32;
var MAX_ID_LENGTH = 64;

// The default remains NHL-only. Supported and expanded league IDs are admitted
// here so the picker can persist them without exposing provider-shaped data.
var ALLOWED_LEAGUE_IDS = ["nhl", "nfl", "mlb", "nba", "college-football", "eng.1", "usa.1",
  "mens-college-basketball"];

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function isFutureSchema(value) {
  return isPlainObject(value)
    && typeof value.schemaVersion === "number"
    && value.schemaVersion > SCHEMA_VERSION;
}

function createDefaults() {
  return {
    schemaVersion: SCHEMA_VERSION,
    enabledLeagues: ["nhl"],
    followedLeagueIds: [],
    favoriteTeamIds: [],
    notifications: {
      enabled: false,
      gameStart: false,
      scoreChange: false,
      gameFinal: false,
      pregameReminder: false,
      closeGame: false
    }
  };
}

function addUniqueBounded(out, value, max, predicate) {
  if (out.length >= max || typeof value !== "string") return;
  var normalized = value.trim().toLowerCase();
  if (!normalized || normalized.length > MAX_ID_LENGTH || !predicate(normalized)) return;
  if (out.indexOf(normalized) === -1) out.push(normalized);
}

function normalizeEnabledLeagues(value) {
  if (!Array.isArray(value)) return null;
  var out = [];
  for (var i = 0; i < value.length; i++) {
    addUniqueBounded(out, value[i], MAX_ENABLED_LEAGUES, function(id) {
      return ALLOWED_LEAGUE_IDS.indexOf(id) !== -1;
    });
  }
  return out;
}

function normalizeFavoriteTeamIds(value) {
  if (!Array.isArray(value)) return null;
  var out = [];
  for (var i = 0; i < value.length; i++) {
    addUniqueBounded(out, value[i], MAX_FAVORITE_TEAM_IDS, function(id) {
      if (!/^[a-z0-9.-]{1,24}:[a-z0-9-]{1,32}$/.test(id)) return false;
      return ALLOWED_LEAGUE_IDS.indexOf(id.slice(0, id.indexOf(":"))) !== -1;
    });
  }
  return out;
}

function normalizeFollowedLeagueIds(value, enabledLeagues) {
  if (!Array.isArray(value)) return null;
  var enabled = Array.isArray(enabledLeagues) ? enabledLeagues : [];
  var out = [];
  for (var i = 0; i < value.length; i++) {
    addUniqueBounded(out, value[i], MAX_FOLLOWED_LEAGUES, function(id) {
      return ALLOWED_LEAGUE_IDS.indexOf(id) !== -1 && enabled.indexOf(id) !== -1;
    });
  }
  return out;
}

function normalizeNotifications(value) {
  if (!isPlainObject(value)) return null;
  var defaults = createDefaults().notifications;
  var out = {};
  var keys = ["enabled", "gameStart", "scoreChange", "gameFinal", "pregameReminder", "closeGame"];
  for (var i = 0; i < keys.length; i++) {
    var key = keys[i];
    out[key] = typeof value[key] === "boolean" ? value[key] : defaults[key];
  }
  return out;
}

function normalizeSettings(value) {
  var out = createDefaults();
  var invalidFields = [];
  var missingFields = [];

  if (!isPlainObject(value)) {
    return {
      settings: out,
      invalidFields: ["root"],
      missingFields: [],
      unknownFields: [],
      changed: true
    };
  }

  var enabledLeagues = normalizeEnabledLeagues(value.enabledLeagues);
  if (enabledLeagues === null) {
    if (value.enabledLeagues === undefined) missingFields.push("enabledLeagues");
    else invalidFields.push("enabledLeagues");
  } else {
    out.enabledLeagues = enabledLeagues;
  }

  var favoriteTeamIds = normalizeFavoriteTeamIds(value.favoriteTeamIds);
  if (favoriteTeamIds === null) {
    if (value.favoriteTeamIds === undefined) missingFields.push("favoriteTeamIds");
    else invalidFields.push("favoriteTeamIds");
  } else {
    out.favoriteTeamIds = favoriteTeamIds;
  }

  var followedLeagueIds = normalizeFollowedLeagueIds(value.followedLeagueIds, out.enabledLeagues);
  if (followedLeagueIds === null) {
    if (value.followedLeagueIds === undefined) missingFields.push("followedLeagueIds");
    else invalidFields.push("followedLeagueIds");
  } else {
    out.followedLeagueIds = followedLeagueIds;
  }

  var notifications = normalizeNotifications(value.notifications);
  if (notifications === null) {
    if (value.notifications === undefined) missingFields.push("notifications");
    else invalidFields.push("notifications");
  } else {
    out.notifications = notifications;
    var notificationKeys = ["enabled", "gameStart", "scoreChange", "gameFinal", "pregameReminder", "closeGame"];
    for (var i = 0; i < notificationKeys.length; i++) {
      var notificationKey = notificationKeys[i];
      if (value.notifications[notificationKey] === undefined)
        missingFields.push("notifications." + notificationKey);
      else if (typeof value.notifications[notificationKey] !== "boolean")
        invalidFields.push("notifications." + notificationKey);
    }
  }

  var knownFields = ["schemaVersion", "enabledLeagues", "followedLeagueIds", "favoriteTeamIds", "notifications"];
  var unknownFields = [];
  for (var key in value) {
    if (knownFields.indexOf(key) === -1) unknownFields.push(key);
  }

  out.schemaVersion = SCHEMA_VERSION;
  return {
    settings: out,
    invalidFields: invalidFields,
    missingFields: missingFields,
    unknownFields: unknownFields,
    changed: invalidFields.length > 0 || missingFields.length > 0 || unknownFields.length > 0
      || JSON.stringify(value) !== JSON.stringify(out)
  };
}

function toggleFavoriteTeam(value, teamId) {
  var normalized = normalizeSettings(value).settings;
  if (typeof teamId !== "string") return normalized;

  var id = teamId.trim().toLowerCase();
  var favorites = normalized.favoriteTeamIds.slice();
  var index = favorites.indexOf(id);
  if (index === -1) favorites.push(id);
  else favorites.splice(index, 1);

  return normalizeSettings({
    schemaVersion: SCHEMA_VERSION,
    enabledLeagues: normalized.enabledLeagues,
    followedLeagueIds: normalized.followedLeagueIds,
    favoriteTeamIds: favorites,
    notifications: normalized.notifications
  }).settings;
}

function toggleLeague(value, leagueId) {
  var normalized = normalizeSettings(value).settings;
  if (typeof leagueId !== "string") return normalized;

  var id = leagueId.trim().toLowerCase();
  if (ALLOWED_LEAGUE_IDS.indexOf(id) === -1) return normalized;

  var enabled = normalized.enabledLeagues.slice();
  var index = enabled.indexOf(id);
  if (index === -1) enabled.push(id);
  else {
    enabled.splice(index, 1);
    normalized.followedLeagueIds = normalized.followedLeagueIds.filter(function(followedId) {
      return followedId !== id;
    });
  }

  return normalizeSettings({
    schemaVersion: SCHEMA_VERSION,
    enabledLeagues: enabled,
    followedLeagueIds: normalized.followedLeagueIds,
    favoriteTeamIds: normalized.favoriteTeamIds,
    notifications: normalized.notifications
  }).settings;
}

function toggleFollowedLeague(value, leagueId) {
  var normalized = normalizeSettings(value).settings;
  if (typeof leagueId !== "string") return normalized;
  var id = leagueId.trim().toLowerCase();
  if (normalized.enabledLeagues.indexOf(id) === -1) return normalized;
  var followed = normalized.followedLeagueIds.slice();
  var index = followed.indexOf(id);
  if (index === -1) followed.push(id);
  else followed.splice(index, 1);
  return normalizeSettings({schemaVersion: SCHEMA_VERSION,
    enabledLeagues: normalized.enabledLeagues, followedLeagueIds: followed,
    favoriteTeamIds: normalized.favoriteTeamIds, notifications: normalized.notifications}).settings;
}

function moveFollowedLeague(value, leagueId, direction) {
  var normalized = normalizeSettings(value).settings;
  var id = typeof leagueId === "string" ? leagueId.trim().toLowerCase() : "";
  var index = normalized.followedLeagueIds.indexOf(id);
  var delta = direction === "up" ? -1 : direction === "down" ? 1 : 0;
  var target = index + delta;
  if (index < 0 || delta === 0 || target < 0 || target >= normalized.followedLeagueIds.length)
    return normalized;
  var followed = normalized.followedLeagueIds.slice();
  followed[index] = followed[target];
  followed[target] = id;
  return normalizeSettings({schemaVersion: SCHEMA_VERSION,
    enabledLeagues: normalized.enabledLeagues, followedLeagueIds: followed,
    favoriteTeamIds: normalized.favoriteTeamIds, notifications: normalized.notifications}).settings;
}

function toggleNotification(value, key) {
  var normalized = normalizeSettings(value).settings;
  var keys = ["enabled", "gameStart", "scoreChange", "gameFinal", "pregameReminder", "closeGame"];
  if (typeof key !== "string" || keys.indexOf(key) === -1) return normalized;

  var notifications = {};
  for (var i = 0; i < keys.length; i++) {
    var notificationKey = keys[i];
    notifications[notificationKey] = normalized.notifications[notificationKey];
  }
  notifications[key] = !notifications[key];

  return normalizeSettings({
    schemaVersion: SCHEMA_VERSION,
    enabledLeagues: normalized.enabledLeagues,
    followedLeagueIds: normalized.followedLeagueIds,
    favoriteTeamIds: normalized.favoriteTeamIds,
    notifications: notifications
  }).settings;
}

function parseSettingsText(raw) {
  var originalText = String(raw === undefined || raw === null ? "" : raw);
  var text = originalText.trim();
  if (!text) {
    return {
      settings: createDefaults(),
      status: "missing",
      recovered: true,
      needsWrite: true,
      error: null,
      preservedRawText: ""
    };
  }

  var value;
  try {
    value = JSON.parse(text);
  } catch (error) {
    return {
      settings: createDefaults(),
      status: "invalid-json",
      recovered: true,
      needsWrite: true,
      error: String(error),
      preservedRawText: ""
    };
  }

  if (!isPlainObject(value)) {
    return {
      settings: createDefaults(),
      status: "invalid-root",
      recovered: true,
      needsWrite: true,
      error: "settings root must be an object",
      preservedRawText: ""
    };
  }

  if (value.schemaVersion !== SCHEMA_VERSION) {
    var preserveFuture = isFutureSchema(value);
    return {
      settings: createDefaults(),
      status: "unsupported-schema",
      recovered: true,
      needsWrite: !preserveFuture,
      error: "expected schema version " + SCHEMA_VERSION,
      preservedRawText: preserveFuture ? originalText : ""
    };
  }

  var normalized = normalizeSettings(value);
  var recovered = normalized.invalidFields.length > 0 || normalized.missingFields.length > 0;
  return {
    settings: normalized.settings,
    status: recovered ? "field-recovered" : (normalized.unknownFields.length ? "unknown-fields-dropped" : "valid"),
    recovered: recovered,
    needsWrite: normalized.changed,
    error: null,
    invalidFields: normalized.invalidFields,
    missingFields: normalized.missingFields,
    unknownFields: normalized.unknownFields,
    preservedRawText: ""
  };
}

var exported = {
  SCHEMA_VERSION: SCHEMA_VERSION,
  MAX_ENABLED_LEAGUES: MAX_ENABLED_LEAGUES,
  MAX_FOLLOWED_LEAGUES: MAX_FOLLOWED_LEAGUES,
  MAX_FAVORITE_TEAM_IDS: MAX_FAVORITE_TEAM_IDS,
  createDefaults: createDefaults,
  normalizeSettings: normalizeSettings,
  toggleFavoriteTeam: toggleFavoriteTeam,
  toggleLeague: toggleLeague,
  toggleFollowedLeague: toggleFollowedLeague,
  moveFollowedLeague: moveFollowedLeague,
  toggleNotification: toggleNotification,
  parseSettingsText: parseSettingsText
};

if (typeof module !== "undefined" && module.exports) module.exports = exported;

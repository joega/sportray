var FAVORITE_ID_PATTERN = /^[a-z0-9.-]{1,24}:[a-z0-9-]{1,32}$/;
var ACTIVE_STATES = {
  live: true,
  intermission: true
};
var BAR_SOON_WINDOW_MS = 60 * 60 * 1000;

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function normalizeFavoriteIds(value) {
  if (!Array.isArray(value)) return [];

  var result = [];
  for (var i = 0; i < value.length; i++) {
    if (typeof value[i] !== "string") continue;
    var id = value[i].trim().toLowerCase();
    if (!FAVORITE_ID_PATTERN.test(id) || result.indexOf(id) !== -1) continue;
    result.push(id);
  }
  return result;
}

function teamId(team) {
  if (!isRecord(team) || typeof team.id !== "string") return null;
  var id = team.id.trim().toLowerCase();
  return FAVORITE_ID_PATTERN.test(id) ? id : null;
}

function isLiveGame(game) {
  return isRecord(game) && ACTIVE_STATES[game.status] === true;
}

function isScheduledGame(game) {
  return isRecord(game) && game.status === "scheduled";
}

function isFavoriteGame(game, favoriteIds) {
  if (!isRecord(game)) return false;
  var favorites = normalizeFavoriteIds(favoriteIds);
  return favorites.indexOf(teamId(game.awayTeam)) !== -1
    || favorites.indexOf(teamId(game.homeTeam)) !== -1;
}

function timestamp(value) {
  if (typeof value !== "string") return Number.POSITIVE_INFINITY;
  var parsed = Date.parse(value);
  return isFinite(parsed) ? parsed : Number.POSITIVE_INFINITY;
}

function identity(game) {
  if (!isRecord(game)) return "";
  if (typeof game.id === "string" && game.id.trim()) return game.id.trim().toLowerCase();
  if (typeof game.providerGameId === "string" && game.providerGameId.trim())
    return game.providerGameId.trim().toLowerCase();
  return "";
}

function category(game, favoriteIds) {
  var favorite = isFavoriteGame(game, favoriteIds);
  if (favorite && isLiveGame(game)) return 0;
  if (favorite) return 1;
  if (isLiveGame(game)) return 2;
  if (isScheduledGame(game)) return 3;
  if (isRecord(game) && game.status === "final") return 4;
  return 5;
}

function compareEntries(left, right, favoriteIds) {
  var leftCategory = category(left.game, favoriteIds);
  var rightCategory = category(right.game, favoriteIds);
  if (leftCategory !== rightCategory) return leftCategory - rightCategory;

  var leftTime = timestamp(left.game.startTime);
  var rightTime = timestamp(right.game.startTime);
  if (leftTime !== rightTime) return leftTime - rightTime;

  var leftIdentity = identity(left.game);
  var rightIdentity = identity(right.game);
  if (leftIdentity < rightIdentity) return -1;
  if (leftIdentity > rightIdentity) return 1;
  return left.index - right.index;
}

function orderGames(games, favoriteIds) {
  var values = Array.isArray(games) ? games : [];
  var entries = [];
  for (var i = 0; i < values.length; i++) {
    if (isRecord(values[i])) entries.push({game: values[i], index: i});
  }

  var favorites = normalizeFavoriteIds(favoriteIds);
  entries.sort(function(left, right) {
    return compareEntries(left, right, favorites);
  });
  return entries.map(function(entry) { return entry.game; });
}

function selectNeutralGame(games) {
  var values = Array.isArray(games) ? games : [];
  var candidates = [];
  for (var i = 0; i < values.length; i++) {
    if (!isRecord(values[i]) || (!isLiveGame(values[i]) && !isScheduledGame(values[i]))) continue;
    candidates.push({game: values[i], index: i});
  }

  candidates.sort(function(left, right) {
    var leftLive = isLiveGame(left.game) ? 0 : 1;
    var rightLive = isLiveGame(right.game) ? 0 : 1;
    if (leftLive !== rightLive) return leftLive - rightLive;

    var leftTime = timestamp(left.game.startTime);
    var rightTime = timestamp(right.game.startTime);
    if (leftTime !== rightTime) return leftTime - rightTime;

    var leftIdentity = identity(left.game);
    var rightIdentity = identity(right.game);
    if (leftIdentity < rightIdentity) return -1;
    if (leftIdentity > rightIdentity) return 1;
    return left.index - right.index;
  });
  return candidates.length > 0 ? candidates[0].game : null;
}

function nowTimestamp(value) {
  if (typeof value === "number" && isFinite(value)) return value;
  if (value instanceof Date && !isNaN(value.getTime())) return value.getTime();
  if (typeof value === "string") {
    var parsed = Date.parse(value);
    if (isFinite(parsed)) return parsed;
  }
  return Date.now();
}

function isStartingSoon(game, now) {
  var start = timestamp(game && game.startTime);
  return isScheduledGame(game) && start !== Number.POSITIVE_INFINITY
    && start >= now && start <= now + BAR_SOON_WINDOW_MS;
}

function selectFavoriteUpcoming(games, favoriteIds, now) {
  var values = Array.isArray(games) ? games : [];
  var currentTime = nowTimestamp(now);
  var candidates = [];
  for (var i = 0; i < values.length; i++) {
    var game = values[i];
    var start = timestamp(game && game.startTime);
    if (!isScheduledGame(game) || !isFavoriteGame(game, favoriteIds)
        || start === Number.POSITIVE_INFINITY || start < currentTime) continue;
    candidates.push({game: game, index: i});
  }

  candidates.sort(function(left, right) {
    if (timestamp(left.game.startTime) !== timestamp(right.game.startTime))
      return timestamp(left.game.startTime) - timestamp(right.game.startTime);
    var leftIdentity = identity(left.game);
    var rightIdentity = identity(right.game);
    if (leftIdentity < rightIdentity) return -1;
    if (leftIdentity > rightIdentity) return 1;
    return left.index - right.index;
  });
  return candidates.length > 0 ? candidates[0].game : null;
}

function selectBarState(games, favoriteIds, now) {
  var favorites = normalizeFavoriteIds(favoriteIds);
  var ordered = orderGames(games, favorites);
  var liveFavorites = ordered.filter(function(game) {
    return isLiveGame(game) && isFavoriteGame(game, favorites);
  });

  if (liveFavorites.length > 1) {
    return {kind: "live-favorite-count", game: null, count: liveFavorites.length};
  }
  if (liveFavorites.length === 1) {
    return {kind: "live-favorite", game: liveFavorites[0], count: 1};
  }

  var currentTime = nowTimestamp(now);
  var soon = ordered.filter(function(game) {
    return isFavoriteGame(game, favorites) && isStartingSoon(game, currentTime);
  });
  if (soon.length > 0) {
    return {kind: "favorite-starting-soon", game: soon[0], count: 1};
  }

  var favoriteUpcoming = selectFavoriteUpcoming(games, favorites, currentTime);
  if (favoriteUpcoming) {
    return {kind: "favorite-upcoming", game: favoriteUpcoming, count: 1};
  }

  return {kind: "neutral", game: selectNeutralGame(games), count: 0};
}

function isLiveFavoriteState(state) {
  if (!state || typeof state !== "object") return false;
  if (state.kind === "live-favorite") return !!state.game;
  return state.kind === "live-favorite-count" && Number(state.count) > 0;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    BAR_SOON_WINDOW_MS: BAR_SOON_WINDOW_MS,
    normalizeFavoriteIds: normalizeFavoriteIds,
    isFavoriteGame: isFavoriteGame,
    gameIdentity: identity,
    orderGames: orderGames,
    selectBarState: selectBarState,
    isLiveFavoriteState: isLiveFavoriteState,
    selectFavoriteUpcoming: selectFavoriteUpcoming
  };
}

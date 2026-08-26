var FavoritePresentation = null;
if (typeof require === "function") FavoritePresentation = require("./FavoritePresentation.js");

var FAVORITE_ID_PATTERN = /^[a-z0-9.-]{1,24}:[a-z0-9-]{1,32}$/;

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function normalizeFavoriteIds(value) {
  if (FavoritePresentation) return FavoritePresentation.normalizeFavoriteIds(value);
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

function normalizeFollowedLeagueIds(value, enabledLeagues) {
  var enabled = Array.isArray(enabledLeagues) ? enabledLeagues : [];
  var result = [];
  (Array.isArray(value) ? value : []).forEach(function(id) {
    if (typeof id !== "string") return;
    var normalized = id.trim().toLowerCase();
    if (enabled.indexOf(normalized) === -1 || result.indexOf(normalized) !== -1) return;
    result.push(normalized);
  });
  return result;
}

function orderLeagueIds(enabledLeagues, followedLeagueIds) {
  var enabled = Array.isArray(enabledLeagues) ? enabledLeagues.slice() : [];
  var followed = normalizeFollowedLeagueIds(followedLeagueIds, enabled);
  return followed.concat(enabled.filter(function(id) { return followed.indexOf(id) === -1; }));
}

function gameIdentity(game) {
  if (!isRecord(game)) return "";
  if (typeof game.id === "string" && game.id.trim()) return game.id.trim().toLowerCase();
  if (typeof game.providerGameId === "string" && game.providerGameId.trim())
    return game.providerGameId.trim().toLowerCase();
  return "";
}

function deduplicateGames(games) {
  var result = [];
  var seen = {};
  (Array.isArray(games) ? games : []).forEach(function(game) {
    var id = gameIdentity(game);
    if (!id || seen[id]) return;
    seen[id] = true;
    result.push(game);
  });
  return result;
}

function teamIsFavorite(team, favoriteIds) {
  if (!isRecord(team) || typeof team.id !== "string") return false;
  return normalizeFavoriteIds(favoriteIds).indexOf(team.id.trim().toLowerCase()) !== -1;
}

function annotate(game, favoriteIds, pinned, matcher, leagueMeta, showLeagueContext) {
  var favorite = isFavoriteGame(game, favoriteIds, matcher);
  var live = game.status === "live" || game.status === "intermission";
  return Object.assign({}, game, {
    presentation: {
      isFavorite: favorite,
      awayIsFavorite: teamIsFavorite(game.awayTeam, favoriteIds),
      homeIsFavorite: teamIsFavorite(game.homeTeam, favoriteIds),
      isLive: live,
      isPinned: pinned === true,
      leagueLabel: leagueMeta && leagueMeta.displayName ? leagueMeta.displayName : "",
      sport: leagueMeta && leagueMeta.sport ? leagueMeta.sport : "",
      showLeagueContext: showLeagueContext === true
    }
  });
}

function annotateGames(games, favoriteIds, pinned, matcher, leagueMeta, showLeagueContext) {
  return (Array.isArray(games) ? games : []).map(function(game) {
    return annotate(game, favoriteIds, pinned, matcher, leagueMeta, showLeagueContext);
  });
}

function availability(state) {
  if (state.loading) return "loading";
  if (state.errorCode && !state.hasData) return "error";
  if (state.stale) return "stale";
  if (state.games.length === 0 && !state.errorCode) return "empty";
  return "ready";
}

function orderGames(games, favoriteIds, orderer) {
  if (typeof orderer === "function") return orderer(games, favoriteIds);
  if (FavoritePresentation) return FavoritePresentation.orderGames(games, favoriteIds);
  return Array.isArray(games) ? games.slice() : [];
}

function isFavoriteGame(game, favoriteIds, matcher) {
  if (typeof matcher === "function") return matcher(game, favoriteIds);
  if (FavoritePresentation) return FavoritePresentation.isFavoriteGame(game, favoriteIds);
  return false;
}

function leagueView(state, favoriteIds, orderer, matcher) {
  var ordered = orderGames(state.games, favoriteIds, orderer);
  var pinned = [];
  var other = [];
  ordered.forEach(function(game) {
    if (isFavoriteGame(game, favoriteIds, matcher)) pinned.push(game);
    else other.push(game);
  });
  var leagueMeta = {
    displayName: state.displayName || "",
    sport: state.sport || ""
  };
  pinned = annotateGames(deduplicateGames(pinned), favoriteIds, true, matcher, leagueMeta, false);
  other = annotateGames(deduplicateGames(other), favoriteIds, false, matcher, leagueMeta, false);
  return {
    kind: "league",
    leagueId: state.leagueId,
    displayName: state.displayName,
    availability: availability(state),
    loading: state.loading === true,
    empty: state.games.length === 0 && state.hasData === true && !state.errorCode,
    stale: state.stale === true,
    errorCode: state.errorCode || "",
    errorSummary: state.errorSummary || "",
    partialErrorCount: state.partialErrorCount || 0,
    hasData: state.hasData === true,
    lastSuccessAt: state.lastSuccessAt || null,
    pinnedGames: pinned,
    otherGames: other,
    games: pinned.concat(other),
    hasFavoriteGames: pinned.length > 0,
    nextGame: state.nextGame || null,
    nextGameDateKey: state.nextGameDateKey || "",
    nextGameStatus: state.nextGameStatus || "idle"
  };
}

function build(composed, favoriteTeamIds, orderer, matcher, followedLeagueIds, revision) {
  var favorites = normalizeFavoriteIds(favoriteTeamIds);
  var leagueStates = composed && Array.isArray(composed.leagueStates)
    ? composed.leagueStates : [];
  var enabledLeagueIds = leagueStates.map(function(state) { return state.leagueId; });
  var followed = normalizeFollowedLeagueIds(followedLeagueIds, enabledLeagueIds);
  var orderedLeagueIds = orderLeagueIds(enabledLeagueIds, followed);
  var orderedStates = orderedLeagueIds.map(function(id) {
    return leagueStates.filter(function(state) { return state.leagueId === id; })[0];
  }).filter(Boolean);
  var leagueViews = orderedStates.map(function(state) {
    return leagueView(state, favorites, orderer, matcher);
  });
  var followingGames = [];
  var followingLeagueIds = [];
  leagueStates.forEach(function(state) {
    state.games.forEach(function(game) {
      if (isFavoriteGame(game, favorites, matcher)) {
        followingGames.push(game);
        if (followingLeagueIds.indexOf(state.leagueId) === -1)
          followingLeagueIds.push(state.leagueId);
      }
    });
  });
  followingGames = deduplicateGames(orderGames(followingGames, favorites, orderer));
  var shown = {};
  followingGames.forEach(function(game) { shown[gameIdentity(game)] = true; });
  var followingSections = [];
  followed.forEach(function(leagueId) {
    var state = orderedStates.filter(function(candidate) { return candidate.leagueId === leagueId; })[0];
    if (!state) return;
    var games = deduplicateGames(orderGames(state.games, favorites, orderer)).filter(function(game) {
      var id = gameIdentity(game);
      if (!id || shown[id]) return false;
      shown[id] = true;
      return true;
    }).map(function(game) {
      return annotate(game, favorites, false, matcher, state, true);
    });
    followingSections.push({leagueId: leagueId, displayName: state.displayName, games: games});
    followingGames = followingGames.concat(games);
  });
  var followingIsMixed = followingLeagueIds.length > 1;
  followingGames = followingGames.map(function(game) {
    var state = leagueStates.filter(function(candidate) {
      return candidate.leagueId === game.league;
    })[0];
    return annotate(game, favorites, false, matcher, state, followingIsMixed);
  });

  return {
    following: {
      kind: "following",
      title: "Following",
      games: followingGames,
      sections: followingSections,
      loading: leagueStates.some(function(state) { return state.loading === true; }),
      hasFavorites: favorites.length > 0,
      hasGames: followingGames.length > 0,
      emptyState: favorites.length === 0 ? "no-favorites"
        : followingGames.length === 0 ? "no-favorite-games" : "",
      isEmpty: followingGames.length === 0
    },
    leagues: leagueViews,
    enabledLeagues: enabledLeagueIds,
    orderedLeagueIds: orderedLeagueIds,
    followedLeagueIds: followed,
    favoriteTeamIds: favorites
  };
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    annotate: annotate,
    build: build,
    deduplicateGames: deduplicateGames,
    gameIdentity: gameIdentity,
    normalizeFavoriteIds: normalizeFavoriteIds,
    normalizeFollowedLeagueIds: normalizeFollowedLeagueIds,
    orderLeagueIds: orderLeagueIds
  };
}

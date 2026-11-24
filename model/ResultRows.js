function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function gameIdentity(game) {
  if (!isRecord(game)) return "";
  if (typeof game.id === "string" && game.id.trim()) return game.id.trim().toLowerCase();
  if (typeof game.providerGameId === "string" && game.providerGameId.trim())
    return game.providerGameId.trim().toLowerCase();
  return "";
}

function sectionRow(id, label, favorite) {
  return {
    kind: "section-header",
    rowId: "section:" + id,
    label: label,
    favorite: favorite === true
  };
}

function gameRow(game, stale) {
  var identity = gameIdentity(game);
  if (!identity) return null;
  return {
    kind: "game",
    rowId: "game:" + identity,
    game: game,
    stale: stale === true,
    action: {
      type: "open-detail",
      label: "View game details",
      enabled: game.isValid === true
    }
  };
}

function slateBucket(game) {
  var status = isRecord(game) && typeof game.status === "string" ? game.status : "unknown";
  if (status === "live" || status === "intermission") return "live";
  if (status === "final") return "final";
  if (status === "scheduled") return "upcoming";
  if (status === "postponed" || status === "canceled") return "changes";
  return "unavailable";
}

function slateLabel(bucket) {
  switch (bucket) {
  case "live": return "Live";
  case "upcoming": return "Upcoming";
  case "final": return "Final";
  case "changes": return "Schedule changes";
  default: return "Unavailable";
  }
}

function statusRow(view) {
  return {
    kind: "status",
    rowId: "status:" + (view.leagueId || "following"),
    status: {
      leagueId: view.leagueId || "",
      displayName: view.displayName || view.title || "Scores",
      loading: view.loading === true,
      errorCode: view.errorCode || "",
      errorSummary: view.errorSummary || "",
      stale: view.stale === true || Boolean(view.errorCode && view.hasData),
      partialErrorCount: Number(view.partialErrorCount) || 0,
      lastSuccessAt: view.lastSuccessAt || null,
      hasData: view.hasData === true, affectedLeagues: view.affectedLeagues || []
    },
    action: {
      type: view.interactiveNotice ? "notice-actions" : "retry",
      label: view.interactiveNotice ? "Data status" : "Retry scores",
      enabled: view.interactiveNotice === true || view.loading !== true
    }
  };
}

function emptyRow(id, text, action, details) {
  var extra = isRecord(details) ? details : {};
  return {
    kind: "empty",
    rowId: "empty:" + id,
    text: text,
    title: extra.title || "",
    supportingText: extra.supportingText || "",
    action: action ? {
      type: action,
      label: action === "choose-teams" ? "Choose favorite teams"
        : action === "browse-leagues" ? "Browse leagues" : action === "show-all" ? "Show all games" : action,
      enabled: true
    } : null
  };
}

function loadingRow(id, retained) {
  return {
    kind: "loading",
    rowId: "loading:" + id,
    retained: retained === true,
    label: retained === true ? "Refreshing scores…" : "Loading scores…",
    action: null
  };
}

function nextGameRow(id, game, dateKey) {
  return {
    kind: "next-game",
    rowId: "next-game:" + id + ":" + dateKey,
    game: game,
    dateKey: dateKey,
    action: {
      type: "view-day",
      label: "View " + dateKey,
      enabled: true
    }
  };
}

function appendGames(rows, games, stale) {
  (Array.isArray(games) ? games : []).forEach(function(game) {
    var row = gameRow(game, stale === true
      || (isRecord(stale) && stale[game.league] === true));
    if (row) rows.push(row);
  });
}

function appendSlateGroups(rows, games, destination, stale) {
  var groups = {
    live: [],
    upcoming: [],
    changes: [],
    final: [],
    unavailable: []
  };
  var seen = {};
  (Array.isArray(games) ? games : []).forEach(function(game) {
    var identity = gameIdentity(game);
    if (!identity || seen[identity]) return;
    seen[identity] = true;
    groups[slateBucket(game)].push(game);
  });

  ["live", "upcoming", "changes", "final", "unavailable"].forEach(function(bucket) {
    if (groups[bucket].length === 0) return;
    rows.push(sectionRow(destination + ":" + bucket, slateLabel(bucket),
      groups[bucket].some(function(game) {
        return game.presentation && game.presentation.isFavorite === true;
      })));
    appendGames(rows, groups[bucket], stale);
  });
}

function flatten(view, destination, selectedDateLabel) {
  var rows = [];
  if (!isRecord(view)) return rows;

  var id = destination || view.leagueId || view.kind || "scores";
  if (view.kind === "following") {
    if (!view.hasFavorites && !view.hasGames
        && (!Array.isArray(view.followedLeagueIds) || view.followedLeagueIds.length === 0)
        && (!Array.isArray(view.leagueStates) || view.leagueStates.length === 0)) {
      rows.push(emptyRow(id + ":no-favorites", "Choose favorite teams to pin their games here.",
        "choose-teams", {
          title: "Follow teams to pin their games here",
          supportingText: "8 leagues available."
        }));
      return rows;
    }
    var staleLeagues = Object.create(null);
    var affected = [];
    (Array.isArray(view.leagueStates) ? view.leagueStates : []).forEach(function(state) {
      staleLeagues[state.leagueId] = state.stale === true
        || Boolean(state.errorCode && state.hasData);
      if (state.errorCode || state.stale) {
        affected.push(state);
        if (!view.compactNotices) rows.push(statusRow(state));
      }
    });
    if (view.compactNotices && affected.length) rows.push(statusRow({
      leagueId: "following", displayName: "", affectedLeagues: affected,
      hasData: view.unfilteredHasGames || affected.some(function(state) { return state.hasData; }),
      loading: view.loading === true, stale: affected.some(function(state) { return state.stale || state.hasData; }),
      interactiveNotice: true
    }));
    if (view.filteredEmpty) {
      rows.push(emptyRow(id + ":filter:" + view.followingFilterId,
        view.followingFilterId === "live" ? "No live games are listed on this date." : "No favorite-team games are listed on this date.",
        "show-all", {title: view.followingFilterId === "live" ? "No live games" : "No favorite-team games",
          supportingText: "Show all games in Following."}));
      return rows;
    }
    if (!view.hasGames) {
      if (view.loading) {
        rows.push(loadingRow(id + ":initial", false));
        return rows;
      }
      // A failed/retained league has not established that its teams are off.
      if (rows.length > 0) return rows;
      var dateLabel = typeof selectedDateLabel === "string" && selectedDateLabel !== ""
        ? selectedDateLabel : "this date";
      rows.push(emptyRow(id + ":no-games", "No games match your Following choices.", "browse-leagues", {
        title: dateLabel.toLowerCase() === "today" ? "No followed games today"
          : "No followed games · " + dateLabel,
        supportingText: "Browse a league for the full slate."
      }));
      return rows;
    }
    appendSlateGroups(rows, view.games, id, staleLeagues);
    return rows;
  }

  var hasGames = (Array.isArray(view.pinnedGames) && view.pinnedGames.length > 0)
    || (Array.isArray(view.otherGames) && view.otherGames.length > 0);
  if (view.loading && !hasGames) {
    rows.push(loadingRow(id + ":initial", false));
    return rows;
  }
  if (view.errorCode !== "" || view.stale)
    rows.push(statusRow(view));

  var games = [];
  if (Array.isArray(view.pinnedGames)) games = games.concat(view.pinnedGames);
  if (Array.isArray(view.otherGames)) games = games.concat(view.otherGames);
  appendSlateGroups(rows, games, id, view.stale);
  if (rows.length === 0 && view.availability === "empty") {
    rows.push(emptyRow(id + ":empty", "Nothing scheduled on this day"));
    if (view.nextGameStatus === "loading")
      rows.push(emptyRow(id + ":next-loading", "Finding the next scheduled game…"));
    else if (view.nextGame)
      rows.push(nextGameRow(id, view.nextGame, view.nextGameDateKey));
    else if (view.nextGameStatus === "unavailable")
      rows.push(emptyRow(id + ":next-unavailable", "No upcoming games found"));
  }

  return rows;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    flatten: flatten,
    gameIdentity: gameIdentity,
    slateBucket: slateBucket
  };
}

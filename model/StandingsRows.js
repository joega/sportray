function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function sectionRow(group) {
  return {
    kind: "standings-section",
    rowId: "standings-section:" + group.id,
    label: group.label || "Standings",
    action: null
  };
}

function standingRow(row, favoriteIds) {
  var favorite = Array.isArray(favoriteIds) && row.team && typeof row.team.id === "string"
    && favoriteIds.indexOf(row.team.id.toLowerCase()) !== -1;
  return {
    kind: "standings",
    rowId: row.id,
    standing: row,
    favorite: favorite,
    action: {
      type: "toggle-favorite-team",
      label: favorite ? "Remove favorite" : "Add favorite",
      enabled: Boolean(row.team && row.team.id)
    }
  };
}

function flatten(state, favoriteIds) {
  if (!isRecord(state)) return [];
  var rows = [];
  if (state.loading === true && state.hasData !== true) {
    rows.push({kind: "standings-loading", rowId: "standings-loading", label: "Loading standings…", action: null});
    return rows;
  }
  if (state.errorCode && state.hasData !== true) {
    rows.push({
      kind: "standings-status",
      rowId: "standings-status",
      label: state.errorSummary || "Standings unavailable",
      action: {type: "retry-standings", label: "Retry standings", enabled: state.loading !== true}
    });
    return rows;
  }

  var groups = Array.isArray(state.groups) ? state.groups : [];
  groups.forEach(function(group) {
    if (!isRecord(group) || !Array.isArray(group.rows) || group.rows.length === 0) return;
    rows.push(sectionRow(group));
    group.rows.forEach(function(row) {
      if (isRecord(row) && isRecord(row.team)) rows.push(standingRow(row, favoriteIds));
    });
  });
  if (rows.length === 0) {
    rows.push({
      kind: "standings-empty",
      rowId: "standings-empty",
      text: "No standings available for this league.",
      action: null
    });
  }
  return rows;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    flatten: flatten,
    standingRow: standingRow
  };
}

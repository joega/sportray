// Provider-neutral standings boundary. Providers map their payload into the
// small group/entry shape accepted here; QML only receives normalized rows.

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function cleanString(value) {
  if (typeof value !== "string") return null;
  var result = value.trim();
  return result || null;
}

function providerId(value) {
  if (typeof value === "number" && isFinite(value)) value = String(value);
  return cleanString(value);
}

function numberOrNull(value) {
  if (typeof value === "string" && value.trim() !== "") value = Number(value.trim());
  if (typeof value !== "number" || !isFinite(value)) return null;
  return value;
}

function integerOrNull(value) {
  var result = numberOrNull(value);
  return result === null || Math.floor(result) !== result ? null : result;
}

function normalizedTeam(rawTeam, leagueId) {
  if (!isRecord(rawTeam)) return null;

  var rawId = providerId(rawTeam.providerTeamId || rawTeam.id);
  if (!rawId) return null;
  var canonicalId = rawId.indexOf(":") !== -1 ? rawId.toLowerCase() : leagueId + ":" + rawId;
  var canonicalLeague = canonicalId.split(":")[0] || leagueId;
  var canonicalProviderId = canonicalId.slice(canonicalLeague.length + 1);
  if (!canonicalProviderId) return null;

  return {
    id: canonicalId,
    league: canonicalLeague,
    providerTeamId: canonicalProviderId,
    name: cleanString(rawTeam.name) || cleanString(rawTeam.displayName),
    shortName: cleanString(rawTeam.shortName) || cleanString(rawTeam.shortDisplayName),
    abbreviation: cleanString(rawTeam.abbreviation),
    primaryColor: cleanString(rawTeam.primaryColor),
    logoUrl: cleanString(rawTeam.logoUrl),
    link: cleanString(rawTeam.link)
  };
}

function normalizeEntry(entry, leagueId, groupId, sourceIndex) {
  if (!isRecord(entry)) return null;
  var team = normalizedTeam(entry.team || entry, leagueId);
  if (!team) return null;

  var rank = integerOrNull(entry.rank);
  rank = rank !== null && rank > 0 ? rank : null;
  var played = integerOrNull(entry.played);
  var wins = integerOrNull(entry.wins);
  var losses = integerOrNull(entry.losses);
  var draws = integerOrNull(entry.draws);
  var ties = integerOrNull(entry.ties);
  var points = numberOrNull(entry.points);
  var differential = numberOrNull(entry.differential);
  var recordLabel = cleanString(entry.recordLabel);

  return {
    id: "standings:" + groupId + ":" + team.id,
    league: leagueId,
    groupId: groupId,
    rank: rank,
    team: team,
    played: played,
    wins: wins,
    losses: losses,
    draws: draws,
    ties: ties,
    points: points,
    differential: differential,
    recordLabel: recordLabel,
    sourceIndex: sourceIndex
  };
}

function compareEntries(left, right) {
  var leftRank = left.rank === null ? Number.POSITIVE_INFINITY : left.rank;
  var rightRank = right.rank === null ? Number.POSITIVE_INFINITY : right.rank;
  if (leftRank !== rightRank) return leftRank - rightRank;

  if (leftRank === Number.POSITIVE_INFINITY) return left.sourceIndex - right.sourceIndex;
  var leftName = left.team.name || left.team.shortName || left.team.abbreviation || left.team.id;
  var rightName = right.team.name || right.team.shortName || right.team.abbreviation || right.team.id;
  if (leftName !== rightName) return leftName < rightName ? -1 : 1;
  return left.sourceIndex - right.sourceIndex;
}

function normalizeGroups(groups, leagueId, initialErrors) {
  var result = {leagueId: leagueId || "", groups: [], rows: [], errors: []};
  if (Array.isArray(initialErrors)) result.errors = initialErrors.slice();
  if (!Array.isArray(groups)) {
    result.errors.push({index: null, code: "invalid-standings-groups"});
    return result;
  }

  groups.forEach(function(group, groupIndex) {
    if (!isRecord(group) || !Array.isArray(group.entries)) {
      result.errors.push({index: groupIndex, code: "invalid-standings-group"});
      return;
    }

    var groupId = providerId(group.id) || "group-" + groupIndex;
    var groupLabel = cleanString(group.label) || "Standings";
    var rows = [];
    group.entries.forEach(function(entry, entryIndex) {
      var row = normalizeEntry(entry, leagueId, groupId, entryIndex);
      if (!row) {
        result.errors.push({index: entryIndex, group: groupId, code: "invalid-standing-entry"});
        return;
      }
      rows.push(row);
    });
    rows.sort(compareEntries);
    result.groups.push({id: groupId, label: groupLabel, rows: rows});
    result.rows = result.rows.concat(rows);
  });

  return result;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    cleanString: cleanString,
    compareEntries: compareEntries,
    normalizeEntry: normalizeEntry,
    normalizeGroups: normalizeGroups,
    normalizedTeam: normalizedTeam,
    numberOrNull: numberOrNull
  };
}

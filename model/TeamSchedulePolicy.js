// Explicit panel-session admission; selecting a team never changes favorites.
function resolve(teamId, catalog, enabledLeagues) {
  if (typeof teamId !== "string" || !/^[a-z0-9.-]{1,24}:\d+$/.test(teamId)
      || !catalog || typeof catalog.length !== "number" || !isFinite(catalog.length)
      || Math.floor(catalog.length) !== catalog.length || catalog.length > 4096
      || catalog.length < 0 || !enabledLeagues || typeof enabledLeagues.length !== "number"
      || !isFinite(enabledLeagues.length) || Math.floor(enabledLeagues.length) !== enabledLeagues.length
      || enabledLeagues.length < 0 || enabledLeagues.length > 8) return null;
  for (var i = 0; i < catalog.length; i++) {
    var team = catalog[i];
    if (!team || team.id !== teamId || typeof team.league !== "string"
        || !/^\d+$/.test(String(team.providerTeamId))
        || team.id !== team.league + ":" + String(team.providerTeamId)) continue;
    for (var j = 0; j < enabledLeagues.length; j++) {
      if (enabledLeagues[j] === team.league) return team;
    }
  }
  return null;
}

if (typeof module !== "undefined" && module.exports) module.exports = {resolve: resolve};

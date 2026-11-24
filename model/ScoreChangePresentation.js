// Observe normalized games only. A newly visible/recycled/stale score is a
// baseline, not an update animation; ordinary clock publications stay quiet.
function finiteScore(value) {
  return typeof value === "number" && isFinite(value) && value >= 0 && Math.floor(value) === value;
}
function snapshot(game, options) {
  var value = game && typeof game === "object" ? game : {};
  var state = options && typeof options === "object" ? options : {};
  var id = typeof value.id === "string" ? value.id : "";
  var canonical = typeof value.league === "string" && typeof value.providerGameId === "string"
    && id === value.league + ":" + value.providerGameId && /^[a-z0-9.-]{1,32}:[a-z0-9-]{1,96}$/.test(id);
  var scored = value.status === "live" || value.status === "intermission" || value.status === "final";
  return {id: canonical ? id : "", away: finiteScore(value.awayScore) ? value.awayScore : null,
    home: finiteScore(value.homeScore) ? value.homeScore : null,
    eligible: Boolean(canonical && value.isValid === true && scored
      && state.visible === true && state.stale !== true && state.reducedMotion !== true)};
}
function observe(previous, game, options) {
  var next = snapshot(game, options);
  var eligible = previous && previous.eligible === true && next.eligible
    && previous.id !== "" && previous.id === next.id;
  return {snapshot: next,
    awayChanged: Boolean(eligible && finiteScore(previous.away) && finiteScore(next.away) && previous.away !== next.away),
    homeChanged: Boolean(eligible && finiteScore(previous.home) && finiteScore(next.home) && previous.home !== next.home)};
}
if (typeof module !== "undefined" && module.exports) module.exports = {
  finiteScore: finiteScore, snapshot: snapshot, observe: observe
};

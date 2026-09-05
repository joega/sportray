function number(value, fallback) {
  var result = Number(value);
  return isFinite(result) && result >= 0 ? result : fallback;
}
function layout(input) {
  var source = input && typeof input === "object" ? input : {};
  var width = number(source.width, 0);
  var padding = number(source.padding, 0);
  var gap = number(source.gap, 0);
  var leading = number(source.leading, 0);
  var trailing = number(source.trailing, 0);
  var available = Math.max(0, width - padding * 2 - leading - trailing - gap * 2);
  var matchup = Math.floor(available * 0.55);
  var score = Math.floor(available * 0.2);
  var status = Math.max(0, available - matchup - score);
  return {width: width, available: available, matchupWidth: matchup, scoreWidth: score,
    statusWidth: status, nonOverlapping: matchup + score + status <= available,
    trailingReachable: trailing > 0 && width >= trailing};
}
if (typeof module !== "undefined" && module.exports) module.exports = {layout: layout};

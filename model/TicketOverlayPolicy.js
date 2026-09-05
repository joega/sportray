function finite(value, fallback) {
  var result = Number(value);
  return isFinite(result) ? result : fallback;
}

function geometry(input) {
  var source = input && typeof input === "object" ? input : {};
  var screenWidth = Math.max(0, finite(source.screenWidth, 0));
  var screenHeight = Math.max(0, finite(source.screenHeight, 0));
  var barHeight = Math.max(0, finite(source.barHeight, 0));
  var width = Math.max(1, finite(source.width, 1));
  var height = Math.max(1, finite(source.height, 1));
  var margin = Math.max(0, finite(source.margin, 0));
  var gap = Math.max(0, finite(source.gap, 0));
  var x = finite(source.x, 0);
  var position = source.position === "bottom" ? "bottom" : "top";
  var y = position === "bottom"
    ? screenHeight - barHeight - height - gap
    : barHeight + gap;
  return {
    x: Math.round(Math.max(margin, Math.min(x, screenWidth - width - margin))),
    y: Math.round(Math.max(margin, Math.min(y, screenHeight - height - margin))),
    position: position,
    flush: gap === 0,
    withinScreen: screenWidth >= width + margin * 2 && screenHeight >= height + margin * 2
  };
}

if (typeof module !== "undefined" && module.exports) module.exports = {geometry: geometry};

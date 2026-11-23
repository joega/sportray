// Omarchy's public bar API supplies a detached, normalized layout snapshot.
// Resolve by module id, not private ModuleSlot objects or their live children.
function regionForLayout(layout, moduleName) {
  if (!layout || typeof layout !== "object" || Array.isArray(layout)
      || typeof moduleName !== "string" || !moduleName) return "";
  var regions = ["left", "centerBegin", "center", "centerEnd", "right", "tray"];
  for (var i = 0; i < regions.length; i++) {
    var entries = layout[regions[i]];
    if (!Array.isArray(entries)) continue;
    for (var j = 0; j < entries.length; j++) {
      var entry = entries[j];
      if (entry && typeof entry === "object" && !Array.isArray(entry)
          && entry.id === moduleName) return regions[i];
    }
  }
  return "";
}

function usesRightEdgeAnchor(region, vertical) {
  return region === "right" && vertical !== true;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    regionForLayout: regionForLayout,
    usesRightEdgeAnchor: usesRightEdgeAnchor
  };
}

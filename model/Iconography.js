// Sportray's small semantic icon vocabulary. The installed Omarchy shell
// uses the Material Design subset of its Nerd Font; keep glyph selection in
// this one local mapping so views never carry raw icon codepoints.

function codePoint(value) {
  var point = Number(value)
  if (!isFinite(point) || point < 0 || point > 0x10ffff) return ""
  if (point <= 0xffff) return String.fromCharCode(point)
  point -= 0x10000
  return String.fromCharCode(
    0xd800 + (point >> 10),
    0xdc00 + (point & 0x3ff))
}

var GLYPHS = {
  star: codePoint(0xf04ce),
  starOutline: codePoint(0xf04d2),
  settings: codePoint(0xf0493),
  refresh: codePoint(0xf0450),
  undo: codePoint(0xf054c),
  check: codePoint(0xf012c),
  overflow: codePoint(0xf01d9),
  close: codePoint(0xf0156),
  chevronLeft: codePoint(0xf0141),
  chevronRight: codePoint(0xf0142),
  hockey: codePoint(0xf087a),
  football: codePoint(0xf025d),
  baseball: codePoint(0xf0852),
  basketball: codePoint(0xf0806),
  soccerField: codePoint(0xf04b8),
  calendar: codePoint(0xf00ed),
  neutral: codePoint(0xf0a1d)
}

var FALLBACKS = {
  star: "*",
  starOutline: "*",
  settings: "[ ]",
  refresh: "R",
  undo: "<-",
  check: "OK",
  overflow: "...",
  close: "X",
  chevronLeft: "<",
  chevronRight: ">",
  hockey: "H",
  football: "F",
  baseball: "B",
  basketball: "B",
  soccerField: "S",
  calendar: "D",
  neutral: "S"
}

function glyph(name) {
  return GLYPHS[name] || ""
}

function fallback(name) {
  return FALLBACKS[name] || "?"
}

function icon(name) {
  return {name: name || "", glyph: glyph(name), fallback: fallback(name)}
}

function iconNameForLeague(leagueId) {
  var id = String(leagueId || "").toLowerCase()
  if (id === "following" || id === "") return "neutral"
  if (id === "nhl") return "hockey"
  if (id === "nfl" || id === "college-football") return "football"
  if (id === "mlb") return "baseball"
  if (id === "nba" || id === "mens-college-basketball") return "basketball"
  if (id === "eng.1" || id === "usa.1") return "soccerField"
  return "neutral"
}

function iconNameForSettingsDestination(destination) {
  var value = String(destination || "")
  if (value === "teams") return "star"
  if (value === "notifications") return "overflow"
  return "settings"
}

function sportKind(leagueId) {
  var name = iconNameForLeague(leagueId)
  return name === "neutral" ? "neutral" : name
}

// A theme may select a non-Nerd font. In that case the ASCII fallback keeps
// the control legible instead of asking the active font to paint a tofu box.
function supportsNerdGlyphs(fontFamily) {
  var family = String(fontFamily || "")
  // Omarchy intentionally binds Style.font.family to the fontconfig
  // `monospace` alias so `omarchy font set` can swap the concrete family.
  // The installed alias resolves to the Nerd Font in the supported shell.
  return family === "monospace"
    || family.indexOf("Nerd") !== -1
    || family.indexOf(" NF") !== -1
}

function displayText(name, fontFamily) {
  return supportsNerdGlyphs(fontFamily) ? glyph(name) : fallback(name)
}

// Export the table for deterministic fixture assertions without exposing it
// as a mutable view-facing object.
var semanticNames = [
  "star", "starOutline", "settings", "refresh", "undo", "check", "overflow",
  "close", "chevronLeft", "chevronRight", "hockey", "football", "baseball",
  "basketball", "soccerField", "calendar", "neutral"
]

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    glyph: glyph,
    codePoint: codePoint,
    fallback: fallback,
    icon: icon,
    iconNameForLeague: iconNameForLeague,
    iconNameForSettingsDestination: iconNameForSettingsDestination,
    sportKind: sportKind,
    supportsNerdGlyphs: supportsNerdGlyphs,
    displayText: displayText,
    semanticNames: semanticNames
  }
}

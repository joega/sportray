// Provider-neutral sizing hints for the attached panel. QML owns the actual
// pixels and fitted-content contract; this module keeps boundary decisions
// deterministic and easy to fixture-test.

function clamp(value, minimum, maximum) {
  return Math.max(minimum, Math.min(maximum, value));
}

function rowHeight(row, tokens) {
  var kind = row && row.kind ? row.kind : "empty";
  if (kind === "section-header") return tokens.section;
  if (kind === "standings-section") return tokens.section;
  if (kind === "game") return tokens.game;
  if (kind === "standings") return tokens.standings || tokens.game;
  if (kind === "status") return tokens.status;
  if (kind === "loading") return tokens.loading;
  if (kind === "next-game") return tokens.nextGame;
  return tokens.empty;
}

function scoreContentRequest(rows, tokens) {
  var values = Array.isArray(rows) ? rows : [];
  var body = 0;
  for (var i = 0; i < values.length; i++) body += rowHeight(values[i], tokens);
  if (values.length > 0) body += Math.max(0, values.length - 1) * tokens.rowGap;
  return clamp(tokens.scoreChrome + body, tokens.compactMinimum, tokens.maximum);
}

function settingsContentRequest(destination, tokens) {
  var request = tokens.settings;
  if (destination === "teams") request = tokens.teams;
  else if (destination === "notifications") request = tokens.notifications;
  return clamp(request, tokens.compactMinimum, tokens.maximum);
}

function contentRequest(rows, destination, settingsOpen, tokens) {
  return settingsOpen
    ? settingsContentRequest(destination, tokens)
    : scoreContentRequest(rows, tokens);
}

function dateRadius(width, compactWidth) {
  return Number(width) > 0 && Number(width) < Number(compactWidth) ? 1 : 2;
}

function compactTabLabel(destination, compact) {
  if (!compact) return destination;
  switch (destination) {
  case "sports": return "Sports";
  case "teams": return "Teams";
  case "notifications": return "Alerts";
  default: return destination;
  }
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    clamp: clamp,
    compactTabLabel: compactTabLabel,
    contentRequest: contentRequest,
    dateRadius: dateRadius,
    rowHeight: rowHeight,
    scoreContentRequest: scoreContentRequest,
    settingsContentRequest: settingsContentRequest
  };
}

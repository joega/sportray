// Provider-neutral ambient bar presentation. The host supplies only the
// orientation boundary; normalized game state and fetch health stay above the
// provider layer and below QML formatting.
var FavoritePresentation = null;
var Formatters = null;
if (typeof require === "function") {
  FavoritePresentation = require("./FavoritePresentation.js");
  Formatters = require("./Formatters.js");
}

var FULL_LABEL_MAX_LENGTH = 32;
var TOOLTIP_MAX_LENGTH = 64;

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function textOr(value, fallback) {
  return typeof value === "string" && value.trim() ? value.trim() : fallback;
}

function capText(value, maxLength) {
  var text = typeof value === "string" ? value.trim() : "";
  var limit = typeof maxLength === "number" && isFinite(maxLength) && maxLength > 0
    ? Math.floor(maxLength) : TOOLTIP_MAX_LENGTH;
  if (text.length <= limit) return text;
  if (limit === 1) return "…";
  return text.slice(0, limit - 1).replace(/\s+$/, "") + "…";
}

function selectMode(value) {
  if (value === "compact" || value === "full") return value;
  return value === true ? "compact" : "full";
}

function modeForBar(bar) {
  return selectMode(!!(bar && bar.vertical === true));
}

function selectState(input) {
  if (isRecord(input.state)) return input.state;
  if (!FavoritePresentation) return {kind: "neutral", game: null, count: 0};
  return FavoritePresentation.selectBarState(
    input.games, input.favoriteTeamIds, input.now);
}

function leagueLabel(state) {
  return state && state.game && typeof state.game.league === "string"
    && state.game.league.trim() ? state.game.league.trim().toUpperCase() : "SPORTRAY";
}

function formatState(state, input) {
  if (!Formatters) return "";
  var config = {
    leagueLabel: leagueLabel(state),
    maxLength: FULL_LABEL_MAX_LENGTH
  };
  if (typeof input.timeZone === "string" && input.timeZone.trim())
    config.timeZone = input.timeZone;
  if (typeof input.startTimeText === "string" && input.startTimeText.trim())
    config.startTimeText = input.startTimeText;
  return Formatters.formatBarText(state, config);
}

function fallbackText(input) {
  if (input.loading === true && input.hasData !== true) return "Sportray …";
  if (typeof input.errorCode === "string" && input.errorCode !== "")
    return "Sportray · offline";
  return input.hasData === true ? "Sportray · no games" : "Sportray";
}

function build(input) {
  var source = isRecord(input) ? input : {};
  var state = selectState(source);
  var mode = source.mode !== undefined ? selectMode(source.mode) : selectMode(source.vertical);
  var fullText = textOr(source.fullText, formatState(state, source));
  fullText = capText(fullText || fallbackText(source), FULL_LABEL_MAX_LENGTH);

  var liveFavorite = typeof source.liveFavorite === "boolean"
    ? source.liveFavorite
    : FavoritePresentation && FavoritePresentation.isLiveFavoriteState(state);
  var tooltip = textOr(source.tooltipText, fullText);
  if (liveFavorite && tooltip.indexOf("Live favorite · ") !== 0)
    tooltip = "Live favorite · " + tooltip;
  tooltip = capText(tooltip, TOOLTIP_MAX_LENGTH);

  return {
    mode: mode,
    state: state,
    fullText: fullText,
    label: mode === "full" ? fullText : "",
    tooltipText: tooltip,
    hasLiveFavorite: liveFavorite === true
  };
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    FULL_LABEL_MAX_LENGTH: FULL_LABEL_MAX_LENGTH,
    TOOLTIP_MAX_LENGTH: TOOLTIP_MAX_LENGTH,
    selectMode: selectMode,
    modeForBar: modeForBar,
    build: build
  };
}

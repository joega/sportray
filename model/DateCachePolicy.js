// Pure admission guards for in-memory league snapshots. A last-known
// snapshot is useful across a same-date disable/re-enable, but never across
// a selected-date change.

var DateModel = null;
if (typeof require === "function") DateModel = require("./DateModel.js");

function isDateKey(value) {
  if (DateModel) return DateModel.isDateKey(value);
  return typeof value === "string" && /^\d{4}-\d{2}-\d{2}$/.test(value);
}

function snapshotMatchesDate(snapshotDateKey, selectedDateKey) {
  return isDateKey(snapshotDateKey) && isDateKey(selectedDateKey)
    && snapshotDateKey === selectedDateKey;
}

function canRestoreLastKnown(snapshotDateKey, selectedDateKey, lastKnownGames, currentGames) {
  return snapshotMatchesDate(snapshotDateKey, selectedDateKey)
    && Array.isArray(lastKnownGames) && lastKnownGames.length > 0
    && Array.isArray(currentGames) && currentGames.length === 0;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    snapshotMatchesDate: snapshotMatchesDate,
    canRestoreLastKnown: canRestoreLastKnown
  };
}

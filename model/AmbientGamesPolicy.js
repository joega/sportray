function project(currentGames, selectedDateKey, todayDateKey, todayGames) {
  if (selectedDateKey === todayDateKey) return Array.isArray(currentGames) ? currentGames : [];
  return Array.isArray(todayGames) ? todayGames : [];
}
if (typeof module !== "undefined" && module.exports) module.exports = {project: project};

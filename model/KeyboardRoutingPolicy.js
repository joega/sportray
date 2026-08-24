function catcherBlocked(editorActive, popupOpen) {
  return editorActive === true || popupOpen === true;
}

function targetForKey(key, text, editorActive, popupOpen) {
  if (catcherBlocked(editorActive, popupOpen)) return "editor";
  if (key === "Escape") return "catcher-close";
  if (["ArrowDown", "ArrowUp", "ArrowRight", "ArrowLeft", "j", "k", "l", "h"]
      .indexOf(key || text) !== -1) return "catcher-navigation";
  if (key === "Enter" || key === "Return" || key === "Space" || key === "Tab")
    return "catcher-action";
  if (text) return "catcher-text";
  return "descendant";
}

function calendarFilterAction(text, calendarOpen, settingsOpen, detailOpen) {
  if (text !== "f" && text !== "F") return "none";
  if (calendarOpen !== true || settingsOpen === true || detailOpen === true)
    return "none";
  return "toggle-calendar-filter";
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    catcherBlocked: catcherBlocked,
    targetForKey: targetForKey,
    calendarFilterAction: calendarFilterAction
  };
}

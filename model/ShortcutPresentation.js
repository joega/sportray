// Contextual keyboard help for existing native routes; owns no preferences or I/O.
function row(keys, description) { return {keys: keys, description: description}; }
function forContext(context) {
  var c = context || {}, surface = c.surface || "scores", view = [];
  var navigation = [row("Escape", "Go back or close the panel")];
  if (surface === "calendar" || surface === "team") {
    if (surface === "calendar") view.push(row("Arrows", "Choose a calendar date"));
    view.push(row("Page Up / Down", surface === "team" ? "Browse the previous or next 35 days" : "Browse months"));
    view.push(row("Enter / Space", "Preview a date or open the selected action"));
    view.push(row("R", "Refresh the schedule"));
    navigation.push(row("Tab / Shift+Tab", "Move between calendar controls"));
  } else if (surface === "detail") {
    view = [row("Up / Down", "Choose a game action"), row("Left / Right", "Scroll the scoring table or choose an action"),
      row("Enter / Space", "Activate the selected action"), row("Page Up / Down", "Scroll game details"), row("Home / End", "Go to the top or bottom")];
    navigation.push(row("Tab / Shift+Tab", "Switch neighboring bar panels"));
  } else if (surface === "settings") {
    view = [row("Arrows", "Choose a settings section or action"), row("Enter / Space", "Activate the selected action")];
    if (c.section === "teams") view.push(row("F", "Filter leagues while browsing teams"), row("/", "Return to team search"), row("V", "Review leagues while browsing teams"));
    navigation.push(row("Tab / Shift+Tab", "Switch neighboring panels outside editors and menus"));
  } else {
    view = [row("Arrows / J K", "Choose a league or result"), row("Enter / Space", "Open the selected result or action"),
      row("Page Up / Down", "Page through results"), row("Home / End", "Go to the first or last result"), row("R", "Refresh the current view")];
    if (surface !== "standings") {
      view.push(row("[ / ]", "Browse score dates"), row("T", "Return to today"), row("G", "Open Calendar"), row("Menu / Shift+F10", "Open the selected game's actions"));
      if (c.following) view.push(row("F", "Cycle All, Live, and Favorites"));
    }
    view.push(row("S", "Switch scores and standings for a supported league"), row("N", "Open Settings"));
    navigation.push(row("Tab / Shift+Tab", "Switch neighboring bar panels"));
  }
  if (c.canUndo) view.push(row("Ctrl+Z", "Undo the last favorite or alert change"));
  return [{title: "Current view", rows: view}, {title: "Navigation", rows: navigation}];
}
if (typeof module !== "undefined" && module.exports) module.exports = {forContext: forContext};

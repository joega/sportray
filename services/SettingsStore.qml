import QtQuick
import Quickshell
import Quickshell.Io
import "../model/SettingsModel.js" as SettingsModel
import "../model/StateModel.js" as StateModel
import "../model/TransitionDedupe.js" as TransitionDedupe

// Persistent application state only. Fetch results, normalized games, and
// provider objects deliberately do not belong here. Transition fingerprints
// are bounded state for the normalized event boundary, not provider data.
Item {
  id: root

  readonly property string statePath: Quickshell.env("HOME") + "/.local/state/omarchy/settings/sportray.json"
  property var settings: SettingsModel.createDefaults()
  property var transitionDedupe: TransitionDedupe.createDefaults()
  property string loadStatus: "pending"
  property bool recovered: false
  property bool ready: false

  function applyText(raw) {
    var result = StateModel.parseStateText(raw, Date.now(), SettingsModel, TransitionDedupe)
    root.settings = result.settings
    root.transitionDedupe = result.transitionDedupe
    root.loadStatus = result.status
    root.recovered = result.recovered
    root.ready = true
    if (result.needsWrite) root.writeState(result.settings, result.transitionDedupe)
  }

  // Settings UI calls this narrow boundary with a candidate object. It is
  // normalized before serialization so unknown or unbounded fields never
  // enter the state file.
  function writeSettings(candidate) {
    var normalized = SettingsModel.normalizeSettings(candidate)
    root.settings = normalized.settings
    root.writeState(normalized.settings, root.transitionDedupe)
    return true
  }

  function writeState(candidateSettings, candidateDedupe) {
    var state = StateModel.createState(candidateSettings, candidateDedupe, SettingsModel, TransitionDedupe)
    root.settings = {
      schemaVersion: state.schemaVersion,
      enabledLeagues: state.enabledLeagues,
      favoriteTeamIds: state.favoriteTeamIds,
      notifications: state.notifications
    }
    root.transitionDedupe = state.transitionDedupe
    settingsFile.setText(JSON.stringify(state, null, 2) + "\n")
    return true
  }

  // M6.3 will call this boundary after the pure detector has produced events.
  // Loading state alone never calls it, so startup cannot create a transition.
  function acceptTransitionEvents(events, now) {
    if (!root.ready) return []
    var result = TransitionDedupe.acceptEvents(root.transitionDedupe, events, now)
    root.transitionDedupe = result.state
    if (result.changed) root.writeState(root.settings, root.transitionDedupe)
    return result.events
  }

  function isFavoriteTeam(teamId) {
    return typeof teamId === "string"
      && root.settings.favoriteTeamIds.indexOf(teamId.trim().toLowerCase()) !== -1
  }

  function isLeagueEnabled(leagueId) {
    return typeof leagueId === "string"
      && root.settings.enabledLeagues.indexOf(leagueId.trim().toLowerCase()) !== -1
  }

  function toggleLeague(leagueId) {
    var next = SettingsModel.toggleLeague(root.settings, leagueId)
    return root.writeSettings(next)
  }

  function toggleFavoriteTeam(teamId) {
    var next = SettingsModel.toggleFavoriteTeam(root.settings, teamId)
    return root.writeSettings(next)
  }

  function toggleNotification(key) {
    var next = SettingsModel.toggleNotification(root.settings, key)
    return root.writeSettings(next)
  }

  function reloadSettings() {
    settingsFile.reload()
  }

  FileView {
    id: settingsFile
    path: root.statePath
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.applyText(text())
    onLoadFailed: root.applyText("")
  }
}

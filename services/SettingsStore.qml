import QtQuick
import Quickshell
import Quickshell.Io
import "../model/SettingsModel.js" as SettingsModel
import "../model/SettingsPermissionPolicy.js" as SettingsPermissionPolicy
import "../model/StateModel.js" as StateModel
import "../model/TransitionDedupe.js" as TransitionDedupe

// Persistent application state only. Fetch results, normalized games, and
// provider objects deliberately do not belong here. Transition fingerprints
// are bounded state for the normalized event boundary, not provider data.
Item {
  id: root

  readonly property string statePath: Quickshell.env("HOME") + "/.local/state/omarchy/settings/sportray.json"
  property bool permissionsReady: false
  property bool loadStarted: false
  property bool writePending: false
  property string permissionStage: "idle"
  property var settings: SettingsModel.createDefaults()
  property var transitionDedupe: TransitionDedupe.createDefaults()
  // A future schema is intentionally kept opaque. The UI receives safe
  // defaults, but no later action may replace the file before a compatible
  // reload supplies a schema this version understands.
  property string preservedRawStateText: ""
  property string loadStatus: "pending"
  property bool recovered: false
  property bool ready: false

  function applyText(raw) {
    var result = StateModel.parseStateText(raw, Date.now(), SettingsModel, TransitionDedupe)
    root.settings = result.settings
    root.transitionDedupe = result.transitionDedupe
    root.preservedRawStateText = result.preservedRawText || ""
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
    if (root.preservedRawStateText.length > 0) return false
    if (!root.permissionsReady || permissionProcess.running) return false
    var state = StateModel.createState(candidateSettings, candidateDedupe, SettingsModel, TransitionDedupe)
    if (candidateSettings !== root.settings) {
      root.settings = {
        schemaVersion: state.schemaVersion,
        enabledLeagues: state.enabledLeagues,
        favoriteTeamIds: state.favoriteTeamIds,
        notifications: state.notifications
      }
    }
    root.transitionDedupe = state.transitionDedupe
    root.permissionsReady = false
    root.writePending = true
    settingsFile.setText(JSON.stringify(state, null, 2) + "\n")
    return true
  }

  function failPermissionRepair(stage) {
    root.permissionsReady = false
    root.writePending = false
    console.warn("Sportray settings permission repair failed", stage)
  }

  function finishPermissionRepair() {
    root.permissionsReady = true
    root.permissionStage = "ready"
    if (!root.loadStarted) root.loadStarted = true
  }

  function beginPermissionRepair() {
    var commands = SettingsPermissionPolicy.commands(root.statePath)
    if (!commands) {
      root.failPermissionRepair("invalid-path")
      return
    }
    root.permissionStage = "make-directory"
    permissionProcess.exec(commands.makeDirectory)
  }

  function repairWrittenFile() {
    var commands = SettingsPermissionPolicy.commands(root.statePath)
    if (!commands) {
      root.failPermissionRepair("invalid-path-after-write")
      return
    }
    root.permissionStage = "harden-written-file"
    permissionProcess.exec(commands.hardenFile)
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
    path: root.loadStarted ? root.statePath : ""
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.applyText(text())
    onLoadFailed: root.applyText("")
    onSaved: root.repairWrittenFile()
    onSaveFailed: root.failPermissionRepair("file-write")
  }

  Process {
    id: permissionProcess
    running: false

    onExited: function(exitCode) {
      var commands = SettingsPermissionPolicy.commands(root.statePath)
      if (!commands) {
        root.failPermissionRepair(root.permissionStage)
        return
      }

      if (root.permissionStage === "make-directory") {
        if (exitCode !== 0) {
          root.failPermissionRepair("make-directory")
          return
        }
        root.permissionStage = "harden-directory"
        permissionProcess.exec(commands.hardenDirectory)
        return
      }

      if (root.permissionStage === "harden-directory") {
        if (exitCode !== 0) {
          root.failPermissionRepair("harden-directory")
          return
        }
        root.permissionStage = "check-file"
        permissionProcess.exec(commands.checkFile)
        return
      }

      if (root.permissionStage === "check-file") {
        if (exitCode === 0) {
          root.permissionStage = "harden-file"
          permissionProcess.exec(commands.hardenFile)
        } else if (exitCode === 1) {
          root.finishPermissionRepair()
        } else {
          root.failPermissionRepair("check-file")
        }
        return
      }

      if (root.permissionStage === "harden-file") {
        if (exitCode === 0) root.finishPermissionRepair()
        else root.failPermissionRepair("harden-file")
        return
      }

      if (root.permissionStage === "harden-written-file") {
        root.writePending = false
        if (SettingsPermissionPolicy.writeResult(exitCode)) {
          root.permissionsReady = true
          root.permissionStage = "ready"
        } else {
          root.failPermissionRepair("harden-written-file")
        }
      }
    }
  }

  Component.onCompleted: root.beginPermissionRepair()

  Component.onDestruction: {
    if (permissionProcess.running) permissionProcess.running = false
  }
}

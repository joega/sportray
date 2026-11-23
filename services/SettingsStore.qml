import QtQuick
import Quickshell
import Quickshell.Io
import "../model/SettingsModel.js" as SettingsModel
import "../model/StateModel.js" as StateModel
import "../model/TransitionDedupe.js" as TransitionDedupe
import "../model/WatchPolicy.js" as WatchPolicy

// Persistent application state only. Fetch results, normalized games, and
// provider objects deliberately do not belong here. Transition fingerprints
// are bounded state for the normalized event boundary, not provider data.
Item {
  id: root

  readonly property string statePath: Quickshell.env("HOME") + "/.local/state/omarchy/settings/sportray.json"
  property bool writePending: false
  property var pendingWrite: null
  property bool readQueued: false
  property string helperOperation: ""
  property var settings: SettingsModel.createDefaults()
  property var transitionDedupe: TransitionDedupe.createDefaults()
  property var watchedGames: []
  // A future schema is intentionally kept opaque. The UI receives safe
  // defaults, but no later action may replace the file before a compatible
  // reload supplies a schema this version understands.
  property string preservedRawStateText: ""
  property string loadStatus: "pending"
  property bool recovered: false
  property bool ready: false

  function applyText(raw) {
    var result = StateModel.parseStateText(raw, Date.now(), SettingsModel, TransitionDedupe, WatchPolicy)
    root.settings = result.settings
    root.transitionDedupe = result.transitionDedupe
    root.watchedGames = result.watchedGames || []
    root.preservedRawStateText = result.preservedRawText || ""
    root.loadStatus = result.status
    root.recovered = result.recovered
    root.ready = true
    if (result.needsWrite) root.writeState(result.settings, result.transitionDedupe, root.watchedGames)
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

  function writeState(candidateSettings, candidateDedupe, candidateWatches) {
    if (root.preservedRawStateText.length > 0) return false
    if (root.helperOperation !== "" || stateHelper.running) {
      root.pendingWrite = {
        settings: candidateSettings,
        transitionDedupe: candidateDedupe,
        watchedGames: candidateWatches || root.watchedGames
      }
      root.writePending = true
      return false
    }
    var state = StateModel.createState(candidateSettings, candidateDedupe, SettingsModel, TransitionDedupe,
      Date.now(), candidateWatches || root.watchedGames, WatchPolicy)
    if (candidateSettings !== root.settings) {
      root.settings = {
        schemaVersion: state.schemaVersion,
        enabledLeagues: state.enabledLeagues,
        followedLeagueIds: state.followedLeagueIds,
        favoriteTeamIds: state.favoriteTeamIds,
        notifications: state.notifications,
        ticker: state.ticker
      }
    }
    root.transitionDedupe = state.transitionDedupe
    root.watchedGames = state.watchedGames
    root.writePending = true
    root.pendingWrite = null
    root.startHelperWrite(JSON.stringify(state, null, 2) + "\n")
    return true
  }

  function flushPendingWrite() {
    if (!root.pendingWrite || root.helperOperation !== "" || stateHelper.running
        || root.preservedRawStateText.length > 0) return
    var pending = root.pendingWrite
    root.pendingWrite = null
    root.writeState(pending.settings, pending.transitionDedupe, pending.watchedGames)
  }

  function failStateHelper(stage) {
    root.writePending = false
    console.warn("Sportray settings helper failed", stage)
  }

  function rejectState() {
    root.settings = SettingsModel.createDefaults()
    root.transitionDedupe = TransitionDedupe.createDefaults()
    root.watchedGames = []
    root.preservedRawStateText = "rejected-state"
    root.loadStatus = "rejected"
    root.recovered = false
    root.ready = true
    root.writePending = false
    root.pendingWrite = null
    console.warn("Sportray settings state rejected")
  }

  function startHelperRead() {
    if (root.helperOperation !== "" || stateHelper.running) {
      root.readQueued = true
      return
    }
    root.readQueued = false
    root.helperOperation = "read"
    stateHelper.command = ["/usr/bin/python3", root.helperPath, "read"]
    stateHelper.running = true
  }

  function startHelperWrite(text) {
    root.helperOperation = "write"
    stateHelper.command = ["/usr/bin/python3", root.helperPath, "write", "--data", text]
    stateHelper.running = true
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

  function setTicker(key, value) {
    var current = root.settings && root.settings.ticker ? root.settings.ticker : SettingsModel.createDefaults().ticker
    var next = {
      enabled: current.enabled,
      position: current.position,
      speed: current.speed
    }
    if (["enabled", "position", "speed"].indexOf(key) === -1) return false
    next[key] = value
    var candidate = {
      schemaVersion: root.settings.schemaVersion,
      enabledLeagues: root.settings.enabledLeagues,
      followedLeagueIds: root.settings.followedLeagueIds,
      favoriteTeamIds: root.settings.favoriteTeamIds,
      notifications: root.settings.notifications,
      ticker: next
    }
    return root.writeSettings(candidate)
  }

  function isLeagueFollowed(leagueId) {
    return typeof leagueId === "string" && root.settings.followedLeagueIds.indexOf(leagueId.trim().toLowerCase()) !== -1
  }

  function toggleFollowedLeague(leagueId) {
    var next = SettingsModel.toggleFollowedLeague(root.settings, leagueId)
    return root.writeSettings(next)
  }

  function moveFollowedLeague(leagueId, direction) {
    var next = SettingsModel.moveFollowedLeague(root.settings, leagueId, direction)
    return root.writeSettings(next)
  }

  // One bounded mutation boundary for the temporary game-watch intent. The
  // UI never edits watchedGames directly; expired records are removed before
  // an add so the 32-record cap cannot be consumed by dead state.
  function toggleWatch(game) {
    if (!root.ready || root.preservedRawStateText.length > 0 || !game)
      return false
    var now = Date.now()
    var current = WatchPolicy.removeExpired(root.watchedGames, now)
    var gameId = WatchPolicy.gameIdFor(game)
    if (!gameId || !game.startTime) return false
    var existing = WatchPolicy.findWatch(current, game)
    var next = current.filter(function(entry) { return entry.gameId !== gameId })
    if (existing) return root.writeState(root.settings, root.transitionDedupe, next)
    if (!root.isLeagueEnabled(game.league)) return false
    if (game.status === "final" || game.status === "canceled") return false
    var created = WatchPolicy.createWatch(game, new Date(now).toISOString(), now)
    if (!created || next.length >= WatchPolicy.MAX_WATCHES) return false
    next.push(created)
    return root.writeState(root.settings, root.transitionDedupe, next)
  }

  function reloadSettings() {
    root.startHelperRead()
  }

  FileView {
    id: settingsFile
    // Watch metadata only. Default preloading would read settings by pathname
    // outside the descriptor-bound helper's validation and byte limit.
    preload: false
    path: root.statePath
    watchChanges: true
    printErrors: false
    onFileChanged: root.reloadSettings()
  }

  Process {
    id: stateHelper
    running: false
    stdout: StdioCollector {
      id: stateHelperOutput
      waitForEnd: true
    }

    onExited: function(exitCode) {
      var operation = root.helperOperation
      root.helperOperation = ""
      if (operation === "read") {
        if (exitCode === 0) root.applyText(stateHelperOutput.text)
        else if (exitCode === 2) root.applyText("")
        else if (exitCode === 4) root.rejectState()
        else root.failStateHelper("read")
      } else if (operation === "write") {
        if (exitCode === 0) {
          root.writePending = false
          root.flushPendingWrite()
        } else root.failStateHelper("write")
      }
      if (root.readQueued && root.helperOperation === "" && !stateHelper.running)
        root.startHelperRead()
    }
  }

  readonly property string helperPath: decodeURIComponent(
    Qt.resolvedUrl("../scripts/settings-state-helper.py").toString().replace("file://", ""))

  Component.onCompleted: root.startHelperRead()

  Component.onDestruction: {
    if (stateHelper.running) stateHelper.running = false
  }
}

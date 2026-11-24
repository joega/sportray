import QtQuick
import Quickshell
import Quickshell.Io
import "../model/SettingsModel.js" as SettingsModel
import "../model/StateModel.js" as StateModel
import "../model/TransitionDedupe.js" as TransitionDedupe
import "../model/WatchPolicy.js" as WatchPolicy
import "../model/ActionFeedbackPolicy.js" as ActionFeedbackPolicy

// Application settings/watch persistence plus one bounded, transient Undo
// intent. Fetch results and provider objects deliberately do not belong here.
// Transition fingerprints remain bounded normalized-event state.
Item {
  id: root

  readonly property string statePath: Quickshell.env("HOME") + "/.local/state/omarchy/settings/sportray.json"
  property bool shuttingDown: false
  property bool writePending: false
  property var pendingWrite: null
  property bool readQueued: false
  property bool metadataWatchEnabled: false
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
  property var feedbackAction: null
  property int feedbackSerial: 0
  property var readBaseSettings: null
  property var readBaseWatches: []
  readonly property var effectiveWatchedGames: root.pendingWrite && Array.isArray(root.pendingWrite.watchedGames)
    ? root.pendingWrite.watchedGames : root.watchedGames
  readonly property bool canUndoFeedback: ActionFeedbackPolicy.canUndo(root.feedbackAction, root.settings,
    root.effectiveWatchedGames, Date.now(), root.ready, root.shuttingDown,
    root.preservedRawStateText.length > 0, WatchPolicy)

  function dismissFeedback() { root.feedbackAction = null }
  function publishFeedback(kind, targetId, before, after, label) {
    root.feedbackSerial = root.feedbackSerial >= 2147483646 ? 1 : root.feedbackSerial + 1
    var action = ActionFeedbackPolicy.action(root.feedbackSerial, kind, targetId,
      before, after, label, Date.now())
    if (kind === "watch" && before) action.expiresAt = Math.min(action.expiresAt,
      Date.parse(before.expiresAt), Date.parse(before.createdAt) + WatchPolicy.HARD_MAX_AGE_MS)
    root.feedbackAction = action
  }
  function mutationReady() { return root.ready && !root.shuttingDown && root.preservedRawStateText.length === 0 }

  onFeedbackActionChanged: {
    feedbackExpiry.stop()
    if (root.feedbackAction) {
      feedbackExpiry.interval = Math.max(0, Math.min(ActionFeedbackPolicy.FEEDBACK_TTL_MS,
        root.feedbackAction.expiresAt - Date.now()))
      feedbackExpiry.start()
    }
  }
  Timer { id: feedbackExpiry; repeat: false; onTriggered: root.dismissFeedback() }

  function applyText(raw) {
    var pending = root.pendingWrite
    var result = StateModel.parseStateText(raw, Date.now(), SettingsModel, TransitionDedupe, WatchPolicy)
    if (pending && root.readBaseSettings && !result.preservedRawText) {
      result.settings = ActionFeedbackPolicy.mergeSettings(root.readBaseSettings, result.settings, pending.settings, SettingsModel)
      result.watchedGames = ActionFeedbackPolicy.mergeWatches(root.readBaseWatches, result.watchedGames || [],
        pending.watchedGames, Date.now(), WatchPolicy, result.settings.enabledLeagues)
      result.transitionDedupe = TransitionDedupe.normalizeState({schemaVersion: 1,
        fingerprints: result.transitionDedupe.fingerprints.concat(pending.transitionDedupe.fingerprints)}, Date.now()).state
    }
    root.settings = result.settings
    root.transitionDedupe = result.transitionDedupe
    root.watchedGames = result.watchedGames || []
    root.preservedRawStateText = result.preservedRawText || ""
    root.loadStatus = result.status
    root.recovered = result.recovered
    root.ready = true
    if (root.preservedRawStateText.length > 0) {
      root.pendingWrite = null
      root.writePending = false
      root.dismissFeedback()
    } else if (pending && root.readBaseSettings) {
      root.pendingWrite = null
      root.writeState(root.settings, root.transitionDedupe, root.watchedGames)
    } else if (result.needsWrite && !root.shuttingDown) root.writeState(result.settings, result.transitionDedupe, root.watchedGames)
    if (root.feedbackAction && !root.feedbackAction.undone
        && !ActionFeedbackPolicy.matches(root.feedbackAction, root.settings, root.effectiveWatchedGames, WatchPolicy))
      root.dismissFeedback()
  }

  // Settings UI calls this narrow boundary with a candidate object. It is
  // normalized before serialization so unknown or unbounded fields never
  // enter the state file.
  function writeSettings(candidate) {
    if (!root.mutationReady()) return false
    var normalized = SettingsModel.normalizeSettings(candidate)
    if (JSON.stringify(normalized.settings) === JSON.stringify(root.settings)) return false
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
        watchedGames: candidateWatches || root.effectiveWatchedGames
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
    if (stage === "write" && root.feedbackAction) {
      root.feedbackSerial = root.feedbackSerial >= 2147483646 ? 1 : root.feedbackSerial + 1
      root.feedbackAction = {id: root.feedbackSerial, kind: "error", summary: "Couldn't save preferences",
        undone: true, severity: "error", expiresAt: Date.now() + ActionFeedbackPolicy.FEEDBACK_TTL_MS}
    }
    console.warn("Sportray settings helper failed", stage)
  }

  function rejectState() {
    root.dismissFeedback()
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

  function beginShutdown() {
    root.dismissFeedback()
    root.shuttingDown = true
    root.readQueued = false
  }

  function resume() {
    root.shuttingDown = false
    root.reloadSettings()
  }

  function startHelperRead() {
    if (root.shuttingDown) return
    if (root.helperOperation !== "" || stateHelper.running) {
      root.readQueued = true
      return
    }
    root.readQueued = false
    root.readBaseSettings = SettingsModel.normalizeSettings(root.settings).settings
    root.readBaseWatches = WatchPolicy.normalizeWatches(root.effectiveWatchedGames, Date.now()).watches
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

  function setFavoriteTeam(teamId, favorite, label) {
    if (!root.mutationReady() || typeof teamId !== "string" || typeof favorite !== "boolean") return false
    var id = teamId.trim().toLowerCase()
    var before = root.isFavoriteTeam(id)
    if (before === favorite) return false
    var next = SettingsModel.toggleFavoriteTeam(root.settings, id)
    if ((next.favoriteTeamIds.indexOf(id) !== -1) !== favorite || !root.writeSettings(next)) return false
    root.publishFeedback("favorite", id, before, favorite, label)
    return true
  }

  function toggleFavoriteTeam(teamId, label) {
    return root.setFavoriteTeam(teamId, !root.isFavoriteTeam(teamId), label)
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
  function toggleWatch(game, label) {
    if (!root.mutationReady() || !game)
      return false
    var now = Date.now()
    var current = WatchPolicy.removeExpired(root.effectiveWatchedGames, now)
    var gameId = WatchPolicy.gameIdFor(game)
    if (!gameId || !game.startTime) return false
    var existing = WatchPolicy.findWatch(current, game)
    var next = current.filter(function(entry) { return entry.gameId !== gameId })
    var created = null
    if (!existing) {
      if (!root.isLeagueEnabled(game.league)) return false
      if (game.status === "final" || game.status === "canceled") return false
      created = WatchPolicy.createWatch(game, new Date(now).toISOString(), now)
      if (!created || next.length >= WatchPolicy.MAX_WATCHES) return false
      next.push(created)
    }
    root.watchedGames = next
    root.writeState(root.settings, root.transitionDedupe, next)
    root.publishFeedback("watch", gameId, existing, created, label)
    return true
  }

  function undoFeedback(expectedId) {
    var action = root.feedbackAction
    if (expectedId !== undefined && (!action || expectedId !== action.id)) return false
    if (!ActionFeedbackPolicy.canUndo(action, root.settings, root.effectiveWatchedGames, Date.now(),
        root.ready, root.shuttingDown, root.preservedRawStateText.length > 0, WatchPolicy)) return false
    if (action.kind === "favorite") {
      var next = SettingsModel.toggleFavoriteTeam(root.settings, action.targetId)
      if ((next.favoriteTeamIds.indexOf(action.targetId) !== -1) !== action.before || !root.writeSettings(next)) return false
    } else {
      var watches = WatchPolicy.removeExpired(root.effectiveWatchedGames, Date.now()).filter(function(entry) {
        return entry.gameId !== action.targetId
      })
      if (action.before) watches.push(WatchPolicy.normalizeEntry(action.before))
      root.watchedGames = watches
      root.writeState(root.settings, root.transitionDedupe, watches)
    }
    root.feedbackSerial = root.feedbackSerial >= 2147483646 ? 1 : root.feedbackSerial + 1
    root.feedbackAction = {id: root.feedbackSerial, kind: action.kind, targetId: action.targetId,
      summary: action.kind === "favorite" ? "Favorite change undone" : "Game alert change undone",
      undone: true, expiresAt: Date.now() + ActionFeedbackPolicy.FEEDBACK_TTL_MS, severity: "info"}
    return true
  }

  function reloadSettings() {
    root.startHelperRead()
  }

  FileView {
    id: settingsFile
    // Watch metadata only. Default preloading would read settings by pathname
    // outside the descriptor-bound helper's validation and byte limit.
    preload: false
    // The helper creates/validates the parent on first install. Registering
    // before that happens leaves FileView without a directory to watch.
    path: root.metadataWatchEnabled ? root.statePath : ""
    watchChanges: !root.shuttingDown
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
        if (root.shuttingDown) {
          // An in-flight external reload can discover an opaque future schema
          // or an unsafe file. Admit its result before publishing queued edits.
          if (exitCode === 0) root.applyText(stateHelperOutput.text)
          else if (exitCode === 2) root.applyText("")
          else if (exitCode === 4) root.rejectState()
          else root.failStateHelper("read")
          if ((exitCode === 0 || exitCode === 2)
              && root.preservedRawStateText.length === 0) root.flushPendingWrite()
          else {
            root.pendingWrite = null
            root.writePending = false
          }
        }
        else if (!root.metadataWatchEnabled) {
          root.metadataWatchEnabled = true
          // A replacement between the first snapshot and registration has no
          // watcher event. Reconcile once through the same bounded helper before
          // applying data or publishing missing/malformed-state recovery.
          root.readQueued = true
        } else {
          if (exitCode === 0) root.applyText(stateHelperOutput.text)
          else if (exitCode === 2) root.applyText("")
          else if (exitCode === 4) root.rejectState()
          else root.failStateHelper("read")
        }
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

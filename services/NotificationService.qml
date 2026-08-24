import QtQuick
import Quickshell.Io
import "../model/DateModel.js" as DateModel
import "../model/NotificationModel.js" as NotificationModel
import "../model/PregameReminderPolicy.js" as PregameReminderPolicy
import "../model/TransitionDedupe.js" as TransitionDedupe
import "../model/TransitionDetector.js" as TransitionDetector

// Consumes only normalized games. Provider response parsing remains owned by
// the provider and league-fetch boundaries.
Item {
  id: root

  property var games: []
  property var settingsStore: null
  property var previousGames: []
  property bool hasBaseline: false
  property bool hasReadyBaseline: false
  property var pendingDeliveries: []

  function currentGames() {
    return Array.isArray(root.games) ? root.games.slice() : []
  }

  function handleGamesChanged() {
    var current = root.currentGames()
    if (!root.hasBaseline) {
      root.previousGames = current
      root.hasBaseline = true
      return
    }

    // A snapshot arriving before settings load must still become the silent
    // baseline; it cannot be replayed as a startup notification later.
    if (!root.settingsStore || root.settingsStore.ready !== true) {
      root.previousGames = current
      return
    }

    // Reminders follow the same first-fetch suppression as transition alerts.
    // A startup snapshot must not become a notification merely because settings
    // finished loading after the scores arrived.
    if (!root.hasReadyBaseline) {
      root.previousGames = current
      root.hasReadyBaseline = true
      return
    }

    var previous = root.previousGames
    root.previousGames = current
    var nowMs = Date.now()
    var events = TransitionDetector.detectGames(previous, current).concat(
      PregameReminderPolicy.eligibleEvents(
        current, root.settingsStore.settings, nowMs,
        DateModel.localDateKey(new Date(nowMs)))
    )
    if (events.length === 0 || typeof root.settingsStore.acceptTransitionEvents !== "function") return

    var deliveries = NotificationModel.buildDeliveries(
      events, current, root.settingsStore.settings)
    if (deliveries.length === 0) return

    // Accept only events that pass favorite and preference gating. The store
    // persists these fingerprints before the helper is launched, so a helper
    // failure cannot corrupt state or cause an unbounded retry loop.
    var accepted = root.settingsStore.acceptTransitionEvents(
      deliveries.map(function(delivery) { return delivery.event; }), Date.now())
    if (!Array.isArray(accepted) || accepted.length === 0) return

    var acceptedKeys = Object.create(null)
    for (var i = 0; i < accepted.length; i++) {
      var key = TransitionDedupe.fingerprintForEvent(accepted[i])
      if (key) acceptedKeys[key] = true
    }

    var ready = deliveries.filter(function(delivery) {
      return acceptedKeys[delivery.fingerprint] === true
    })
    root.pendingDeliveries = root.pendingDeliveries.concat(ready)
    root.drainQueue()
  }

  function drainQueue() {
    if (notificationProcess.running || root.pendingDeliveries.length === 0) return
    var next = root.pendingDeliveries[0]
    root.pendingDeliveries = root.pendingDeliveries.slice(1)
    notificationProcess.command = next.argv
    notificationProcess.running = true
  }

  // Settings preview deliberately bypasses event preferences and dedupe. It
  // exercises the same Omarchy helper and direct Process argument boundary as
  // real alerts without changing persisted notification state.
  function sendTestNotification() {
    var delivery = NotificationModel.buildTestDelivery()
    root.pendingDeliveries = root.pendingDeliveries.concat([delivery])
    root.drainQueue()
  }

  onGamesChanged: root.handleGamesChanged()

  Connections {
    target: root.settingsStore
    function onReadyChanged() { root.handleGamesChanged() }
  }

  Component.onCompleted: root.handleGamesChanged()

  Process {
    id: notificationProcess
    running: false

    onExited: function(exitCode) {
      var outcome = NotificationModel.helperOutcome(exitCode, null)
      if (!outcome.ok) {
        console.warn("Sportray notification helper failed", outcome.exitCode)
      }
      root.drainQueue()
    }
  }

  Component.onDestruction: {
    root.pendingDeliveries = []
    if (notificationProcess.running) notificationProcess.running = false
  }
}

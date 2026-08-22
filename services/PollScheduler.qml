import QtQuick
import "../model/PollPolicy.js" as PollPolicy
import "../model/DateModel.js" as DateModel

// One timer for the whole fetch service. The scheduler emits refresh intent;
// FetchService remains the owner of the existing per-league curl processes.
Item {
  id: root

  property var games: []
  property var favoriteTeamIds: []
  property var enabledLeagues: []
  property string selectedDateKey: ""
  property bool panelOpen: false
  property bool initialized: false
  property double nowMs: Date.now()
  property double timerDueAtMs: 0
  readonly property real jitterUnit: Math.random()

  readonly property int jitterSeed: PollPolicy.seedForGames(root.games)
  readonly property var cadence: PollPolicy.selectCadence(
    root.games, root.favoriteTeamIds, root.panelOpen, root.nowMs, root.jitterSeed,
    root.selectedDateKey, DateModel.localDateKey(new Date(root.nowMs)))
  readonly property int intervalMs: PollPolicy.spreadIntervalMs(
    root.cadence.intervalMs, root.jitterUnit)
  readonly property string cadenceKind: root.cadence.kind

  signal refreshRequested(string reason)

  function restartTimer() {
    var now = Date.now()
    var requestedDueAt = now + root.intervalMs
    var dueAt = pollTimer.running && root.timerDueAtMs > 0
      ? PollPolicy.earliestDeadline(root.timerDueAtMs, requestedDueAt)
      : requestedDueAt
    root.timerDueAtMs = dueAt
    pollTimer.interval = PollPolicy.delayUntil(dueAt, now)
    pollTimer.restart()
  }

  function scheduleRetry(delayMs) {
    var delay = Math.max(1, Number(delayMs) || 1)
    var now = Date.now()
    var requestedDueAt = now + delay
    var dueAt = pollTimer.running && root.timerDueAtMs > 0
      ? PollPolicy.earliestDeadline(root.timerDueAtMs, requestedDueAt)
      : requestedDueAt
    root.timerDueAtMs = dueAt
    pollTimer.interval = PollPolicy.delayUntil(dueAt, now)
    pollTimer.restart()
  }

  function requestRefresh(reason) {
    root.nowMs = Date.now()
    console.debug("Sportray polling", reason, root.cadenceKind, root.intervalMs)
    root.restartTimer()
    root.refreshRequested(reason)
  }

  function manualRefresh() {
    root.requestRefresh("manual")
  }

  onGamesChanged: {
    if (root.initialized) root.restartTimer()
  }

  onFavoriteTeamIdsChanged: {
    if (root.initialized) root.restartTimer()
  }

  onEnabledLeaguesChanged: {
    if (root.initialized) root.requestRefresh("enabled-leagues-changed")
  }

  onPanelOpenChanged: {
    if (!root.initialized) return
    root.restartTimer()
  }

  onSelectedDateKeyChanged: {
    if (root.initialized) root.restartTimer()
  }

  Component.onCompleted: {
    root.initialized = true
    root.requestRefresh("initialization")
  }

  Component.onDestruction: pollTimer.stop()

  Timer {
    id: pollTimer
    repeat: false
    interval: root.intervalMs
    onTriggered: root.requestRefresh("timer")
  }
}

import QtQuick
import Quickshell.Io
import "../providers/NhlProvider.js" as NhlProvider
import "../model/CalendarModel.js" as CalendarModel
import "../model/CalendarCachePolicy.js" as CalendarCachePolicy
import "../model/ChunkPolicy.js" as ChunkPolicy
import "../model/DateModel.js" as DateModel
import "../model/ResponsePolicy.js" as ResponsePolicy

Item {
  id: root

  property bool calendarEnabled: false
  property string requestedMonthKey: ""
  property var windows: ({})
  property var windowOrder: []
  property var currentState: ({leagueId: "nhl", displayName: "NHL", days: [], status: "unknown",
    loading: false, stale: false, errorCode: ""})
  property int generation: 0
  property int activeGeneration: 0
  property var planWindows: []
  property int planIndex: 0
  property var activeDays: []
  property string activeWindowKey: ""
  property string pendingBody: ""
  property bool bodyReceived: false
  property bool responseTooLarge: false
  property bool stoppingRequest: false
  property bool ownerDestroyed: false
  property string queuedMonthKey: ""
  property bool calendarCacheReady: false
  property string planKind: ""
  property var backgroundDays: []
  property int backgroundIndex: 0

  function windowKey(monthKey) { return "nhl:" + monthKey }
  function backgroundWindowKey(window) {
    return "nhl:rolling:" + window.startDate + ":" + window.endDate
  }

  function snapshot() { return root.currentState }

  function publishBackground(days) {
    var merged = CalendarCachePolicy.mergeState(root.currentState, {
      leagueId: "nhl", displayName: "NHL", days: days || []
    })
    root.backgroundDays = merged.days
    root.currentState = {
      leagueId: "nhl", displayName: "NHL", days: merged.days,
      status: root.currentState.status || "unknown",
      loading: root.currentState.loading === true, stale: root.currentState.stale === true,
      errorCode: root.currentState.errorCode || ""
    }
  }

  function setState(status, days, errorCode, stale) {
    root.currentState = {
      leagueId: "nhl", displayName: "NHL", days: Array.isArray(days) ? days : [],
      status: status || "unknown", loading: status === "loading", stale: stale === true,
      errorCode: errorCode || ""
    }
  }

  function cached(key, nowMs) {
    var entry = root.windows[key]
    return entry && CalendarCachePolicy.isFresh(entry, nowMs,
      DateModel.localDateKey(new Date(nowMs))) ? entry : null
  }

  function publishEntry(entry) {
    if (!entry) return
    root.setState(entry.status, entry.days, entry.status === "unavailable" ? "unavailable" : "",
      entry.stale === true)
  }

  function remember(entry) {
    var key = root.activeWindowKey
    var next = {}
    for (var existing in root.windows) next[existing] = root.windows[existing]
    next[key] = entry
    var order = root.windowOrder.filter(function(value) { return value !== key })
    order.push(key)
    while (order.length > CalendarCachePolicy.MAX_CACHE_WINDOWS) {
      var evicted = order.shift()
      delete next[evicted]
    }
    root.windows = next
    root.windowOrder = order
  }

  function cancel() {
    root.generation++
    root.activeGeneration = root.generation
    if (calendarProcess.running) {
      root.stoppingRequest = true
      calendarProcess.running = false
    }
    root.planWindows = []
    root.planIndex = 0
    root.activeDays = []
    root.pendingBody = ""
    root.bodyReceived = false
    root.responseTooLarge = false
    root.planKind = ""
  }

  function cancelSchedule() {
    root.queuedMonthKey = ""
    root.cancel()
  }

  onCalendarEnabledChanged: {
    if (!root.calendarEnabled) root.cancel()
  }

  onCalendarCacheReadyChanged: {
    if (!root.calendarCacheReady && root.planKind === "background") root.cancel()
  }

  function requestMonth(monthKey) {
    if (!root.calendarEnabled || root.ownerDestroyed || !DateModel.isDateKey(monthKey)) return false
    var requested = DateModel.monthKey(monthKey)
    if (!requested) return false
    root.requestedMonthKey = requested
    if (calendarProcess.running) {
      root.queuedMonthKey = requested
      root.cancel()
      return false
    }
    root.queuedMonthKey = ""
    root.cancel()
    root.activeWindowKey = root.windowKey(requested)
    root.planKind = "month"
    var nowMs = Date.now()
    var hit = root.cached(root.activeWindowKey, nowMs)
    if (hit) {
      root.publishEntry(hit)
      return false
    }

    var dates = CalendarModel.monthDateKeys(requested)
    if (!dates || dates.length !== 42) {
      root.setState("unavailable", [], "configuration", false)
      return false
    }
    var plan = ChunkPolicy.plan("nhl", dates[0], dates[dates.length - 1])
    if (plan.kind !== "plan" || plan.requestCount > ChunkPolicy.MAX_REQUESTS) {
      root.setState("unavailable", [], "configuration", false)
      return false
    }
    root.planWindows = plan.windows
    root.planIndex = 0
    root.activeDays = CalendarCachePolicy.createWindow("nhl", dates[0], dates[dates.length - 1], nowMs).days
    root.setState("loading", root.activeDays, "", false)
    root.startNext()
    return true
  }

  function requestBackground() {
    if (!root.calendarEnabled || !root.calendarCacheReady || root.ownerDestroyed
        || calendarProcess.running || root.queuedMonthKey) return false
    var today = DateModel.localDateKey(new Date())
    var plan = ChunkPolicy.planRolling("nhl", today)
    if (plan.kind !== "plan" || plan.requestCount > ChunkPolicy.MAX_REQUESTS) return false
    root.cancel()
    root.planKind = "background"
    var index = root.backgroundIndex % plan.windows.length
    root.planWindows = [plan.windows[index]]
    root.planIndex = 0
    root.activeDays = []
    root.startNext()
    return true
  }

  function startNext() {
    if (root.ownerDestroyed || root.planIndex >= root.planWindows.length) {
      if (root.planKind === "background") {
        root.backgroundIndex = (root.backgroundIndex + 1) % 5
        root.planKind = ""
        root.activeDays = []
        return
      }
      var complete = root.activeDays.every(function(day) { return day.complete === true })
      var entry = {providerId: "nhl", startDate: root.planWindows.length
        ? root.planWindows[0].startDate : "", endDate: root.planWindows.length
        ? root.planWindows[root.planWindows.length - 1].endDate : "",
        status: complete ? "complete" : "partial", stale: false,
        updatedAtMs: Date.now(), days: root.activeDays}
      root.remember(entry)
      root.publishEntry(entry)
      return
    }
    var window = root.planWindows[root.planIndex]
    root.pendingBody = ""
    root.bodyReceived = false
    root.responseTooLarge = false
    calendarProcess.requestGeneration = root.activeGeneration
    calendarProcess.command = ["curl", "-fsSL", "--max-time", "10",
      "--max-filesize", String(ResponsePolicy.MAX_RESPONSE_BYTES),
      NhlProvider.buildNextGamesUrl(window.startDate)]
    calendarProcess.running = true
  }

  function appendChunk(value) {
    if (root.responseTooLarge) return
    var chunk = String(value || "")
    if (!ResponsePolicy.canAppend(root.pendingBody, chunk)) {
      root.responseTooLarge = true
      if (calendarProcess.running) calendarProcess.signal(9)
      return
    }
    root.pendingBody += chunk
    root.bodyReceived = root.pendingBody !== ""
  }

  function applyResponse(window, payload) {
    var parsed = null
    try { parsed = NhlProvider.parseCalendarScheduleResponse(payload) } catch (error) { parsed = null }
    var next = CalendarCachePolicy.applyChunk(
      CalendarCachePolicy.createWindow("nhl", window.startDate, window.endDate, Date.now()),
      window.startDate, window.endDate, parsed, Date.now())
    root.activeDays = CalendarCachePolicy.mergeState({leagueId: "nhl", days: root.activeDays}, next).days
    root.planIndex++
    root.setState("loading", root.activeDays, "", false)
    root.startNext()
  }

  function applyBackgroundResponse(window, payload) {
    var parsed = null
    try { parsed = NhlProvider.parseCalendarScheduleResponse(payload) } catch (error) { parsed = null }
    var next = CalendarCachePolicy.applyChunk(
      CalendarCachePolicy.createWindow("nhl", window.startDate, window.endDate, Date.now()),
      window.startDate, window.endDate, parsed, Date.now())
    root.activeWindowKey = root.backgroundWindowKey(window)
    root.remember(next)
    root.publishBackground(next.days)
    root.planIndex++
    root.startNext()
  }

  Component.onDestruction: {
    root.ownerDestroyed = true
    root.cancel()
    if (calendarProcess.running) calendarProcess.running = false
  }

  Process {
    id: calendarProcess
    running: false
    property int requestGeneration: 0

    stdout: SplitParser {
      splitMarker: ""
      onRead: function(data) {
        if (calendarProcess.requestGeneration !== root.activeGeneration
            || root.stoppingRequest || root.ownerDestroyed) return
        root.appendChunk(data)
      }
    }

    onExited: function(exitCode, exitStatus) {
      var matches = calendarProcess.requestGeneration === root.activeGeneration
      var stopped = root.stoppingRequest || !matches
      root.stoppingRequest = false
      var window = root.planWindows[root.planIndex]
      var body = root.pendingBody.trim()
      root.pendingBody = ""
      root.bodyReceived = false
      var payload = null
      if (!root.responseTooLarge && body !== "") {
        try { payload = JSON.parse(body) } catch (error) { payload = null }
      }
      root.responseTooLarge = false
      if (root.ownerDestroyed || !root.calendarEnabled || !window) return
      if (stopped) {
        var queued = root.queuedMonthKey
        root.queuedMonthKey = ""
        if (queued) root.requestMonth(queued)
        return
      }
      if (exitCode !== 0 || !payload) {
        if (root.planKind === "background") {
          root.planIndex = root.planWindows.length
          root.startNext()
          return
        }
        root.planIndex = root.planWindows.length
        var stale = root.windows[root.activeWindowKey]
        if (stale) {
          stale.stale = true
          root.publishEntry(stale)
        } else root.setState("unavailable", root.activeDays, "unavailable", false)
        return
      }
      if (root.planKind === "background") root.applyBackgroundResponse(window, payload)
      else root.applyResponse(window, payload)
    }
  }

  Timer {
    id: backgroundTimer
    interval: ChunkPolicy.ROLLING_INTERVAL_MS
    repeat: true
    running: root.calendarEnabled && root.calendarCacheReady && !root.ownerDestroyed
    onTriggered: root.requestBackground()
  }
}

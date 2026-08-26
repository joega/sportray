import QtQuick
import Quickshell.Io
import "../providers/NhlProvider.js" as NhlProvider
import "../providers/EspnProvider.js" as EspnProvider
import "../providers/LeagueCatalog.js" as LeagueCatalog
import "../model/CalendarModel.js" as CalendarModel
import "../model/CalendarCachePolicy.js" as CalendarCachePolicy
import "../model/ChunkPolicy.js" as ChunkPolicy
import "../model/DateModel.js" as DateModel
import "../model/ResponsePolicy.js" as ResponsePolicy

Item {
  id: root

  property bool calendarEnabled: false
  property var enabledLeagues: ["nhl"]
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
  property var scheduleStates: ({})
  property string activeLeagueId: ""

  function providerIdFor(leagueId) {
    if (leagueId === "nhl") return "nhl"
    if (leagueId === "nfl") return "espn-nfl"
    if (leagueId === "nba") return "espn-nba"
    if (leagueId === "eng.1") return "espn-epl"
    if (leagueId === "usa.1") return "espn-mls"
    return ""
  }

  function windowKey(leagueId, monthKey) { return leagueId + ":" + monthKey }
  function backgroundWindowKey(window) {
    return "nhl:rolling:" + window.startDate + ":" + window.endDate
  }

  function snapshot() { return root.currentState }
  function snapshotFor(leagueId) {
    return root.scheduleStates[leagueId] || {
      leagueId: leagueId || "", displayName: "", days: [], status: "unknown",
      loading: false, stale: false, errorCode: ""
    }
  }

  function publishBackground(days) {
    var merged = CalendarCachePolicy.mergeState(root.snapshotFor("nhl"), {
      leagueId: "nhl", displayName: "NHL", days: days || []
    })
    root.backgroundDays = merged.days
    root.setStateFor("nhl", root.snapshotFor("nhl").status || "unknown", merged.days,
      root.snapshotFor("nhl").errorCode || "", root.snapshotFor("nhl").stale === true)
  }

  function setStateFor(leagueId, status, days, errorCode, stale) {
    var nextStates = {}
    for (var key in root.scheduleStates) nextStates[key] = root.scheduleStates[key]
    var league = LeagueCatalog.getLeague(leagueId)
    nextStates[leagueId] = {
      leagueId: leagueId, displayName: league ? league.displayName : leagueId,
      days: Array.isArray(days) ? days : [], status: status || "unknown",
      loading: status === "loading", stale: stale === true, errorCode: errorCode || ""
    }
    root.scheduleStates = nextStates
    if (leagueId === root.activeLeagueId || root.activeLeagueId === "") root.currentState = nextStates[leagueId]
  }

  function setState(status, days, errorCode, stale) {
    root.setStateFor(root.activeLeagueId || "nhl", status, days, errorCode, stale)
  }

  function eligibleLeagues() {
    var result = []
    var ids = Array.isArray(root.enabledLeagues) ? root.enabledLeagues : []
    ids.forEach(function(value) {
      var id = String(value || "").toLowerCase()
      if (root.providerIdFor(id) && result.indexOf(id) === -1) result.push(id)
    })
    return result
  }

  function finishActiveLeague() {
    if (!root.activeLeagueId || !root.planWindows.length) return
    var first = root.planWindows.filter(function(item) { return item.leagueId === root.activeLeagueId })[0]
    if (!first) return
    var complete = root.activeDays.every(function(day) { return day.complete === true })
    var entry = {providerId: first.providerId, startDate: first.monthStart,
      endDate: first.monthEnd, status: complete ? "complete" : "partial", stale: false,
      updatedAtMs: Date.now(), days: root.activeDays}
    root.rememberFor(root.windowKey(root.activeLeagueId, first.monthKey), entry)
    root.setStateFor(root.activeLeagueId, entry.status, entry.days, "", false)
  }

  function rememberFor(key, entry) {
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
    root.activeLeagueId = ""
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
    if (!root.calendarEnabled) {
      root.cancel()
    } else if (root.requestedMonthKey && root.planKind === "") {
      // Settings can finish loading after the panel asks for its first
      // calendar month. Retry that bounded request once the owner becomes
      // eligible instead of waiting for a day click to start score polling.
      Qt.callLater(function() { root.requestMonth(root.requestedMonthKey) })
    }
  }

  onCalendarCacheReadyChanged: {
    if (!root.calendarCacheReady && root.planKind === "background") root.cancel()
  }

  function requestMonth(monthKey) {
    var requested = DateModel.monthKey(monthKey)
    if (!requested) return false
    root.requestedMonthKey = requested
    if (!root.calendarEnabled || root.ownerDestroyed) return false
    if (calendarProcess.running) {
      root.queuedMonthKey = requested
      root.cancel()
      return false
    }
    root.queuedMonthKey = ""
    root.cancel()
    root.planKind = "month"
    var nowMs = Date.now()
    var dates = CalendarModel.monthDateKeys(requested)
    if (!dates || dates.length !== 42) {
      root.setState("unavailable", [], "configuration", false)
      return false
    }
    root.planWindows = []
    root.eligibleLeagues().forEach(function(leagueId) {
      var key = root.windowKey(leagueId, requested)
      var hit = root.cached(key, nowMs)
      if (hit) {
        root.setStateFor(leagueId, hit.status, hit.days,
          hit.status === "unavailable" ? "unavailable" : "", hit.stale === true)
        return
      }
      var plan = ChunkPolicy.plan(root.providerIdFor(leagueId), dates[0], dates[dates.length - 1])
      if (plan.kind !== "plan" || plan.requestCount > ChunkPolicy.MAX_REQUESTS) return
      plan.windows.forEach(function(window) {
        root.planWindows.push({leagueId: leagueId, providerId: root.providerIdFor(leagueId),
          monthKey: requested, monthStart: dates[0], monthEnd: dates[dates.length - 1],
          startDate: window.startDate, endDate: window.endDate, spanDays: window.spanDays})
      })
    })
    if (root.planWindows.length === 0) return false
    root.planIndex = 0
    root.activeLeagueId = ""
    root.startNext()
    return true
  }

  function requestBackground() {
    if (!root.calendarEnabled || !root.calendarCacheReady || root.ownerDestroyed
        || calendarProcess.running || root.queuedMonthKey
        || root.eligibleLeagues().indexOf("nhl") === -1) return false
    var today = DateModel.localDateKey(new Date())
    var plan = ChunkPolicy.planRolling("nhl", today)
    if (plan.kind !== "plan" || plan.requestCount > ChunkPolicy.MAX_REQUESTS) return false
    root.cancel()
    root.planKind = "background"
    var index = root.backgroundIndex % plan.windows.length
    root.planWindows = [plan.windows[index]]
    root.planWindows[0].leagueId = "nhl"
    root.planWindows[0].providerId = "nhl"
    root.planWindows[0].monthKey = DateModel.monthKey(today)
    root.planWindows[0].monthStart = plan.windows[index].startDate
    root.planWindows[0].monthEnd = plan.windows[index].endDate
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
      root.finishActiveLeague()
      root.planKind = ""
      return
    }
    var window = root.planWindows[root.planIndex]
    if (window.leagueId !== root.activeLeagueId) {
      root.finishActiveLeague()
      root.activeLeagueId = window.leagueId
      root.activeWindowKey = root.windowKey(window.leagueId, window.monthKey)
      root.activeDays = CalendarCachePolicy.createWindow(window.providerId,
        window.monthStart, window.monthEnd, Date.now()).days
      root.setStateFor(window.leagueId, "loading", root.activeDays, "", false)
    }
    root.pendingBody = ""
    root.bodyReceived = false
    root.responseTooLarge = false
    calendarProcess.requestGeneration = root.activeGeneration
    var url = window.providerId === "nhl" ? NhlProvider.buildNextGamesUrl(window.startDate)
      : EspnProvider.buildNextGamesUrl(window.leagueId, window.startDate, window.endDate)
    calendarProcess.command = ["curl", "-fsSL", "--max-time", "10",
      "--max-filesize", String(ResponsePolicy.MAX_RESPONSE_BYTES),
      url]
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
    try {
      parsed = window.providerId === "nhl"
        ? NhlProvider.parseCalendarScheduleResponse(payload)
        : EspnProvider.parseCalendarRangeResponse(payload, window.leagueId,
          window.startDate, window.endDate)
    } catch (error) { parsed = null }
    var next = CalendarCachePolicy.applyChunk(
      CalendarCachePolicy.createWindow(window.providerId, window.startDate, window.endDate, Date.now()),
      window.startDate, window.endDate, parsed, Date.now())
    root.activeDays = CalendarCachePolicy.mergeState({leagueId: window.leagueId, days: root.activeDays}, next).days
    root.planIndex++
    root.setStateFor(window.leagueId, "loading", root.activeDays, "", false)
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

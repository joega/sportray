import QtQuick
import Quickshell.Io
import "../providers/NhlProvider.js" as NhlProvider
import "../providers/EspnProvider.js" as EspnProvider
import "../model/FreshnessPolicy.js" as FreshnessPolicy
import "../model/DateModel.js" as DateModel
import "../model/DateCachePolicy.js" as DateCachePolicy
import "../model/NextEventModel.js" as NextEventModel
import "../model/LookaheadPolicy.js" as LookaheadPolicy
import "../model/PollPolicy.js" as PollPolicy
import "../model/ResponsePolicy.js" as ResponsePolicy

Item {
  id: root

  signal retryRequested(int delayMs)

  required property string leagueId
  required property string displayName
  property string dateKey: ""
  property bool leagueEnabled: false
  property var favoriteTeamIds: []
  property bool panelOpen: false
  property real jitterUnit: 0
  property var games: []
  property var lastKnownGames: []
  property bool hasData: false
  property bool loading: false
  property bool stale: false
  property string errorCode: ""
  property string errorSummary: ""
  property int partialErrorCount: 0
  property string lastSuccessAt: ""
  property string lastAttemptAt: ""
  property bool lookaheadEnabled: false
  property var nextGame: null
  property string nextGameDateKey: ""
  property string nextGameStatus: "idle"

  property var pendingResult: null
  property string pendingResponseBody: ""
  property bool responseTooLarge: false
  property bool streamFinished: false
  property bool bodyReceived: false
  property bool refreshQueued: false
  property string queuedRefreshReason: ""
  property bool stoppingRequest: false
  property bool ownerDestroyed: false
  property int requestGeneration: 0
  property int activeRequestGeneration: 0
  property bool initialized: false
  property var pendingLookaheadResult: null
  property string pendingLookaheadBody: ""
  property bool lookaheadResponseTooLarge: false
  property bool lookaheadStreamFinished: false
  property bool lookaheadBodyReceived: false
  property bool stoppingLookahead: false
  property int lookaheadGeneration: 0
  property int activeLookaheadGeneration: 0
  property int lookaheadHopCount: 0
  property string lookaheadRequestDateKey: ""
  property string requestDateKey: ""
  property string snapshotDateKey: ""
  property double lastSuccessMs: 0
  property double nextEligibleAtMs: 0
  property int consecutiveFailures: 0
  property double retryNotBeforeMs: 0
  property var dateCache: ({})
  property var dateCacheOrder: []
  property var lookaheadCache: ({})
  property var lookaheadCacheOrder: []
  readonly property int dateCacheLimit: 5

  function buildUrl() {
    if (root.leagueId === "nhl") return NhlProvider.buildScoreUrl(root.dateKey)
    return EspnProvider.buildScoreUrl(root.leagueId, root.dateKey.replace(/-/g, ""))
  }

  function currentCadence(nowMs) {
    var current = typeof nowMs === "number" ? nowMs : Date.now()
    return PollPolicy.selectCadence(root.games, root.favoriteTeamIds,
      root.panelOpen, current, PollPolicy.seedForGames(root.games), root.dateKey,
      DateModel.localDateKey(new Date(current)))
  }

  function scheduleNextEligible(nowMs) {
    var current = typeof nowMs === "number" ? nowMs : Date.now()
    root.nextEligibleAtMs = current + PollPolicy.spreadIntervalMs(
      root.currentCadence(current).intervalMs, root.jitterUnit)
  }

  function requestDue(reason, nowMs) {
    var current = typeof nowMs === "number" ? nowMs : Date.now()
    return PollPolicy.isRequestDue({
      hasData: root.hasData,
      lastSuccessMs: root.lastSuccessMs,
      nextEligibleAtMs: root.nextEligibleAtMs,
      consecutiveFailures: root.consecutiveFailures,
      retryNotBeforeMs: root.retryNotBeforeMs,
      games: root.games,
      favoriteTeamIds: root.favoriteTeamIds,
      panelOpen: root.panelOpen,
      selectedDateKey: root.dateKey,
      todayDateKey: DateModel.localDateKey(new Date(current)),
      jitterUnit: root.jitterUnit
    }, reason, current)
  }

  function storeDateCache(dateKey) {
    if (!DateModel.isDateKey(dateKey) || !root.hasData || !Array.isArray(root.games)) return
    var cache = {}
    for (var key in root.dateCache) cache[key] = root.dateCache[key]
    cache[dateKey] = {
      games: root.games.slice(),
      lastSuccessAt: root.lastSuccessAt,
      lastSuccessMs: root.lastSuccessMs,
      nextEligibleAtMs: root.nextEligibleAtMs
    }

    var order = root.dateCacheOrder.filter(function(value) { return value !== dateKey })
    order.push(dateKey)
    while (order.length > root.dateCacheLimit) {
      var evicted = order.shift()
      delete cache[evicted]
    }
    root.dateCache = cache
    root.dateCacheOrder = order
  }

  function restoreDateCache(dateKey) {
    var entry = root.dateCache[dateKey]
    if (!entry || !Array.isArray(entry.games)) return false
    root.games = entry.games.slice()
    root.lastKnownGames = entry.games.slice()
    root.hasData = true
    root.stale = false
    root.errorCode = ""
    root.errorSummary = ""
    root.partialErrorCount = 0
    root.lastSuccessAt = entry.lastSuccessAt || ""
    root.lastSuccessMs = Number(entry.lastSuccessMs) || Date.parse(root.lastSuccessAt) || 0
    root.nextEligibleAtMs = Number(entry.nextEligibleAtMs) || 0
    root.consecutiveFailures = 0
    root.retryNotBeforeMs = 0
    return true
  }

  function clearSnapshot() {
    root.resetLookahead()
    root.pendingResult = null
    root.streamFinished = false
    root.bodyReceived = false
    root.lastKnownGames = []
    root.games = []
    root.hasData = false
    root.loading = false
    root.stale = false
    root.errorCode = ""
    root.errorSummary = ""
    root.partialErrorCount = 0
    root.lastSuccessAt = ""
    root.lastAttemptAt = ""
    root.lastSuccessMs = 0
    root.nextEligibleAtMs = 0
    root.consecutiveFailures = 0
    root.retryNotBeforeMs = 0
  }

  function resetLookahead() {
    root.activeLookaheadGeneration++
    if (lookaheadProcess.running) {
      root.stoppingLookahead = true
      lookaheadProcess.running = false
    }
    root.pendingLookaheadResult = null
    root.pendingLookaheadBody = ""
    root.lookaheadResponseTooLarge = false
    root.lookaheadStreamFinished = false
    root.lookaheadBodyReceived = false
    root.lookaheadHopCount = 0
    root.lookaheadRequestDateKey = ""
    root.nextGame = null
    root.nextGameDateKey = ""
    root.nextGameStatus = "idle"
    root.stoppingLookahead = false
  }

  function storeLookaheadCache(status, game, gameDateKey, intervalMs) {
    if (!DateModel.isDateKey(root.dateKey)) return
    var cache = {}
    for (var key in root.lookaheadCache) cache[key] = root.lookaheadCache[key]
    cache[root.dateKey] = {
      status: status,
      game: game || null,
      gameDateKey: gameDateKey || "",
      expiresAtMs: Date.now() + PollPolicy.spreadIntervalMs(intervalMs, root.jitterUnit)
    }
    var order = root.lookaheadCacheOrder.filter(function(value) { return value !== root.dateKey })
    order.push(root.dateKey)
    while (order.length > root.dateCacheLimit) {
      var evicted = order.shift()
      delete cache[evicted]
    }
    root.lookaheadCache = cache
    root.lookaheadCacheOrder = order
  }

  function restoreLookaheadCache() {
    var entry = root.lookaheadCache[root.dateKey]
    if (!entry || Number(entry.expiresAtMs) <= Date.now()) return false
    root.nextGame = entry.game || null
    root.nextGameDateKey = entry.gameDateKey || ""
    root.nextGameStatus = entry.status || "unavailable"
    return true
  }

  function finishLookahead(status, cacheIntervalMs) {
    root.nextGame = null
    root.nextGameDateKey = ""
    root.nextGameStatus = status || "unavailable"
    if (cacheIntervalMs > 0)
      root.storeLookaheadCache(root.nextGameStatus, null, "", cacheIntervalMs)
  }

  function lookaheadUrl(dateKey) {
    if (root.leagueId === "nhl") return NhlProvider.buildNextGamesUrl(dateKey)
    return EspnProvider.buildNextGamesUrl(root.leagueId, dateKey,
      DateModel.addDays(root.dateKey, NextEventModel.MAX_LOOKAHEAD_DAYS))
  }

  function startLookahead(dateKey) {
    if (!root.lookaheadEnabled || !root.leagueEnabled || root.ownerDestroyed
        || root.loading || root.errorCode !== "" || root.games.length > 0) return false
    if (!DateModel.isDateKey(dateKey)
        || DateModel.calendarDistance(dateKey, root.dateKey) > NextEventModel.MAX_LOOKAHEAD_DAYS) {
      root.finishLookahead("unavailable")
      return false
    }
    if (root.lookaheadHopCount >= LookaheadPolicy.MAX_HOPS) {
      root.finishLookahead("unavailable", PollPolicy.EMPTY_INTERVAL_MS)
      return false
    }
    if (lookaheadProcess.running) return false

    var url = root.lookaheadUrl(dateKey)
    if (!url) {
      root.finishLookahead("unavailable")
      return false
    }

    root.lookaheadGeneration++
    root.activeLookaheadGeneration = root.lookaheadGeneration
    root.lookaheadRequestDateKey = dateKey
    root.lookaheadStreamFinished = false
    root.lookaheadBodyReceived = false
    root.pendingLookaheadResult = null
    root.pendingLookaheadBody = ""
    root.lookaheadResponseTooLarge = false
    root.lookaheadHopCount++
    root.nextGameStatus = "loading"
    lookaheadProcess.requestGeneration = root.activeLookaheadGeneration
    lookaheadProcess.command = ["curl", "-fsSL", "--max-time", "10",
      "--max-filesize", String(ResponsePolicy.MAX_RESPONSE_BYTES), url]
    lookaheadProcess.running = true
    return true
  }

  function syncLookahead() {
    if (!root.lookaheadEnabled || !root.leagueEnabled) return
    if (root.loading || root.errorCode !== "" || root.games.length > 0) {
      root.resetLookahead()
      return
    }
    if (root.nextGameStatus === "idle" && !root.restoreLookaheadCache())
      root.startLookahead(DateModel.addDays(root.dateKey, 1))
  }

  function parseLookaheadBody(raw) {
    if (!raw || !ResponsePolicy.bodyWithinLimit(raw)) return null
    try {
      var payload = JSON.parse(raw)
      if (root.leagueId === "nhl") return NhlProvider.parseScheduleResponse(payload)
      return EspnProvider.parseNextGamesResponse(payload, root.leagueId)
    } catch (error) {
      return null
    }
  }

  function applyLookaheadResult(result) {
    if (!result || !Array.isArray(result.games)) {
      root.finishLookahead("unavailable", PollPolicy.RETRY_MAX_INTERVAL_MS)
      return
    }

    var next = NextEventModel.findNext(result.games, root.dateKey)
    if (next) {
      root.nextGame = next.game
      root.nextGameDateKey = next.dateKey
      root.nextGameStatus = "ready"
      var nowMs = Date.now()
      var cadence = PollPolicy.selectCadence([next.game], root.favoriteTeamIds,
        false, nowMs, 0, next.dateKey, DateModel.localDateKey(new Date(nowMs)))
      root.storeLookaheadCache("ready", next.game, next.dateKey, cadence.intervalMs)
      return
    }

    var nextDate = typeof result.nextDateKey === "string" ? result.nextDateKey : ""
    var decision = LookaheadPolicy.decideNextDate(root.dateKey,
      root.lookaheadRequestDateKey, nextDate, root.lookaheadHopCount)
    if (decision.kind === "request") {
      root.startLookahead(decision.dateKey)
      return
    }
    root.finishLookahead("unavailable", PollPolicy.EMPTY_INTERVAL_MS)
  }

  function handleDateChanged() {
    if (!root.initialized) return
    root.snapshotDateKey = root.dateKey
    root.refreshQueued = root.leagueEnabled
    root.queuedRefreshReason = root.leagueEnabled ? "date-changed" : ""
    root.activeRequestGeneration++
    if (requestProcess.running) {
      root.stoppingRequest = true
      requestProcess.running = false
    }
    root.clearSnapshot()
    if (!root.leagueEnabled) return
    root.restoreDateCache(root.dateKey)
    if (!requestProcess.running) root.finishQueuedRefresh()
  }

  function parseBody(raw) {
    if (!raw || !ResponsePolicy.bodyWithinLimit(raw)) return null
    try {
      var payload = JSON.parse(raw)
      if (root.leagueId === "nhl") return NhlProvider.parseScoreResponse(payload)
      return EspnProvider.parseScoreboardResponse(payload, root.leagueId)
    } catch (error) {
      return null
    }
  }

  function finishQueuedRefresh() {
    if (root.ownerDestroyed || !root.leagueEnabled || !root.refreshQueued) {
      root.refreshQueued = false
      root.queuedRefreshReason = ""
      return false
    }

    var reason = root.queuedRefreshReason || "queued"
    root.refreshQueued = false
    root.queuedRefreshReason = ""
    return root.refresh(reason)
  }

  function refresh(reason) {
    if (root.ownerDestroyed || !root.leagueEnabled) return false
    if (root.stoppingRequest || requestProcess.running) {
      root.refreshQueued = true
      root.queuedRefreshReason = reason || "queued"
      console.debug("Sportray league fetch", root.leagueId,
        "queued", root.queuedRefreshReason)
      return false
    }

    var refreshReason = reason || "refresh"
    if (!root.requestDue(refreshReason, Date.now())) {
      console.debug("Sportray league fetch", root.leagueId,
        "cache-hit", refreshReason, root.dateKey)
      return false
    }

    root.lastAttemptAt = new Date().toISOString()
    root.requestGeneration++
    root.activeRequestGeneration = root.requestGeneration
    root.requestDateKey = root.dateKey

    var url = root.buildUrl()
    if (!url) {
      root.fail("configuration")
      return false
    }

    root.loading = true
    root.errorCode = ""
    root.errorSummary = ""
    root.partialErrorCount = 0
    root.pendingResult = null
    root.pendingResponseBody = ""
    root.responseTooLarge = false
    root.streamFinished = false
    root.bodyReceived = false
    root.stoppingRequest = false
    // The NHL endpoint redirects to a dated slate. -L is harmless for ESPN
    // and keeps redirect handling inside this transport boundary.
    requestProcess.command = ["curl", "-fsSL", "--max-time", "10",
      "--max-filesize", String(ResponsePolicy.MAX_RESPONSE_BYTES), url]
    requestProcess.requestGeneration = root.activeRequestGeneration
    requestProcess.running = true
    console.debug("Sportray league fetch", root.leagueId,
      "started", refreshReason, root.activeRequestGeneration)
    return true
  }

  function fail(code) {
    root.loading = false
    root.errorCode = code || "unavailable"
    root.errorSummary = FreshnessPolicy.userSafeError(root.errorCode)
    root.partialErrorCount = 0
    root.stale = root.hasData
    root.scheduleFailureRetry()
    console.warn("Sportray league fetch", root.leagueId, root.errorCode)
  }

  function scheduleFailureRetry() {
    root.consecutiveFailures++
    var delayMs = PollPolicy.spreadIntervalMs(
      PollPolicy.retryDelayMs(root.consecutiveFailures), root.jitterUnit)
    root.retryNotBeforeMs = Date.now() + delayMs
    root.retryRequested(delayMs)
  }

  function applyResult(result) {
    if (!result || !Array.isArray(result.games) || !Array.isArray(result.errors)) {
      root.fail("invalid-data")
      return
    }

    if (result.errors.length > 0) {
      if (result.games.length === 0) {
        root.fail("invalid-data")
        return
      }

      // A partial response is not a new last-good snapshot. Keep the prior
      // league data when available; only a first response may seed the view
      // with its usable subset.
      if (!root.hasData) {
        root.games = result.games
        root.lastKnownGames = result.games.slice()
        root.hasData = true
      }
      root.stale = root.hasData
      root.errorCode = "partial-data"
      root.errorSummary = FreshnessPolicy.userSafeError(root.errorCode)
      root.partialErrorCount = result.errors.length
      root.loading = false
      root.scheduleFailureRetry()
      console.warn("Sportray league fetch", root.leagueId,
        "partial-data", result.errors.length)
      return
    }

    root.games = result.games
    root.lastKnownGames = result.games.slice()
    root.hasData = true
    root.stale = false
    root.errorCode = ""
    root.errorSummary = ""
    root.partialErrorCount = 0
    root.lastSuccessAt = new Date().toISOString()
    root.lastSuccessMs = Date.parse(root.lastSuccessAt)
    root.consecutiveFailures = 0
    root.retryNotBeforeMs = 0
    root.scheduleNextEligible(root.lastSuccessMs)
    root.storeDateCache(root.requestDateKey || root.dateKey)
    root.loading = false
  }

  function appendRequestChunk(chunk) {
    if (root.responseTooLarge) return
    var value = String(chunk || "")
    if (!ResponsePolicy.canAppend(root.pendingResponseBody, value)) {
      root.responseTooLarge = true
      if (requestProcess.running) requestProcess.signal(9)
      return
    }
    root.pendingResponseBody += value
    root.bodyReceived = root.pendingResponseBody !== ""
    root.streamFinished = root.bodyReceived
  }

  function appendLookaheadChunk(chunk) {
    if (root.lookaheadResponseTooLarge) return
    var value = String(chunk || "")
    if (!ResponsePolicy.canAppend(root.pendingLookaheadBody, value)) {
      root.lookaheadResponseTooLarge = true
      if (lookaheadProcess.running) lookaheadProcess.signal(9)
      return
    }
    root.pendingLookaheadBody += value
    root.lookaheadBodyReceived = root.pendingLookaheadBody !== ""
    root.lookaheadStreamFinished = root.lookaheadBodyReceived
  }

  function handleEnabledChanged() {
    if (root.leagueEnabled) {
      if (root.stoppingRequest || requestProcess.running) {
        root.refreshQueued = true
        root.queuedRefreshReason = "enabled-league-changed"
        return
      }
      if (DateCachePolicy.canRestoreLastKnown(root.snapshotDateKey, root.dateKey,
          root.lastKnownGames, root.games)) {
        root.games = root.lastKnownGames.slice()
        root.hasData = true
        root.stale = true
      }
      if (!root.hasData) root.restoreDateCache(root.dateKey)
      root.syncLookahead()
      return
    }

    root.refreshQueued = false
    root.queuedRefreshReason = ""
    root.activeRequestGeneration++
    if (requestProcess.running) {
      root.stoppingRequest = true
      requestProcess.running = false
    }
    root.pendingResult = null
    root.pendingResponseBody = ""
    root.responseTooLarge = false
    root.streamFinished = false
    root.bodyReceived = false
    root.games = []
    root.hasData = false
    root.loading = false
    root.stale = false
    root.errorCode = ""
    root.errorSummary = ""
    root.partialErrorCount = 0
    root.resetLookahead()
  }

  function effectiveStale() {
    if (!root.hasData) return false
    if (root.stale) return true
    return root.nextEligibleAtMs > 0
      && Date.now() > root.nextEligibleAtMs + FreshnessPolicy.MIN_STALE_THRESHOLD_MS
  }

  function snapshot() {
    return {
      leagueId: root.leagueId,
      displayName: root.displayName,
      games: root.leagueEnabled ? root.games : [],
      hasData: root.leagueEnabled && root.hasData,
      loading: root.leagueEnabled && root.loading,
      stale: root.leagueEnabled && root.effectiveStale(),
      errorCode: root.leagueEnabled ? root.errorCode : "",
      errorSummary: root.leagueEnabled ? root.errorSummary : "",
      partialErrorCount: root.leagueEnabled ? root.partialErrorCount : 0,
      lastSuccessAt: root.lastSuccessAt,
      lastAttemptAt: root.lastAttemptAt,
      nextGame: root.leagueEnabled ? root.nextGame : null,
      nextGameDateKey: root.leagueEnabled ? root.nextGameDateKey : "",
      nextGameStatus: root.leagueEnabled ? root.nextGameStatus : "idle",
      staleThresholdMs: Math.max(FreshnessPolicy.MIN_STALE_THRESHOLD_MS,
        root.nextEligibleAtMs - root.lastSuccessMs + FreshnessPolicy.MIN_STALE_THRESHOLD_MS)
    }
  }

  // Calendar projection source. Reads the already-fetched bounded date cache
  // only; it never starts a request, and admission/filtering stays in
  // model/CalendarModel.js.
  function calendarSnapshot() {
    var days = []
    for (var i = 0; i < root.dateCacheOrder.length; i++) {
      var dateKey = root.dateCacheOrder[i]
      var entry = root.dateCache[dateKey]
      if (!entry || !Array.isArray(entry.games)) continue
      days.push({dateKey: dateKey, games: entry.games.slice()})
    }
    return {leagueId: root.leagueId, displayName: root.displayName, days: days}
  }

  onLeagueEnabledChanged: root.handleEnabledChanged()

  onDateKeyChanged: root.handleDateChanged()

  onLookaheadEnabledChanged: {
    if (!root.lookaheadEnabled) root.resetLookahead()
    else root.syncLookahead()
  }

  Component.onCompleted: {
    root.snapshotDateKey = root.dateKey
    root.restoreDateCache(root.dateKey)
    root.initialized = true
  }

  Component.onDestruction: {
    root.ownerDestroyed = true
    root.refreshQueued = false
    root.queuedRefreshReason = ""
    root.activeRequestGeneration++
    root.resetLookahead()
    if (requestProcess.running) requestProcess.running = false
    if (lookaheadProcess.running) lookaheadProcess.running = false
  }

  Process {
    id: requestProcess
    running: false
    property int requestGeneration: 0

    onRunningChanged: {
      if (!running) return
      requestGeneration = root.activeRequestGeneration
      console.debug("Sportray league fetch", root.leagueId,
        "process-running", requestGeneration)
    }

    stdout: SplitParser {
      splitMarker: ""
      onRead: function(data) {
        if (requestProcess.requestGeneration !== root.activeRequestGeneration
            || root.stoppingRequest || root.ownerDestroyed) return
        root.appendRequestChunk(data)
      }
    }

    onExited: function(exitCode, exitStatus) {
      var completedGeneration = requestProcess.requestGeneration
      var generationMatches = completedGeneration === root.activeRequestGeneration
      var wasStopping = root.stoppingRequest || !generationMatches
      root.stoppingRequest = false
      console.debug("Sportray league fetch", root.leagueId,
        "process-exited", exitCode, exitStatus, completedGeneration)
      var result = root.responseTooLarge ? null
        : root.parseBody(root.pendingResponseBody.trim())
      root.pendingResult = null
      if (root.ownerDestroyed || wasStopping || !root.leagueEnabled) {
        root.streamFinished = false
        root.bodyReceived = false
        root.pendingResponseBody = ""
        root.responseTooLarge = false
        root.finishQueuedRefresh()
        return
      }
      if (exitCode !== 0 || !root.streamFinished || !result) {
        root.fail(exitCode === 28 ? "timeout"
          : root.bodyReceived ? "invalid-data" : "unavailable")
        root.streamFinished = false
        root.bodyReceived = false
        root.pendingResponseBody = ""
        root.responseTooLarge = false
        root.finishQueuedRefresh()
        return
      }
      root.streamFinished = false
      root.bodyReceived = false
      root.pendingResponseBody = ""
      root.responseTooLarge = false
      root.applyResult(result)
      root.syncLookahead()
      root.finishQueuedRefresh()
    }
  }

  Process {
    id: lookaheadProcess
    running: false
    property int requestGeneration: 0

    stdout: SplitParser {
      splitMarker: ""
      onRead: function(data) {
        if (lookaheadProcess.requestGeneration !== root.activeLookaheadGeneration
            || root.stoppingLookahead || root.ownerDestroyed) return
        root.appendLookaheadChunk(data)
      }
    }

    onExited: function(exitCode, exitStatus) {
      var completedGeneration = lookaheadProcess.requestGeneration
      var generationMatches = completedGeneration === root.activeLookaheadGeneration
      var wasStopping = root.stoppingLookahead || !generationMatches
      root.stoppingLookahead = false
      var result = root.lookaheadResponseTooLarge ? null
        : root.parseLookaheadBody(root.pendingLookaheadBody.trim())
      root.pendingLookaheadResult = null
      if (root.ownerDestroyed || wasStopping || !root.lookaheadEnabled || !root.leagueEnabled) {
        root.lookaheadStreamFinished = false
        root.lookaheadBodyReceived = false
        root.pendingLookaheadBody = ""
        root.lookaheadResponseTooLarge = false
        return
      }
      if (exitCode !== 0 || !root.lookaheadStreamFinished || !result) {
        root.finishLookahead("unavailable", PollPolicy.RETRY_MAX_INTERVAL_MS)
        root.lookaheadStreamFinished = false
        root.lookaheadBodyReceived = false
        root.pendingLookaheadBody = ""
        root.lookaheadResponseTooLarge = false
        return
      }
      root.lookaheadStreamFinished = false
      root.lookaheadBodyReceived = false
      root.pendingLookaheadBody = ""
      root.lookaheadResponseTooLarge = false
      root.applyLookaheadResult(result)
    }
  }
}

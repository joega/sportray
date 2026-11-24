import QtQuick
import Quickshell.Io
import "../providers/NhlProvider.js" as NhlProvider
import "../providers/EspnProvider.js" as EspnProvider
import "../providers/LeagueCatalog.js" as LeagueCatalog
import "../providers/MlbStatsProvider.js" as MlbStatsProvider
import "../providers/UpcomingScheduleProvider.js" as UpcomingScheduleProvider
import "../model/CalendarModel.js" as CalendarModel
import "../model/CalendarCachePolicy.js" as CalendarCachePolicy
import "../model/ChunkPolicy.js" as ChunkPolicy
import "../model/DateModel.js" as DateModel
import "../model/ResponsePolicy.js" as ResponsePolicy

Item {
  id: root

  readonly property string transportHelperPath: decodeURIComponent(
    Qt.resolvedUrl("../scripts/provider-transport-helper.py").toString().replace("file://", ""))

  property bool calendarEnabled: false
  property bool calendarFeatureEnabled: false
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
  property string queuedPlanKind: ""
  property bool calendarCacheReady: false
  property string planKind: ""
  property int planFailureCount: 0
  property var backgroundDays: []
  property int backgroundIndex: 0
  property var scheduleStates: ({})
  property string activeLeagueId: ""
  property string activeRangeStart: ""
  property var diskCache: null
  property string rehydrationStatus: "idle"
  property string rehydrationMonthKey: ""
  property int rehydrationCompleted: 0
  property int rehydrationTotal: 0
  readonly property bool rehydrating: root.planKind === "rehydration"
    || root.queuedPlanKind === "rehydration"

  // The team calendar is on-demand and shares the existing sequential
  // process. The dormant range/hydration route remains separately disabled.
  property bool upcomingEnabled: false
  property var upcomingCatalogTeams: []
  property var upstreamBusyLeagues: []
  property var upcomingState: ({owner: "", teamId: "", loading: false, hasData: false,
    partial: false, stale: false, errorSummary: "", entries: [], coverageStart: "", coverageEnd: "", lastSuccessAt: ""})
  property string upcomingOwner: ""
  property var upcomingPlan: null
  property var queuedUpcoming: null
  property var upcomingEntries: []
  property var upcomingRetainedEntries: []
  property bool upcomingPartial: false
  property int upcomingResponses: 0
  property int upcomingFailures: 0
  property string upcomingLastSuccessAt: ""
  property string upcomingProcessLeague: ""
  property var upcomingCache: ({})
  property var upcomingCacheOrder: []
  readonly property int upcomingCacheLimit: 8
  readonly property int upcomingCacheTtlMs: 15 * 60 * 1000
  readonly property var upcomingLockedLeagues: {
    var leagues = []
    if (root.upcomingProcessLeague) leagues.push(root.upcomingProcessLeague)
    if (root.planKind === "upcoming" && root.upcomingPlan
        && leagues.indexOf(root.upcomingPlan.leagueId) === -1) leagues.push(root.upcomingPlan.leagueId)
    if (root.queuedUpcoming && root.queuedUpcoming.plan
        && leagues.indexOf(root.queuedUpcoming.plan.leagueId) === -1) leagues.push(root.queuedUpcoming.plan.leagueId)
    return leagues
  }

  function upcomingKey(plan) { return plan.teamId + ":" + plan.startDate + ":" + plan.endDate }

  function mergeUpcomingEntries(previous, additions) {
    var merged = [], indices = Object.create(null)
    ;(previous || []).concat(additions || []).forEach(function(entry) {
      if (!entry || !entry.game || !entry.game.id) return
      var id = entry.game.id
      if (indices[id] !== undefined) merged[indices[id]] = entry
      else { indices[id] = merged.length; merged.push(entry) }
    })
    // Reject a union overflow; never turn a truncated schedule into success.
    return merged.length <= 256 ? merged : null
  }

  function upcomingCached(plan) {
    var hit = root.upcomingCache[root.upcomingKey(plan)]
    var age = hit ? Date.now() - hit.updatedAtMs : -1
    return hit && age >= 0 && age < hit.ttlMs ? hit.state : null
  }

  function requestUpcoming(owner, teamId, startDate, endDate, force) {
    if (!root.upcomingEnabled || root.ownerDestroyed || !owner
        || root.calendarFeatureEnabled && root.calendarEnabled) return false
    var plan = UpcomingScheduleProvider.buildPlan(teamId, startDate, endDate,
      root.upcomingCatalogTeams, MlbStatsProvider.TEAM_IDS_BY_STATS_ID)
    if (!plan || plan.kind !== "plan" || !plan.requests.length || plan.requests.length > 8) return false
    if (!force && root.planKind === "upcoming" && root.upcomingPlan
        && root.upcomingKey(plan) === root.upcomingKey(root.upcomingPlan)) {
      root.upcomingOwner = owner
      root.upcomingState = Object.assign({}, root.upcomingState, {owner: owner})
      return true
    }
    var hit = root.upcomingCached(plan)
    var saved = root.upcomingCache[root.upcomingKey(plan)]
    var retained = saved ? saved.state : null
    root.upcomingOwner = owner
    root.queuedUpcoming = null
    root.cancel()
    if (hit && !force) {
      root.upcomingState = Object.assign({}, hit, {owner: owner, loading: false})
      return true
    }
    var intent = {owner: owner, plan: plan, retained: retained ? retained.entries : []}
    root.upcomingState = {owner: owner, teamId: teamId, loading: true, hasData: Boolean(retained),
      partial: retained ? retained.partial : false, stale: Boolean(retained), errorSummary: "",
      entries: retained ? retained.entries : [], coverageStart: startDate, coverageEnd: endDate,
      lastSuccessAt: retained ? retained.lastSuccessAt : ""}
    if (root.stoppingRequest || calendarProcess.running || root.upcomingProcessLeague !== "") {
      root.queuedUpcoming = intent
      return true
    }
    root.beginUpcoming(intent)
    return true
  }

  function beginUpcoming(intent) {
    if (!intent || !root.upcomingEnabled || root.ownerDestroyed
        || intent.owner !== root.upcomingOwner) return false
    root.upcomingPlan = intent.plan
    root.upcomingEntries = []
    root.upcomingRetainedEntries = intent.retained || []
    root.upcomingResponses = 0
    root.upcomingFailures = 0
    root.upcomingPartial = false
    root.upcomingLastSuccessAt = root.upcomingState.lastSuccessAt || ""
    root.planWindows = intent.plan.requests
    root.planIndex = 0
    root.planKind = "upcoming"
    root.startUpcomingNext()
    return true
  }

  function cancelUpcoming(owner) {
    if (owner && owner !== root.upcomingOwner) return false
    root.upcomingOwner = ""
    root.queuedUpcoming = null
    if (root.planKind === "upcoming") root.cancel()
    if (root.upcomingState.loading)
      root.upcomingState = Object.assign({}, root.upcomingState, {loading: false})
    return true
  }

  function publishUpcoming(loading) {
    var plan = root.upcomingPlan
    if (!plan || !root.upcomingOwner) return
    var retained = root.upcomingRetainedEntries
    var entries = root.upcomingResponses > 0 ? root.upcomingEntries : retained
    var partial = root.upcomingPartial || root.upcomingFailures > 0
    var retaining = retained.length > 0 && (loading || partial || root.upcomingResponses === 0)
    if (retaining) {
      var union = root.mergeUpcomingEntries(retained, root.upcomingEntries)
      if (union) entries = union
      else { entries = retained; partial = true }
    }
    var message = root.upcomingFailures > 0
      ? (entries.length ? "Some schedule requests failed. Saved games are shown." : "Schedule unavailable. Try again.")
      : partial && retaining ? "Schedule is incomplete. Previously listed games are retained."
      : partial ? "Only published games are shown. More dates may be announced." : ""
    root.upcomingState = {owner: root.upcomingOwner, teamId: plan.teamId, loading: loading,
      hasData: root.upcomingResponses > 0 || entries.length > 0,
      partial: partial, stale: retaining, failed: root.upcomingFailures > 0,
      errorSummary: message, entries: entries, coverageStart: plan.startDate, coverageEnd: plan.endDate,
      coverageComplete: !loading && !partial, lastSuccessAt: root.upcomingLastSuccessAt}
  }

  function rememberUpcoming() {
    if (!root.upcomingPlan || !root.upcomingState.hasData) return
    var key = root.upcomingKey(root.upcomingPlan)
    var cache = Object.assign({}, root.upcomingCache)
    cache[key] = {updatedAtMs: Date.now(), ttlMs: root.upcomingFailures > 0 ? 30000 : root.upcomingCacheTtlMs,
      state: Object.assign({}, root.upcomingState, {loading: false})}
    var order = root.upcomingCacheOrder.filter(function(value) { return value !== key })
    order.push(key)
    while (order.length > root.upcomingCacheLimit) delete cache[order.shift()]
    root.upcomingCache = cache
    root.upcomingCacheOrder = order
  }

  function startUpcomingNext() {
    if (!root.upcomingEnabled || !root.upcomingOwner || root.ownerDestroyed
        || root.planKind !== "upcoming" || root.stoppingRequest || calendarProcess.running
        || root.upcomingProcessLeague !== "") return
    if (root.planIndex >= root.planWindows.length) {
      root.publishUpcoming(false)
      root.rememberUpcoming()
      root.planKind = ""
      return
    }
    // An already-running score/lookahead request keeps its slot. The shared
    // league lock blocks new requests until this plan (or its stop) settles.
    if (root.upstreamBusyLeagues.indexOf(root.upcomingPlan.leagueId) !== -1) return
    var request = root.planWindows[root.planIndex]
    root.pendingBody = ""
    root.bodyReceived = false
    root.responseTooLarge = false
    root.upcomingProcessLeague = root.upcomingPlan.leagueId
    calendarProcess.requestGeneration = root.activeGeneration
    calendarProcess.command = ["/usr/bin/python3", root.transportHelperPath, request.url]
    calendarProcess.running = true
  }

  function finishUpcomingResponse(exitCode, body, oversized) {
    var request = root.planWindows[root.planIndex]
    var result = null
    if (exitCode === 0 && !oversized && request) {
      try {
        result = UpcomingScheduleProvider.parseResponse(request, body, {
          parseEspn: EspnProvider.parseScoreboardResponse,
          parseNhl: NhlProvider.parseScheduleResponse,
          parseMlb: MlbStatsProvider.parseScoreResponse})
      } catch (error) { result = null }
    }
    if (!result || result.accepted !== true) root.upcomingFailures++
    else {
      var merged = root.mergeUpcomingEntries(root.upcomingEntries, result.entries)
      if (merged === null) root.upcomingFailures++
      else {
        root.upcomingEntries = merged
        root.upcomingResponses++
        root.upcomingLastSuccessAt = new Date().toISOString()
      }
      if (result.complete !== true) root.upcomingPartial = true
    }
    root.planIndex++
    root.publishUpcoming(true)
    root.startUpcomingNext()
  }

  onUpcomingEnabledChanged: if (!root.upcomingEnabled) root.cancelUpcoming()
  onUpcomingCatalogTeamsChanged: {
    if (root.upcomingOwner && !root.upcomingCatalogTeams.some(function(team) {
      return team.id === root.upcomingState.teamId
    })) root.cancelUpcoming()
  }
  onUpstreamBusyLeaguesChanged: if (root.planKind === "upcoming") root.startUpcomingNext()

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

  function leagueCovered(leagueId, dates) {
    if (!root.diskCache || root.diskCache.ready !== true
        || typeof root.diskCache.coverageFor !== "function") return false
    var coverage = root.diskCache.coverageFor([leagueId], dates)
    return coverage && coverage.needsHydration !== true
  }

  function finishActiveLeague() {
    if (!root.activeLeagueId || !root.planWindows.length) return
    var first = root.planWindows.filter(function(item) {
      return item.leagueId === root.activeLeagueId
        && item.monthStart === root.activeRangeStart
    })[0]
    if (!first) return
    var complete = root.activeDays.length > 0
      && root.activeDays.every(function(day) { return day.complete === true })
    if (root.planKind === "rehydration" && !complete) root.planFailureCount++
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
    root.activeRangeStart = ""
    root.pendingBody = ""
    root.bodyReceived = false
    root.responseTooLarge = false
    root.planKind = ""
  }

  function cancelSchedule() {
    if (root.planKind === "upcoming" || root.queuedUpcoming) return
    // Closing the view must not kill a one-time startup rehydration. It is a
    // shared cache repair owned by this service, not by the panel lifecycle.
    if (root.planKind === "rehydration") {
      if (root.queuedPlanKind === "month") {
        root.queuedMonthKey = ""
        root.queuedPlanKind = ""
      }
      return
    }
    if (root.queuedPlanKind !== "rehydration") {
      root.queuedMonthKey = ""
      root.queuedPlanKind = ""
    }
    root.cancel()
  }

  function startQueuedPlan() {
    var monthKey = root.queuedMonthKey
    var kind = root.queuedPlanKind
    root.queuedMonthKey = ""
    root.queuedPlanKind = ""
    if (!monthKey) return false
    return root.beginMonthPlan(monthKey, kind === "rehydration" ? "rehydration" : "month")
  }

  onCalendarEnabledChanged: {
    if (!root.calendarEnabled) {
      if (root.planKind !== "upcoming") root.cancel()
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
    if (!root.calendarFeatureEnabled || !root.calendarEnabled || root.ownerDestroyed) return false
    if (calendarProcess.running) {
      if (root.planKind === "rehydration") {
        // The shared repair keeps its sequential request slot. A visible
        // adjacent-month request waits behind it instead of canceling the
        // background pass that is filling the empty cache.
        if (requested === root.rehydrationMonthKey) return true
        root.queuedMonthKey = requested
        root.queuedPlanKind = "month"
        return true
      }
      root.queuedMonthKey = requested
      root.queuedPlanKind = "month"
      root.cancel()
      return false
    }
    return root.beginMonthPlan(requested, "month")
  }

  function requestRehydration(monthKey) {
    var requested = DateModel.monthKey(monthKey)
    if (!requested || !root.calendarFeatureEnabled || !root.calendarEnabled || root.ownerDestroyed)
      return false
    if (root.rehydrationStatus === "loading" && root.rehydrationMonthKey === requested)
      return true
    root.rehydrationMonthKey = requested
    root.rehydrationStatus = "loading"
    root.rehydrationCompleted = 0
    root.rehydrationTotal = 0
    if (calendarProcess.running) {
      root.queuedMonthKey = requested
      root.queuedPlanKind = "rehydration"
      if (root.planKind === "background") root.cancel()
      return true
    }
    return root.beginMonthPlan(requested, "rehydration")
  }

  function appendPlanWindows(leagueId, monthKey, startDate, endDate) {
    var providerId = root.providerIdFor(leagueId)
    var plan = ChunkPolicy.plan(providerId, startDate, endDate)
    if (plan.kind !== "plan" || plan.requestCount > ChunkPolicy.MAX_REQUESTS) return
    plan.windows.forEach(function(window) {
      root.planWindows.push({leagueId: leagueId, providerId: providerId,
        monthKey: monthKey, monthStart: startDate, monthEnd: endDate,
        startDate: window.startDate, endDate: window.endDate, spanDays: window.spanDays})
    })
  }

  function beginWindowHydration(requested) {
    var dates = root.diskCache && typeof root.diskCache.windowDateKeys === "function"
      ? root.diskCache.windowDateKeys() : []
    root.planWindows = []
    if (dates.length && root.diskCache && typeof root.diskCache.hydrationRanges === "function") {
      root.diskCache.hydrationRanges(root.eligibleLeagues(), dates, ChunkPolicy.MAX_RANGE_DAYS)
        .forEach(function(range) {
          root.appendPlanWindows(range.leagueId, requested, range.startDate, range.endDate)
        })
    }
    if (root.planWindows.length === 0) {
      root.rehydrationStatus = "complete"
      console.log("Sportray calendar rehydration complete", requested, 0)
      root.planKind = ""
      return true
    }
    root.rehydrationTotal = root.planWindows.length
    console.log("Sportray calendar rehydration started", requested, root.rehydrationTotal)
    root.planIndex = 0
    root.activeLeagueId = ""
    root.activeRangeStart = ""
    root.startNext()
    return true
  }

  function beginMonthPlan(requested, kind) {
    root.queuedMonthKey = ""
    root.queuedPlanKind = ""
    root.cancel()
    root.planKind = kind === "rehydration" ? "rehydration" : "month"
    root.planFailureCount = 0
    if (root.planKind === "rehydration") return root.beginWindowHydration(requested)
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
      if (root.leagueCovered(leagueId, dates)) return
      root.appendPlanWindows(leagueId, requested, dates[0], dates[dates.length - 1])
    })
    if (root.planWindows.length === 0) {
      root.planKind = ""
      return true
    }
    root.planIndex = 0
    root.activeLeagueId = ""
    root.activeRangeStart = ""
    root.startNext()
    return true
  }

  function requestBackground() {
    if (!root.calendarFeatureEnabled || !root.calendarEnabled || !root.calendarCacheReady
        || root.ownerDestroyed
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
      var finishedKind = root.planKind
      var failureCount = root.planFailureCount
      root.planKind = ""
      if (finishedKind === "rehydration") {
        root.rehydrationCompleted = root.rehydrationTotal
        root.rehydrationStatus = failureCount > 0 ? "partial" : "complete"
        console.log("Sportray calendar rehydration finished",
          root.rehydrationStatus, root.rehydrationCompleted,
          root.rehydrationTotal)
      }
      root.startQueuedPlan()
      return
    }
    var window = root.planWindows[root.planIndex]
    if (window.leagueId !== root.activeLeagueId
        || window.monthStart !== root.activeRangeStart) {
      root.finishActiveLeague()
      root.activeLeagueId = window.leagueId
      root.activeRangeStart = window.monthStart
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
    calendarProcess.command = ["/usr/bin/python3", root.transportHelperPath, url]
    calendarProcess.running = true
  }

  function appendChunk(value) {
    if (root.responseTooLarge) return
    var chunk = String(value || "")
    var fits = root.planKind === "upcoming"
      ? UpcomingScheduleProvider.canAppend(root.pendingBody, chunk, root.planWindows[root.planIndex])
      : ResponsePolicy.canAppend(root.pendingBody, chunk)
    if (!fits) {
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
    if (root.planKind === "rehydration") root.rehydrationCompleted = root.planIndex
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
    root.upcomingOwner = ""
    root.queuedUpcoming = null
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
      var oversized = root.responseTooLarge
      root.pendingBody = ""
      root.bodyReceived = false
      root.responseTooLarge = false
      root.upcomingProcessLeague = ""
      if (root.ownerDestroyed) return
      if (root.queuedUpcoming) {
        var queued = root.queuedUpcoming
        root.queuedUpcoming = null
        root.beginUpcoming(queued)
        return
      }
      if (root.planKind === "upcoming") {
        if (!stopped && root.upcomingEnabled && root.upcomingOwner)
          root.finishUpcomingResponse(exitCode, body, oversized)
        return
      }
      var payload = null
      if (!oversized && body !== "") {
        try { payload = JSON.parse(body) } catch (error) { payload = null }
      }
      root.responseTooLarge = false
      // cancel() deliberately clears planWindows. Service a queued plan before
      // requiring the exited request's window or the replacement is lost.
      if (root.ownerDestroyed || !root.calendarEnabled) return
      if (stopped) {
        root.startQueuedPlan()
        return
      }
      if (!window) return
      if (exitCode !== 0 || !payload) {
        if (root.planKind === "background") {
          root.planIndex = root.planWindows.length
          root.startNext()
          return
        }
        if (root.planKind !== "rehydration") {
          root.planIndex = root.planWindows.length
          var stale = root.windows[root.activeWindowKey]
          if (stale) {
            stale.stale = true
            root.publishEntry(stale)
          } else root.setState("unavailable", root.activeDays, "unavailable", false)
          root.planKind = ""
          root.startQueuedPlan()
          return
        }
        root.planFailureCount++
        root.planIndex++
        if (root.planKind === "rehydration") root.rehydrationCompleted = root.planIndex
        root.setState("loading", root.activeDays, "unavailable", false)
        root.startNext()
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

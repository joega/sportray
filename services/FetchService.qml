import QtQuick
import "../model/ScoreboardModel.js" as ScoreboardModel
import "../model/CalendarCachePolicy.js" as CalendarCachePolicy
import "../model/DateModel.js" as DateModel

Item {
  id: root

  property var enabledLeagues: ["nhl"]
  property var favoriteTeamIds: []
  property string selectedDateKey: ""
  property string lookaheadLeagueId: ""
  property bool panelOpen: false
  property bool calendarOpen: false
  property var leagueStates: []
  property var calendarStates: []
  property var games: []
  property bool hasData: false
  property bool loading: false
  property bool stale: false
  property string errorCode: ""
  property string errorSummary: ""
  property int partialErrorCount: 0
  property string lastSuccessAt: ""
  property string lastAttemptAt: ""
  property string calendarMonthKey: ""
  readonly property var calendarScheduleState: calendarFetch.snapshotFor("nhl")

  function isLeagueEnabled(leagueId) {
    return Array.isArray(root.enabledLeagues) && root.enabledLeagues.indexOf(leagueId) !== -1
  }

  function refresh(reason) {
    var refreshReason = reason || "manual"
    var started = false
    started = nhlFetch.refresh(refreshReason) || started
    started = nflFetch.refresh(refreshReason) || started
    started = mlbFetch.refresh(refreshReason) || started
    started = nbaFetch.refresh(refreshReason) || started
    started = ncaafFetch.refresh(refreshReason) || started
    started = eplFetch.refresh(refreshReason) || started
    started = mlsFetch.refresh(refreshReason) || started
    started = ncaabFetch.refresh(refreshReason) || started
    return started
  }

  function requestRefresh(reason) {
    return pollScheduler.requestRefresh(reason || "manual")
  }

  function requestCalendarMonth(monthKey) {
    root.calendarMonthKey = monthKey || ""
    return calendarFetch.requestMonth(root.calendarMonthKey)
  }

  function calendarKnownLeagueIds() {
    return calendarFetch.eligibleLeagues()
  }

  function syncCalendarOpen() {
    if (!root.calendarOpen) {
      calendarFetch.cancelSchedule()
      return
    }
    var monthKey = DateModel.monthKey(root.selectedDateKey)
    if (!monthKey) return
    root.calendarMonthKey = monthKey
    calendarFetch.requestMonth(monthKey)
  }

  function cancelCalendarSchedule() {
    calendarFetch.cancelSchedule()
  }

  function buildLeagueStates() {
    if (!nhlFetch || !nflFetch || !mlbFetch || !nbaFetch || !ncaafFetch || !eplFetch || !mlsFetch || !ncaabFetch
        || typeof nhlFetch.snapshot !== "function") return []
    return [nhlFetch.snapshot(), nflFetch.snapshot(), mlbFetch.snapshot(), nbaFetch.snapshot(),
      ncaafFetch.snapshot(), eplFetch.snapshot(), mlsFetch.snapshot(), ncaabFetch.snapshot()]
  }

  function buildCalendarStates() {
    if (!nhlFetch || !nflFetch || !mlbFetch || !nbaFetch || !ncaafFetch || !eplFetch || !mlsFetch || !ncaabFetch
        || typeof nhlFetch.calendarSnapshot !== "function") return []
    var liveNhl = nhlFetch.calendarSnapshot()
    var scheduleNhl = calendarFetch.snapshotFor("nhl")
    var mergedNhl = CalendarCachePolicy.mergeState(
      CalendarCachePolicy.mergeState(liveNhl, scheduleNhl), calendarDiskCache.snapshotFor("nhl"))
    var liveStates = [mergedNhl, nflFetch.calendarSnapshot(), mlbFetch.calendarSnapshot(),
      nbaFetch.calendarSnapshot(), ncaafFetch.calendarSnapshot(), eplFetch.calendarSnapshot(),
      mlsFetch.calendarSnapshot(), ncaabFetch.calendarSnapshot()]
    return liveStates.map(function(state) {
      var schedule = state.leagueId === "nhl" ? scheduleNhl
        : calendarFetch.snapshotFor(state.leagueId)
      var merged = state.leagueId === "nhl" ? state : CalendarCachePolicy.mergeState(state, schedule)
      return CalendarCachePolicy.mergeState(merged, calendarDiskCache.snapshotFor(state.leagueId))
    })
  }

  function updateAggregateState() {
    var states = root.buildLeagueStates()
    root.leagueStates = states
    root.calendarStates = root.buildCalendarStates()
    calendarDiskCache.persistStates(root.calendarStates)
    var composed = ScoreboardModel.compose(states, root.enabledLeagues, [], null, root.selectedDateKey)
    root.games = composed.games
    root.hasData = composed.hasData
    root.loading = composed.loading
    root.stale = states.some(function(state) { return state.stale === true })
    root.errorCode = states.some(function(state) { return state.errorCode !== "" })
      ? "partial-data" : ""
    root.errorSummary = states.map(function(state) { return state.errorSummary || "" })
      .filter(function(value) { return value !== "" })[0] || ""
    root.partialErrorCount = states.reduce(function(total, state) {
      return total + (Number(state.partialErrorCount) || 0)
    }, 0)
    var timestamps = states.map(function(state) { return state.lastSuccessAt || "" })
    root.lastSuccessAt = timestamps.filter(function(value) { return value !== "" }).sort().pop() || ""
    var attempts = states.map(function(state) { return state.lastAttemptAt || "" })
    root.lastAttemptAt = attempts.filter(function(value) { return value !== "" }).sort().pop() || ""
  }

  onEnabledLeaguesChanged: {
    root.updateAggregateState()
  }

  onSelectedDateKeyChanged: root.updateAggregateState()

  onCalendarOpenChanged: root.syncCalendarOpen()

  Component.onCompleted: root.updateAggregateState()

  Connections {
    target: calendarFetch
    function onCurrentStateChanged() { root.updateAggregateState() }
  }

  Connections {
    target: calendarDiskCache
    function onReadyChanged() { root.updateAggregateState() }
  }

  Connections {
    target: pollScheduler
    function onRefreshRequested(reason) { root.refresh(reason) }
  }

  Connections {
    target: nhlFetch
    function onRetryRequested(delayMs) { pollScheduler.scheduleRetry(delayMs) }
    function onLeagueEnabledChanged() { root.updateAggregateState() }
    function onGamesChanged() { root.updateAggregateState() }
    function onLoadingChanged() { root.updateAggregateState() }
    function onStaleChanged() { root.updateAggregateState() }
    function onErrorCodeChanged() { root.updateAggregateState() }
    function onPartialErrorCountChanged() { root.updateAggregateState() }
    function onLastSuccessAtChanged() { root.updateAggregateState() }
    function onLastAttemptAtChanged() { root.updateAggregateState() }
    function onErrorSummaryChanged() { root.updateAggregateState() }
    function onNextGameChanged() { root.updateAggregateState() }
    function onNextGameDateKeyChanged() { root.updateAggregateState() }
    function onNextGameStatusChanged() { root.updateAggregateState() }
  }

  Connections {
    target: nflFetch
    function onRetryRequested(delayMs) { pollScheduler.scheduleRetry(delayMs) }
    function onLeagueEnabledChanged() { root.updateAggregateState() }
    function onGamesChanged() { root.updateAggregateState() }
    function onLoadingChanged() { root.updateAggregateState() }
    function onStaleChanged() { root.updateAggregateState() }
    function onErrorCodeChanged() { root.updateAggregateState() }
    function onPartialErrorCountChanged() { root.updateAggregateState() }
    function onLastSuccessAtChanged() { root.updateAggregateState() }
    function onLastAttemptAtChanged() { root.updateAggregateState() }
    function onErrorSummaryChanged() { root.updateAggregateState() }
    function onNextGameChanged() { root.updateAggregateState() }
    function onNextGameDateKeyChanged() { root.updateAggregateState() }
    function onNextGameStatusChanged() { root.updateAggregateState() }
  }

  Connections {
    target: mlbFetch
    function onRetryRequested(delayMs) { pollScheduler.scheduleRetry(delayMs) }
    function onLeagueEnabledChanged() { root.updateAggregateState() }
    function onGamesChanged() { root.updateAggregateState() }
    function onLoadingChanged() { root.updateAggregateState() }
    function onStaleChanged() { root.updateAggregateState() }
    function onErrorCodeChanged() { root.updateAggregateState() }
    function onPartialErrorCountChanged() { root.updateAggregateState() }
    function onLastSuccessAtChanged() { root.updateAggregateState() }
    function onLastAttemptAtChanged() { root.updateAggregateState() }
    function onErrorSummaryChanged() { root.updateAggregateState() }
    function onNextGameChanged() { root.updateAggregateState() }
    function onNextGameDateKeyChanged() { root.updateAggregateState() }
    function onNextGameStatusChanged() { root.updateAggregateState() }
  }

  Connections {
    target: nbaFetch
    function onRetryRequested(delayMs) { pollScheduler.scheduleRetry(delayMs) }
    function onLeagueEnabledChanged() { root.updateAggregateState() }
    function onGamesChanged() { root.updateAggregateState() }
    function onLoadingChanged() { root.updateAggregateState() }
    function onStaleChanged() { root.updateAggregateState() }
    function onErrorCodeChanged() { root.updateAggregateState() }
    function onPartialErrorCountChanged() { root.updateAggregateState() }
    function onLastSuccessAtChanged() { root.updateAggregateState() }
    function onLastAttemptAtChanged() { root.updateAggregateState() }
    function onErrorSummaryChanged() { root.updateAggregateState() }
    function onNextGameChanged() { root.updateAggregateState() }
    function onNextGameDateKeyChanged() { root.updateAggregateState() }
    function onNextGameStatusChanged() { root.updateAggregateState() }
  }

  Connections {
    target: ncaafFetch
    function onRetryRequested(delayMs) { pollScheduler.scheduleRetry(delayMs) }
    function onLeagueEnabledChanged() { root.updateAggregateState() }
    function onGamesChanged() { root.updateAggregateState() }
    function onLoadingChanged() { root.updateAggregateState() }
    function onStaleChanged() { root.updateAggregateState() }
    function onErrorCodeChanged() { root.updateAggregateState() }
    function onPartialErrorCountChanged() { root.updateAggregateState() }
    function onLastSuccessAtChanged() { root.updateAggregateState() }
    function onLastAttemptAtChanged() { root.updateAggregateState() }
    function onErrorSummaryChanged() { root.updateAggregateState() }
    function onNextGameChanged() { root.updateAggregateState() }
    function onNextGameDateKeyChanged() { root.updateAggregateState() }
    function onNextGameStatusChanged() { root.updateAggregateState() }
  }

  Connections {
    target: eplFetch
    function onRetryRequested(delayMs) { pollScheduler.scheduleRetry(delayMs) }
    function onLeagueEnabledChanged() { root.updateAggregateState() }
    function onGamesChanged() { root.updateAggregateState() }
    function onLoadingChanged() { root.updateAggregateState() }
    function onStaleChanged() { root.updateAggregateState() }
    function onErrorCodeChanged() { root.updateAggregateState() }
    function onPartialErrorCountChanged() { root.updateAggregateState() }
    function onLastSuccessAtChanged() { root.updateAggregateState() }
    function onLastAttemptAtChanged() { root.updateAggregateState() }
    function onErrorSummaryChanged() { root.updateAggregateState() }
    function onNextGameChanged() { root.updateAggregateState() }
    function onNextGameDateKeyChanged() { root.updateAggregateState() }
    function onNextGameStatusChanged() { root.updateAggregateState() }
  }

  Connections {
    target: mlsFetch
    function onRetryRequested(delayMs) { pollScheduler.scheduleRetry(delayMs) }
    function onLeagueEnabledChanged() { root.updateAggregateState() }
    function onGamesChanged() { root.updateAggregateState() }
    function onLoadingChanged() { root.updateAggregateState() }
    function onStaleChanged() { root.updateAggregateState() }
    function onErrorCodeChanged() { root.updateAggregateState() }
    function onPartialErrorCountChanged() { root.updateAggregateState() }
    function onLastSuccessAtChanged() { root.updateAggregateState() }
    function onLastAttemptAtChanged() { root.updateAggregateState() }
    function onErrorSummaryChanged() { root.updateAggregateState() }
    function onNextGameChanged() { root.updateAggregateState() }
    function onNextGameDateKeyChanged() { root.updateAggregateState() }
    function onNextGameStatusChanged() { root.updateAggregateState() }
  }

  Connections {
    target: ncaabFetch
    function onRetryRequested(delayMs) { pollScheduler.scheduleRetry(delayMs) }
    function onLeagueEnabledChanged() { root.updateAggregateState() }
    function onGamesChanged() { root.updateAggregateState() }
    function onLoadingChanged() { root.updateAggregateState() }
    function onStaleChanged() { root.updateAggregateState() }
    function onErrorCodeChanged() { root.updateAggregateState() }
    function onPartialErrorCountChanged() { root.updateAggregateState() }
    function onLastSuccessAtChanged() { root.updateAggregateState() }
    function onLastAttemptAtChanged() { root.updateAggregateState() }
    function onErrorSummaryChanged() { root.updateAggregateState() }
    function onNextGameChanged() { root.updateAggregateState() }
    function onNextGameDateKeyChanged() { root.updateAggregateState() }
    function onNextGameStatusChanged() { root.updateAggregateState() }
  }

  PollScheduler {
    id: pollScheduler
    games: root.games
    favoriteTeamIds: root.favoriteTeamIds
    enabledLeagues: root.enabledLeagues
    selectedDateKey: root.selectedDateKey
    panelOpen: root.panelOpen
  }

  CalendarFetch {
    id: calendarFetch
    calendarEnabled: root.enabledLeagues.length > 0
    enabledLeagues: root.enabledLeagues
    calendarCacheReady: calendarDiskCache.ready
  }

  CalendarDiskCache { id: calendarDiskCache }

  LeagueFetch {
    id: nhlFetch
    leagueId: "nhl"
    displayName: "NHL"
    dateKey: root.selectedDateKey
    leagueEnabled: root.isLeagueEnabled("nhl")
    favoriteTeamIds: root.favoriteTeamIds
    panelOpen: root.panelOpen
    jitterUnit: pollScheduler.jitterUnit
    lookaheadEnabled: root.panelOpen && root.lookaheadLeagueId === "nhl"
  }

  LeagueFetch {
    id: nflFetch
    leagueId: "nfl"
    displayName: "NFL"
    dateKey: root.selectedDateKey
    leagueEnabled: root.isLeagueEnabled("nfl")
    favoriteTeamIds: root.favoriteTeamIds
    panelOpen: root.panelOpen
    jitterUnit: pollScheduler.jitterUnit
    lookaheadEnabled: root.panelOpen && root.lookaheadLeagueId === "nfl"
  }

  LeagueFetch {
    id: mlbFetch
    leagueId: "mlb"
    displayName: "MLB"
    dateKey: root.selectedDateKey
    leagueEnabled: root.isLeagueEnabled("mlb")
    favoriteTeamIds: root.favoriteTeamIds
    panelOpen: root.panelOpen
    jitterUnit: pollScheduler.jitterUnit
    lookaheadEnabled: root.panelOpen && root.lookaheadLeagueId === "mlb"
  }

  LeagueFetch {
    id: nbaFetch
    leagueId: "nba"
    displayName: "NBA"
    dateKey: root.selectedDateKey
    leagueEnabled: root.isLeagueEnabled("nba")
    favoriteTeamIds: root.favoriteTeamIds
    panelOpen: root.panelOpen
    jitterUnit: pollScheduler.jitterUnit
    lookaheadEnabled: root.panelOpen && root.lookaheadLeagueId === "nba"
  }

  LeagueFetch {
    id: ncaafFetch
    leagueId: "college-football"
    displayName: "NCAA Football"
    dateKey: root.selectedDateKey
    leagueEnabled: root.isLeagueEnabled("college-football")
    favoriteTeamIds: root.favoriteTeamIds
    panelOpen: root.panelOpen
    jitterUnit: pollScheduler.jitterUnit
    lookaheadEnabled: root.panelOpen && root.lookaheadLeagueId === "college-football"
  }

  LeagueFetch {
    id: eplFetch
    leagueId: "eng.1"
    displayName: "Premier League"
    dateKey: root.selectedDateKey
    leagueEnabled: root.isLeagueEnabled("eng.1")
    favoriteTeamIds: root.favoriteTeamIds
    panelOpen: root.panelOpen
    jitterUnit: pollScheduler.jitterUnit
    lookaheadEnabled: root.panelOpen && root.lookaheadLeagueId === "eng.1"
  }

  LeagueFetch {
    id: mlsFetch
    leagueId: "usa.1"
    displayName: "MLS"
    dateKey: root.selectedDateKey
    leagueEnabled: root.isLeagueEnabled("usa.1")
    favoriteTeamIds: root.favoriteTeamIds
    panelOpen: root.panelOpen
    jitterUnit: pollScheduler.jitterUnit
    lookaheadEnabled: root.panelOpen && root.lookaheadLeagueId === "usa.1"
  }

  LeagueFetch {
    id: ncaabFetch
    leagueId: "mens-college-basketball"
    displayName: "NCAA Men's Basketball"
    dateKey: root.selectedDateKey
    leagueEnabled: root.isLeagueEnabled("mens-college-basketball")
    favoriteTeamIds: root.favoriteTeamIds
    panelOpen: root.panelOpen
    jitterUnit: pollScheduler.jitterUnit
    lookaheadEnabled: root.panelOpen && root.lookaheadLeagueId === "mens-college-basketball"
  }
}

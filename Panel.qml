import QtQuick
import "model/UiTypography.js" as Typography
import "model/UiContrast.js" as UiContrast
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "components"
import "model/FavoritePresentation.js" as FavoritePresentation
import "model/BarPresentation.js" as BarPresentation
import "model/CalendarModel.js" as CalendarModel
import "model/Formatters.js" as Formatters
import "model/GameDetailState.js" as GameDetailState
import "model/LiveFavoriteRotationPolicy.js" as LiveFavoriteRotationPolicy
import "model/PanelPresentation.js" as PanelPresentation
import "model/FollowingPresentation.js" as FollowingPresentation
import "model/NavigationContext.js" as NavigationContext
import "model/TeamSchedulePolicy.js" as TeamSchedulePolicy
import "model/ResultRows.js" as ResultRows
import "model/WatchPolicy.js" as WatchPolicy
import "model/ScoreboardModel.js" as ScoreboardModel
import "model/Iconography.js" as Iconography
import "model/DateModel.js" as DateModel
import "model/PanelLayout.js" as PanelLayout
import "model/PointerInteractionPolicy.js" as PointerInteractionPolicy
import "model/KeyboardRoutingPolicy.js" as KeyboardRoutingPolicy
import "model/LifecyclePolicy.js" as LifecyclePolicy
import "model/StandingsRows.js" as StandingsRows
import "providers/LeagueCatalog.js" as LeagueCatalog
import "providers/NhlTeamCatalog.js" as NhlTeamCatalog
import "providers/EspnTeamCatalog.js" as EspnTeamCatalog
import "services" as Services

Panel {
  id: root
  moduleName: "io.github.joega.sportray"
  ipcTarget: "io.github.joega.sportray"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var service: Services.SportrayService
  property var settingsStore: null
  readonly property var actionFeedbackState: root.settingsStore
    && typeof root.settingsStore.feedbackAction !== "undefined" ? root.settingsStore.feedbackAction : null
  readonly property bool actionUndoAvailable: root.settingsStore
    && typeof root.settingsStore.canUndoFeedback !== "undefined" && root.settingsStore.canUndoFeedback === true
  property string barRegion: ""
  property bool settingsOpen: false
  property bool standingsOpen: false
  property bool choosingStandingsLeague: false
  property bool calendarOpen: false
  property bool calendarFavoritesOnly: false
  property string calendarLeagueId: ""
  property string calendarMonthKey: ""
  property bool scheduleOpen: false
  property int scheduleGeneration: 0
  property string upcomingTeamId: ""
  property string upcomingMonthKey: ""
  property string upcomingWindowStart: ""
  property string upcomingBrowseDate: ""
  property string upcomingLocalError: ""
  property bool detailOpen: false
  property var detailGame: null
  property string detailDateKey: ""
  property string detailLastSuccessAt: ""
  readonly property var detailState: GameDetailState.resolve(root.detailOpen
    ? {game: root.detailGame, dateKey: root.detailDateKey,
      lastSuccessAt: root.detailLastSuccessAt} : null,
    root.fetchService ? root.fetchService.leagueStates : [], root.selectedDateKey, root.ambientNowMs)

  property string utilityReturnDestination: "following"
  property bool utilityReturnTabFocused: true
  property string settingsDestination: "sports"
  property string activeDestination: "following"
  property string followingFilterId: "all"
  property var resultContextOrder: []
  property var navigationStack: []
  property var utilityReturnContext: null
  property string resultActionFocus: ""
  property var activeGameActionsRow: null
  property var pendingResultFocus: null
  property string resultViewportKey: ""
  property var upcomingReturnContext: null
  readonly property bool gameActionsOpen: !!root.activeGameActionsRow && root.activeGameActionsRow.popupOpen
  readonly property string returnLabel: NavigationContext.label(root.navigationStack.length
    ? root.navigationStack[root.navigationStack.length - 1] : null)
  property int tabCursor: 0
  property bool tabStripFocused: true
  property int selectedRowIndex: -1
  property string selectedRowId: ""
  property double nowMs: Date.now()
  property string panelToken: ""
  // Qt.callLater cannot be canceled. Keep the guard as a plain JS object so
  // a deferred closure can reject itself without dereferencing a destroyed
  // QML object first.
  readonly property var callbackOwner: LifecyclePolicy.createOwnerState()
  readonly property var resultListLifecycle: LifecyclePolicy.createOwnerState()
  readonly property var fetchService: root.service ? root.service.fetchService : null
  readonly property var logoImageStore: root.service ? root.service.logoImageStore : null
  readonly property bool calendarFeatureEnabled: root.service
    ? root.service.calendarFeatureEnabled === true : false
  readonly property double ambientNowMs: root.service && typeof root.service.nowMs === "number"
    ? root.service.nowMs : root.nowMs
  readonly property string ambientTodayDateKey: root.service
    && typeof root.service.todayDateKey === "string" && root.service.todayDateKey !== ""
    ? root.service.todayDateKey : DateModel.localDateKey(new Date(root.ambientNowMs))
  readonly property string selectedDateKey: root.service
    ? root.service.selectedDateKey : DateModel.localDateKey(new Date())
  property string observedTodayDateKey: DateModel.localDateKey(new Date())
  property var scrollPositions: ({})
  property var selectedRowIds: ({})
  // Assigned only at deliberate view/date/settings boundaries. Polling may
  // replace rows, but must not resize the attached card or reset its viewport.
  property int panelContentHeightRequest: Style.space(320)
  // A date/destination change can first expose a bounded loading row and then
  // replace it with the fetched slate. Keep one deferred resize request alive
  // across that fetch, but never use ordinary polling updates as a resize
  // trigger.
  property bool panelHeightRecalculationPending: false
  // QML does not reliably invalidate bindings that read through a dynamic
  // SettingsStore object. Keep the presentation boundary explicit so a
  // picker write and a watched state-file load both rebuild Following.
  property int presentationRevision: 0
  property int standingsRevision: 0
  readonly property var barIdentity: hostWidget || root

  onCalendarOpenChanged: {
    if (!root.calendarFeatureEnabled && root.calendarOpen) root.calendarOpen = false
    if (root.fetchService)
      root.fetchService.calendarOpen = root.calendarFeatureEnabled && root.calendarOpen
  }

  function copyStringList(value, fallback) {
    var result = []
    if (!value || typeof value.length !== "number")
      return fallback ? fallback.slice() : result
    for (var i = 0; i < value.length; i++) {
      if (typeof value[i] === "string") result.push(value[i])
    }
    return result
  }

  readonly property var favoriteTeamIds: root.copyStringList(
    root.settingsStore && root.settingsStore.settings ? root.settingsStore.settings.favoriteTeamIds : [], [])
  // The final argument is an invalidation token; the provider-neutral JS
  // boundary ignores extra arguments.
  readonly property var scoreboard: ScoreboardModel.compose(
    fetchService.leagueStates, root.enabledLeagues, root.favoriteTeamIds,
    FavoritePresentation.orderGames, root.selectedDateKey, root.presentationRevision)
  readonly property var normalizedGames: scoreboard.games
  readonly property var panelPresentation: PanelPresentation.build(
    scoreboard, root.favoriteTeamIds, FavoritePresentation.orderGames,
    FavoritePresentation.isFavoriteGame, root.followedLeagueIds, root.presentationRevision,
    root.settingsStore ? root.settingsStore.watchedGames : [], root.nowMs, WatchPolicy.normalizeWatches)
  readonly property var followingProjection: FollowingPresentation.project(panelPresentation.following, root.followingFilterId)
  readonly property bool followingControlsVisible: root.activeDestination === "following"
    && !root.standingsOpen && !root.calendarOpen
  readonly property var tabItems: buildTabItems()
  readonly property var sportOptions: buildSportOptions()
  readonly property var sportsPicker: leaguePicker
  readonly property var activeView: viewForDestination(root.activeDestination)
  readonly property var resultRows: ResultRows.flatten(
    root.activeView, root.activeDestination, root.selectedDateLabel)
  readonly property var standingsService: root.service ? root.service.standingsService : null
  readonly property var notificationService: root.service ? root.service.notificationService : null
  readonly property var standingsState: {
    root.standingsRevision
    return root.standingsService
    && typeof root.standingsService.snapshot === "function"
    ? root.standingsService.snapshot() : ({leagueId: "", groups: [], rows: [], hasData: false,
      loading: false, errorCode: "", errorSummary: ""})
  }
  readonly property bool activeLeagueSupportsStandings: {
    var league = LeagueCatalog.getLeague(root.activeDestination)
    return Boolean(league && league.standingsSupported === true)
  }
  readonly property var standingsRows: StandingsRows.flatten(
    root.standingsState, root.favoriteTeamIds, root.standingsRevision).map(function(row) {
      return row.kind === "standings-status" ? Object.assign({}, row,
        {action: {type: "notice-actions", label: "Data status", enabled: true}}) : row
    })
  function calendarProjectionOptions(monthKey) {
    return {
      enabledLeagues: root.enabledLeagues,
      knownLeagueIds: root.fetchService && typeof root.fetchService.calendarKnownLeagueIds === "function"
        ? root.fetchService.calendarKnownLeagueIds() : root.enabledLeagues,
      favoriteTeamIds: root.favoriteTeamIds,
      monthKey: monthKey,
      selectedDateKey: root.selectedDateKey,
      todayDateKey: root.todayDateKey,
      favoritesOnly: root.calendarFavoritesOnly,
      leagueId: root.calendarLeagueId,
      selectedLoading: root.fetchService && root.fetchService.loading
        && !root.fetchService.hasData,
      selectedUnavailable: root.fetchService && root.fetchService.errorCode !== ""
        && !root.fetchService.hasData,
      selectedErrorCode: root.fetchService ? root.fetchService.errorCode : "",
      selectedErrorSummary: root.fetchService ? root.fetchService.errorSummary : "",
      orderer: FavoritePresentation.orderGames,
      matcher: FavoritePresentation.isFavoriteGame,
      annotate: function(game, leagueMeta) {
        return PanelPresentation.annotate(game, root.favoriteTeamIds, false,
          FavoritePresentation.isFavoriteGame, leagueMeta, true)
      },
      revision: root.presentationRevision,
      calendarStatesRevision: root.fetchService
        ? root.fetchService.calendarStatesRevision : 0
    }
  }
  // Calendar projects the bounded schedule cache plus the selected-day live
  // cache; schedule ownership remains in FetchService, not in this view.
  readonly property var calendarState: !root.calendarOpen ? {cells: [], monthLabel: ""}
    : CalendarModel.monthGrid(
    root.fetchService ? root.fetchService.calendarStates : [],
    root.calendarProjectionOptions(root.calendarMonthKey || CalendarModel.monthKey(root.selectedDateKey)))
  // Keep one month on either side in the bounded view window. Scrolling to an
  // edge advances the center month, so the calendar never requires paging
  // buttons while still avoiding an unbounded model or provider crawl.
  readonly property var calendarPages: !root.calendarOpen ? [] : [-1, 0, 1].map(function(delta) {
    return CalendarModel.monthGrid(root.fetchService ? root.fetchService.calendarStates : [],
      root.calendarProjectionOptions(CalendarModel.addMonths(
        root.calendarMonthKey || CalendarModel.monthKey(root.selectedDateKey), delta)))
  })
  readonly property var calendarDaySummaries: root.calendarState.cells || []
  readonly property var calendarDayRows: CalendarModel.flattenDay(
    root.calendarState, root.selectedDateKey, {
      showUnknown: true,
      loading: root.fetchService && root.fetchService.loading && !root.fetchService.hasData,
      unavailable: root.fetchService && root.fetchService.errorCode !== ""
        && !root.fetchService.hasData,
      errorCode: root.fetchService ? root.fetchService.errorCode : "",
      errorSummary: root.fetchService ? root.fetchService.errorSummary : ""
    })
  readonly property var displayRows: root.standingsOpen
    ? root.standingsRows : root.calendarOpen ? root.calendarDayRows : root.resultRows
  readonly property var orderedGames: scoreboard.games
  readonly property var unrotatedBarState: FavoritePresentation.selectBarState(
    normalizedGames, favoriteTeamIds, null, root.presentationRevision)
  // Reuse the singleton's existing minute publication. This is a presentation
  // cadence, not a polling setting or a second timer contract.
  readonly property int ambientRotationCadenceMs: 60 * 1000
  readonly property var barLiveFavoriteRotation: LiveFavoriteRotationPolicy.select({
    todayDateKey: root.ambientTodayDateKey,
    selectedDateKey: root.selectedDateKey,
    nowMs: root.ambientNowMs,
    cadenceMs: root.ambientRotationCadenceMs,
    favoriteTeamIds: root.favoriteTeamIds,
    hasData: root.hasData,
    errorCode: root.fetchService ? root.fetchService.errorCode : "",
    games: root.normalizedGames
  })
  readonly property var barState: BarPresentation.applyLiveFavoriteRotation(
    root.unrotatedBarState, root.barLiveFavoriteRotation)
  readonly property bool hasGames: scoreboard.hasGames
  readonly property bool hasData: scoreboard.hasData
  readonly property var barGame: barState.game
  readonly property string barIconName: barIconNameForState()
  readonly property bool barHasLiveFavorite: FavoritePresentation.isLiveFavoriteState(barState)
  readonly property var enabledLeagues: {
    return root.copyStringList(root.settingsStore && root.settingsStore.settings
      ? root.settingsStore.settings.enabledLeagues : [], ["nhl"])
  }
  readonly property var followedLeagueIds: root.copyStringList(root.settingsStore && root.settingsStore.settings
    ? root.settingsStore.settings.followedLeagueIds : [], [])

  function calendarLeagueLabel() {
    if (root.calendarLeagueId === "") return "All leagues"
    var league = LeagueCatalog.getLeague(root.calendarLeagueId)
    return league && league.displayName ? league.displayName : root.calendarLeagueId
  }
  readonly property var pickerTeams: buildPickerTeams()
  readonly property var upcomingTeamOptions: [{value: "", label: "All followed leagues"}].concat(root.pickerTeams.filter(function(team) {
    return (root.favoriteTeamIds.indexOf(team.id) !== -1 || team.id === root.upcomingTeamId)
      && root.enabledLeagues.indexOf(team.league) !== -1
  }).map(function(team) {
    var league = LeagueCatalog.getLeague(team.league)
    return {value: team.id, label: team.name + " · "
      + (league ? league.displayName : team.league.toUpperCase())}
  }))
  readonly property var upcomingScheduleState: root.upcomingLocalError !== ""
    ? {teamId: root.upcomingTeamId, scope: root.upcomingTeamId ? "team" : "global",
      dateKey: root.upcomingBrowseDate, loading: false, hasData: false,
      failed: true, partial: false, errorSummary: root.upcomingLocalError, entries: []}
    : root.fetchService && typeof root.fetchService.upcomingState !== "undefined"
      ? root.fetchService.upcomingState : ({})
  readonly property string barScoreText: buildBarScoreText()
  readonly property string barTooltipText: buildBarTooltipText()
  readonly property var verticalScoreLines: buildVerticalScoreLines()
  readonly property string todayDateKey: DateModel.localDateKey(new Date(root.nowMs))
  readonly property string selectedDateLabel: DateModel.displayLabel(
    root.selectedDateKey, root.todayDateKey)

  function refresh() {
    if (root.scheduleOpen) {
      var context = upcomingCalendar.captureContext()
      root.requestUpcoming(true)
      upcomingCalendar.restoreContext(context)
    }
    else if (root.standingsOpen && root.standingsService)
      root.standingsService.refresh(root.activeDestination)
    else if (root.fetchService) root.fetchService.requestRefresh("manual")
  }

  function undoLastAction(actionId) {
    return root.actionUndoAvailable && root.settingsStore
      && typeof root.settingsStore.undoFeedback === "function"
      ? root.settingsStore.undoFeedback(actionId) : false
  }

  function requestUpcoming(force) {
    root.upcomingLocalError = ""
    if (!root.upcomingTeamId) {
      if (!root.fetchService || typeof root.fetchService.requestGlobalCalendar !== "function"
          || !root.fetchService.requestGlobalCalendar(root.panelToken, root.upcomingBrowseDate, force === true))
        root.upcomingLocalError = "Calendar unavailable. Try again."
      return
    }
    if (!root.fetchService || typeof root.fetchService.requestUpcoming !== "function"
        || !root.fetchService.requestUpcoming(root.panelToken, root.upcomingTeamId,
          root.upcomingWindowStart, DateModel.addDays(root.upcomingWindowStart, 34), force === true))
      root.upcomingLocalError = "Schedule unavailable. Try again."
  }

  function openUpcomingCalendar() {
    if (root.settingsOpen || root.detailOpen || root.standingsOpen) return
    if (root.scheduleOpen) { root.closeSchedule(); return }
    root.closeGameActions()
    root.pushNavigation(root.captureNavigationContext())
    root.upcomingTeamId = ""
    root.upcomingBrowseDate = root.selectedDateKey
    root.upcomingMonthKey = CalendarModel.monthKey(root.selectedDateKey)
    root.upcomingWindowStart = root.todayDateKey
    root.showSchedule()
    root.requestUpcoming(false)
  }

  function jumpToUpcomingDate(dateKey) {
    if (!DateModel.isDateKey(dateKey)) return
    var league = root.upcomingTeamId.split(":")[0]
    root.pushNavigation(root.captureNavigationContext())
    root.closeUpcomingForNavigation()
    root.detailOpen = false
    root.settingsOpen = false
    if (!root.upcomingTeamId) root.selectDestination("following")
    else if (root.activeDestination !== league)
      root.selectDestination(league)
    root.selectDate(dateKey)
  }

  function closeGameActions() {
    if (root.activeGameActionsRow && typeof root.activeGameActionsRow.closeActions === "function")
      root.activeGameActionsRow.closeActions()
    root.activeGameActionsRow = null
  }

  function openSelectedGameActions() {
    if (root.settingsOpen || root.detailOpen || root.standingsOpen || root.calendarOpen) return false
    var delegate = resultList.itemAtIndex(root.selectedRowIndex)
    if (!delegate || typeof delegate.openGameActions !== "function") return false
    root.resultActionFocus = "actions"
    return delegate.openGameActions()
  }

  function activateResultAction() {
    if (!root.selectableRow(root.selectedRowIndex)) return
    var row = root.displayRows[root.selectedRowIndex]
    if (root.resultActionFocus.indexOf("team:") === 0) {
      var teamId = root.resultActionFocus.slice(5)
      var contains = row.kind === "game" && row.game
        && ((row.game.awayTeam && row.game.awayTeam.id === teamId)
          || (row.game.homeTeam && row.game.homeTeam.id === teamId))
      contains = contains || row.kind === "standings" && row.standing && row.standing.team
        && row.standing.team.id === teamId
      if (contains) root.openTeamSchedule(teamId, root.resultActionFocus)
      else root.resultActionFocus = ""
    } else if (root.resultActionFocus === "actions") root.openSelectedGameActions()
    else root.activateRow(root.selectedRowIndex)
  }

  function moveSelectedNotice(delta) {
    var delegate = resultList.itemAtIndex(root.selectedRowIndex)
    return delegate && typeof delegate.moveNoticeCursor === "function" ? delegate.moveNoticeCursor(delta) : false
  }

  function revealNotice(index) {
    root.setSelectedRow(index)
    root.tabStripFocused = false
    root.deferResultListCallback(function(list) {
      list.positionViewAtIndex(index, ListView.Contain)
      if (!keyCatcher.blocked) keyCatcher.forceActiveFocus()
    })
  }

  function captureNavigationContext(focusId) {
    root.saveResultPosition(root.activeDestination)
    var selectedItem = resultList.itemAtIndex(root.selectedRowIndex)
    return {surface: root.scheduleOpen ? (root.upcomingTeamId ? "team" : "calendar")
        : root.detailOpen ? "detail" : root.standingsOpen ? "standings" : "scores",
      destination: root.activeDestination, dateKey: root.selectedDateKey,
      baseSurface: root.detailOpen ? "detail" : root.standingsOpen ? "standings" : "scores",
      followingFilterId: root.followingFilterId, selectedRowId: root.selectedRowId,
      listScrollY: resultList.contentY - resultList.originY,
      rowViewportY: selectedItem ? selectedItem.mapToItem(resultList, 0, 0).y : null,
      tabStripFocused: root.tabStripFocused,
      focusId: focusId || root.resultActionFocus,
      detailGame: root.detailState.game, detailDateKey: root.detailDateKey,
      detailLastSuccessAt: root.detailState.lastSuccessAt || root.detailLastSuccessAt,
      detailContext: gameDetailView.captureContext(),
      upcomingTeamId: root.upcomingTeamId, upcomingMonthKey: root.upcomingMonthKey,
      upcomingWindowStart: root.upcomingWindowStart, upcomingBrowseDate: root.upcomingBrowseDate,
      upcomingContext: upcomingCalendar.captureContext()}
  }

  function pushNavigation(frame) { root.navigationStack = NavigationContext.push(root.navigationStack, frame) }

  function showSchedule() {
    root.scheduleGeneration++
    var generation = root.scheduleGeneration
    root.scheduleOpen = true
    root.detailOpen = false
    root.recalculatePanelHeight()
    root.deferPanelCallback(function() {
      if (!root.scheduleOpen || root.scheduleGeneration !== generation) return
      if (root.upcomingReturnContext) {
        var context = root.upcomingReturnContext
        root.upcomingReturnContext = null
        upcomingCalendar.restoreContext(context)
      } else upcomingCalendar.focusCalendar()
    })
  }

  function hideSchedule() {
    root.scheduleGeneration++
    root.scheduleOpen = false
    root.upcomingReturnContext = null
    upcomingCalendar.pendingContext = null
    if (root.panelToken && root.fetchService && typeof root.fetchService.cancelUpcoming === "function")
      root.fetchService.cancelUpcoming(root.panelToken)
  }

  function closeUpcomingForNavigation() { root.hideSchedule() }

  function closeSchedule() {
    root.hideSchedule()
    if (!root.goBack()) {
      root.recalculatePanelHeight()
      root.deferPanelCallback(function() { keyCatcher.forceActiveFocus() })
    }
  }

  function restoreNavigationContext(frame) {
    if (!frame || !root.opened) return
    var destination = NavigationContext.destination(frame, root.enabledLeagues)
    root.settingsOpen = false
    root.followingFilterId = FollowingPresentation.normalizeFilter(frame.followingFilterId)
    root.setSelectedDate(frame.dateKey)
    root.activeDestination = destination
    root.standingsOpen = (frame.surface === "standings" || frame.baseSurface === "standings") && destination !== "following"
    if (root.standingsOpen && root.standingsService) root.standingsService.load(destination, false)
    root.detailOpen = (frame.surface === "detail" || frame.baseSurface === "detail") && !!frame.detailGame
      && root.enabledLeagues.indexOf(frame.detailGame.league) !== -1
    root.detailGame = root.detailOpen ? frame.detailGame : null
    root.detailDateKey = frame.detailDateKey || ""
    root.detailLastSuccessAt = frame.detailLastSuccessAt || ""
    root.tabStripFocused = frame.tabStripFocused === true
    root.resultActionFocus = frame.focusId || ""
    root.pendingResultFocus = {key: root.resultContextKey(destination),
      rowId: frame.selectedRowId || "", focusId: frame.focusId || ""}
    var key = root.resultContextKey(destination)
    var positions = Object.assign({}, root.scrollPositions)
    positions[key] = Number(frame.listScrollY) || 0
    var selected = Object.assign({}, root.selectedRowIds)
    selected[key] = frame.selectedRowId || ""
    var order = root.resultContextOrder.filter(function(value) { return value !== key })
    order.push(key)
    while (order.length > 32) {
      var evicted = order.shift()
      delete positions[evicted]
      delete selected[evicted]
    }
    root.resultContextOrder = order
    root.scrollPositions = positions
    root.selectedRowIds = selected
    root.restoreResultPosition()
    if (frame.surface === "team" || frame.surface === "calendar") {
      var validTeam = frame.upcomingTeamId
        ? TeamSchedulePolicy.resolve(frame.upcomingTeamId, root.pickerTeams, root.enabledLeagues) : null
      root.upcomingTeamId = validTeam ? validTeam.id : ""
      root.upcomingMonthKey = frame.upcomingMonthKey || CalendarModel.monthKey(root.todayDateKey)
      root.upcomingWindowStart = frame.upcomingWindowStart || root.todayDateKey
      root.upcomingBrowseDate = frame.upcomingBrowseDate || root.todayDateKey
      root.upcomingReturnContext = frame.upcomingContext || null
      root.showSchedule()
      root.requestUpcoming(false)
    }
    root.recalculatePanelHeight()
    root.deferPanelCallback(function() {
      scoreChrome.forceLayout()
      contentColumn.forceLayout()
      root.restoreResultPosition(true, frame)
      if (!root.scheduleOpen && root.detailOpen) gameDetailView.restoreContext(frame.detailContext)
    })
  }

  function restorePendingResultFocus() {
    var pending = root.pendingResultFocus
    if (!pending || root.detailOpen || root.scheduleOpen || root.settingsOpen) return
    if (pending.key !== root.resultContextKey(root.activeDestination)) { root.pendingResultFocus = null; return }
    if (pending.rowId && pending.rowId !== root.selectedRowId) {
      if (!root.activeView.loading) root.pendingResultFocus = null
      return
    }
    keyCatcher.forceActiveFocus()
    root.resultActionFocus = pending.focusId
    var delegate = resultList.itemAtIndex(root.selectedRowIndex)
    if (delegate && typeof delegate.restoreActionFocus === "function") delegate.restoreActionFocus(pending.focusId)
    root.pendingResultFocus = null
  }

  function goBack() {
    if (!root.navigationStack.length) return false
    var result = NavigationContext.pop(root.navigationStack)
    root.navigationStack = result.stack
    root.restoreNavigationContext(result.frame)
    return true
  }

  function openTeamSchedule(teamId, focusId) {
    var team = TeamSchedulePolicy.resolve(teamId, root.pickerTeams, root.enabledLeagues)
    if (!team || !root.opened) return false
    if (!root.scheduleOpen) root.pushNavigation(root.captureNavigationContext(focusId))
    root.closeGameActions()
    root.upcomingTeamId = team.id
    root.upcomingWindowStart = root.todayDateKey
    root.upcomingBrowseDate = root.selectedDateKey
    root.upcomingMonthKey = CalendarModel.monthKey(root.todayDateKey)
    root.showSchedule()
    root.requestUpcoming(false)
    return true
  }

  onUpcomingTeamOptionsChanged: {
    if (!root.scheduleOpen) return
    if (root.upcomingTeamOptions.some(function(option) { return option.value === root.upcomingTeamId })) return
    if (root.fetchService && typeof root.fetchService.cancelUpcoming === "function")
      root.fetchService.cancelUpcoming(root.panelToken)
    root.upcomingTeamId = root.upcomingTeamOptions.length ? root.upcomingTeamOptions[0].value : ""
    root.requestUpcoming(false)
  }

  onFollowedLeagueIdsChanged: {
    if (root.scheduleOpen && !root.upcomingTeamId)
      root.deferPanelCallback(function() { if (root.scheduleOpen) root.requestUpcoming(false) })
  }
  onEnabledLeaguesChanged: {
    if (root.scheduleOpen && !root.upcomingTeamId)
      root.deferPanelCallback(function() { if (root.scheduleOpen) root.requestUpcoming(false) })
  }

  function openStandings() {
    if (!root.activeLeagueSupportsStandings || !root.standingsService) return
    root.standingsOpen = true
    root.calendarOpen = false
    root.selectedRowIndex = -1
    root.selectedRowId = ""
    root.standingsService.load(root.activeDestination, false)
    root.recalculatePanelHeight()
    root.deferPanelCallback(function() {
      root.recalculatePanelHeight()
      keyCatcher.forceActiveFocus()
    })
  }

  function toggleStandings() {
    if (!root.activeLeagueSupportsStandings) {
      root.choosingStandingsLeague = true
      if (root.sportsPicker) root.sportsPicker.open()
      return
    }
    if (root.standingsOpen) {
      root.standingsOpen = false
      root.recalculatePanelHeight()
    } else {
      root.openStandings()
    }
  }

  function openCalendar() {
    if (!root.calendarFeatureEnabled) return
    root.calendarMonthKey = CalendarModel.monthKey(root.selectedDateKey)
    root.calendarOpen = true
    if (root.fetchService) {
      root.fetchService.calendarOpen = true
      // Rebuild after the cache-read boundary so a panel created before the
      // durable cache became ready cannot retain a sparse calendar projection.
      if (typeof root.fetchService.refreshCalendarStates === "function")
        root.fetchService.refreshCalendarStates(false)
    }
    root.standingsOpen = false
    root.selectedRowIndex = -1
    root.selectedRowId = ""
    root.tabStripFocused = false
    root.recalculatePanelHeight()
    root.deferPanelCallback(function() {
      root.recalculatePanelHeight()
      keyCatcher.forceActiveFocus()
    })
  }

  function closeCalendar() {
    if (!root.calendarOpen) return
    if (root.fetchService) root.fetchService.calendarOpen = false
    root.calendarOpen = false
    root.selectedRowIndex = -1
    root.selectedRowId = ""
    root.tabStripFocused = true
    root.recalculatePanelHeight()
    root.deferPanelCallback(function() {
      root.recalculatePanelHeight()
      keyCatcher.forceActiveFocus()
    })
  }

  function toggleCalendar() {
    if (!root.calendarFeatureEnabled) return
    root.calendarOpen ? root.closeCalendar() : root.openCalendar()
  }

  function toggleCalendarFilter() {
    if (!root.calendarOpen) return
    root.calendarFavoritesOnly = !root.calendarFavoritesOnly
    root.selectedRowIndex = -1
    root.selectedRowId = ""
    root.recalculatePanelHeight()
  }

  function cycleCalendarLeague() {
    if (!root.calendarOpen) return
    var ids = PanelPresentation.orderLeagueIds(root.enabledLeagues, root.followedLeagueIds)
    var options = [""]
    ids.forEach(function(id) { if (options.indexOf(id) === -1) options.push(id) })
    var index = options.indexOf(root.calendarLeagueId)
    root.calendarLeagueId = options[(index + 1 + options.length) % options.length]
    root.selectedRowIndex = -1
    root.selectedRowId = ""
    root.recalculatePanelHeight()
  }

  function changeCalendarMonth(delta) {
    if (!root.calendarOpen) return
    var next = CalendarModel.addMonths(root.calendarMonthKey
      || CalendarModel.monthKey(root.selectedDateKey), delta)
    if (!next) return
    root.calendarMonthKey = next
    if (root.fetchService && typeof root.fetchService.requestCalendarMonth === "function")
      root.fetchService.requestCalendarMonth(next)
    root.selectedRowIndex = -1
    root.selectedRowId = ""
    root.deferPanelCallback(function() { monthCalendar.focusSelected() })
    root.recalculatePanelHeight()
  }

  function jumpCalendarToNextGames() {
    if (!root.calendarOpen) return
    var target = CalendarModel.nextGamesDateKey(root.calendarState,
      root.selectedDateKey)
    if (!DateModel.isDateKey(target)) return
    root.selectDate(target)
  }

  function syncDetailSnapshot() {
    if (!root.detailOpen || !root.fetchService) return
    var resolved = GameDetailState.resolve({game: root.detailGame, dateKey: root.detailDateKey,
      lastSuccessAt: root.detailLastSuccessAt}, root.fetchService.leagueStates,
      root.selectedDateKey, root.ambientNowMs)
    // Cache only the newest resolved identity. Keep this event-driven so no
    // presentation binding writes back into its own dependencies.
    if (resolved.game && root.detailGame !== resolved.game) root.detailGame = resolved.game
    if (!resolved.missing && resolved.lastSuccessAt)
      root.detailLastSuccessAt = resolved.lastSuccessAt
  }

  Connections {
    target: root.fetchService
    function onLeagueStatesChanged() { root.syncDetailSnapshot() }
  }

  function openGameDetail(game) {
    if (!game || game.isValid !== true) return
    if (!root.detailOpen) root.pushNavigation(root.captureNavigationContext())
    root.closeGameActions()
    root.detailDateKey = root.selectedDateKey
    root.detailLastSuccessAt = ""
    root.detailGame = game
    root.detailOpen = true
    root.syncDetailSnapshot()
    root.standingsOpen = false
    root.tabStripFocused = false
    root.recalculatePanelHeight()
    root.deferPanelCallback(function() {
      gameDetailView.resetCursor()
      keyCatcher.forceActiveFocus()
    })
  }

  function closeDetail() {
    if (!root.detailOpen) return
    if (root.goBack()) return
    root.detailOpen = false
    root.detailGame = null
    root.tabStripFocused = false
    root.recalculatePanelHeight()
    root.deferPanelCallback(function() { keyCatcher.forceActiveFocus() })
  }

  function moveDetailCursor(delta) {
    if (!root.detailOpen) return
    gameDetailView.moveCursor(delta)
  }

  function activateDetailCursor() {
    if (!root.detailOpen) return
    gameDetailView.activateCursor()
  }

  function setSelectedDate(dateKey) {
    if (!root.service || !DateModel.isDateKey(dateKey)) return
    root.service.selectedDateKey = dateKey
  }

  function syncSharedContext() {
    if (!root.service || !root.panelToken) return
    root.service.updatePanel(root.panelToken, root.opened,
      !root.settingsOpen && root.activeDestination !== "following"
        ? root.activeDestination : "")
  }

  function recalculatePanelHeight() {
    if (root.scheduleOpen) {
      root.panelContentHeightRequest = PanelLayout.clamp(header.height + contentColumn.spacing
        + upcomingCalendar.implicitHeight, Style.space(320), Style.space(640))
      return
    }
    if (root.detailOpen) {
      root.panelContentHeightRequest = PanelLayout.detailContentRequest(
        gameDetailView.implicitHeight,
        panel && panel.screen ? panel.screen.height : 0, {
          minimum: gameDetailView.scheduledPresentation ? Style.space(280) : Style.space(320),
          fixedCap: Style.space(600),
          viewportFraction: 0.5
        })
      return
    }
    root.panelContentHeightRequest = root.measuredPanelContentRequest()
  }

  function measuredPanelContentRequest() {
    var tokens = {
        compactMinimum: Style.space(280),
        maximum: Style.space(640),
        scoreChrome: Style.space(112),
        section: Style.space(22),
        game: Style.space(88),
        standings: Style.space(64),
        status: Style.space(42),
        loading: Style.space(170),
        nextGame: Style.space(250),
        empty: Style.space(104),
        rowGap: Style.spacing.md,
        settings: Style.space(440),
        teams: Style.space(640),
        notifications: Style.space(520)
        ,ticker: Style.space(300)
    }
    if (!header || !contentColumn)
      return PanelLayout.contentRequest(root.displayRows, root.settingsDestination,
        root.settingsOpen, tokens)

    var bodyHeight = 0
    if (root.settingsOpen && utilityColumn) {
      bodyHeight = utilityColumn.implicitHeight
    } else if (scoreChrome && resultList) {
      // Use the actual laid-out delegates. The host still applies the bounded
      // fitted height, so dense result lists remain scrollable instead of
      // forcing the popup beyond the available screen.
      bodyHeight = scoreChrome.implicitHeight + Style.spacing.md
        + Math.max(0, Number(resultList.contentHeight) || 0)
    }
    return PanelLayout.clamp(header.height + contentColumn.spacing + bodyHeight,
      tokens.compactMinimum, tokens.maximum)
  }

  function deferPanelCallback(callback) {
    if (typeof callback !== "function") return
    var owner = root.callbackOwner
    var generation = LifecyclePolicy.captureGeneration(owner)
    Qt.callLater(function() {
      // The QML import namespace may already be gone after a monitor removes
      // this panel. Inspect only the captured plain owner before touching it.
      if (!owner || owner.alive !== true || owner.generation !== generation) return
      callback()
    })
  }

  function deferResultListCallback(callback) {
    if (typeof callback !== "function" || !resultList) return
    var panelOwner = root.callbackOwner
    var list = resultList
    var listLifecycle = root.resultListLifecycle
    var panelGeneration = LifecyclePolicy.captureGeneration(panelOwner)
    var listGeneration = LifecyclePolicy.captureGeneration(listLifecycle)
    Qt.callLater(function() {
      if (!panelOwner || panelOwner.alive !== true || panelOwner.generation !== panelGeneration
          || !listLifecycle || listLifecycle.alive !== true || listLifecycle.generation !== listGeneration
          || resultList !== list) return
      callback(list)
    })
  }

  function queuePanelHeightRecalculation() {
    root.panelHeightRecalculationPending = true
    panelHeightSettleTimer.restart()
  }

  function firstLeagueDestination() {
    return root.tabItems.length > 1 ? root.tabItems[1].id : "following"
  }

  function selectDate(dateKey) {
    if (!DateModel.isDateKey(dateKey) || dateKey === root.selectedDateKey) return
    root.saveResultPosition(root.activeDestination)
    root.resultActionFocus = ""
    root.pendingResultFocus = null
    root.closeGameActions()
    if (root.calendarOpen) root.calendarMonthKey = CalendarModel.monthKey(dateKey)
    root.queuePanelHeightRecalculation()
    root.setSelectedDate(dateKey)
    root.selectedRowIndex = -1
    root.selectedRowId = ""
    root.deferPanelCallback(root.recalculatePanelHeight)
  }

  function selectRelativeDate(delta) {
    root.selectDate(DateModel.addDays(root.selectedDateKey, delta))
  }

  function buildTabItems() {
    var items = [{id: "following", label: "Following", iconName: "neutral"}]
    for (var i = 0; i < panelPresentation.leagues.length; i++) {
      var league = panelPresentation.leagues[i]
      items.push({
        id: league.leagueId,
        label: league.displayName || league.leagueId.toUpperCase(),
        iconName: Iconography.iconNameForLeague(league.leagueId)
      })
    }
    return items
  }

  function buildSportOptions() {
    var options = []
    for (var i = 0; i < root.tabItems.length; i++) {
      var item = root.tabItems[i]
      options.push({value: item.id, label: item.label})
    }
    return options
  }


  function viewForDestination(destination) {
    if (destination === "following") return root.followingProjection.view
    for (var i = 0; i < panelPresentation.leagues.length; i++) {
      if (panelPresentation.leagues[i].leagueId === destination)
        return Object.assign({}, panelPresentation.leagues[i], {interactiveNotice: true})
    }
    return root.followingProjection.view
  }

  function destinationIndex(destination) {
    for (var i = 0; i < root.tabItems.length; i++) {
      if (root.tabItems[i].id === destination) return i
    }
    return 0
  }

  function selectDestination(destination) {
    root.resultActionFocus = ""
    root.pendingResultFocus = null
    root.closeGameActions()
    var index = root.destinationIndex(destination)
    root.queuePanelHeightRecalculation()
    root.saveResultPosition(root.activeDestination)
    root.standingsOpen = false
    root.calendarOpen = false
    root.tabCursor = index
    root.activeDestination = root.tabItems[index].id
    root.tabStripFocused = true
    root.restoreResultPosition()
    root.recalculatePanelHeight()
  }

  function chooseLeague(destination) {
    var showStandings = root.choosingStandingsLeague
    root.choosingStandingsLeague = false
    root.selectDestination(destination)
    if (showStandings) root.openStandings()
  }

  function moveTabCursor(delta) {
    if (root.tabItems.length === 0) return
    var index = Math.max(0, Math.min(root.tabItems.length - 1, root.tabCursor + delta))
    root.selectDestination(root.tabItems[index].id)
  }

  function activateTabCursor() {
    root.choosingStandingsLeague = false
    if (root.sportsPicker) root.sportsPicker.open()
  }

  function resultContextKey(destination) {
    return JSON.stringify([root.standingsOpen ? "standings" : "scores", destination,
      root.selectedDateKey, destination === "following" ? root.followingFilterId : "all"])
  }

  function setFollowingFilter(filterId) {
    var next = FollowingPresentation.normalizeFilter(filterId)
    if (next !== root.followingFilterId) {
      root.resultActionFocus = ""
      root.pendingResultFocus = null
      root.closeGameActions()
      root.saveResultPosition(root.activeDestination)
      root.followingFilterId = next
      root.selectedRowIndex = -1
      root.selectedRowId = ""
      root.restoreResultPosition()
      root.recalculatePanelHeight()
    }
    root.deferPanelCallback(function() { if (!keyCatcher.blocked) keyCatcher.forceActiveFocus() })
  }

  function saveResultPosition(destination) {
    if (!destination || !resultList) return
    var key = root.resultContextKey(destination)
    var positions = Object.assign({}, root.scrollPositions || {})
    var selected = Object.assign({}, root.selectedRowIds || {})
    positions[key] = resultList.contentY - resultList.originY
    selected[key] = root.selectedRowId || ""
    var order = root.resultContextOrder.filter(function(value) { return value !== key })
    order.push(key)
    while (order.length > 32) {
      var evicted = order.shift()
      delete positions[evicted]
      delete selected[evicted]
    }
    root.resultContextOrder = order
    root.scrollPositions = positions
    root.selectedRowIds = selected
  }

  function rowIndexForId(rowId) {
    if (!rowId) return -1
    for (var i = 0; i < root.displayRows.length; i++) {
      if (root.displayRows[i].rowId === rowId) return i
    }
    return -1
  }

  function selectableRow(index) {
    return index >= 0 && index < root.displayRows.length
      && root.displayRows[index].action
      && root.displayRows[index].action.enabled === true
  }

  function nearestSelectableRow(index, direction) {
    var step = direction < 0 ? -1 : 1
    var cursor = Math.max(0, Math.min(root.displayRows.length - 1, index))
    while (cursor >= 0 && cursor < root.displayRows.length) {
      if (root.selectableRow(cursor)) return cursor
      cursor += step
    }
    return -1
  }

  function setSelectedRow(index) {
    if (!root.selectableRow(index)) return
    root.tabStripFocused = false
    if (root.selectedRowIndex !== index) root.resultActionFocus = ""
    root.selectedRowIndex = index
    root.selectedRowId = root.displayRows[index].rowId
    var selected = Object.assign({}, root.selectedRowIds || {})
    selected[root.resultContextKey(root.activeDestination)] = root.selectedRowId
    root.selectedRowIds = selected
    root.deferResultListCallback(function(list) {
      if (root.selectedRowIndex === index && list.count > index)
        list.positionViewAtIndex(index, ListView.Contain)
    })
  }

  function activateRow(index) {
    if (root.detailOpen) return
    if (!root.selectableRow(index)) return
    var row = root.displayRows[index]
    var delegate = resultList.itemAtIndex(index)
    if (row.action.type === "choose-teams") {
      root.openUtility("teams")
    } else if (row.action.type === "browse-leagues") {
      root.selectDestination(root.firstLeagueDestination())
    } else if (row.action.type === "show-all") {
      root.setFollowingFilter("all")
    } else if (row.action.type === "notice-actions") {
      if (delegate && typeof delegate.activateNoticeCursor === "function") delegate.activateNoticeCursor()
    } else if (row.action.type === "open-detail") {
      root.openGameDetail(row.game)
    } else if (row.action.type === "open-source") {
      if (delegate && typeof delegate.activatePrimaryAction === "function")
        delegate.activatePrimaryAction()
    } else if (delegate && typeof delegate.activatePrimaryAction === "function") {
      delegate.activatePrimaryAction()
    } else if (row.action.type === "retry" || row.action.type === "retry-standings") {
      root.refresh()
    }
  }

  function moveResultCursor(delta) {
    var next = root.selectedRowIndex
    if (next < 0) next = delta < 0 ? root.displayRows.length - 1 : 0
    else next += delta < 0 ? -1 : 1
    next = root.nearestSelectableRow(next, delta)
    if (next >= 0) root.setSelectedRow(next)
  }

  function moveResultCursorByPage(direction) {
    if (root.displayRows.length === 0) return
    var page = Math.max(1, Math.floor(resultList.height / Style.space(56)))
    var next = root.selectedRowIndex < 0
      ? (direction < 0 ? root.displayRows.length - 1 : 0)
      : root.selectedRowIndex + direction * page
    next = Math.max(0, Math.min(root.displayRows.length - 1, next))
    next = root.nearestSelectableRow(next, direction)
    if (next >= 0) root.setSelectedRow(next)
  }

  function moveResultCursorToEdge(direction) {
    var next = direction < 0 ? 0 : root.displayRows.length - 1
    next = root.nearestSelectableRow(next, direction)
    if (next >= 0) root.setSelectedRow(next)
  }

  function restoreResultPosition(forceSavedPosition, frame) {
    var key = root.resultContextKey(root.activeDestination)
    var savedId = root.selectedRowIds && root.selectedRowIds[key] ? root.selectedRowIds[key] : ""
    var index = root.rowIndexForId(savedId)
    root.selectedRowId = index >= 0 ? savedId : ""
    root.selectedRowIndex = index
    if (index < 0) root.resultActionFocus = ""
    root.deferResultListCallback(function(list) {
      if (key !== root.resultContextKey(root.activeDestination)) return
      var savedY = root.scrollPositions && root.scrollPositions[key] ? root.scrollPositions[key] : 0
      var returning = root.pendingResultFocus && root.pendingResultFocus.key === key
      if (forceSavedPosition === true || root.resultViewportKey !== key || returning)
        list.contentY = list.originY + Math.max(0, Math.min(savedY, list.contentHeight - list.height))
      root.resultViewportKey = key
      if (index >= 0) list.positionViewAtIndex(index, ListView.Contain)
      // A virtualized ListView may change originY and estimated item positions
      // while its hidden viewport resizes. Restore the selected row's actual
      // screen position after layout, with normalized scroll as the fallback.
      if (frame && frame.selectedRowId === root.selectedRowId
          && typeof frame.rowViewportY === "number" && isFinite(frame.rowViewportY)) {
        for (var pass = 0; pass < 2; pass++) {
          list.forceLayout()
          var item = list.itemAtIndex(index)
          if (!item) break
          var correction = item.mapToItem(list, 0, 0).y - frame.rowViewportY
          list.contentY = list.originY + Math.max(0, Math.min(list.contentY - list.originY + correction,
            Math.max(0, list.contentHeight - list.height)))
        }
      }
      root.restorePendingResultFocus()
    })
  }

  function buildPickerTeams() {
    var teams = []
    // Favorites remain discoverable when a league is temporarily disabled;
    // fetching and destination visibility still follow enabledLeagues.
    var leagues = LeagueCatalog.listLeagues().map(function(league) { return league.id })
    for (var i = 0; i < leagues.length; i++) {
      var league = String(leagues[i]).toLowerCase()
      if (league === "nhl") teams = teams.concat(NhlTeamCatalog.listTeams())
      else teams = teams.concat(EspnTeamCatalog.listTeams(league))
    }
    return teams
  }

  function open() {
    root.choosingStandingsLeague = false
    root.controller.show()
  }

  onOpenedChanged: {
    root.syncSharedContext()
    if (!root.opened) {
      root.navigationStack = []
      root.pendingResultFocus = null
      root.resultActionFocus = ""
      root.utilityReturnContext = null
      root.closeGameActions()
      root.hideSchedule()
      if (root.fetchService && typeof root.fetchService.cancelCalendarSchedule === "function")
        root.fetchService.cancelCalendarSchedule()
      root.detailOpen = false
      root.detailGame = null
      root.settingsOpen = false
      return
    }
    root.nowMs = Date.now()
    root.followingFilterId = "all"
    root.standingsOpen = false
    root.calendarOpen = false
    root.calendarFavoritesOnly = false
    root.panelHeightRecalculationPending = root.displayRows.some(function(row) {
      return row.kind === "loading"
    })
    root.recalculatePanelHeight()
    if (root.panelHeightRecalculationPending) panelHeightSettleTimer.restart()
    root.activeDestination = "following"
    root.tabCursor = 0
    root.tabStripFocused = true
    root.deferPanelCallback(function() {
      root.restoreResultPosition()
      keyCatcher.forceActiveFocus()
      root.recalculatePanelHeight()
    })
  }

  onTodayDateKeyChanged: {
    if (root.selectedDateKey === root.observedTodayDateKey)
      root.setSelectedDate(root.todayDateKey)
    root.observedTodayDateKey = root.todayDateKey
  }

  onSelectedDateKeyChanged: {
    root.resultActionFocus = ""
    root.selectedRowIndex = -1
    root.selectedRowId = ""
    root.deferPanelCallback(root.restoreResultPosition)
    root.deferPanelCallback(root.recalculatePanelHeight)
  }

  onActiveDestinationChanged: {
    root.resultActionFocus = ""
    root.standingsOpen = false
    root.calendarOpen = false
    root.tabCursor = root.destinationIndex(root.activeDestination)
    if (sportsPicker) sportsPicker.value = root.activeDestination
    root.recalculatePanelHeight()
    root.syncSharedContext()
  }

  onResultRowsChanged: {
    root.deferPanelCallback(root.restoreResultPosition)
    if (root.panelHeightRecalculationPending) panelHeightSettleTimer.restart()
  }

  onDisplayRowsChanged: {
    root.deferPanelCallback(root.restoreResultPosition)
    if (root.panelHeightRecalculationPending) panelHeightSettleTimer.restart()
  }

  onStandingsOpenChanged: {
    if (root.standingsOpen) root.hideSchedule()
    root.selectedRowIndex = -1
    root.selectedRowId = ""
    root.recalculatePanelHeight()
    root.syncSharedContext()
  }

  Timer {
    id: panelHeightSettleTimer
    interval: 250
    repeat: false
    onTriggered: {
      if (!LifecyclePolicy.canRun(root.callbackOwner,
          LifecyclePolicy.captureGeneration(root.callbackOwner))) return
      if (!root.panelHeightRecalculationPending) return
      if (root.activeView && root.activeView.loading === true) {
        restart()
        return
      }
      root.panelHeightRecalculationPending = false
      root.recalculatePanelHeight()
    }
  }

  onSettingsOpenChanged: {
    if (root.settingsOpen) root.hideSchedule()
    root.deferPanelCallback(root.recalculatePanelHeight)
    root.syncSharedContext()
  }

  onTabItemsChanged: if (root.destinationIndex(root.activeDestination) === 0
                         && root.activeDestination !== "following")
    root.activeDestination = "following"

  function close() {
    root.navigationStack = []
    root.pendingResultFocus = null
    root.resultActionFocus = ""
    root.utilityReturnContext = null
    root.closeGameActions()
    root.hideSchedule()
    root.choosingStandingsLeague = false
    // The bar remains an ambient current-day indicator; browsing another day
    // is a panel session, so closing returns the next ambient refresh to today.
    if (root.selectedDateKey !== root.todayDateKey)
      root.setSelectedDate(root.todayDateKey)
    root.detailOpen = false
    root.detailGame = null
    root.calendarOpen = false
    root.controller.hide()
  }

  function closeForPopoutSwitch() {
    root.popoutSwitchClosing = true
    root.close()
    root.deferPanelCallback(function() { root.popoutSwitchClosing = false })
  }

  function toggle() {
    root.opened ? root.close() : root.open()
  }

  function togglePicker() {
    root.settingsOpen ? root.closeUtility() : root.openUtility("teams")
  }

  function toggleSettings() {
    root.settingsOpen ? root.closeUtility() : root.openUtility("sports")
  }

  function openSettings(destination) {
    root.openUtility(destination || "sports")
  }

  function openUtility(destination) {
    root.utilityReturnContext = root.captureNavigationContext()
    root.detailOpen = false
    root.closeGameActions()
    if (root.scheduleOpen) root.closeUpcomingForNavigation()
    root.saveResultPosition(root.activeDestination)
    root.utilityReturnTabFocused = root.tabStripFocused
    root.utilityReturnDestination = root.activeDestination
    root.settingsDestination = destination || "sports"
    root.settingsOpen = true
    settingsHub.reset(root.settingsDestination)
    root.tabStripFocused = false
    utilityScroll.contentY = 0
    root.recalculatePanelHeight()
    root.deferPanelCallback(function() {
      if (root.settingsOpen && !keyCatcher.blocked) keyCatcher.forceActiveFocus()
    })
  }

  function closeUtility() {
    root.settingsOpen = false
    if (root.utilityReturnContext) {
      var context = root.utilityReturnContext
      root.utilityReturnContext = null
      root.restoreNavigationContext(context)
      return
    }
    // The selected league may have been disabled in Settings.
    root.activeDestination = root.tabItems.some(function(item) {
      return item.id === root.utilityReturnDestination
    }) ? root.utilityReturnDestination : "following"
    root.tabCursor = root.destinationIndex(root.activeDestination)
    root.tabStripFocused = root.utilityReturnTabFocused
    root.restoreResultPosition()
    root.recalculatePanelHeight()
    root.deferPanelCallback(function() { keyCatcher.forceActiveFocus() })
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  Timer {
    id: panelClockTimer
    interval: 60000
    repeat: true
    running: root.opened
    onTriggered: root.nowMs = Date.now()
  }

  function localStartTime(value) {
    if (typeof value !== "string") return ""
    var date = new Date(value)
    if (isNaN(date.getTime())) return ""
    return Qt.formatDateTime(date, "h:mm AP")
  }

  function barFormatOptions(maxLength) {
    var options = {leagueLabel: barState.game ? String(barState.game.league || "").toUpperCase() : "SPORTRAY"}
    options.maxLength = typeof maxLength === "number" ? maxLength : 32
    if (barState.game) options.startTimeText = localStartTime(barState.game.startTime)
    return options
  }

  function barIconNameForState() {
    // While the panel is open, the tray button represents the league the user
    // is actually browsing. The ambient state below remains favorite-first
    // when the panel is closed.
    if (root.opened && !root.settingsOpen && root.activeDestination !== "following")
      return Iconography.iconNameForLeague(root.activeDestination)

    if (barState.game)
      return Iconography.iconNameForLeague(barState.game.league)

    if (barState.kind === "live-favorite-count") {
      var liveFavorites = root.normalizedGames.filter(function(game) {
        return FavoritePresentation.isFavoriteGame(game, root.favoriteTeamIds)
          && (game.status === "live" || game.status === "intermission")
      })
      if (liveFavorites.length > 0)
        return Iconography.iconNameForLeague(liveFavorites[0].league)
    }

    return "soccerField"
  }

  function buildBarScoreText() {
    var text = Formatters.formatBarText(barState, root.barFormatOptions())
    if (text !== "") return text
    if (fetchService.loading && !fetchService.hasData) return "Sportray …"
    if (fetchService.errorCode !== "") return "Sportray · offline"
    return fetchService.hasData ? "Sportray · no games" : "Sportray"
  }

  function buildBarTooltipText() {
    var text = Formatters.formatBarTooltip(barState, root.barFormatOptions(64))
    if (root.fetchService && root.fetchService.calendarRehydrating)
      return "Sportray · rehydrating calendar "
        + root.fetchService.calendarRehydrationCompleted + " of "
        + root.fetchService.calendarRehydrationTotal
    if (root.barHasLiveFavorite && text !== "") return "Live favorite · " + text
    if (text !== "") return text
    if (fetchService.errorCode !== "") return "Sportray · scores unavailable"
    return fetchService.hasData ? "Sportray · no games" : "Sportray"
  }

  function buildVerticalScoreLines() {
    var lines = Formatters.formatBarVerticalLines(barState, {
      leagueLabel: barState.game ? String(barState.game.league || "").toUpperCase() : "SPORT"
    })
    if (lines.length > 0) return lines
    if (fetchService.loading && !fetchService.hasData) return ["SPORT", "…", ""]
    if (fetchService.errorCode !== "") return ["SPORT", "OFF", ""]
    return ["SPORT", "—", ""]
  }

  Connections {
    target: root.settingsStore
    function onSettingsChanged() {
      root.presentationRevision++
      root.standingsRevision++
    }
  }

  Connections {
    target: root.standingsService
    function onGroupsChanged() { root.standingsRevision++ }
    function onRowsChanged() { root.standingsRevision++ }
    function onLoadingChanged() { root.standingsRevision++ }
    function onHasDataChanged() { root.standingsRevision++ }
    function onErrorCodeChanged() { root.standingsRevision++ }
    function onErrorSummaryChanged() { root.standingsRevision++ }
    function onStaleChanged() { root.standingsRevision++ }
    function onLastSuccessAtChanged() { root.standingsRevision++ }
  }

  Component.onCompleted: {
    root.panelToken = root.service.registerPanel()
    root.syncSharedContext()
  }

  Component.onDestruction: {
    LifecyclePolicy.invalidate(root.callbackOwner)
    LifecyclePolicy.invalidate(root.resultListLifecycle)
    panelHeightSettleTimer.stop()
    panelClockTimer.stop()
    if (root.fetchService && typeof root.fetchService.cancelUpcoming === "function")
      root.fetchService.cancelUpcoming(root.panelToken)
    if (root.service && root.panelToken) root.service.unregisterPanel(root.panelToken)
  }

  Connections {
    target: settingsHub
    function onContentFocusRequested() {
      root.deferPanelCallback(function() {
        if (root.settingsOpen) keyCatcher.forceActiveFocus()
      })
    }
    function onEscapeRequested() { root.closeUtility() }
    function onContentBoundsRequested(top, bottom) {
      var contentTop = settingsHub.y + top
      var contentBottom = settingsHub.y + bottom
      if (contentTop < utilityScroll.contentY)
        utilityScroll.contentY = Math.max(0, contentTop)
      else if (contentBottom > utilityScroll.contentY + utilityScroll.height)
        utilityScroll.contentY = Math.min(utilityScroll.contentHeight - utilityScroll.height,
          Math.max(0, contentBottom - utilityScroll.height))
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    // Keep the score surface attached to the configured bar region instead of
    // opening as a centered dashboard. Zero margin/gap makes its top edge meet
    // the top bar directly; KeyboardPanel keeps it on the Overlay layer above
    // tiled application windows. The host component owns the card surface and
    // transition; the default popup border frames the card like other Omarchy
    // popups and matches the ticker's accent edge.
    centerOnBar: root.barRegion === "center"
    margin: 0
    gap: 0
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.fittedContentHeight(root.panelContentHeightRequest, Style.space(640))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      // The installed catcher runs BeforeItem and otherwise consumes panel
      // navigation keys before an active editor can receive them. Let the
      // editor own all keys, including Escape, while it has focus.
      blocked: root.scheduleOpen || root.gameActionsOpen || KeyboardRoutingPolicy.catcherBlocked(
        settingsHub.inputActive, sportsPicker && sportsPicker.popupOpen)
      onCloseRequested: root.detailOpen ? root.closeDetail()
        : root.settingsOpen ? root.closeUtility()
        : root.calendarOpen ? root.closeCalendar() : root.navigationStack.length ? root.goBack() : root.close()
      onMoveRequested: function(dx, dy) {
        root.resultActionFocus = ""
        root.pendingResultFocus = null
        if (root.detailOpen) {
          if (dy !== 0 || !gameDetailView.scrollLines(dx))
            root.moveDetailCursor(dy !== 0 ? dy : dx)
        }
        else if (root.settingsOpen) settingsHub.moveCursor(dx, dy)
        else if (root.calendarOpen) monthCalendar.moveFocus(dx, dy)
        else if (dx !== 0 && !root.tabStripFocused && root.moveSelectedNotice(dx)) {
          // A selected status row owns its visible Details/Retry action cursor.
        } else if (dx !== 0) {
          root.tabStripFocused = true
          root.moveTabCursor(dx)
        }
        else if (dy !== 0) { root.tabStripFocused = false; root.moveResultCursor(dy) }
        // A pointer-selected native button may still own Qt focus. Once the
        // user moves the panel cursor, activation must follow that cursor.
        root.deferPanelCallback(function() {
          if (!keyCatcher.blocked) keyCatcher.forceActiveFocus()
        })
      }
      onActivateRequested: {
        if (root.detailOpen) root.activateDetailCursor()
        else if (root.settingsOpen) settingsHub.activateCursor()
        else if (root.calendarOpen) monthCalendar.activateFocused()
        else if (root.tabStripFocused) root.activateTabCursor()
        else root.activateResultAction()
      }
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(text) {
        if (settingsHub.inputActive) return
        if (root.detailOpen) return
        if (root.settingsOpen) {
          settingsHub.handleTextKey(text)
          return
        }
        if (root.followingControlsVisible && (text === "f" || text === "F")) {
          root.setFollowingFilter(FollowingPresentation.nextFilter(root.followingFilterId))
          return
        }
        if (!root.standingsOpen && (text === "g" || text === "G")) root.openUpcomingCalendar()
        if (text === "r" || text === "R") root.refresh()
        if (text === "n" || text === "N") root.openSettings()
        if (root.calendarFeatureEnabled && (text === "c" || text === "C")
            && !root.settingsOpen && !root.detailOpen)
          root.toggleCalendar()
        if (KeyboardRoutingPolicy.calendarFilterAction(text, root.calendarOpen,
            root.settingsOpen, root.detailOpen) === "toggle-calendar-filter")
          root.toggleCalendarFilter()
        if (KeyboardRoutingPolicy.calendarJumpAction(text, root.calendarOpen,
            root.settingsOpen, root.detailOpen) === "jump-to-next-games")
          root.jumpCalendarToNextGames()
        if (KeyboardRoutingPolicy.calendarLeagueAction(text, root.calendarOpen,
            root.settingsOpen, root.detailOpen) === "cycle-calendar-league")
          root.cycleCalendarLeague()
        if ((text === "s" || text === "S") && !root.settingsOpen)
          root.toggleStandings()
        if (!root.standingsOpen && (text === "[" || text === "{")) root.selectRelativeDate(-1)
        if (!root.standingsOpen && (text === "]" || text === "}")) root.selectRelativeDate(1)
        if (!root.standingsOpen && (text === "t" || text === "T")) root.selectDate(root.todayDateKey)
      }

      // PanelKeyCatcher owns arrows, tab, activation, Escape, and text keys.
      // Keep only the extra viewport navigation keys here; the installed
      // Omarchy handler does not emit semantic signals for these keys.
      Keys.onPressed: function(event) {
        if (event.accepted) return
        if (event.key === Qt.Key_Z && (event.modifiers & Qt.ControlModifier)
            && !settingsHub.inputActive && !root.gameActionsOpen && !sportsPicker.popupOpen
            && !(root.scheduleOpen && upcomingCalendar.chooserOpen)) {
          event.accepted = root.undoLastAction(root.actionFeedbackState ? root.actionFeedbackState.id : undefined)
          if (event.accepted) return
        }
        if (root.scheduleOpen) {
          if (upcomingCalendar.chooserOpen) return
          if (event.key === Qt.Key_Escape) root.closeSchedule()
          else if (!upcomingCalendar.inputActive && event.key === Qt.Key_R) root.refresh()
          else if (!upcomingCalendar.inputActive && event.key === Qt.Key_N) root.openSettings()
          else return
          event.accepted = true
          return
        }
        if (keyCatcher.blocked) return
        if (event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier))) {
          event.accepted = root.openSelectedGameActions()
          return
        }
        if (root.settingsOpen) return
        if (root.detailOpen) {
          if (event.key === Qt.Key_PageDown) gameDetailView.scrollPage(1)
          else if (event.key === Qt.Key_PageUp) gameDetailView.scrollPage(-1)
          else if (event.key === Qt.Key_Home) gameDetailView.scrollEdge(-1)
          else if (event.key === Qt.Key_End) gameDetailView.scrollEdge(1)
          else return
          event.accepted = true
          return
        }
        if (root.calendarOpen && event.key === Qt.Key_PageDown) {
          root.changeCalendarMonth(1)
          event.accepted = true
        } else if (root.calendarOpen && event.key === Qt.Key_PageUp) {
          root.changeCalendarMonth(-1)
          event.accepted = true
        } else if (event.key === Qt.Key_PageDown) {
          root.tabStripFocused = false
          root.moveResultCursorByPage(1)
        } else if (event.key === Qt.Key_PageUp) {
          root.tabStripFocused = false
          root.moveResultCursorByPage(-1)
        } else if (event.key === Qt.Key_Home) {
          root.tabStripFocused = false
          root.moveResultCursorToEdge(-1)
        } else if (event.key === Qt.Key_End) {
          root.tabStripFocused = false
          root.moveResultCursorToEdge(1)
        } else {
          return
        }
        event.accepted = true
      }


      Column {
        id: contentColumn
        anchors.fill: parent
        spacing: Style.spacing.md
        // The card is intentionally bounded even when the result model is
        // dense. The body below uses the actual fitted card height.

      Item {
          id: header
          width: parent.width
          property real spacing: Style.spacing.sm
          property bool compactActions: width < Style.space(900)
          height: Math.max(Style.space(32), headerTitle.implicitHeight, headerActions.implicitHeight)

          Text {
            textFormat: Text.PlainText
            id: headerTitle
            anchors.left: parent.left
            anchors.right: headerActions.left
            anchors.rightMargin: header.spacing
            height: parent.height
            text: root.settingsOpen ? "Settings" : root.scheduleOpen ? (root.upcomingTeamId ? "Team schedule" : "Calendar") : root.detailOpen ? "Game details"
              : root.calendarOpen ? "Calendar" : root.standingsOpen ? "Standings"
              : root.selectedDateKey === root.todayDateKey ? "Today"
              : DateModel.shortDateLabel(root.selectedDateKey)
            font.family: Typography.family
            font.pixelSize: Style.font.title
            color: Commons.Color.popups.text
            font.bold: true
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
          }

          Row {
            id: headerActions
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: header.spacing

            SemanticActionButton {
              visible: (root.scheduleOpen || root.navigationStack.length > 0) && !root.settingsOpen && !root.detailOpen
              iconName: "chevronLeft"
              fallbackText: "<"
              tooltipText: root.returnLabel
              focusable: true
              onClicked: root.scheduleOpen ? root.closeSchedule() : root.goBack()
              Accessible.name: root.returnLabel
              Accessible.role: Accessible.Button
            }

            SemanticActionButton {
              id: upcomingLeagues
              visible: root.scheduleOpen && !root.upcomingTeamId && !root.settingsOpen
              text: "Leagues"
              textFontSize: Style.font.caption
              tooltipText: "Choose followed leagues"
              focusable: true
              onClicked: root.openUtility("sports")
              Accessible.name: "Choose followed leagues in Sports & leagues"
              Accessible.role: Accessible.Button
            }

            SemanticActionButton {
            id: todayButton
            visible: !root.settingsOpen && !root.detailOpen && !root.scheduleOpen
              && !root.standingsOpen
              && root.selectedDateKey !== root.todayDateKey
            iconName: ""
            text: header.compactActions ? "" : "Show Today"
            fallbackText: "T"
            textBold: true
            textFontSize: Style.font.caption
            textVerticalPadding: Style.spacing.controlPaddingY / 2
            tooltipText: "Return to today"
            focusable: true
            height: refreshButton.implicitHeight
            onClicked: root.selectDate(root.todayDateKey)
            Accessible.name: "Show today"
            Accessible.role: Accessible.Button
            }

            SemanticActionButton {
            id: standingsButton
            visible: !root.settingsOpen && !root.detailOpen && !root.scheduleOpen
            bordered: true
            iconName: root.standingsOpen ? "scores" : "list"
            fallbackText: root.standingsOpen ? "S" : "T"
            tooltipText: !root.activeLeagueSupportsStandings ? "Choose a league to view standings"
              : root.standingsOpen ? "Show scores" : "Show standings"
            text: root.standingsOpen ? "Scores" : "Standings"
            textFontSize: Style.font.caption
            textBold: true
            textVerticalPadding: Style.spacing.controlPaddingY / 2
            height: refreshButton.implicitHeight
            focusable: true
            onClicked: root.toggleStandings()
            Accessible.name: !root.activeLeagueSupportsStandings ? "Choose a league for standings"
              : root.standingsOpen ? "Show scores" : "Show standings"
            Accessible.role: Accessible.Button
            }

            SemanticActionButton {
            id: legacyCalendarButton
            visible: root.calendarFeatureEnabled && !root.settingsOpen && !root.detailOpen
            iconName: root.calendarOpen ? "scores" : "calendar"
            fallbackText: root.calendarOpen ? "S" : "C"
            tooltipText: root.calendarOpen ? "Show scores" : "Show calendar"
            text: header.compactActions ? "" : (root.calendarOpen ? "Scores" : "Calendar")
            textFontSize: Style.font.caption
            textBold: true
            textVerticalPadding: Style.spacing.controlPaddingY / 2
            width: root.calendarOpen ? Style.space(62) : Style.space(76)
            height: refreshButton.implicitHeight
            focusable: true
            onClicked: root.toggleCalendar()
            Accessible.name: root.calendarOpen ? "Show scores" : "Show calendar"
            Accessible.role: Accessible.Button
            }

            SemanticActionButton {
            id: calendarFilterButton
            visible: root.calendarOpen && !root.settingsOpen && !root.detailOpen
            iconName: ""
            fallbackText: "A"
            tooltipText: root.calendarFavoritesOnly
              ? "Show every enabled league (F)" : "Show only favorite games (F)"
            text: header.compactActions ? "" : (root.calendarFavoritesOnly ? "Favorites" : "All games")
            textFontSize: Style.font.caption
            textBold: true
            textVerticalPadding: Style.spacing.controlPaddingY / 2
            height: refreshButton.implicitHeight
            focusable: true
            onClicked: root.toggleCalendarFilter()
            Accessible.name: root.calendarFavoritesOnly
              ? "Show every enabled league (F)" : "Show only favorite games (F)"
            Accessible.role: Accessible.Button
            }

            SemanticActionButton {
            id: calendarLeagueButton
            visible: root.calendarOpen && !root.settingsOpen && !root.detailOpen
            iconName: ""
            fallbackText: "L"
            tooltipText: root.calendarLeagueId === ""
              ? "Filter calendar by league (L)" : "Show all enabled leagues (L)"
            text: header.compactActions ? "" : root.calendarLeagueLabel()
            textFontSize: Style.font.caption
            textBold: true
            textVerticalPadding: Style.spacing.controlPaddingY / 2
            height: refreshButton.implicitHeight
            focusable: true
            onClicked: root.cycleCalendarLeague()
            Accessible.name: root.calendarLeagueId === ""
              ? "Filter calendar by league" : "Show all enabled leagues"
            Accessible.role: Accessible.Button
            }

            SemanticActionButton {
            id: refreshButton
            readonly property bool refreshing: root.scheduleOpen ? root.upcomingScheduleState.loading === true
              : root.standingsOpen ? root.standingsState.loading === true : fetchService.loading
            visible: !root.settingsOpen && !root.detailOpen
            iconName: "refresh"
            fallbackText: refreshButton.refreshing ? "..." : "R"
            tooltipText: root.scheduleOpen ? (refreshButton.refreshing ? "Updating schedule" : "Refresh schedule")
              : root.standingsOpen
              ? (refreshButton.refreshing ? "Refreshing standings" : "Refresh standings")
              : (refreshButton.refreshing ? "Refreshing scores" : "Refresh scores")
            enabled: !refreshButton.refreshing
            focusable: true
            onClicked: root.refresh()
            Accessible.name: refreshButton.tooltipText
            Accessible.role: Accessible.Button
            }

            SemanticActionButton {
            id: settingsButton
            visible: !root.detailOpen
            iconName: root.settingsOpen ? "close" : "settings"
            fallbackText: root.settingsOpen ? "X" : "[ ]"
            tooltipText: root.settingsOpen ? "Close settings" : "Sportray settings"
            focusable: true
            onClicked: root.toggleSettings()
            Accessible.name: root.settingsOpen ? "Close settings" : "Sportray settings"
            Accessible.role: Accessible.Button
            }
          }
        }

        Item {
          id: panelBody
          width: parent.width
          height: Math.max(0, parent.height - header.height - contentColumn.spacing)

          ActionFeedback {
            id: actionFeedbackView
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            z: 20
            action: root.actionFeedbackState
            canUndo: root.actionUndoAvailable
            onUndoRequested: function(actionId) { root.undoLastAction(actionId) }
          }

          FocusScope {
            id: upcomingPage
            anchors.fill: parent
            visible: root.scheduleOpen && !root.settingsOpen
          UpcomingCalendar {
            id: upcomingCalendar
            anchors.fill: parent
            teamOptions: root.upcomingTeamOptions
            teamId: root.upcomingTeamId
            globalSelectionEmpty: root.followedLeagueIds.filter(function(id) {
              return root.enabledLeagues.indexOf(id) !== -1
            }).length === 0
            selectedDateKey: root.upcomingTeamId ? root.upcomingWindowStart : root.upcomingBrowseDate
            todayDateKey: root.todayDateKey
            currentTime: root.nowMs
            monthKey: root.upcomingMonthKey
            scheduleState: root.upcomingScheduleState
            imageStore: root.logoImageStore
            onImplicitHeightChanged: if (root.scheduleOpen) root.deferPanelCallback(root.recalculatePanelHeight)
            onTeamSelected: function(teamId) {
              upcomingCalendar.pendingContext = null
              root.upcomingTeamId = teamId
              if (teamId) root.upcomingWindowStart = root.todayDateKey
              root.requestUpcoming(false)
            }
            onMonthRequested: function(monthKey) {
              upcomingCalendar.pendingContext = null
              root.upcomingMonthKey = monthKey
              root.upcomingBrowseDate = monthKey
              root.requestUpcoming(false)
            }
            onDaySelected: function(dateKey) {
              upcomingCalendar.pendingContext = null
              root.upcomingBrowseDate = dateKey
              root.upcomingMonthKey = CalendarModel.monthKey(dateKey)
              root.requestUpcoming(false)
            }
            onWindowRequested: function(startDateKey) {
              upcomingCalendar.pendingContext = null
              root.upcomingWindowStart = startDateKey
              root.requestUpcoming(false)
            }
            onDateSelected: function(dateKey) { root.jumpToUpcomingDate(dateKey) }
            onRetryRequested: root.requestUpcoming(true)
            onCloseRequested: root.closeSchedule()
          }
          }

          Flickable {
            id: utilityScroll
            anchors.fill: parent
            visible: root.settingsOpen
            contentWidth: width
            contentHeight: utilityColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            // Favorite teams owns the inner wheel/list. Other settings
            // destinations use this outer surface as their single owner.
            interactive: root.settingsDestination !== "teams" && contentHeight > height
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            Column {
              id: utilityColumn
              width: utilityScroll.width
              spacing: Style.spacing.md

              SettingsHub {
                id: settingsHub
                width: utilityColumn.width
                visible: root.settingsOpen
                teams: root.pickerTeams
                leagues: LeagueCatalog.listLeagues()
                settingsStore: root.settingsStore
                imageStore: root.logoImageStore
                notificationService: root.notificationService
                settingsRevision: root.presentationRevision
                callbackOwner: root.callbackOwner
                compact: utilityScroll.width < Style.space(360)
              }
            }
          }

            Item {
        id: scoreContent
              anchors.fill: parent
              visible: !root.settingsOpen && !root.detailOpen && !root.scheduleOpen
        clip: true

        SportAtmosphere {
              id: sportAtmosphere
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              height: Math.min(parent.height, Style.space(136))
              leagueId: root.activeDestination
              visible: false
              z: 0
            }

            Column {
              id: scoreChrome
              width: parent.width
              spacing: Style.spacing.md
              z: 1

              Item {
                id: dateNavigation
                width: parent.width
                visible: !root.calendarOpen && !root.standingsOpen
                height: !root.calendarOpen && !root.standingsOpen ? dateCarousel.implicitHeight : 0

                DateCarousel {
                  id: dateCarousel
                  anchors.left: parent.left
                  anchors.right: calendarButton.left
                  anchors.rightMargin: Style.spacing.xs
                  selectedDateKey: root.selectedDateKey
                  todayDateKey: root.todayDateKey
                  compact: dateNavigation.width < Style.space(360)
                  onDateSelected: function(dateKey) { root.selectDate(dateKey) }
                }

                SemanticActionButton {
                  id: calendarButton
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  size: dateCarousel.implicitHeight
                  iconName: "calendar"
                  fallbackText: "G"
                  tooltipText: "Calendar (G)"
                  bordered: true
                  focusable: true
                  onClicked: root.openUpcomingCalendar()
                  Accessible.name: "Calendar. Browse followed leagues or a team schedule"
                  Accessible.role: Accessible.Button
                }
              }

              MonthCalendar {
                id: monthCalendar
                width: parent.width
                visible: root.calendarOpen
                height: root.calendarOpen ? implicitHeight : 0
                gridState: root.calendarState
                pages: root.calendarPages
                selectedDateKey: root.selectedDateKey
                calendarCacheLoading: root.fetchService
                  ? !root.fetchService.calendarCacheReady : true
                rehydrating: root.fetchService && root.fetchService.calendarRehydrating
                rehydrationStatus: root.fetchService
                  ? root.fetchService.calendarRehydrationStatus : "idle"
                rehydrationCompleted: root.fetchService
                  ? root.fetchService.calendarRehydrationCompleted : 0
                rehydrationTotal: root.fetchService
                  ? root.fetchService.calendarRehydrationTotal : 0
                onDateSelected: function(dateKey) {
                  root.selectDate(dateKey)
                  root.deferPanelCallback(function() { monthCalendar.focusSelected() })
                }
                onMonthRequested: function(delta) { root.changeCalendarMonth(delta) }
                onTodayRequested: function() {
                  root.selectDate(root.todayDateKey)
                  root.calendarMonthKey = CalendarModel.monthKey(root.todayDateKey)
                  if (root.fetchService && typeof root.fetchService.requestCalendarMonth === "function")
                    root.fetchService.requestCalendarMonth(root.calendarMonthKey)
                }
              }

              Item {
                id: tabStrip
                width: parent.width
                height: !root.calendarOpen ? (sportsPicker ? sportsPicker.implicitHeight : 0) : 0
                visible: !root.calendarOpen

                SemanticIcon {
                  id: activeSportIcon
                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                  width: Style.space(28)
                  height: width
                  iconName: Iconography.iconNameForLeague(root.activeDestination)
                  fontSize: Style.font.subtitle
                  color: Commons.Color.accent
                  decorative: true
                }

                Dropdown {
                  id: leaguePicker
                  anchors.left: activeSportIcon.right
                  anchors.leftMargin: Style.spacing.sm
                  anchors.right: parent.right
                  label: "League"
                  showLabel: false
                  fontFamily: Typography.family
                  value: root.activeDestination
                  options: root.sportOptions
                  hasCursor: root.tabStripFocused
                  onChanged: function(value) { root.chooseLeague(value) }
                  onPopupOpenChanged: if (!popupOpen) root.choosingStandingsLeague = false
                  Accessible.name: "Choose a league"
                  Accessible.role: Accessible.ComboBox
                  Accessible.onPressAction: leaguePicker.open()
                }
              }

              FollowingOverview {
                id: followingOverview
                width: parent.width
                visible: root.followingControlsVisible
                height: root.followingControlsVisible ? implicitHeight : 0
                projection: root.followingProjection
                onFilterSelected: function(filterId) { root.setFollowingFilter(filterId) }
              }
            }

            Item {
              id: resultViewport
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: scoreChrome.bottom
              anchors.bottom: parent.bottom
              anchors.topMargin: Style.spacing.md
              clip: true

              ListView {
                id: resultList
                anchors.fill: parent
                model: root.displayRows
                currentIndex: root.selectedRowIndex
                spacing: root.standingsOpen ? Style.spacing.xxs : Style.spacing.md
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                onCurrentIndexChanged: if (currentIndex >= 0)
                  root.deferResultListCallback(function(list) {
                    list.positionViewAtIndex(currentIndex, ListView.Contain)
                  })

                delegate: Item {
                  required property var modelData
                  required property int index
                  readonly property var gameValue: modelData && modelData.game
                    ? modelData.game : ({
                      status: "unknown", awayTeam: null, homeTeam: null,
                      awayScore: null, homeScore: null, presentation: {}
                    })
                  readonly property var statusValue: modelData && modelData.status
                    ? modelData.status : ({
                      displayName: "Scores", loading: false, stale: false,
                      errorCode: "", errorSummary: "", partialErrorCount: 0,
                      lastSuccessAt: null
                    })
                  width: ListView.view.width
                  height: rowColumn.implicitHeight
                  readonly property bool nestedActionPressed: PointerInteractionPolicy.childActionPressed(
                    gameRow.childActionPressed,
                    leagueStatus.pointerPressed || standingsStatus.pointerPressed,
                    nextGameCard.childActionPressed,
                    emptyAction.pointerPressed,
                    standingsRow.childActionPressed)

                  Column {
                    id: rowColumn
                    width: parent.width
                    spacing: modelData.kind === "game" ? 0 : Style.spacing.sm

                    Text {
                      textFormat: Text.PlainText
                      width: parent.width
                      // Do not bind a QQuickText height to its own
                      // implicitHeight. The delegate's bounded row height
                      // makes that self-dependency surface as a runtime loop.
                      height: modelData && modelData.kind === "section-header" ? font.pixelSize : 0
                      visible: modelData && modelData.kind === "section-header"
                      text: modelData.label || "Scores"
                      color: UiContrast.foreground(Commons.Color.accent, Commons.Color.popups.text, Commons.Color.popups.background)
                      font.family: Typography.family
                      font.pixelSize: Style.font.caption
                      font.bold: true
                    }

                    StandingsHeader {
                      width: parent.width
                      height: modelData && modelData.kind === "standings-section" ? implicitHeight : 0
                      visible: modelData && modelData.kind === "standings-section"
                      label: modelData.label || "Standings"
                      leagueId: root.activeDestination
                      seeded: root.standingsState.rows && root.standingsState.rows.some(function(row) {
                        return row.rankKind === "seed"
                      })
                    }

                    GameRow {
                      id: gameRow
                      width: parent.width
                      height: modelData && modelData.kind === "game" ? implicitHeight : 0
                      visible: modelData && modelData.kind === "game"
                      game: gameValue
                      settingsStore: root.settingsStore
                      imageStore: root.logoImageStore
                      currentTime: root.ambientNowMs
                      stale: modelData && modelData.stale === true
                      startTimeTextOverride: modelData
                        && typeof modelData.timeLabel === "string"
                        ? modelData.timeLabel : ""
                      selected: root.selectedRowId === (modelData ? modelData.rowId : "")
                      featured: Boolean(gameValue.presentation
                        && gameValue.presentation.isFavorite
                        && gameValue.presentation.isLive)
                      onPrimaryActionRequested: {
                        root.setSelectedRow(index)
                        root.resultActionFocus = ""
                        root.openGameDetail(gameValue)
                      }
                      onTeamScheduleRequested: function(teamId) {
                        root.setSelectedRow(index)
                        root.resultActionFocus = "team:" + teamId
                        root.openTeamSchedule(teamId, root.resultActionFocus)
                      }
                      onPopupOpenChanged: {
                        if (popupOpen) {
                          root.setSelectedRow(index)
                          root.activeGameActionsRow = gameRow
                          root.resultActionFocus = "actions"
                        }
                      }
                      onFocusReturnRequested: root.deferPanelCallback(function() {
                        if (!keyCatcher.blocked) keyCatcher.forceActiveFocus()
                      })
                    }

                    LeagueStatus {
                      id: leagueStatus
                      width: parent.width
                      height: modelData && modelData.kind === "status" ? implicitHeight : 0
                      visible: modelData && modelData.kind === "status"
                      status: statusValue
                      currentTime: root.nowMs
                      hasCursor: root.selectedRowId === modelData.rowId && !root.tabStripFocused
                      onRetry: root.refresh()
                      onContentFocusRequested: root.revealNotice(index)
                    }

                    StandingsStatus {
                      id: standingsStatus
                      width: parent.width
                      height: modelData && (modelData.kind === "standings-loading"
                        || modelData.kind === "standings-status" || modelData.kind === "standings-empty") ? implicitHeight : 0
                      visible: modelData && (modelData.kind === "standings-loading"
                        || modelData.kind === "standings-status" || modelData.kind === "standings-empty")
                      row: modelData
                      currentTime: root.nowMs
                      hasCursor: root.selectedRowId === modelData.rowId && !root.tabStripFocused
                      onRetry: root.refresh()
                      onContentFocusRequested: root.revealNotice(index)
                    }

                    LoadingState {
                      width: parent.width
                      height: modelData && modelData.kind === "loading" ? implicitHeight : 0
                      visible: modelData && modelData.kind === "loading"
                      retained: modelData && modelData.retained === true
                      labelText: modelData && modelData.label ? modelData.label : "Loading scores…"
                    }

                    BorderSurface {
                      id: emptyCard
                      width: parent.width
                      height: modelData && modelData.kind === "empty" ? emptyColumn.implicitHeight + Style.spacing.md * 2 : 0
                      visible: modelData && modelData.kind === "empty"
                      color: Util.alpha(Commons.Color.popups.background, 0.72)
                      borderSpec: Border.controlSpec("normal", Commons.Color.popups.text, Commons.Color.accent)
                      radius: Style.cornerRadius

                      Column {
                        id: emptyColumn
                        anchors.fill: parent
                        anchors.margins: Style.spacing.md
                        spacing: Style.spacing.xs

                        Text {
                          textFormat: Text.PlainText
                          width: parent.width
                          text: modelData.title || modelData.text || "No games on this date"
                          color: Commons.Color.popups.text
                          font.family: Typography.family
                          font.pixelSize: Style.font.subtitle
                          font.bold: Boolean(modelData.title)
                          wrapMode: Text.WordWrap
                        }

                        Text {
                          textFormat: Text.PlainText
                          width: parent.width
                          text: modelData.title ? modelData.text : ""
                          visible: text !== ""
                          color: Qt.alpha(Commons.Color.popups.text, 0.85)
                          font.family: Typography.family
                          font.pixelSize: Style.font.bodySmall
                          wrapMode: Text.WordWrap
                        }

                        Text {
                          textFormat: Text.PlainText
                          width: parent.width
                          text: modelData.supportingText || ""
                          visible: text !== ""
                          color: UiContrast.foreground(Commons.Color.accent, Commons.Color.popups.text, Commons.Color.popups.background)
                          font.family: Typography.family
                          font.pixelSize: Style.font.caption
                        }

                        SemanticActionButton {
                          id: emptyAction
                          visible: Boolean(modelData.action && modelData.action.enabled)
                          text: modelData.action ? modelData.action.label : ""
                          textBold: true
                          textFontSize: Style.font.bodySmall
                          bordered: true
                          focusable: true
                          onClicked: root.activateRow(index)
                          Accessible.name: modelData.action ? modelData.action.label : ""
                          Accessible.role: Accessible.Button
                        }
                      }
                    }

                    NextGameCard {
                      id: nextGameCard
                      width: parent.width
                      visible: modelData && modelData.kind === "next-game"
                      game: gameValue
                      dateKey: modelData.dateKey || ""
                      onJumpRequested: root.selectDate(modelData.dateKey)
                    }

                    StandingsRow {
                      id: standingsRow
                      width: parent.width
                      height: modelData && modelData.kind === "standings" ? implicitHeight : 0
                      visible: modelData && modelData.kind === "standings"
                      standing: modelData && modelData.standing ? modelData.standing : ({team: {}})
                      favorite: modelData && modelData.favorite === true
                      selected: root.selectedRowId === (modelData ? modelData.rowId : "")
                      settings: root.settingsStore
                      imageStore: root.logoImageStore
                      onTeamScheduleRequested: function(teamId) {
                        root.setSelectedRow(index)
                        root.resultActionFocus = "team:" + teamId
                        root.openTeamSchedule(teamId, root.resultActionFocus)
                      }
                    }
                  }

                  TapHandler {
                    // Qt pointer handlers observe child MouseAreas too. Disable this
                    // row handler for the duration of a nested action press so the
                    // child keeps the tap exclusively instead of also firing the row.
                    enabled: PointerInteractionPolicy.allowsRowActivation(parent.nestedActionPressed)
                    onTapped: {
                      if (!PointerInteractionPolicy.allowsRowActivation(parent.nestedActionPressed)) return
                      root.setSelectedRow(index)
                      if (modelData.kind !== "standings") root.activateRow(index)
                      else root.deferPanelCallback(function() {
                        if (!keyCatcher.blocked) keyCatcher.forceActiveFocus()
                      })
                    }
                  }

                  function activatePrimaryAction() {
                    if (modelData.kind === "game") gameRow.activatePrimaryAction()
                    else if (modelData.kind === "next-game") nextGameCard.activatePrimaryAction()
                    else if (modelData.kind === "status") leagueStatus.activatePrimaryAction()
                    else if (modelData.kind === "standings") standingsRow.activatePrimaryAction()
                    else if (modelData.action && modelData.action.type === "retry-standings")
                      root.refresh()
                    else if (modelData.action && modelData.action.type === "choose-teams")
                      root.openUtility("teams")
                    else if (modelData.action && modelData.action.type === "browse-leagues")
                      root.selectDestination(root.firstLeagueDestination())
                    else if (modelData.action && modelData.action.type === "retry")
                      root.refresh()
                  }

                  function openGameActions() {
                    if (modelData.kind !== "game") return false
                    gameRow.openActions()
                    return true
                  }
                  function restoreActionFocus(focusId) {
                    if (focusId.indexOf("team:") === 0) {
                      if (modelData.kind === "game") gameRow.focusTeam(focusId.slice(5))
                      else if (modelData.kind === "standings") standingsRow.focusTeam()
                    } else if (focusId === "actions" && modelData.kind === "game") gameRow.focusActions()
                  }
                  function moveNoticeCursor(delta) {
                    if (modelData.kind === "status") return leagueStatus.moveCursor(delta)
                    if (modelData.kind === "standings-status") return standingsStatus.moveCursor(delta)
                    return false
                  }
                  function activateNoticeCursor() {
                    if (modelData.kind === "status") leagueStatus.activateCursor()
                    else if (modelData.kind === "standings-status") standingsStatus.activateCursor()
                    root.revealNotice(index)
                  }
                }
              }

              // A refresh with retained games must not insert a row above the
              // slate. Keep the notice in the viewport chrome so polling
              // leaves the chooser and result positions stable.
              BorderSurface {
                id: refreshToast
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Style.spacing.sm
                visible: root.activeView && root.activeView.loading === true
                  && !root.actionFeedbackState
                  && root.resultRows.some(function(row) { return row.kind === "game" })
                  && !root.resultRows.some(function(row) { return row.kind === "status" })
                z: 2
                height: refreshToastRow.implicitHeight + Style.spacing.sm * 2
                color: Util.alpha(Commons.Color.popups.background, 0.94)
                borderSpec: Border.controlSpec("normal", Commons.Color.popups.text, Commons.Color.accent)
                radius: Style.cornerRadius

                Row {
                  id: refreshToastRow
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.leftMargin: Style.spacing.sm
                  anchors.rightMargin: Style.spacing.sm
                  spacing: Style.spacing.xs

                  SemanticIcon {
                    width: Style.space(18)
                    height: width
                    iconName: "refresh"
                    fontSize: Style.font.bodySmall
                    color: Commons.Color.accent
                    decorative: true
                  }

                  Text {
                    textFormat: Text.PlainText
                    width: parent.width - refreshToastRow.spacing - Style.space(18)
                    text: "Updating scores…"
                    color: Commons.Color.popups.text
                    font.family: Typography.family
                    font.pixelSize: Style.font.bodySmall
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                  }
                }

              Accessible.name: "Updating scores"
              Accessible.role: Accessible.StaticText
            }

          }

        }

          GameDetailView {
            id: gameDetailView
            imageStore: root.logoImageStore
            anchors.fill: parent
            visible: root.detailOpen && !root.scheduleOpen
            game: root.detailState.game
            updateMessage: root.detailState.message
            stale: root.detailState.stale
            loading: root.detailState.loading
            lastSuccessAt: root.detailState.lastSuccessAt
            settingsStore: root.settingsStore
            currentTime: root.ambientNowMs
            onBackRequested: root.closeDetail()
            onTeamScheduleRequested: function(teamId) { root.openTeamSchedule(teamId) }
            onRefreshRequested: root.refresh()
          }
        }
      }
    }
  }
}

import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Ui
import "components"
import "model/FavoritePresentation.js" as FavoritePresentation
import "model/BarPresentation.js" as BarPresentation
import "model/CalendarModel.js" as CalendarModel
import "model/Formatters.js" as Formatters
import "model/LiveFavoriteRotationPolicy.js" as LiveFavoriteRotationPolicy
import "model/PanelPresentation.js" as PanelPresentation
import "model/ResultRows.js" as ResultRows
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
  property string barRegion: ""
  property bool settingsOpen: false
  property bool standingsOpen: false
  property bool calendarOpen: false
  property bool calendarFavoritesOnly: false
  property string calendarLeagueId: ""
  property string calendarMonthKey: ""
  property bool detailOpen: false
  property var detailGame: null
  property string utilityReturnDestination: "following"
  property string settingsDestination: "sports"
  property string activeDestination: "following"
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
  readonly property var fetchService: root.service ? root.service.fetchService : null
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

  onCalendarOpenChanged: if (root.fetchService)
    root.fetchService.calendarOpen = root.calendarOpen

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
    FavoritePresentation.isFavoriteGame, root.followedLeagueIds, root.presentationRevision)
  readonly property var tabItems: buildTabItems()
  readonly property var sportOptions: buildSportOptions()
  readonly property var activeView: viewForDestination(root.activeDestination)
  readonly property var resultRows: ResultRows.flatten(
    root.activeView, root.activeDestination, root.selectedDateLabel)
  readonly property var standingsService: root.service ? root.service.standingsService : null
  readonly property var notificationService: root.service ? root.service.notificationService : null
  readonly property var standingsState: root.standingsService
    && typeof root.standingsService.snapshot === "function"
    ? root.standingsService.snapshot() : ({leagueId: "", groups: [], rows: [], hasData: false,
      loading: false, errorCode: "", errorSummary: ""})
  readonly property bool activeLeagueSupportsStandings: {
    var league = LeagueCatalog.getLeague(root.activeDestination)
    return Boolean(league && league.standingsSupported === true)
  }
  readonly property var standingsRows: StandingsRows.flatten(
    root.standingsState, root.favoriteTeamIds, root.standingsRevision)
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
  readonly property string barScoreText: buildBarScoreText()
  readonly property string barTooltipText: buildBarTooltipText()
  readonly property var verticalScoreLines: buildVerticalScoreLines()
  readonly property string todayDateKey: DateModel.localDateKey(new Date(root.nowMs))
  readonly property string selectedDateLabel: DateModel.displayLabel(
    root.selectedDateKey, root.todayDateKey)

  function refresh() {
    fetchService.requestRefresh("manual")
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
    if (root.standingsOpen) {
      root.standingsOpen = false
      root.recalculatePanelHeight()
    } else {
      root.openStandings()
    }
  }

  function openCalendar() {
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

  function openGameDetail(game) {
    if (!game || game.isValid !== true) return
    root.detailGame = game
    root.detailOpen = true
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
    if (root.detailOpen) {
      root.panelContentHeightRequest = PanelLayout.detailContentRequest(
        gameDetailView.implicitHeight,
        panel && panel.screen ? panel.screen.height : 0, {
          minimum: Style.space(320),
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
      if (!LifecyclePolicy.canRun(owner, generation)) return
      callback()
    })
  }

  function deferResultListCallback(callback) {
    if (typeof callback !== "function" || !resultList) return
    var panelOwner = root.callbackOwner
    var list = resultList
    var listOwner = list.callbackOwner
    var panelGeneration = LifecyclePolicy.captureGeneration(panelOwner)
    var listGeneration = LifecyclePolicy.captureGeneration(listOwner)
    Qt.callLater(function() {
      if (!LifecyclePolicy.canRun(panelOwner, panelGeneration)
          || !LifecyclePolicy.canRun(listOwner, listGeneration)) return
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
    if (root.calendarOpen) root.calendarMonthKey = CalendarModel.monthKey(dateKey)
    root.queuePanelHeightRecalculation()
    root.setSelectedDate(dateKey)
    root.selectedRowIndex = -1
    root.selectedRowId = ""
    var positions = Object.assign({}, root.scrollPositions || {})
    delete positions[root.activeDestination]
    root.scrollPositions = positions
    var selected = Object.assign({}, root.selectedRowIds || {})
    delete selected[root.activeDestination]
    root.selectedRowIds = selected
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
    if (destination === "following") return panelPresentation.following
    for (var i = 0; i < panelPresentation.leagues.length; i++) {
      if (panelPresentation.leagues[i].leagueId === destination) return panelPresentation.leagues[i]
    }
    return panelPresentation.following
  }

  function destinationIndex(destination) {
    for (var i = 0; i < root.tabItems.length; i++) {
      if (root.tabItems[i].id === destination) return i
    }
    return 0
  }

  function selectDestination(destination) {
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

  function moveTabCursor(delta) {
    if (root.tabItems.length === 0) return
    root.tabCursor = Math.max(0, Math.min(root.tabItems.length - 1, root.tabCursor + delta))
  }

  function activateTabCursor() {
    if (root.tabItems.length > 0) root.selectDestination(root.tabItems[root.tabCursor].id)
  }

  function saveResultPosition(destination) {
    if (!destination || !resultList) return
    var positions = Object.assign({}, root.scrollPositions || {})
    positions[destination] = resultList.contentY
    root.scrollPositions = positions

    var selected = Object.assign({}, root.selectedRowIds || {})
    selected[destination] = root.selectedRowId || ""
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
    root.selectedRowIndex = index
    root.selectedRowId = root.displayRows[index].rowId
    var selected = Object.assign({}, root.selectedRowIds || {})
    selected[root.activeDestination] = root.selectedRowId
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
    } else if (row.action.type === "open-detail") {
      root.openGameDetail(row.game)
    } else if (row.action.type === "open-source") {
      if (delegate && typeof delegate.activatePrimaryAction === "function")
        delegate.activatePrimaryAction()
    } else if (delegate && typeof delegate.activatePrimaryAction === "function") {
      delegate.activatePrimaryAction()
    } else if (row.action.type === "retry") {
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

  function restoreResultPosition() {
    var savedId = root.selectedRowIds && root.selectedRowIds[root.activeDestination]
      ? root.selectedRowIds[root.activeDestination] : ""
    var index = root.rowIndexForId(savedId)
    root.selectedRowId = savedId
    root.selectedRowIndex = index
    root.deferResultListCallback(function(list) {
      var savedY = root.scrollPositions && root.scrollPositions[root.activeDestination]
        ? root.scrollPositions[root.activeDestination] : 0
      if (index >= 0) list.positionViewAtIndex(index, ListView.Contain)
      else list.contentY = Math.max(0, Math.min(savedY, list.contentHeight - list.height))
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
    root.controller.show()
  }

  onOpenedChanged: {
    root.syncSharedContext()
    if (!root.opened) {
      if (root.fetchService && typeof root.fetchService.cancelCalendarSchedule === "function")
        root.fetchService.cancelCalendarSchedule()
      root.detailOpen = false
      root.detailGame = null
      return
    }
    root.nowMs = Date.now()
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
    root.selectedRowIndex = -1
    root.selectedRowId = ""
    root.deferPanelCallback(root.restoreResultPosition)
    root.deferPanelCallback(root.recalculatePanelHeight)
  }

  onActiveDestinationChanged: {
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
    root.deferPanelCallback(root.recalculatePanelHeight)
    root.syncSharedContext()
  }

  onTabItemsChanged: if (root.destinationIndex(root.activeDestination) === 0
                         && root.activeDestination !== "following")
    root.activeDestination = "following"

  function close() {
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
    root.utilityReturnDestination = root.activeDestination
    root.settingsDestination = destination || "sports"
    root.settingsOpen = true
    settingsHub.reset(root.settingsDestination)
    root.tabStripFocused = false
    utilityScroll.contentY = 0
    root.recalculatePanelHeight()
  }

  function closeUtility() {
    root.settingsOpen = false
    root.activeDestination = root.utilityReturnDestination
    root.tabCursor = root.destinationIndex(root.activeDestination)
    root.tabStripFocused = true
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
  }

  Component.onCompleted: {
    root.panelToken = root.service.registerPanel()
    root.syncSharedContext()
  }

  Component.onDestruction: {
    LifecyclePolicy.invalidate(root.callbackOwner)
    panelHeightSettleTimer.stop()
    panelClockTimer.stop()
    if (root.service && root.panelToken) root.service.unregisterPanel(root.panelToken)
  }

  Connections {
    target: settingsHub
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
    // transition; its default popup/bar backgrounds are identical in Omarchy's
    // current theme.
    centerOnBar: root.barRegion === "center"
    margin: 0
    gap: 0
    // The card is the panel surface itself, not a floating window frame. Keep
    // its fill and rounded shape while removing the popup outline at the bar.
    borderSpec: Border.none()
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.fittedContentHeight(root.panelContentHeightRequest, Style.space(640))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      // The installed catcher runs BeforeItem and otherwise consumes panel
      // navigation keys before an active editor can receive them. Let the
      // editor own all keys, including Escape, while it has focus.
      blocked: KeyboardRoutingPolicy.catcherBlocked(
        settingsHub.inputActive, sportsPicker.popupOpen)
      onCloseRequested: root.detailOpen ? root.closeDetail()
        : root.settingsOpen ? root.closeUtility()
        : root.calendarOpen ? root.closeCalendar() : root.close()
      onMoveRequested: function(dx, dy) {
        if (root.detailOpen) root.moveDetailCursor(dy !== 0 ? dy : dx)
        else if (root.settingsOpen) settingsHub.moveCursor(dx, dy)
        else if (root.calendarOpen) monthCalendar.moveFocus(dx, dy)
        else if (dx !== 0) {
          root.tabStripFocused = true
          root.moveTabCursor(dx)
        }
        else if (dy !== 0) { root.tabStripFocused = false; root.moveResultCursor(dy) }
      }
      onActivateRequested: {
        if (root.detailOpen) root.activateDetailCursor()
        else if (root.settingsOpen) settingsHub.activateCursor()
        else if (root.calendarOpen) monthCalendar.activateFocused()
        else if (root.tabStripFocused) root.activateTabCursor()
          else root.activateRow(root.selectedRowIndex)
      }
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(text) {
        if (settingsHub.inputActive) return
        if (root.detailOpen) return
        if (text === "r" || text === "R") root.refresh()
        if (text === "n" || text === "N") root.openSettings()
        if ((text === "c" || text === "C") && !root.settingsOpen && !root.detailOpen)
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
        if (text === "[" || text === "{") root.selectRelativeDate(-1)
        if (text === "]" || text === "}") root.selectRelativeDate(1)
        if (text === "t" || text === "T") root.selectDate(root.todayDateKey)
      }

      // PanelKeyCatcher owns arrows, tab, activation, Escape, and text keys.
      // Keep only the extra viewport navigation keys here; the installed
      // Omarchy handler does not emit semantic signals for these keys.
      Keys.onPressed: function(event) {
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
          height: Math.max(headerTitle.implicitHeight, headerActions.implicitHeight)

          Text {
            id: headerTitle
            anchors.left: parent.left
            anchors.right: headerActions.left
            anchors.rightMargin: header.spacing
            height: parent.height
            text: (Iconography.displayText(
              root.settingsOpen ? "settings" : root.detailOpen ? "scores" : "calendar",
              Style.font.family) || "S")
            + (root.settingsOpen ? "  Settings"
              : root.detailOpen ? "  Game details"
              : root.calendarOpen ? "  Calendar"
              : root.standingsOpen ? "  Standings" : "  " + root.selectedDateLabel)
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            color: Color.accent
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
            id: todayButton
            visible: !root.settingsOpen && !root.detailOpen
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
            visible: !root.settingsOpen && !root.detailOpen && root.activeLeagueSupportsStandings
            iconName: root.standingsOpen ? "scores" : "list"
            fallbackText: root.standingsOpen ? "S" : "T"
            tooltipText: root.standingsOpen ? "Show scores" : "Show standings"
            text: header.compactActions ? "" : (root.standingsOpen ? "Scores" : "Table")
            textFontSize: Style.font.caption
            textBold: true
            textVerticalPadding: Style.spacing.controlPaddingY / 2
            width: root.standingsOpen ? Style.space(62) : Style.space(54)
            height: refreshButton.implicitHeight
            focusable: true
            onClicked: root.toggleStandings()
            Accessible.name: root.standingsOpen ? "Show scores" : "Show standings"
            Accessible.role: Accessible.Button
            }

            SemanticActionButton {
            id: calendarButton
            visible: !root.settingsOpen && !root.detailOpen
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
            visible: !root.settingsOpen && !root.detailOpen
            iconName: "refresh"
            fallbackText: fetchService.loading ? "..." : "R"
            tooltipText: fetchService.loading ? "Refreshing scores" : "Refresh scores"
            enabled: !fetchService.loading
            focusable: true
            onClicked: root.refresh()
            Accessible.name: fetchService.loading ? "Refreshing scores" : "Refresh scores"
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
              visible: !root.settingsOpen && !root.detailOpen
              clip: true

            SportAtmosphere {
              id: sportAtmosphere
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              height: Math.min(parent.height, Style.space(136))
              leagueId: root.activeDestination
              visible: !root.settingsOpen && !root.detailOpen
              z: 0
            }

            Column {
              id: scoreChrome
              width: parent.width
              spacing: Style.spacing.md
              z: 1

              DateCarousel {
                id: dateCarousel
                width: parent.width
                visible: !root.calendarOpen
                height: root.calendarOpen ? 0 : implicitHeight
                selectedDateKey: root.selectedDateKey
                compact: parent.width < Style.space(360)
                onDateSelected: function(dateKey) { root.selectDate(dateKey) }
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
                height: visible ? sportsPicker.implicitHeight : 0
                visible: !root.calendarOpen

                Item {
                  id: sportChooser
                  anchors.fill: parent

                  SemanticIcon {
                    id: activeSportIcon
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: Style.space(28)
                    height: parent.height
                    iconName: Iconography.iconNameForLeague(root.activeDestination)
                    fontSize: Style.font.subtitle
                    color: Color.accent
                    decorative: true
                  }

                  Dropdown {
                    id: sportsPicker
                    anchors.left: activeSportIcon.right
                    anchors.leftMargin: Style.spacing.sm
                    anchors.right: parent.right
                    height: parent.height
                    value: root.activeDestination
                    options: root.sportOptions
                    showLabel: false
                    hasCursor: root.tabStripFocused
                    Accessible.name: "Choose sport"
                    onChanged: function(value) {
                      root.selectDestination(value)
                    }
                  }
                }
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
                readonly property var callbackOwner: LifecyclePolicy.createOwnerState()
                anchors.fill: parent
                model: root.displayRows
                currentIndex: root.selectedRowIndex
                spacing: Style.spacing.md
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                onCurrentIndexChanged: if (currentIndex >= 0)
                  root.deferResultListCallback(function(list) {
                    list.positionViewAtIndex(currentIndex, ListView.Contain)
                  })

                Component.onDestruction: LifecyclePolicy.invalidate(callbackOwner)

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
                    leagueStatus.pointerPressed,
                    nextGameCard.childActionPressed,
                    emptyAction.pointerPressed,
                    standingsRow.childActionPressed)

                  Column {
                    id: rowColumn
                    width: parent.width
                    spacing: modelData.kind === "game" ? 0 : Style.spacing.sm

                    Text {
                      width: parent.width
                      // Do not bind a QQuickText height to its own
                      // implicitHeight. The delegate's bounded row height
                      // makes that self-dependency surface as a runtime loop.
                      height: visible ? font.pixelSize : 0
                      visible: modelData && modelData.kind === "section-header"
                      text: modelData.label || "Scores"
                      color: Color.accent
                      font.family: Style.font.family
                      font.pixelSize: Style.font.caption
                      font.bold: true
                    }

                    Text {
                      width: parent.width
                      height: visible ? font.pixelSize : 0
                      visible: modelData && modelData.kind === "standings-section"
                      text: modelData.label || "Standings"
                      color: Color.accent
                      font.family: Style.font.family
                      font.pixelSize: Style.font.caption
                      font.bold: true
                    }

                    GameRow {
                      id: gameRow
                      width: parent.width
                      height: visible ? implicitHeight : 0
                      visible: modelData && modelData.kind === "game"
                      game: gameValue
                      settingsStore: root.settingsStore
                      currentTime: root.ambientNowMs
                      stale: modelData && modelData.stale === true
                      startTimeTextOverride: modelData
                        && typeof modelData.timeLabel === "string"
                        ? modelData.timeLabel : ""
                      selected: root.selectedRowId === (modelData ? modelData.rowId : "")
                      featured: Boolean(gameValue.presentation
                        && gameValue.presentation.isFavorite
                        && gameValue.presentation.isLive)
                      onPrimaryActionRequested: root.openGameDetail(gameValue)
                    }

                    LeagueStatus {
                      id: leagueStatus
                      width: parent.width
                      height: visible ? implicitHeight : 0
                      visible: modelData && modelData.kind === "status"
                      status: statusValue
                      onRetry: root.refresh()
                    }

                    LoadingState {
                      width: parent.width
                      height: visible ? implicitHeight : 0
                      visible: modelData && modelData.kind === "loading"
                      retained: modelData && modelData.retained === true
                      labelText: modelData && modelData.label ? modelData.label : "Loading scores…"
                    }

                    BorderSurface {
                      id: emptyCard
                      width: parent.width
                      height: visible ? emptyColumn.implicitHeight + Style.spacing.md * 2 : 0
                      visible: modelData && modelData.kind === "empty"
                      color: Util.alpha(Color.popups.background, 0.72)
                      borderSpec: Border.controlSpec("normal", Color.popups.text, Color.accent)
                      radius: Style.cornerRadius

                      Column {
                        id: emptyColumn
                        anchors.fill: parent
                        anchors.margins: Style.spacing.md
                        spacing: Style.spacing.xs

                        Text {
                          width: parent.width
                          text: modelData.title || modelData.text || "No games on this date"
                          color: Color.popups.text
                          font.family: Style.font.family
                          font.pixelSize: Style.font.subtitle
                          font.bold: Boolean(modelData.title)
                          wrapMode: Text.WordWrap
                        }

                        Text {
                          width: parent.width
                          text: modelData.title ? modelData.text : ""
                          visible: text !== ""
                          color: Color.muted
                          font.family: Style.font.family
                          font.pixelSize: Style.font.bodySmall
                          wrapMode: Text.WordWrap
                        }

                        Text {
                          width: parent.width
                          text: modelData.supportingText || ""
                          visible: text !== ""
                          color: Color.accent
                          font.family: Style.font.family
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
                      height: visible ? implicitHeight : 0
                      visible: modelData && modelData.kind === "standings"
                      standing: modelData && modelData.standing ? modelData.standing : ({team: {}})
                      favorite: modelData && modelData.favorite === true
                      selected: root.selectedRowId === (modelData ? modelData.rowId : "")
                      settings: root.settingsStore
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
                      root.activateRow(index)
                    }
                  }

                  function activatePrimaryAction() {
                    if (modelData.kind === "game") gameRow.activatePrimaryAction()
                    else if (modelData.kind === "next-game") nextGameCard.activatePrimaryAction()
                    else if (modelData.kind === "status") leagueStatus.activatePrimaryAction()
                    else if (modelData.kind === "standings") standingsRow.activatePrimaryAction()
                    else if (modelData.action && modelData.action.type === "choose-teams")
                      root.openUtility("teams")
                    else if (modelData.action && modelData.action.type === "browse-leagues")
                      root.selectDestination(root.firstLeagueDestination())
                    else if (modelData.action && modelData.action.type === "retry")
                      root.refresh()
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
                  && root.resultRows.some(function(row) { return row.kind === "game" })
                z: 2
                height: refreshToastRow.implicitHeight + Style.spacing.sm * 2
                color: Util.alpha(Color.popups.background, 0.94)
                borderSpec: Border.controlSpec("normal", Color.popups.text, Color.accent)
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
                    color: Color.accent
                    decorative: true
                  }

                  Text {
                    width: parent.width - refreshToastRow.spacing - Style.space(18)
                    text: "Refreshing scores…"
                    color: Color.popups.text
                    font.family: Style.font.family
                    font.pixelSize: Style.font.bodySmall
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                  }
                }

              Accessible.name: "Refreshing scores"
              Accessible.role: Accessible.StaticText
            }

          }

        }

          GameDetailView {
            id: gameDetailView
            anchors.fill: parent
            visible: root.detailOpen
            game: root.detailGame
            settingsStore: root.settingsStore
            currentTime: root.ambientNowMs
            onBackRequested: root.closeDetail()
          }
        }
      }
    }
  }
}

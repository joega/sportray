import QtQuick
import QtQuick.Window
import QtTest as Test
import Quickshell
import qs.Commons as Commons
import "../.." as Plugin
import "../../components" as Components
import "../../model/SettingsModel.js" as SettingsModel
import "../../model/DateModel.js" as DateModel
import "../../providers/NhlTeamCatalog.js" as NhlTeamCatalog
import "../../providers/EspnTeamCatalog.js" as EspnTeamCatalog

// Capture current native views with illustrative state. No shared worker is
// acquired, no provider request/notification is started, and no settings persist.
ShellRoot {
  id: root
  property var sample: null
  property var logoSources: ({})
  property var uiCase: ({name: "light", width: 400, fontSize: 12})
  readonly property double demoNow: sample ? Date.parse(sample.now) : 0

  function readJson(path) { return JSON.parse(readText(path)) }
  function readText(path) {
    var request = new XMLHttpRequest()
    request.open("GET", Qt.resolvedUrl(path), false)
    request.send()
    if (!request.responseText) throw new Error("Empty capture input: " + path)
    return request.responseText
  }

  QtObject {
    id: store
    property bool ready: true
    property string preservedRawStateText: ""
    property var settings: root.sample ? root.sample.settings : SettingsModel.createDefaults()
    property var watchedGames: []
    property int watchCalls: 0
    property int favoriteCalls: 0
    property var tickerCalls: []
    property var leagueCalls: []
    function toggleLeague(league) {
      leagueCalls = leagueCalls.concat([league])
      settings = SettingsModel.toggleLeague(settings, league)
      return true
    }
    function setTicker(key, value) {
      tickerCalls = tickerCalls.concat([{key: key, value: value}])
      settings = Object.assign({}, settings,
        {ticker: Object.assign({}, settings.ticker, {[key]: value})})
    }
    function isLeagueEnabled(league) { return settings.enabledLeagues.indexOf(league) !== -1 }
    function toggleWatch(game) {
      watchCalls++
      return true
    }
    function toggleFavoriteTeam(id) {
      favoriteCalls++
      var ids = settings.favoriteTeamIds.slice()
      var index = ids.indexOf(id)
      if (index === -1) ids.push(id)
      else ids.splice(index, 1)
      settings = Object.assign({}, settings, {favoriteTeamIds: ids})
      return true
    }
  }
  QtObject {
    id: fetch
    property var leagueStates: root.sample ? root.sample.settings.enabledLeagues.map(function(league) {
      return {leagueId: league, displayName: league.toUpperCase(),
        games: root.sample.games.filter(function(game) { return game.league === league }),
        // Retained NHL rows plus its notice exercise mixed delegate geometry
        // when detail/settings temporarily hide the entire score surface.
        hasData: true, loading: false, stale: league === "nhl",
        errorCode: league === "nhl" ? "unavailable" : "",
        errorSummary: league === "nhl" ? "Fixture interruption" : "",
        partialErrorCount: 0, lastSuccessAt: root.sample.now, lastAttemptAt: root.sample.now,
        nextGame: null, nextGameDateKey: "", nextGameStatus: "idle"}
    }) : []
    property var games: root.sample ? root.sample.games : []
    property bool hasData: true
    property bool loading: false
    property string errorCode: ""
    property string errorSummary: ""
    property bool calendarOpen: false
    property var calendarStates: []
    property int calendarStatesRevision: 0
    property bool calendarCacheReady: true
    property bool calendarRehydrating: false
    property string calendarRehydrationStatus: "idle"
    property int calendarRehydrationCompleted: 0
    property int calendarRehydrationTotal: 0
    property int refreshCalls: 0
    function requestRefresh(reason) { refreshCalls++; return true }
    function cancelCalendarSchedule() {}
    property var upcomingRequests: []
    property var globalRequests: []
    property var upcomingCancellations: []
    property var upcomingState: ({owner: "", teamId: "", loading: false, hasData: false,
      partial: false, stale: false, entries: [], errorSummary: "", coverageStart: "", coverageEnd: ""})
    function requestUpcoming(owner, teamId, first, last, force) {
      upcomingRequests = upcomingRequests.concat([{owner: owner, teamId: teamId,
        startDate: first, endDate: last, force: force === true}])
      var original = root.sample.games.filter(function(game) {
        return game.awayTeam.id === teamId || game.homeTeam.id === teamId
      })[0]
      if (!original) {
        // Admit any canonical enabled catalog team, including a nonfavorite
        // opponent absent from today's score fixture. Never change preferences.
        var catalog = NhlTeamCatalog.listTeams()
        store.settings.enabledLeagues.forEach(function(league) {
          if (league !== "nhl") catalog = catalog.concat(EspnTeamCatalog.listTeams(league))
        })
        var team = catalog.filter(function(value) { return value.id === teamId })[0]
        if (!team) return false
        var leagueGame = root.sample.games.filter(function(game) { return game.league === team.league })[0]
        if (!leagueGame) return false
        original = JSON.parse(JSON.stringify(leagueGame))
        original.awayTeam = team
      }
      var entries = [21, 22, 23, 24, 25, 26, 28, 30].map(function(distance, index) {
        var date = DateModel.addDays(root.sample.dateKey, distance)
        var game = JSON.parse(JSON.stringify(original))
        game.id = game.league + ":calendar-fixture-" + index
        game.providerGameId = "calendar-fixture-" + index
        game.startTime = date + "T20:00:00Z"
        game.endTime = null
        game.status = "scheduled"
        game.statusDetail = null
        game.period = 0
        game.periodLabel = null
        game.clock = null
        game.awayScore = null
        game.homeScore = null
        return {game: game, dateKey: date, timeKnown: index === 0}
      }).filter(function(entry) { return entry.dateKey >= first && entry.dateKey <= last })
      upcomingState = {owner: owner, scope: "team", teamId: teamId, loading: false, hasData: true,
        partial: false, stale: false, entries: entries, errorSummary: "",
        coverageStart: first, coverageEnd: last, coverageComplete: true, lastSuccessAt: root.sample.now}
      return true
    }
    function requestGlobalCalendar(owner, dateKey, force) {
      var followed = store.settings.followedLeagueIds.filter(function(id) {
        return store.settings.enabledLeagues.indexOf(id) !== -1
      })
      globalRequests = globalRequests.concat([{owner: owner, dateKey: dateKey,
        leagues: followed.slice(), force: force === true}])
      var entries = root.sample.games.filter(function(game) {
        return followed.indexOf(game.league) !== -1
      }).map(function(original, index) {
        var game = JSON.parse(JSON.stringify(original))
        game.id = game.league + ":global-ui-" + index
        game.providerGameId = "global-ui-" + index
        game.startTime = dateKey + "T20:00:00Z"
        return {game: game, dateKey: dateKey, timeKnown: true}
      })
      upcomingState = {owner: owner, scope: "global", teamId: "", dateKey: dateKey,
        loading: false, hasData: followed.length > 0, partial: followed.length > 0,
        failed: false, stale: false, entries: entries,
        daySummaries: followed.length ? [{dateKey: dateKey, count: entries.length,
          loaded: true, partial: true, stale: false, complete: false}] : [],
        errorSummary: followed.length ? "Listed games from followed leagues. Some schedules may be incomplete."
          : "Follow a league in Sports & leagues to see its games here.",
        coverageStart: dateKey, coverageEnd: dateKey, coverageComplete: false}
      return true
    }
    function cancelUpcoming(owner) {
      upcomingCancellations = upcomingCancellations.concat([owner])
      upcomingState = Object.assign({}, upcomingState, {loading: false})
      return true
    }
  }
  QtObject {
    id: table
    property string leagueId: "nhl"
    property var groups: root.sample ? root.sample.standings.groups : []
    property var rows: root.sample ? root.sample.standings.rows : []
    property bool hasData: true
    property bool loading: false
    property bool stale: false
    property string errorCode: ""
    property string errorSummary: ""
    property string lastSuccessAt: root.sample ? root.sample.now : ""
    function load(league, force) { leagueId = league; return true }
    property int refreshCalls: 0
    function refresh(league) { refreshCalls++; return load(league, true) }
    function snapshot() { return {leagueId: leagueId, groups: groups, rows: rows, hasData: hasData,
      loading: loading, stale: stale, errorCode: errorCode, errorSummary: errorSummary, lastSuccessAt: lastSuccessAt} }
  }
  QtObject { id: alerts; function sendTestNotification() {} }
  QtObject { id: logos; function sourceFor(url) { return root.logoSources[url] || "" } }
  QtObject {
    id: service
    property var settingsStore: store
    property var fetchService: fetch
    property var standingsService: table
    property var notificationService: alerts
    property var logoImageStore: logos
    property bool calendarFeatureEnabled: false
    property double nowMs: root.demoNow
    property string todayDateKey: root.sample ? root.sample.dateKey : ""
    property string selectedDateKey: todayDateKey
    function registerPanel() { return "readme" }
    function updatePanel(token, open, league) {}
    function unregisterPanel(token) {}
  }

  // Full production Panel presentation in the existing capture-only host. The
  // real Wayland PanelWindow, providers and persistent settings are excluded.
  Window {
    id: window
    visible: true
    width: root.uiCase.width
    height: 640
    color: Commons.Color.popups.background
    Item { id: surface; anchors.fill: parent }
    Timer { interval: 300; running: true; onTriggered: checks.run() }
    Test.TestCase {
      id: checks
      when: false

      function check(value, message) { if (!value) throw new Error(message || "Verification failed") }
      function same(actual, expected, message) {
        if (actual !== expected) throw new Error((message || "Values differ") + ": " + actual + " != " + expected)
      }
      function items(object, predicate, seen, found) {
        if (!object || seen.indexOf(object) !== -1 || seen.length > 6000) return found
        seen.push(object)
        if (predicate(object)) found.push(object)
        var keys = ["children", "contentItem", "data"]
        for (var k = 0; k < keys.length; k++) {
          var value = object[keys[k]]
          if (!value) continue
          if (typeof value.length === "number") {
            for (var i = 0; i < value.length; i++) items(value[i], predicate, seen, found)
          } else items(value, predicate, seen, found)
        }
        return found
      }
      function findAll(object, predicate) { return items(object, predicate, [], []) }
      function find(object, predicate) { var result = findAll(object, predicate); return result.length ? result[0] : null }
      function textItem(object, value) {
        return find(object, function(item) { return "text" in item && item.text === value && item.visible })
      }
      function capture(name, item) {
        var done = false, saved = false
        ;(item || surface).grabToImage(function(result) {
          saved = result.saveToFile(Quickshell.env("SPORTRAY_TEST_CAPTURE") + "/" + name + ".png")
          done = true
        })
        tryVerify(function() { return done }, 5000)
        check(saved, "Could not save " + name)
      }
      function settle(panel) {
        panel.testClock.stop()
        panel.nowMs = root.demoNow
        panel.panelHeightRecalculationPending = false
        wait(300)
        // Keep the fixture viewport fixed while exercising production content.
        panel.testHost.contentHeight = 640
        wait(40)
      }
      function naturalKey(panel, value) {
        // Preserve the actual editor/popup/catcher focus owner. This is used
        // for handoff tests so forcing focus cannot hide an unreachable route.
        keyClick(value)
        settle(panel)
      }
      function key(panel, value) {
        panel.testCatcher.forceActiveFocus()
        naturalKey(panel, value)
      }
      function visibleGame(panel, league) {
        var list = panel.testList
        for (var i = 0; i < panel.displayRows.length; i++) {
          if (panel.displayRows[i].kind !== "game" || (league && panel.displayRows[i].game.league !== league)) continue
          list.positionViewAtIndex(i, ListView.Beginning)
          wait(60)
          var delegate = list.itemAtIndex(i)
          var row = find(delegate, function(item) { return "awayLabel" in item && "childActionPressed" in item && item.visible })
          if (row) return {index: i, row: row}
        }
        check(false, "No visible rendered game row")
      }
      function rowViewportY(panel, rowId) {
        // ListView's origin/contentY may shift as virtual rows are measured.
        // The canonical row's rendered position is the user's scroll context.
        var index = panel.displayRows.findIndex(function(row) { return row.rowId === rowId })
        check(index >= 0, "Restored row no longer exists: " + rowId)
        var delegate = panel.testList.itemAtIndex(index)
        check(delegate !== null, "Restored row is outside the rendered viewport: " + rowId)
        return delegate.mapToItem(panel.testList, 0, 0).y
      }
      function checkScheduleSurface(panel, heading) {
        var page = panel.testSchedulePage
        check(panel.scheduleOpen && page.visible, "Schedule did not become the visible panel destination: "
          + JSON.stringify({open: panel.scheduleOpen, visible: page.visible, parentVisible: page.parent.visible,
            settings: panel.settingsOpen, details: panel.detailOpen, opened: panel.opened,
            parentHeight: page.parent.height, height: page.height}))
        check(!panel.testScoreContent.visible, "Scores remain visible behind the schedule page")
        check(!panel.testDetail.visible, "Game details remain visible behind the schedule page")
        same(panel.testHeaderTitle.text, heading, "Schedule did not own the shared header")
        same(findAll(panel, function(item) {
          return item.visible && "text" in item && item.text === heading
        }).length, 1, "Schedule has a duplicate title")
        var point = page.mapToItem(window.contentItem, 0, 0)
        check(page.width > 0 && page.height > 0 && point.x >= -1 && point.y >= -1
          && point.x + page.width <= window.width + 1 && point.y + page.height <= window.height + 1,
          "Schedule page exceeds the shared panel body")
        check(!panel.gameActionsOpen, "Game actions remain open over the schedule page")
      }
      function checkSchedulePage(panel) {
        var calendar = panel.testUpcomingCalendar
        var originalDate = panel.selectedDateKey
        var originalRowId = panel.selectedRowId
        var originalScrollOffset = panel.testList.contentY - panel.testList.originY
        var futureDate = DateModel.addDays(root.sample.dateKey, 21)
        var calls = fetch.refreshCalls
        var cancels = fetch.upcomingCancellations.length
        check(panel.testCalendarButton.visible, "Calendar button is unavailable")
        naturalKey(panel, Qt.Key_G)
        check(panel.scheduleOpen && panel.opened && calendar.globalMode, "G must open the global calendar: "
          + JSON.stringify({schedule: panel.scheduleOpen, opened: panel.opened,
            globalMode: calendar.globalMode, team: panel.upcomingTeamId, settings: panel.settingsOpen,
            details: panel.detailOpen, standings: panel.standingsOpen, focus: panel.testCatcher.activeFocus,
            blocked: panel.testCatcher.blocked, history: panel.navigationStack}))
        check(panel.testCatcher.blocked, "Calendar did not take keyboard ownership")
        check(calendar.width > 0 && calendar.width <= root.uiCase.width, "Calendar exceeds viewport width")
        checkScheduleSurface(panel, "Calendar")
        same(fetch.upcomingRequests.length, 0, "Default global calendar requested a favorite-team schedule")
        check(fetch.globalRequests.length > 0, "Global calendar did not request its selected day")
        same(fetch.globalRequests[0].leagues.join(","), store.settings.followedLeagueIds.join(","),
          "Global calendar must admit followed leagues independently of favorites")
        same(calendar.selectedDateKey, originalDate)
        check(calendar.globalDayLoaded && calendar.agendaEntries.length > 0, "Global selected-day agenda missing")
        check(findAll(calendar, function(item) { return item.visible && "selectedDay" in item }).length === 42,
          "Global calendar must show its complete month grid")
        capture("calendar-global", window.contentItem)
        var leaguesAction = find(panel, function(item) {
          return item.visible && "tooltipText" in item && item.tooltipText === "Choose followed leagues"
        })
        check(leaguesAction !== null, "Global calendar lost its shared-header Leagues action")
        mouseClick(leaguesAction, leaguesAction.width / 2, leaguesAction.height / 2,
          Qt.LeftButton, Qt.NoModifier, 20)
        settle(panel)
        check(panel.settingsOpen && !panel.testSchedulePage.visible,
          "Calendar Leagues did not hand the panel to Settings")
        same(panel.testHub.destination, "sports", "Leagues opened the wrong settings destination")
        naturalKey(panel, Qt.Key_Escape)
        checkScheduleSurface(panel, "Calendar")
        same(calendar.selectedDateKey, originalDate, "Leagues Settings return lost the preview day")
        var refreshSchedule = find(panel, function(item) {
          return item.visible && "tooltipText" in item && item.tooltipText === "Refresh schedule"
        })
        check(refreshSchedule !== null, "Schedule has no context-specific header refresh")
        var beforeRefresh = fetch.globalRequests.length
        mouseClick(refreshSchedule, refreshSchedule.width / 2, refreshSchedule.height / 2,
          Qt.LeftButton, Qt.NoModifier, 20)
        settle(panel)
        check(fetch.globalRequests.length > beforeRefresh
          && fetch.globalRequests[fetch.globalRequests.length - 1].force === true,
          "Schedule header refresh did not update its current day")
        same(fetch.refreshCalls, calls, "Schedule header refresh updated hidden scores")
        mouseMove(window.contentItem, 2, window.height - 2, 20)
        naturalKey(panel, Qt.Key_BracketLeft)
        naturalKey(panel, Qt.Key_BracketRight)
        naturalKey(panel, Qt.Key_T)
        naturalKey(panel, Qt.Key_S)
        naturalKey(panel, Qt.Key_R)
        same(panel.selectedDateKey, originalDate, "Schedule text keys changed hidden score date")
        check(!panel.standingsOpen && !panel.settingsOpen, "Schedule keys changed a hidden panel route")
        same(fetch.refreshCalls, calls, "Schedule R refreshed hidden scores")
        var requestCount = fetch.globalRequests.length
        naturalKey(panel, Qt.Key_Right)
        same(fetch.globalRequests.length, requestCount, "Moving a date cursor must not request that day yet")
        naturalKey(panel, Qt.Key_Return)
        var previewDate = DateModel.addDays(originalDate, 1)
        same(calendar.selectedDateKey, previewDate, "Enter did not preview the focused day")
        same(panel.selectedDateKey, originalDate, "Day preview committed the score date")
        var originalMonth = calendar.displayedMonthKey
        naturalKey(panel, Qt.Key_PageDown)
        check(calendar.displayedMonthKey !== originalMonth, "PageDown did not browse global month")
        same(calendar.selectedDateKey, calendar.displayedMonthKey, "Month navigation must preview its first day")
        same(panel.selectedDateKey, originalDate, "Month preview changed hidden score date")
        var globalJump = find(calendar, function(item) {
          return item.visible && "tooltipText" in item && item.tooltipText === "Open scores for the selected date"
        })
        check(globalJump !== null, "Global calendar has no View day")
        for (var tab = 0; tab < 20 && !globalJump.activeFocus; tab++) naturalKey(panel, Qt.Key_Tab)
        check(globalJump.activeFocus, "Global View day is not reachable by native Tab")
        var committedDate = calendar.selectedDateKey
        naturalKey(panel, Qt.Key_Return)
        check(!panel.scheduleOpen && panel.opened, "Global View day must return to scores")
        same(panel.selectedDateKey, committedDate)
        same(panel.activeDestination, "following", "Global View day must open Following")
        naturalKey(panel, Qt.Key_Escape)
        check(panel.scheduleOpen && calendar.globalMode, "Back from View day did not restore global calendar")
        same(calendar.selectedDateKey, committedDate, "Back lost preview date")
        naturalKey(panel, Qt.Key_Escape)
        check(!panel.scheduleOpen && panel.opened, "Calendar Escape did not restore scores")
        same(panel.selectedDateKey, originalDate)
        same(panel.selectedRowId, originalRowId, "Calendar Back changed score selection")
        if (!originalRowId) check(Math.abs(panel.testList.contentY - panel.testList.originY - originalScrollOffset) < 1,
          "Calendar Back lost unselected normalized scroll position")

        // Native focus traverses the selector, featured Next, controls and all
        // later rows. No direct focus calls or programmatic page opening.
        naturalKey(panel, Qt.Key_G)
        check(calendar.globalMode, "Every G opening must start in global mode")
        var teamPicker = find(calendar, function(item) {
          return item.visible && "popupOpen" in item && "options" in item
        })
        check(teamPicker !== null && teamPicker.options[0].value === "", "Global selector option missing")
        naturalKey(panel, Qt.Key_Tab)
        naturalKey(panel, Qt.Key_Return)
        check(teamPicker.popupOpen && panel.scheduleOpen, "Native Tab/Enter cannot open schedule selector")
        var expectedTeam = teamPicker.options[1].value
        keyClick(Qt.Key_Down)
        keyClick(Qt.Key_Return)
        settle(panel)
        same(calendar.teamId, expectedTeam)
        check(!calendar.globalMode && !teamPicker.popupOpen && panel.scheduleOpen, "Team selection lost schedule-page ownership")
        checkScheduleSurface(panel, "Team schedule")
        same(fetch.upcomingState.scope, "team")
        check(fetch.upcomingRequests.every(function(request) {
          return request.owner === panel.panelToken && request.teamId
            && DateModel.calendarDistance(request.endDate, request.startDate) === 34
        }), "Team intents are not owner-scoped 35-day windows")
        check(findAll(calendar, function(item) { return item.visible && "selectedDay" in item }).length === 0,
          "Team agenda must not retain a visible month grid")
        same(calendar.selectedDateKey, root.sample.dateKey, "Team schedule must anchor at Today")
        same(calendar.nextEntry.dateKey, futureDate, "Featured Next did not bridge the21-day/month gap")
        same(calendar.agendaEntries.length, 7, "Team agenda silently truncated later games")
        var jump = find(calendar, function(item) {
          return item.visible && "tooltipText" in item && item.tooltipText === "Jump to the next listed game"
        })
        var nextRange = find(calendar, function(item) {
          return item.visible && "tooltipText" in item && item.tooltipText === "Next 35 days"
        })
        check(jump && nextRange && jump.mapToItem(calendar, 0, 0).y < nextRange.mapToItem(calendar, 0, 0).y,
          "Featured Next must precede range controls")
        capture("upcoming", window.contentItem)
        var lastDate = calendar.agendaEntries[calendar.agendaEntries.length - 1].dateKey
        var lastRow = find(calendar, function(item) {
          return item.visible && item.activeFocusOnTab && "modelData" in item
            && item.modelData && item.modelData.dateKey === lastDate
        })
        check(lastRow !== null, "Last later game was not rendered")
        for (tab = 0; tab < 25 && !lastRow.activeFocus; tab++) naturalKey(panel, Qt.Key_Tab)
        check(lastRow.activeFocus, "Later game beyond the sixth is unreachable by native Tab")
        var point = lastRow.mapToItem(window.contentItem, 0, 0)
        check(point.y >= -1 && point.y + lastRow.height <= window.height + 1,
          "Last focused agenda row is outside the schedule viewport")
        var agendaContext = calendar.captureContext()
        panel.openUtility("notifications")
        settle(panel)
        naturalKey(panel, Qt.Key_Escape)
        check(panel.scheduleOpen && calendar.teamId === expectedTeam, "Settings lost team agenda")
        var restoredAgenda = calendar.captureContext()
        same(restoredAgenda.focusKind, agendaContext.focusKind, "Settings lost agenda focus kind")
        same(restoredAgenda.gameId, agendaContext.gameId, "Settings lost focused agenda game")
        check(Math.abs(restoredAgenda.scrollY - agendaContext.scrollY) < 1, "Settings lost agenda scroll")
        naturalKey(panel, Qt.Key_PageDown)
        same(calendar.windowStartKey, DateModel.addDays(originalDate, 35), "Team PageDown did not browse35days")
        same(panel.selectedDateKey, originalDate)
        naturalKey(panel, Qt.Key_PageUp)
        same(calendar.nextEntry.dateKey, futureDate)
        for (tab = 0; tab < 25 && !jump.activeFocus; tab++) naturalKey(panel, Qt.Key_Tab)
        check(jump.activeFocus, "Team View day is unreachable by native Tab")
        naturalKey(panel, Qt.Key_Return)
        check(!panel.scheduleOpen && panel.opened, "Team View day must return to scores")
        same(panel.selectedDateKey, futureDate)
        same(panel.activeDestination, expectedTeam.split(":")[0], "Team View day must select its league")
        naturalKey(panel, Qt.Key_Escape)
        check(panel.scheduleOpen && calendar.teamId === expectedTeam, "Back from team View day lost team agenda")
        same(calendar.nextEntry.dateKey, futureDate)
        naturalKey(panel, Qt.Key_Escape)
        same(panel.selectedDateKey, originalDate)
        naturalKey(panel, Qt.Key_G)
        check(calendar.globalMode && panel.scheduleOpen, "Team selection leaked into next global opening")
        naturalKey(panel, Qt.Key_Escape)
        check(!panel.scheduleOpen && panel.opened, "Escape must keep host open")
        check(fetch.upcomingCancellations.length > cancels, "Schedule exit did not cancel its owner")
        var savedSettings = store.settings
        store.settings = Object.assign({}, savedSettings, {favoriteTeamIds: []})
        naturalKey(panel, Qt.Key_G)
        check(panel.scheduleOpen && calendar.globalMode && calendar.agendaEntries.length > 0,
          "Global calendar requires favorites despite followed leagues")
        naturalKey(panel, Qt.Key_Escape)
        store.settings = Object.assign({}, savedSettings, {favoriteTeamIds: [], followedLeagueIds: []})
        naturalKey(panel, Qt.Key_G)
        check(panel.scheduleOpen && calendar.globalMode && calendar.agendaEntries.length === 0,
          "No-followed global calendar shows games outside admission")
        check(calendar.teamOptions.length === 1 && calendar.teamOptions[0].value === "",
          "No-favorites calendar lost global selector")
        check(textItem(calendar, "Follow leagues to see their games") !== null
          || calendar.notice.summary.toLowerCase().indexOf("follow") !== -1,
          "No-followed global calendar lost its guidance")
        naturalKey(panel, Qt.Key_Escape)
        store.settings = savedSettings
        settle(panel)
        // Restore only the fixture route; every calendar assertion above used
        // real keyboard events and actual production signal handlers.
        panel.selectDestination("following")
        settle(panel)
      }
      function checkFollowingPolish(panel) {
        var originalSettings = JSON.stringify(store.settings)
        var projection = panel.followingProjection
        var allGames = panel.resultRows.filter(function(row) { return row.kind === "game" })
        same(projection.counts.all, allGames.length, "Overview count differs from existing Following union")
        same(projection.counts.live, allGames.filter(function(row) {
          return row.game.status === "live" || row.game.status === "intermission"
        }).length, "Live count differs from union")
        check(panel.testFollowingOverview.visible && projection.summary.indexOf("loaded games") !== -1,
          "Limited mixed slate summary did not qualify its counts")
        check(allGames.every(function(row) { return row.game.presentation.showLeagueContext }),
          "Mixed Following cards lost league context")
        naturalKey(panel, Qt.Key_F)
        same(panel.followingFilterId, "live", "F did not select Live")
        check(panel.resultRows.filter(function(row) { return row.kind === "game" }).every(function(row) {
          return row.game.status === "live" || row.game.status === "intermission"
        }), "Live admitted another game state")
        naturalKey(panel, Qt.Key_F)
        same(panel.followingFilterId, "favorites", "F did not select Favorites")
        var favorites = panel.resultRows.filter(function(row) { return row.kind === "game" })
        check(favorites.length > 10 && favorites.every(function(row) { return row.game.presentation.isFavorite }),
          "Favorites differs from favorite-side membership")
        naturalKey(panel, Qt.Key_Down)
        var index = -1
        for (var i = panel.displayRows.length - 1; i >= 0; i--) {
          var candidate = panel.displayRows[i]
          if (candidate.kind === "game" && candidate.game.league === "nhl"
              && store.settings.favoriteTeamIds.indexOf(candidate.game.awayTeam.id) === -1) { index = i; break }
        }
        check(index >= 0, "Missing nonfavorite away team in filtered busy fixture")
        panel.setSelectedRow(index)
        for (var pass = 0; pass < 3; pass++) {
          panel.testList.forceLayout()
          panel.testList.positionViewAtIndex(index, ListView.Center)
          wait(80)
        }
        var selected = panel.selectedRowId, scroll = panel.testList.contentY
        var selectedCard = find(panel.testList.itemAtIndex(index), function(item) { return item.visible && "awayLabel" in item })
        var beforeCardY = selectedCard.mapToItem(panel.testList, 0, 0).y
        check(scroll > 0, "Filtered fixture did not overflow")
        panel.testCatcher.forceActiveFocus()
        naturalKey(panel, Qt.Key_Return)
        check(panel.detailOpen, "Filtered Enter did not open detail")
        var detail = panel.testDetail
        naturalKey(panel, Qt.Key_F)
        same(panel.followingFilterId, "favorites", "Detail F changed hidden Following filter")
        naturalKey(panel, Qt.Key_Down)
        same(detail.cursorActions[detail.cursorIndex].id, "away-schedule")
        var nonfavorite = detail.game.awayTeam.id
        check(store.settings.favoriteTeamIds.indexOf(nonfavorite) === -1, "Away fixture must be nonfavorite")
        var snapshot = detail.captureContext()
        var favoriteCalls = store.favoriteCalls
        naturalKey(panel, Qt.Key_Return)
        check(panel.scheduleOpen && panel.upcomingTeamId === nonfavorite,
          "Nonfavorite detail team did not open agenda")
        checkScheduleSurface(panel, "Team schedule")
        same(panel.testUpcomingCalendar.windowStartKey, root.sample.dateKey, "Team schedule did not start Today")
        naturalKey(panel, Qt.Key_Escape)
        check(panel.detailOpen && !panel.scheduleOpen, "Team Back lost detail origin")
        same(detail.focusId, snapshot.focusId, "Team Back lost semantic detail action")
        same(store.favoriteCalls, favoriteCalls, "Team navigation mutated favorites")
        panel.openUtility("notifications")
        settle(panel)
        check(panel.settingsOpen, "Detail Settings did not open")
        var utilitySnapshot = panel.utilityReturnContext
        check(utilitySnapshot && utilitySnapshot.surface === "detail" && utilitySnapshot.detailGame,
          "Settings did not capture detail frame: " + JSON.stringify(utilitySnapshot))
        var hiddenDetailCursor = detail.cursorIndex
        check(panel.testCatcher.activeFocus && !panel.testCatcher.blocked,
          "Detail Settings did not acquire keyboard focus")
        var settingsCursor = panel.testHub.sectionCursor
        naturalKey(panel, Qt.Key_Down)
        same(panel.testHub.sectionCursor, Math.min(settingsCursor + 1, panel.testHub.destinations.length - 1),
          "Settings Down did not move visible section cursor")
        naturalKey(panel, Qt.Key_Return)
        check(panel.testHub.contentFocused, "Settings Enter did not reach visible settings content")
        same(detail.cursorIndex, hiddenDetailCursor, "Settings Down moved hidden detail cursor")
        naturalKey(panel, Qt.Key_Escape)
        check(panel.detailOpen && !panel.settingsOpen, "Settings return lost detail")
        same(detail.focusId, snapshot.focusId, "Settings return lost detail action")
        naturalKey(panel, Qt.Key_Escape)
        check(!panel.detailOpen && panel.followingFilterId === "favorites", "Detail Back lost Favorites")
        same(panel.selectedRowId, selected, "Filtered Back lost selected game")
        check(Math.abs(rowViewportY(panel, selected) - beforeCardY) < 1,
          "Filtered Back moved selected row: " + beforeCardY + " -> " + rowViewportY(panel, selected))
        panel.openUtility("notifications")
        settle(panel)
        naturalKey(panel, Qt.Key_F)
        same(panel.followingFilterId, "favorites", "Settings F changed hidden Following filter")
        naturalKey(panel, Qt.Key_Escape)
        same(panel.followingFilterId, "favorites")
        same(panel.selectedRowId, selected)
        check(Math.abs(rowViewportY(panel, selected) - beforeCardY) < 1, "Filtered Settings return lost row position")
        naturalKey(panel, Qt.Key_Menu)
        check(panel.gameActionsOpen && panel.testCatcher.blocked, "Selected Menu did not open")
        naturalKey(panel, Qt.Key_Return)
        check(panel.scheduleOpen && panel.upcomingTeamId === nonfavorite,
          "Score menu did not open nonfavorite agenda")
        naturalKey(panel, Qt.Key_Escape)
        same(panel.followingFilterId, "favorites")
        same(panel.selectedRowId, selected, "Score menu Back lost row")
        check(Math.abs(rowViewportY(panel, selected) - beforeCardY) < 1, "Score menu Back lost row position")
        naturalKey(panel, Qt.Key_F)
        same(panel.followingFilterId, "all", "F did not complete filter cycle")
        panel.selectDestination("nhl")
        settle(panel)
        check(!panel.testFollowingOverview.visible, "Overview leaked into league view")
        naturalKey(panel, Qt.Key_F)
        same(panel.followingFilterId, "all", "League F changed hidden Following filter")
        panel.selectDestination("following")
        settle(panel)
        same(JSON.stringify(store.settings), originalSettings, "Presentation navigation changed preferences")
        same(panel.navigationStack.length, 0, "Completed Back routes leaked history")
      }
      function checkSettingsGeometry(panel, destination) {
        var hub = panel.testHub
        hub.selectDestination(destination)
        settle(panel)
        var section = find(hub, function(item) {
          if (!item.visible || !("cursorBounds" in item)) return false
          return destination === "sports" ? "actionsPerLeague" in item
            : destination === "notifications" ? "preferenceOptions" in item
            : "options" in item && "ticker" in item
        })
        check(section !== null, "Missing settings section: " + destination)
        section.moveCursor(10000)
        hub.ensureCursorVisible()
        settle(panel)
        var target = find(section, function(item) {
          return item.visible && "hasCursor" in item && item.hasCursor && item.width > 0 && item.height > 0
        })
        check(target !== null, "Settings cursor has no rendered target: " + destination)
        var local = target.mapToItem(section, 0, 0)
        var bounds = section.cursorBounds()
        check(bounds.top <= local.y + 1 && bounds.bottom >= local.y + target.height - 1,
          destination + " cursorBounds does not enclose its actual target: "
          + JSON.stringify(bounds) + " target " + local.y + ".." + (local.y + target.height))
        var mapped = target.mapToItem(panel.testUtilityScroll, 0, 0)
        check(mapped.y >= -1 && mapped.y + target.height <= panel.testUtilityScroll.height + 1,
          destination + " focused action is outside the visible settings viewport")
      }
      function run() {
        var panel = null
        try {
          root.uiCase = root.readJson("ui-case.json")
          root.sample = root.readJson("sample-state.json")
          // Busy fixture ensures navigation tests actually scroll instead of
          // proving an always-visible row. IDs stay distinct, data normalized.
          var expanded = root.sample.games.slice()
          for (var n = 0; n < 10; n++) {
            var added = JSON.parse(JSON.stringify(root.sample.games[0]))
            added.id = "nhl:ui-fixture-" + n
            added.providerGameId = "ui-fixture-" + n
            expanded.push(added)
          }
          root.sample = Object.assign({}, root.sample, {games: expanded})
          Commons.Color.loadUserShell("")
          Commons.Color.loadColors(root.readText("theme/colors.toml"))
          Commons.Color.loadShell(root.readText("theme/shell.toml"))
          Commons.Style.cornerRadius = 8
          Commons.Style.fontBaseSize = root.uiCase.fontSize
          Commons.Style.fontFamily = "JetBrainsMono Nerd Font"
          var component = Qt.createComponent(Qt.resolvedUrl("../../Panel.qml"))
          same(component.status, Component.Ready, component.errorString())
          panel = component.createObject(surface, {service: service, settingsStore: store,
            width: root.uiCase.width, height: 640, barRegion: "right"})
          check(panel !== null, component.errorString())
          panel.open()
          panel.observedTodayDateKey = root.sample.dateKey
          settle(panel)
          same(panel.activeDestination, "following")
          check(panel.displayRows.filter(function(row) { return row.kind === "game" }).length > 10)
          check(panel.testList.contentHeight > panel.testList.height, "Busy fixture must overflow the viewport")
          check(panel.displayRows.some(function(row) { return row.kind === "status" }),
            "Busy fixture must retain a league-specific failure notice alongside games")
          check(panel.testLeaguePicker.width > 0 && panel.testLeaguePicker.width <= root.uiCase.width)
          var scheduledRow = visibleGame(panel, "nba").row
          var baselineComponent = Qt.createComponent(Qt.resolvedUrl("../../components/LegacyDensityGameRow.qml"))
          same(baselineComponent.status, Component.Ready, baselineComponent.errorString())
          var baselineCard = baselineComponent.createObject(surface, {visible: false, width: scheduledRow.width,
            game: scheduledRow.game, settingsStore: store, imageStore: logos, currentTime: root.demoNow})
          check(baselineCard !== null, baselineComponent.errorString())
          wait(80)
          var controlCost = panel.testFollowingOverview.height + panel.testChrome.spacing
          var newRows = Math.floor((panel.testList.height + panel.testList.spacing)
            / (scheduledRow.height + panel.testList.spacing))
          var oldRows = Math.floor((panel.testList.height + controlCost + panel.testList.spacing)
            / (baselineCard.height + panel.testList.spacing))
          console.info("UI_DENSITY " + JSON.stringify({case: root.uiCase.name,
            overviewHeight: panel.testFollowingOverview.height, controlCost: controlCost,
            scoreChromeHeight: panel.testChrome.height, listHeight: panel.testList.height,
            viewportHeight: window.height, baselineScheduled: baselineCard.height,
            scheduled: scheduledRow.height, oldRows: oldRows, newRows: newRows}))
          if (root.uiCase.name === "light") {
            check(controlCost <= 48, "Integrated Following controls exceed the native card density budget")
            check(newRows >= oldRows + 1, "Actual Following controls erased the scheduled-card density gain")
          }
          baselineCard.destroy()
          panel.testList.positionViewAtBeginning()
          wait(80)
          capture("following")
          checkSchedulePage(panel)
          checkFollowingPolish(panel)

          // Genuine pointer input on nested children must not also open detail.
          var first = visibleGame(panel, "nhl")
          naturalKey(panel, Qt.Key_Down)
          panel.setSelectedRow(first.index)
          panel.testCatcher.forceActiveFocus()
          naturalKey(panel, Qt.Key_Menu)
          check(panel.gameActionsOpen && panel.testCatcher.blocked, "Menu must own keyboard input")
          var actions = find(first.row, function(item) { return "actions" in item && "menuGameId" in item })
          check(actions !== null && actions.popupOpen, "Native game action popup missing")
          var actionDate = panel.selectedDateKey
          var actionRefresh = fetch.refreshCalls
          naturalKey(panel, Qt.Key_BracketRight)
          naturalKey(panel, Qt.Key_R)
          naturalKey(panel, Qt.Key_F)
          same(panel.followingFilterId, "all", "Menu F changed hidden Following filter")
          same(panel.selectedDateKey, actionDate, "Menu changed hidden date")
          same(fetch.refreshCalls, actionRefresh, "Menu refreshed hidden scores")
          naturalKey(panel, Qt.Key_Down)
          naturalKey(panel, Qt.Key_Down)
          same(actions.actions[actions.cursorIndex].kind, "alerts")
          same(store.watchCalls, 0)
          naturalKey(panel, Qt.Key_Return)
          same(store.watchCalls, 1, "Menu alert must activate exactly once")
          check(!panel.detailOpen && !panel.gameActionsOpen, "Alert also opened detail or retained popup")
          keyClick(Qt.Key_F10, Qt.ShiftModifier)
          settle(panel)
          check(panel.gameActionsOpen, "Shift F10 did not open selected game actions")
          actions = find(first.row, function(item) { return "actions" in item && "menuGameId" in item })
          naturalKey(panel, Qt.Key_Down)
          naturalKey(panel, Qt.Key_Down)
          naturalKey(panel, Qt.Key_Down)
          same(actions.actions[actions.cursorIndex].kind, "source")
          naturalKey(panel, Qt.Key_Return)
          check(!panel.detailOpen && !panel.gameActionsOpen, "Source also opened detail or retained popup")

          // Keep real row selection and scroll across detail and Settings.
          var targetIndex = panel.displayRows.map(function(row) { return row.kind }).lastIndexOf("game") - 4
          while (panel.displayRows[targetIndex].kind !== "game") targetIndex--
          panel.setSelectedRow(targetIndex)
          // Let ListView instantiate variable-height delegates before fixing
          // the pointer target; its initial offscreen size estimate may move.
          for (var layoutPass = 0; layoutPass < 3; layoutPass++) {
            panel.testList.forceLayout()
            panel.testList.positionViewAtIndex(targetIndex, ListView.Center)
            wait(100)
          }
          var savedId = panel.selectedRowId
          var savedY = panel.testList.contentY
          check(savedY > 0, "Navigation fixture did not scroll")
          var selected = panel.testList.itemAtIndex(targetIndex)
          check(selected !== null)
          var selectedGame = find(selected, function(item) { return item.visible && "awayLabel" in item })
          var savedRowY = selectedGame.mapToItem(panel.testList, 0, 0).y
          var savedOriginY = panel.testList.originY
          var clickPoint = selectedGame.mapToItem(panel.testList, 8, selectedGame.height / 2)
          check(clickPoint.y >= 0 && clickPoint.y < panel.testList.height, "Fixture click outside score viewport: " + clickPoint.y + "/" + panel.testList.height)
          mouseClick(selectedGame, 8, selectedGame.height / 2, Qt.LeftButton, Qt.NoModifier, 20)
          settle(panel)
          check(panel.detailOpen, "Row pointer activation did not open detail")
          key(panel, Qt.Key_Escape)
          check(!panel.detailOpen)
          same(panel.selectedRowId, savedId, "Back changed selected game")
          check(Math.abs(rowViewportY(panel, savedId) - savedRowY) < 1, "Back moved score row " + savedRowY + " -> " + rowViewportY(panel, savedId))
          check(!panel.tabStripFocused, "Back lost row cursor")
          panel.openUtility("notifications")
          settle(panel)
          key(panel, Qt.Key_Escape)
          check(!panel.settingsOpen)
          same(panel.selectedRowId, savedId, "Settings return changed selected game")
          check(Math.abs(rowViewportY(panel, savedId) - savedRowY) < 1, "Settings return moved score row")
          check(!panel.tabStripFocused, "Settings return lost row cursor")

          // Long live state must stay fully readable at every tested width.
          var longGame = JSON.parse(JSON.stringify(root.sample.games[0]))
          longGame.periodLabel = "Overtime after weather delay, resumed with possession review"
          longGame.clock = "00:42"
          panel.selectDestination("nhl")
          fetch.leagueStates = [{leagueId: "nhl", displayName: "NHL", games: [longGame],
            hasData: true, loading: false, stale: false, errorCode: "", errorSummary: "",
            lastSuccessAt: root.sample.now}]
          settle(panel)
          first = visibleGame(panel)
          var state = textItem(first.row, first.row.detailLabel)
          check(state !== null, "Live status text not rendered")
          check(!state.truncated, "Live status was elided")
          check(state.wrapMode !== Text.NoWrap, "Live status does not allow wrapping")
          check(state.width <= first.row.width, "Live status exceeds row")

          // Twelve periods remain accessible in the horizontal line table;
          // full last-play content wraps rather than disappearing into ellipsis.
          var rich = JSON.parse(JSON.stringify(root.sample.games.filter(function(game) {
            return game.id === root.sample.detailGameId
          })[0]))
          // Exercise the complete bounded detail surface, including its two
          // admitted secondary links and a long, wrapping venue descriptor.
          rich.links = [{key: "highlights", url: "https://www.espn.com/mlb/game/_/gameId/401999901"},
            {key: "preview", url: "https://www.espn.com/mlb/game/_/gameId/401999902"}]
          rich.venue = "Yankee Stadium · New York Yankees home ballpark in the Bronx, New York · Major League Baseball championship venue with listed seating and accessibility information"
          rich.lines = {away: [], home: []}
          for (var period = 1; period <= 12; period++) {
            rich.lines.away.push({period: period, value: period % 2})
            rich.lines.home.push({period: period, value: (period + 1) % 2})
          }
          rich.stats = {away: [], home: []}
          for (var stat = 0; stat < 8; stat++) {
            rich.stats.away.push({key: "fixture-" + stat, label: "Fixture team stat " + stat, value: String(stat)})
            rich.stats.home.push({key: "fixture-" + stat, label: "Fixture team stat " + stat, value: String(stat + 1)})
          }
          rich.situation.lastPlay = "Judge singles to center; the runner advances to second after a long throw, and the next batter steps in with two runners aboard and one out."
          fetch.leagueStates = [{leagueId: rich.league, displayName: "MLB", games: [rich],
            hasData: true, loading: false, stale: false, errorCode: "", errorSummary: "",
            lastSuccessAt: root.sample.now}]
          panel.openGameDetail(rich)
          settle(panel)
          var detail = panel.testDetail
          var play = find(detail, function(item) {
            return item.visible && "text" in item && item.text.indexOf(rich.situation.lastPlay) !== -1
          })
          check(play !== null && !play.truncated, "Long last play is missing or elided")
          check(play.wrapMode !== Text.NoWrap, "Long last play does not wrap")
          same(detail.linesData.away.length, 12)
          var lineScroll = find(detail, function(item) {
            return item.visible && "contentX" in item && "contentWidth" in item && item.contentWidth > item.width
          })
          check(lineScroll !== null, "Twelve periods have no horizontal overflow surface")
          var detailScroll = find(detail, function(item) {
            return item.visible && "flickableDirection" in item
              && item.flickableDirection === Flickable.VerticalFlick
          })
          check(detailScroll !== null && detailScroll.contentHeight > detailScroll.height,
            "Rich fixture must have vertical overflow: " + (detailScroll ? detailScroll.contentHeight + "/" + detailScroll.height : "missing"))
          var actionCursor = detail.cursorIndex
          var backgroundSelection = panel.selectedRowId
          same(lineScroll.contentX, 0, "New detail did not start at the first period")
          key(panel, Qt.Key_Right)
          check(lineScroll.contentX > 0, "Right key did not scroll periods")
          same(detail.cursorIndex, actionCursor, "Horizontal period scrolling changed action cursor")
          var linePosition = lineScroll.mapToItem(detailScroll, 0, 0)
          check(linePosition.y >= -1 && linePosition.y + lineScroll.height <= detailScroll.height + 1,
            "Keyboard period scrolling did not reveal its table vertically")
          key(panel, Qt.Key_Left)
          same(lineScroll.contentX, 0, "Left key did not return to the first period")
          same(detail.cursorIndex, actionCursor, "Left key changed action cursor")
          for (var step = 0; step < 10; step++) key(panel, Qt.Key_Right)
          check(Math.abs(lineScroll.contentX - (lineScroll.contentWidth - lineScroll.width)) < 1,
            "Keyboard cannot reach the last periods")
          capture("detail")
          key(panel, Qt.Key_Home)
          same(detailScroll.contentY, 0, "Home did not return detail to the top")
          key(panel, Qt.Key_PageDown)
          var afterPageDown = detailScroll.contentY
          check(afterPageDown > 0, "PageDown did not scroll detail")
          key(panel, Qt.Key_PageUp)
          check(detailScroll.contentY < afterPageDown, "PageUp did not scroll detail back")
          key(panel, Qt.Key_End)
          check(Math.abs(detailScroll.contentY - (detailScroll.contentHeight - detailScroll.height)) < 1,
            "End did not reveal the last detail section")
          key(panel, Qt.Key_Home)
          same(detailScroll.contentY, 0)
          same(detail.cursorIndex, actionCursor, "Viewport keys changed detail action cursor")
          same(panel.selectedRowId, backgroundSelection, "Detail viewport keys changed background selection")
          key(panel, Qt.Key_Escape)
          panel.openGameDetail(rich)
          settle(panel)
          same(lineScroll.contentX, 0, "Deliberate reopen retained the previous horizontal period offset")
          key(panel, Qt.Key_Escape)

          // State changes render only relevant optional sections. Start with a
          // normalized sparse pregame, then odds and a final result, retaining
          // the same fixture source identity throughout.
          var sparse = JSON.parse(JSON.stringify(rich))
          sparse.status = "scheduled"
          sparse.awayScore = null
          sparse.homeScore = null
          sparse.period = null
          sparse.periodLabel = null
          sparse.clock = null
          sparse.lines = null
          sparse.stats = null
          sparse.situation = null
          sparse.odds = null
          sparse.links = []
          function showGame(game) {
            fetch.leagueStates = [{leagueId: game.league, displayName: "MLB", games: [game],
              hasData: true, loading: false, stale: false, errorCode: "", errorSummary: "",
              lastSuccessAt: root.sample.now}]
            panel.openGameDetail(game)
            settle(panel)
          }
          showGame(sparse)
          same(detail.linesData, null)
          same(detail.statsData, null)
          same(detail.situationData, null)
          same(detail.oddsData, null)
          same(detail.outcomeLabel(), null)
          check(detail.sourceAvailable, "Sparse pregame lost its source action")
          check(textItem(detail, "Game situation") === null, "Sparse game shows an empty situation section")
          check(textItem(detail, "Scoring by inning") === null, "Sparse game shows an empty line table")
          check(textItem(detail, "Team stats") === null, "Sparse game shows empty team stats")
          check(textItem(detail, "Pregame odds") === null, "Sparse game shows an empty odds section")
          var pregame = JSON.parse(JSON.stringify(sparse))
          pregame.odds = {details: "NYY -110", overUnder: 8.5, provider: "Fixture bookmaker"}
          showGame(pregame)
          check(detail.oddsData !== null && textItem(detail, "Pregame odds") !== null,
            "Pregame odds section was not rendered")
          var finalGame = JSON.parse(JSON.stringify(pregame))
          finalGame.status = "final"
          finalGame.awayScore = 2
          finalGame.homeScore = 4
          showGame(finalGame)
          check(detail.detail.outcome !== null && detail.detail.outcome.winner === "home",
            "Final result did not show its outcome")
          check(textItem(detail, detail.outcomeLabel()) !== null, "Final outcome text is not visible")
          check(textItem(detail, "Pregame odds") === null, "Final game shows the pregame odds section")
          naturalKey(panel, Qt.Key_Down)
          same(detail.cursorActions[detail.cursorIndex].id, "away-schedule", "Detail Down did not reach away schedule")
          naturalKey(panel, Qt.Key_Down)
          same(detail.cursorActions[detail.cursorIndex].id, "home-schedule")
          naturalKey(panel, Qt.Key_Down)
          same(detail.cursorActions[detail.cursorIndex].id, "source", "Final detail did not skip disabled Watch toward source")
          naturalKey(panel, Qt.Key_Up)
          same(detail.cursorActions[detail.cursorIndex].id, "home-schedule")
          naturalKey(panel, Qt.Key_Up)
          naturalKey(panel, Qt.Key_Up)
          same(detail.cursorActions[detail.cursorIndex].id, "back")
          naturalKey(panel, Qt.Key_Return)
          check(!panel.detailOpen, "Return after source Up did not activate Back")

          panel.selectDestination("nhl")
          panel.selectDate("2026-10-10")
          panel.openStandings()
          settle(panel)
          var retainedDate = panel.selectedDateKey
          check(retainedDate !== panel.todayDateKey, "Date guard fixture must use a non-today date")
          check(!panel.testDates.visible, "Score-date strip remains visible in standings")
          check(find(panel, function(item) {
            return item.visible && "tooltipText" in item && item.tooltipText === "Return to today"
          }) === null, "Standings exposes a misleading Today action")
          naturalKey(panel, Qt.Key_BracketLeft)
          same(panel.selectedDateKey, retainedDate, "Standings [ changed the hidden score date")
          naturalKey(panel, Qt.Key_BracketRight)
          same(panel.selectedDateKey, retainedDate, "Standings ] changed the hidden score date")
          naturalKey(panel, Qt.Key_T)
          same(panel.selectedDateKey, retainedDate, "Standings T changed the hidden score date")

          // Header refresh busy state and click routing follow the visible
          // standings owner, independently of an unrelated score request.
          var refresh = find(panel, function(item) {
            return item.visible && "refreshing" in item && "clicked" in item
          })
          check(refresh !== null, "Header refresh action is missing")
          fetch.loading = true
          table.loading = false
          settle(panel)
          check(refresh.enabled && !refresh.refreshing && refresh.tooltipText === "Refresh standings",
            "Unrelated score loading disabled or mislabeled standings Refresh")
          var tableRefreshCalls = table.refreshCalls
          var scoreRefreshCalls = fetch.refreshCalls
          mouseClick(refresh, refresh.width / 2, refresh.height / 2, Qt.LeftButton, Qt.NoModifier, 20)
          settle(panel)
          same(table.refreshCalls, tableRefreshCalls + 1, "Refresh did not target standings exactly once")
          same(fetch.refreshCalls, scoreRefreshCalls, "Standings Refresh also requested scores")
          fetch.loading = false
          table.loading = true
          settle(panel)
          check(!refresh.enabled && refresh.refreshing && refresh.tooltipText === "Refreshing standings",
            "Standings loading did not disable and label its Refresh action")
          table.loading = false
          settle(panel)
          var standingIndex = panel.displayRows.findIndex(function(row) {
            return row.kind === "standings" && store.settings.favoriteTeamIds.indexOf(row.standing.team.id) === -1
              && !root.sample.games.some(function(game) {
                return game.awayTeam.id === row.standing.team.id || game.homeTeam.id === row.standing.team.id
              })
          })
          check(standingIndex >= 0)
          panel.testList.positionViewAtIndex(standingIndex, ListView.Beginning)
          wait(60)
          var standing = find(panel.testList.itemAtIndex(standingIndex), function(item) {
            return item.visible && "standing" in item && "activatePrimaryAction" in item
          })
          check(standing !== null)
          var favoriteAction = find(standing, function(item) {
            return item.visible && "clicked" in item && "pointerPressed" in item
              && (("iconName" in item && item.iconName.indexOf("star") !== -1)
                || ("tooltipText" in item && item.tooltipText.toLowerCase().indexOf("favorite") !== -1))
          })
          check(favoriteAction !== null, "Standings has no explicit favorite action")
          var oldFavoriteCalls = store.favoriteCalls
          panel.setSelectedRow(standingIndex)
          var standingRowId = panel.selectedRowId
          var standingsScroll = rowViewportY(panel, standingRowId)
          // Rank/metrics select the row; the named team is the pointer route.
          mouseClick(standing, standing.geometry.padding + standing.geometry.rankWidth / 2,
            standing.height / 2, Qt.LeftButton, Qt.NoModifier, 20)
          wait(40)
          same(store.favoriteCalls, oldFavoriteCalls, "Clicking table body changed a favorite")
          check(!panel.scheduleOpen, "Standings metrics unexpectedly opened a schedule")
          same(panel.selectedRowId, standingRowId, "Standings body did not select its row")
          check(panel.testCatcher.activeFocus && !panel.testCatcher.blocked,
            "Standings body selection did not acquire keyboard focus")
          naturalKey(panel, Qt.Key_Return)
          check(panel.scheduleOpen && panel.upcomingTeamId === standing.standing.team.id,
            "Standings Enter did not open selected team schedule")
          same(panel.testUpcomingCalendar.selectedDateKey, root.sample.dateKey, "Historical standings team schedule did not begin Today")
          naturalKey(panel, Qt.Key_Escape)
          check(panel.standingsOpen && !panel.scheduleOpen, "Back from team lost standings")
          same(panel.selectedDateKey, retainedDate, "Back from team lost standings date")
          same(panel.selectedRowId, standingRowId, "Back from team lost standings row")
          check(Math.abs(rowViewportY(panel, standingRowId) - standingsScroll) < 1, "Back moved standings row")
          same(store.favoriteCalls, oldFavoriteCalls, "Back from standings team mutated favorites")
          var standingLink = find(standing, function(item) {
            return item.visible && "scheduleTeamId" in item && item.scheduleTeamId === standing.standing.team.id
          })
          check(standingLink !== null, "Standings team has no explicit schedule link")
          mouseClick(standingLink, standingLink.width / 2, standingLink.height / 2, Qt.LeftButton, Qt.NoModifier, 20)
          settle(panel)
          check(panel.scheduleOpen && panel.upcomingTeamId === standing.standing.team.id,
            "Standings team link did not open schedule")
          same(store.favoriteCalls, oldFavoriteCalls, "Standings team link changed favorites")
          naturalKey(panel, Qt.Key_Escape)
          check(panel.standingsOpen && !panel.scheduleOpen, "Team link Back lost standings")
          same(panel.selectedRowId, standingRowId)
          check(Math.abs(rowViewportY(panel, standingRowId) - standingsScroll) < 1, "Team link Back moved standings row")
          mouseClick(favoriteAction, favoriteAction.width / 2, favoriteAction.height / 2,
            Qt.LeftButton, Qt.NoModifier, 20)
          wait(50)
          same(store.favoriteCalls, oldFavoriteCalls + 1, "Favorite star did not activate exactly once")
          capture("standings")

          panel.toggleStandings()
          check(!panel.standingsOpen, "Settings date guard must start from scores")
          panel.openUtility("notifications")
          settle(panel)
          var settingsDate = panel.selectedDateKey
          naturalKey(panel, Qt.Key_BracketLeft)
          same(panel.selectedDateKey, settingsDate, "Settings [ changed hidden score date")
          naturalKey(panel, Qt.Key_BracketRight)
          same(panel.selectedDateKey, settingsDate, "Settings ] changed hidden score date")
          naturalKey(panel, Qt.Key_T)
          same(panel.selectedDateKey, settingsDate, "Settings T changed hidden score date")
          var refreshCallsBeforeSettingsKey = fetch.refreshCalls
          naturalKey(panel, Qt.Key_R)
          same(fetch.refreshCalls, refreshCallsBeforeSettingsKey, "Settings R refreshed hidden scores")
          checkSettingsGeometry(panel, "notifications")
          checkSettingsGeometry(panel, "sports")
          checkSettingsGeometry(panel, "ticker")
          var tickerSection = find(panel.testHub, function(item) {
            return item.visible && "choices" in item && "setValue" in item
          })
          check(tickerSection !== null, "Ticker settings section missing")
          var topChoice = find(tickerSection, function(item) {
            return item.visible && "text" in item && item.text === "Top" && "clicked" in item
          })
          var slowChoice = find(tickerSection, function(item) {
            return item.visible && "text" in item && item.text === "Slow" && "clicked" in item
          })
          check(topChoice !== null && slowChoice !== null, "Explicit ticker choices missing")
          mouseClick(topChoice, topChoice.width / 2, topChoice.height / 2, Qt.LeftButton, Qt.NoModifier, 20)
          wait(50)
          same(store.settings.ticker.position, "top", "Top choice did not select its explicit value")
          mouseClick(slowChoice, slowChoice.width / 2, slowChoice.height / 2, Qt.LeftButton, Qt.NoModifier, 20)
          wait(50)
          same(store.settings.ticker.speed, "slow", "Slow choice did not select its explicit value")
          same(store.tickerCalls.length, 2, "Ticker choices did not mutate exactly once each")
          check(topChoice.selected && slowChoice.selected, "Ticker selected states disagree with preferences")
          capture("settings")

          // Reach Teams through the settings tab cursor, then use only real
          // keys: search -> results -> filter -> search -> Escape. No direct
          // opening of the dropdown or forced focus can mask a missing route.
          naturalKey(panel, Qt.Key_Left)
          same(panel.testHub.sectionCursor, 2, "Left did not reach Alerts tab cursor")
          naturalKey(panel, Qt.Key_Left)
          same(panel.testHub.sectionCursor, 1, "Left did not reach Teams tab cursor")
          naturalKey(panel, Qt.Key_Return)
          same(panel.testHub.destination, "teams", "Tab cursor did not activate Teams")
          var picker = find(panel.testHub, function(item) {
            return item.visible && "leagueFilter" in item && "visibleTeams" in item
          })
          check(picker !== null, "Favorite picker missing")
          check(picker.inputActive && panel.testCatcher.blocked, "Teams did not focus its search editor")
          var filter = find(picker, function(item) {
            return item.visible && "options" in item && "popupOpen" in item && "open" in item
          })
          check(filter !== null, "Native favorite league filter missing")
          var callsBeforeBrowse = store.favoriteCalls
          naturalKey(panel, Qt.Key_Down)
          check(!picker.inputActive && panel.testCatcher.activeFocus,
            "Search Down did not hand focus to result navigation")
          same(store.favoriteCalls, callsBeforeBrowse, "Leaving search changed a favorite")
          var cursorBeforeBrowse = picker.cursorIndex
          naturalKey(panel, Qt.Key_Down)
          same(picker.cursorIndex, cursorBeforeBrowse + 1, "Result Down did not browse teams")
          naturalKey(panel, Qt.Key_Return)
          same(store.favoriteCalls, callsBeforeBrowse + 1, "Result Enter did not toggle exactly one favorite")
          naturalKey(panel, Qt.Key_F)
          check(filter.popupOpen && panel.testCatcher.blocked, "F did not open the native league filter")
          keyClick(Qt.Key_Down)
          keyClick(Qt.Key_Return)
          settle(panel)
          same(picker.leagueFilter, "nhl", "Popup arrows/Enter did not select NHL")
          check(picker.visibleTeams.length > 0 && picker.visibleTeams.every(function(team) {
            return team.league === "nhl"
          }), "Favorite league filter did not update its rows")
          check(!filter.popupOpen && panel.settingsOpen, "Selecting a filter closed Settings")
          check(panel.testCatcher.activeFocus, "Filter selection did not return focus to results")
          naturalKey(panel, Qt.Key_F)
          check(filter.popupOpen)
          keyClick(Qt.Key_Escape)
          settle(panel)
          check(!filter.popupOpen && panel.settingsOpen, "Filter Escape also closed Settings")
          check(panel.testCatcher.activeFocus, "Filter Escape did not restore result navigation")

          // From results, Left/Right reaches another settings page rather than
          // disappearing into an input. Enter activates the highlighted tab.
          naturalKey(panel, Qt.Key_Right)
          same(panel.testHub.sectionCursor, 2)
          check(!panel.testHub.contentFocused)
          naturalKey(panel, Qt.Key_Return)
          same(panel.testHub.destination, "notifications", "Right/Enter did not open Alerts")
          naturalKey(panel, Qt.Key_Left)
          naturalKey(panel, Qt.Key_Return)
          same(panel.testHub.destination, "teams")
          naturalKey(panel, Qt.Key_Down)
          naturalKey(panel, Qt.Key_Slash)
          check(picker.inputActive && panel.testCatcher.blocked, "/ did not return to team search")
          var callsBeforeSearchReturn = store.favoriteCalls
          naturalKey(panel, Qt.Key_Return)
          check(!picker.inputActive && panel.testCatcher.activeFocus,
            "Search Return did not hand off to results")
          same(store.favoriteCalls, callsBeforeSearchReturn, "Search Return implicitly toggled a favorite")
          naturalKey(panel, Qt.Key_Slash)
          check(picker.inputActive)
          naturalKey(panel, Qt.Key_Tab)
          check(picker.inputActive && panel.testCatcher.blocked,
            "Native editor Tab did not keep ownership on filter control")
          naturalKey(panel, Qt.Key_Return)
          check(filter.popupOpen, "Native editor Tab/Return did not open the league filter")
          keyClick(Qt.Key_Escape)
          settle(panel)
          check(!filter.popupOpen && panel.settingsOpen, "Tab-opened filter Escape closed Settings")
          naturalKey(panel, Qt.Key_Slash)
          check(picker.inputActive)
          keyClick(Qt.Key_Escape)
          settle(panel)
          check(!panel.settingsOpen, "Escape from search did not close Settings")

          // Disable the league that Settings will return to through its real
          // control, then close normally. Restore the in-memory fixture only.
          var savedFixtureSettings = JSON.parse(JSON.stringify(store.settings))
          panel.selectDestination("nhl")
          panel.openUtility("sports")
          settle(panel)
          same(panel.utilityReturnDestination, "nhl")
          var sports = find(panel.testHub, function(item) {
            return item.visible && "actionsPerLeague" in item && "leagues" in item
          })
          check(sports !== null)
          var nhlSettingsRow = find(sports, function(item) {
            return item.visible && "modelData" in item && item.modelData
              && item.modelData.id === "nhl" && "index" in item
          })
          check(nhlSettingsRow !== null, "NHL settings fixture row is missing")
          var disableNhl = find(nhlSettingsRow, function(item) {
            return item.visible && "tooltipText" in item && item.tooltipText === "Disable league"
          })
          check(disableNhl !== null)
          mouseClick(disableNhl, disableNhl.width / 2, disableNhl.height / 2, Qt.LeftButton, Qt.NoModifier, 20)
          settle(panel)
          check(!store.isLeagueEnabled("nhl"), "League control did not disable NHL")
          same(store.leagueCalls.length, 1, "League control toggled more than once")
          naturalKey(panel, Qt.Key_Escape)
          check(!panel.settingsOpen)
          same(panel.activeDestination, "following", "Settings restored a disabled league destination")
          same(panel.testLeaguePicker.value, "following", "League chooser disagrees with fallback route")
          check(!panel.tabItems.some(function(item) { return item.id === "nhl" }),
            "Disabled league remains in navigation")
          store.settings = savedFixtureSettings
          settle(panel)
          check(store.isLeagueEnabled("nhl"), "In-memory league fixture was not restored")
          same(JSON.stringify(store.settings), JSON.stringify(savedFixtureSettings))
          console.log("UI_PRESENTATION_PASS " + root.uiCase.name)
        } catch (error) {
          console.error("UI_PRESENTATION_FAIL " + String(error) + " " + error.stack)
        }
        if (panel) panel.destroy()
        Qt.quit()
      }
    }
  }
}

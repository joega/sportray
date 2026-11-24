import QtQuick
import QtQuick.Window
import QtTest as Test
import Quickshell
import qs.Commons as Commons
import "../.." as Plugin
import "../../components" as Components
import "../../model/SettingsModel.js" as SettingsModel
import "../../model/DateModel.js" as DateModel

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
    property var upcomingCancellations: []
    property var upcomingState: ({owner: "", teamId: "", loading: false, hasData: false,
      partial: false, stale: false, entries: [], errorSummary: "", coverageStart: "", coverageEnd: ""})
    function requestUpcoming(owner, teamId, first, last, force) {
      upcomingRequests = upcomingRequests.concat([{owner: owner, teamId: teamId,
        startDate: first, endDate: last, force: force === true}])
      var original = root.sample.games.filter(function(game) {
        return game.awayTeam.id === teamId || game.homeTeam.id === teamId
      })[0]
      if (!original) return false
      var entries = [21, 28].map(function(distance, index) {
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
      upcomingState = {owner: owner, teamId: teamId, loading: false, hasData: true,
        partial: false, stale: false, entries: entries, errorSummary: "",
        coverageStart: first, coverageEnd: last, coverageComplete: true, lastSuccessAt: root.sample.now}
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
      function checkUpcomingPopup(panel) {
        var popup = panel.testUpcomingPopup
        var calendar = panel.testUpcomingCalendar
        var originalDate = panel.selectedDateKey
        var futureDate = DateModel.addDays(root.sample.dateKey, 21)
        var calls = fetch.refreshCalls
        var cancels = fetch.upcomingCancellations.length
        check(panel.testCalendarButton.visible, "Team calendar button is unavailable")
        naturalKey(panel, Qt.Key_G)
        check(popup.opened && panel.opened, "G did not open the team calendar over the host panel")
        check(panel.testCatcher.blocked, "Team popup did not take keyboard ownership")
        check(calendar.width > 0 && calendar.width <= root.uiCase.width,
          "Team calendar does not fit the viewport width")
        check(popup.height <= window.height && popup.y >= 0, "Team popup exceeds the window")
        check(fetch.upcomingRequests.length > 0, "Opening calendar did not request a selected-team window")
        check(fetch.upcomingRequests.every(function(request) {
          return request.owner === panel.panelToken && request.teamId
            && DateModel.calendarDistance(request.endDate, request.startDate) === 34
        }), "Calendar intents are not owner-scoped 35-day windows")
        check(calendar.nextEntry !== null && calendar.nextEntry.dateKey === futureDate,
          "Next listed game did not bridge the21-day/month gap")
        check(futureDate.slice(0, 7) !== originalDate.slice(0, 7), "Upcoming fixture must cross a month")
        naturalKey(panel, Qt.Key_BracketLeft)
        naturalKey(panel, Qt.Key_BracketRight)
        naturalKey(panel, Qt.Key_T)
        naturalKey(panel, Qt.Key_S)
        naturalKey(panel, Qt.Key_R)
        same(panel.selectedDateKey, originalDate, "Popup text keys changed the hidden score date")
        check(!panel.standingsOpen && !panel.settingsOpen, "Popup key changed a hidden panel route")
        same(fetch.refreshCalls, calls, "Popup R refreshed hidden scores")
        naturalKey(panel, Qt.Key_Right)
        check(calendar.focusedDateKey !== originalDate, "Calendar arrows did not move its date cursor")
        same(panel.selectedDateKey, originalDate, "Calendar cursor movement selected a hidden score day")
        var originalMonth = calendar.displayedMonthKey
        naturalKey(panel, Qt.Key_PageDown)
        check(calendar.displayedMonthKey !== originalMonth, "PageDown did not browse the calendar month")
        same(panel.selectedDateKey, originalDate, "Calendar month browsing changed score date")

        // Native Tab/Enter reaches the team chooser from the calendar cursor;
        // selection and popup dismissal keep the enclosing team calendar open.
        var teamPicker = find(calendar, function(item) {
          return item.visible && "popupOpen" in item && "options" in item
        })
        check(teamPicker !== null && teamPicker.options.length > 1, "Team chooser fixture is missing")
        naturalKey(panel, Qt.Key_Tab)
        naturalKey(panel, Qt.Key_Return)
        check(teamPicker.popupOpen && popup.opened, "Native Tab/Enter did not open the team chooser")
        var selectedIndex = teamPicker.options.findIndex(function(option) { return option.value === calendar.teamId })
        var direction = selectedIndex < teamPicker.options.length - 1 ? 1 : -1
        var expectedTeam = teamPicker.options[selectedIndex + direction].value
        keyClick(direction > 0 ? Qt.Key_Down : Qt.Key_Up)
        keyClick(Qt.Key_Return)
        settle(panel)
        same(calendar.teamId, expectedTeam, "Team chooser keyboard selection was lost")
        same(fetch.upcomingState.teamId, expectedTeam, "Team selection did not request its own schedule")
        check(popup.opened && !teamPicker.popupOpen, "Team selection dismissed the enclosing calendar")
        naturalKey(panel, Qt.Key_Escape)
        check(!popup.opened && panel.opened, "Calendar Escape also closed the host panel")
        same(panel.selectedDateKey, originalDate, "Closing calendar changed score date")
        check(fetch.upcomingCancellations.length > cancels, "Calendar close did not cancel its schedule owner")

        naturalKey(panel, Qt.Key_G)
        check(popup.opened)
        same(calendar.nextEntry.dateKey, futureDate)
        var jump = find(calendar, function(item) {
          return item.visible && "tooltipText" in item && item.tooltipText === "Jump to the next listed game"
        })
        check(jump !== null, "Next listed game has no View day action")
        for (var tab = 0; tab < 20 && !jump.activeFocus; tab++) naturalKey(panel, Qt.Key_Tab)
        check(jump.activeFocus, "Next listed View day is not reachable by native Tab")
        var point = jump.mapToItem(window.contentItem, 0, 0)
        check(point.y >= -1 && point.y + jump.height <= window.height + 1,
          "Focused View day is outside the popup viewport")
        capture("upcoming", window.contentItem)
        naturalKey(panel, Qt.Key_Return)
        check(!popup.opened && panel.opened, "View day did not close only the team calendar")
        same(panel.selectedDateKey, futureDate, "View day did not jump across the21-day/month gap")
        check(!panel.detailOpen && !panel.settingsOpen && !panel.standingsOpen,
          "View day activated a hidden score action")
        naturalKey(panel, Qt.Key_T)
        same(panel.selectedDateKey, originalDate, "Today did not restore the score fixture after a calendar jump")
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
          capture("following")
          checkUpcomingPopup(panel)

          // Genuine pointer input on nested children must not also open detail.
          var first = visibleGame(panel, "nhl")
          var watch = find(first.row, function(item) { return item.visible && "watchCount" in item && "activate" in item })
          var source = find(first.row, function(item) { return item.visible && "sourceUrl" in item && "openSource" in item })
          check(watch !== null && source !== null, "Score actions are missing")
          same(store.watchCalls, 0)
          mouseClick(watch, watch.width / 2, watch.height / 2, Qt.LeftButton, Qt.NoModifier, 20)
          wait(50)
          same(store.watchCalls, 1, "Watch must activate exactly once")
          check(!panel.detailOpen, "Nested Watch also opened the row")
          mouseClick(source, source.width / 2, source.height / 2, Qt.LeftButton, Qt.NoModifier, 20)
          wait(100)
          check(!panel.detailOpen, "Nested source also opened the row")

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
          check(Math.abs(panel.testList.contentY - savedY) < 1, "Back changed score scroll " + savedY + " -> " + panel.testList.contentY + " origin " + savedOriginY + " -> " + panel.testList.originY + " rowY " + savedRowY + " -> " + selectedGame.mapToItem(panel.testList, 0, 0).y)
          check(!panel.tabStripFocused, "Back lost row cursor")
          panel.openUtility("notifications")
          settle(panel)
          key(panel, Qt.Key_Escape)
          check(!panel.settingsOpen)
          same(panel.selectedRowId, savedId, "Settings return changed selected game")
          check(Math.abs(panel.testList.contentY - savedY) < 1, "Settings return changed score scroll " + savedY + " -> " + panel.testList.contentY)
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
            "Rich fixture must have vertical overflow")
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
          same(detail.cursorIndex, 2, "Final detail did not skip disabled Watch toward source")
          naturalKey(panel, Qt.Key_Up)
          same(detail.cursorIndex, 0, "Source Up did not skip disabled Watch back to Back")
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
          var standingIndex = panel.displayRows.findIndex(function(row) { return row.kind === "standings" })
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
          mouseClick(standing, standing.width * 0.45, standing.height / 2, Qt.LeftButton, Qt.NoModifier, 20)
          wait(40)
          same(store.favoriteCalls, oldFavoriteCalls, "Clicking table body changed a favorite")
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

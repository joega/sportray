import QtQuick
import QtQuick.Window
import QtTest as Test
import Quickshell
import qs.Commons as Commons
import "../.." as Plugin
import "../../components" as Components
import "../../model/SettingsModel.js" as SettingsModel

// Capture current native views with illustrative state. No shared worker is
// acquired, no provider request/notification is started, and no settings persist.
ShellRoot {
  id: root
  property var sample: null
  property var logoSources: ({})
  property var examples: []
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
    property var watchedGames: root.sample ? [{gameId: root.sample.detailGameId,
      league: "mlb", providerGameId: "demo-nyy-lad", startTime: "2026-10-11T20:00:00Z",
      createdAt: "2026-10-11T19:00:00Z", expiresAt: "2026-10-12T08:00:00Z", status: "active"}] : []
    function isLeagueEnabled(league) { return settings.enabledLeagues.indexOf(league) !== -1 }
    function toggleWatch(game) { return false }
    function toggleFavoriteTeam(id) { return false }
  }
  QtObject {
    id: fetch
    property var leagueStates: root.sample ? root.sample.settings.enabledLeagues.map(function(league) {
      return {leagueId: league, displayName: league.toUpperCase(),
        games: root.sample.games.filter(function(game) { return game.league === league }),
        hasData: true, loading: false, stale: false, errorCode: "", errorSummary: "",
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
    function requestRefresh(reason) { return false }
    function cancelCalendarSchedule() {}
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
    function refresh(league) { return load(league, true) }
    function snapshot() { return {leagueId: leagueId, groups: groups, rows: rows, hasData: true,
      loading: false, stale: false, errorCode: "", errorSummary: "", lastSuccessAt: lastSuccessAt} }
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

  Window {
    id: window
    visible: true
    width: 1280
    height: 720
    color: Commons.Color.background
    Item { id: single; width: 400; height: 640 }
    Item {
      id: board
      width: 1280
      height: 720
      visible: false
      Rectangle { anchors.fill: parent; color: Commons.Color.background }
      Repeater {
        model: ["FOLLOW YOUR TEAMS", "LEAGUE STANDINGS", "GAME DETAILS"]
        Text {
          required property string modelData
          required property int index
          x: 20 + index * 420
          y: 17
          width: 400
          text: modelData
          textFormat: Text.PlainText
          font.family: Commons.Style.font.family
          font.pixelSize: 13
          font.bold: true
          color: Commons.Color.accent
        }
      }
    }
    Components.TicketStrip {
      id: ticker
      width: 1280
      height: 32
      y: 0
      visible: false
      games: root.sample ? root.sample.games.slice(0, 3) : []
      favoriteTeamIds: store.settings.favoriteTeamIds
      tickerState: "ready"
      nowMs: root.demoNow
      reducedMotion: true
      imageStore: logos
    }
    Timer { interval: 400; running: true; onTriggered: gallery.render() }
    Test.TestCase {
      id: gallery
      when: false
      function createPanel() {
        var component = Qt.createComponent(Qt.resolvedUrl("../../Panel.qml"))
        compare(component.status, Component.Ready, component.errorString())
        var panel = component.createObject(single, {service: service, settingsStore: store,
          width: 400, height: 640, barRegion: "right"})
        verify(panel !== null)
        panel.open()
        panel.captureClock.stop()
        panel.nowMs = root.demoNow
        panel.observedTodayDateKey = root.sample.dateKey
        panel.panelHeightRecalculationPending = false
        panel.panelContentHeightRequest = 640
        return panel
      }
      function settle(panel) {
        panel.captureClock.stop()
        panel.nowMs = root.demoNow
        panel.panelHeightRecalculationPending = false
        wait(300)
        panel.panelContentHeightRequest = 640
        panel.captureList.contentY = 0
        wait(120)
      }
      function capture(item, name, width, height) {
        var done = false, saved = false
        item.grabToImage(function(result) {
          saved = result.saveToFile(Quickshell.env("SPORTRAY_SCREENSHOT_DIR") + "/" + name + ".png")
          done = true
        }, Qt.size(width, height))
        tryVerify(function() { return done }, 5000)
        verify(saved, "Screenshot was not saved: " + name)
      }
      function render() {
        try {
          root.sample = root.readJson("sample-state.json")
          root.logoSources = root.readJson("logos.json")
          Commons.Color.loadUserShell("")
          Commons.Color.loadColors(root.readText("theme/colors.toml"))
          Commons.Color.loadShell(root.readText("theme/shell.toml"))
          Commons.Style.cornerRadius = 8
          Commons.Style.fontFamily = "JetBrainsMono Nerd Font"
          var panel = createPanel()
          settle(panel)
          verify(panel.resultRows.some(function(row) { return row.kind === "game" }))
          capture(single, "sportray-following", 800, 1280)
          panel.selectDestination("nhl")
          panel.openStandings()
          settle(panel)
          compare(panel.standingsRows.filter(function(row) { return row.kind === "standings" }).length, 8)
          capture(single, "sportray-standings", 800, 1280)
          panel.selectDestination("mlb")
          panel.openGameDetail(root.sample.games.filter(function(g) { return g.id === root.sample.detailGameId })[0])
          settle(panel)
          capture(single, "sportray-details", 800, 1280)
          panel.destroy()
          wait(0)
          panel = createPanel()
          panel.openUtility("teams")
          settle(panel)
          capture(single, "sportray-favorites", 800, 1280)
          panel.captureHub.selectDestination("sports")
          settle(panel)
          capture(single, "sportray-leagues", 800, 1280)
          panel.captureHub.selectDestination("notifications")
          settle(panel)
          capture(single, "sportray-notifications", 800, 1280)
          single.visible = false
          ticker.visible = true
          wait(100)
          // Fit the sample strip to its native content so no game is cut at
          // either edge. The production strip's layout remains unchanged.
          ticker.width = Math.ceil(ticker.captureContentWidth + ticker.captureControlWidth
            + Commons.Style.spacing.sm * 2 + Commons.Style.spacing.md)
          wait(100)
          ticker.captureViewport.x = 0
          capture(ticker, "sportray-ticker", Math.ceil(ticker.width * 2), 64)
          ticker.visible = false
          board.visible = true
          panel.destroy()
          wait(0)
          for (var i = 0; i < 3; i++) {
            var example = createPanel()
            example.parent = board
            example.x = 20 + i * 420
            example.y = 48
            if (i === 1) { example.selectDestination("nhl"); example.openStandings() }
            if (i === 2) {
              example.selectDestination("mlb")
              example.openGameDetail(root.sample.games.filter(function(g) { return g.id === root.sample.detailGameId })[0])
            }
            settle(example)
          }
          wait(150)
          capture(board, "preview", 1280, 720)
          console.log("SPORTRAY_CAPTURE_PASS")
        } catch (error) {
          console.error("SPORTRAY_CAPTURE_FAIL " + String(error))
        }
        Qt.quit()
      }
    }
  }
}

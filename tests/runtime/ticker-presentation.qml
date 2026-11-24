import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import qs.Commons as Commons
import "../../components" as Components

Scope {
  id: root
  property var uiCase: ({name: "light", width: 400, fontSize: 12})
  property var fixtureGames: []
  property int panelCalls: 0
  property int pauseCalls: 0
  property var tooltipTarget: null
  property string tooltipText: ""
  readonly property string browserLog: Quickshell.env("SPORTRAY_TICKER_BROWSER_LOG")
  function readText(path) {
    var request = new XMLHttpRequest()
    request.open("GET", path, false)
    request.send()
    return request.responseText
  }
  Component.onCompleted: {
    root.uiCase = JSON.parse(root.readText(Qt.resolvedUrl("ui-case.json")))
    var sample = JSON.parse(root.readText(Qt.resolvedUrl("sample-state.json")))
    var hockey = JSON.parse(JSON.stringify(sample.games.filter(function(game) { return game.league === "nhl" })[0]))
    var football = JSON.parse(JSON.stringify(sample.games.filter(function(game) { return game.league === "nfl" })[0]))
    hockey.id = "nhl:2026020001"
    hockey.status = "live"
    hockey.startTime = sample.now
    hockey.awayScore = 9
    hockey.homeScore = 2
    hockey.periodLabel = "2nd"
    hockey.statusDetail = ""
    hockey.clock = "08:42"
    hockey.link = "https://www.nhl.com/gamecenter/2026020001"
    football.status = "live"
    football.startTime = sample.now
    football.awayScore = 20
    football.homeScore = 17
    football.periodLabel = "4th"
    football.statusDetail = ""
    football.clock = "02:16"
    root.fixtureGames = [hockey, football]
    Commons.Color.loadUserShell("")
    Commons.Color.loadColors(root.readText(Qt.resolvedUrl("theme/colors.toml")))
    Commons.Color.loadShell(root.readText(Qt.resolvedUrl("theme/shell.toml")))
    Commons.Style.cornerRadius = 8
    Commons.Style.fontBaseSize = root.uiCase.fontSize
    Commons.Style.fontFamily = "JetBrainsMono Nerd Font"
    test.start()
  }

  Window {
    id: window
    visible: true
    width: root.uiCase.width
    height: 160
    color: Commons.Color.background
    Components.TicketStrip {
      id: strip
      x: 0
      y: 40
      width: window.width
      games: root.fixtureGames
      favoriteTeamIds: root.fixtureGames.length ? [root.fixtureGames[0].awayTeam.id] : []
      nowMs: Date.parse(root.fixtureGames.length ? root.fixtureGames[0].startTime : "2026-10-11T20:00:00Z")
      tickerState: "ready"
      onPrimaryActionRequested: root.panelCalls++
      onPauseToggled: { root.pauseCalls++; strip.paused = !strip.paused }
      onTooltipRequested: function(target, text) { root.tooltipTarget = target; root.tooltipText = text }
      onTooltipDismissed: function(target) { if (root.tooltipTarget === target) { root.tooltipTarget = null; root.tooltipText = "" } }
    }
  }
  TestCase {
    id: test
    name: "TickerPresentation"
    when: false
    function check(condition, message) {
      if (!condition) throw new Error(message || "Ticker assertion failed")
    }
    function same(actual, expected, message) {
      check(JSON.stringify(actual) === JSON.stringify(expected), (message || "Different values")
        + ": " + JSON.stringify(actual) + " expected " + JSON.stringify(expected))
    }
    function closeTo(actual, expected, message) {
      check(Math.abs(actual - expected) < 0.1, (message || "Motion offset changed") + ": " + actual + " vs " + expected)
    }
    function findText(item, value) {
      if (item && item.visible && "text" in item && item.text === value) return item
      var children = item && item.children ? item.children : []
      for (var i = 0; i < children.length; i++) {
        var found = findText(children[i], value)
        if (found) return found
      }
      return null
    }
    function layoutDump(item) {
      var result = []
      var children = item && item.children ? item.children : []
      for (var i = 0; i < children.length; i++) {
        var child = children[i]
        if ("text" in child) result.push({text: child.text, width: child.width,
          implicit: child.implicitWidth, visible: child.visible, font: child.font.pixelSize})
        result = result.concat(layoutDump(child))
      }
      return result
    }
    function browserLines() {
      var value = root.readText("file://" + root.browserLog).trim()
      return value ? value.split("\n") : []
    }
    function capture(name) {
      var finished = false
      var ok = strip.grabToImage(function(result) {
        ok = result.saveToFile(Quickshell.env("SPORTRAY_TEST_CAPTURE") + "/" + name + ".png")
        finished = true
      })
      check(ok, "Could not start ticker capture")
      tryVerify(function() { return finished }, 2000)
      check(ok, "Could not save ticker capture")
    }
    function outside() { mouseMove(window.contentItem, window.width / 2, 120); wait(35) }
    function start() { when = true }
    function test_flow() {
      try {
        failOnWarning(/.?/)
        tryVerify(function() { return root.fixtureGames.length === 2 && strip.ticker.items.length === 2 }, 3000)
        // Let singleton file readers settle, then apply the explicit fixture
        // palette and font size as the real presentation harness does.
        wait(60)
        Commons.Color.loadUserShell("")
        Commons.Color.loadColors(root.readText(Qt.resolvedUrl("theme/colors.toml")))
        Commons.Color.loadShell(root.readText(Qt.resolvedUrl("theme/shell.toml")))
        Commons.Style.fontBaseSize = root.uiCase.fontSize
        Commons.Style.fontFamily = "JetBrainsMono Nerd Font"
        wait(30)
        same(Commons.Style.fontBaseSize, root.uiCase.fontSize, "Font fixture was not applied")
        outside()
        check(strip.hasTickerGames && strip.motionRunning, "Ticker motion never started")
        var start = strip.motionOffset
        wait(130)
        check(strip.motionOffset < start - 1, "Ticker did not advance with real frame animation")
        capture("ticker-ready")
        var pause = findChild(strip, "tickerPause")
        check(pause !== null && pause.height <= strip.height, "Pause target is clipped")
        mouseMove(pause, pause.width / 2, pause.height / 2)
        wait(40)
        check(strip.hoverPaused && !strip.motionRunning && !strip.paused, "Hover changed manual pause or did not freeze")
        var hovered = strip.motionOffset
        wait(120)
        closeTo(strip.motionOffset, hovered, "Hover did not freeze at the current position")
        mouseClick(pause, pause.width / 2, pause.height / 2)
        same(root.pauseCalls, 1, "Pause did not emit exactly once")
        same(root.panelCalls, 0, "Pause also opened the scores panel")
        same(browserLines().length, 0, "Pause also opened a source")
        outside()
        check(strip.paused && !strip.motionRunning, "Leaving hover resumed manual pause")
        var pausedOffset = strip.motionOffset
        wait(120)
        closeTo(strip.motionOffset, pausedOffset, "Manual pause snapped/reset position")
        capture("ticker-paused")
        wait(50)

        var first = findChild(strip, "tickerGame-0")
        var second = findChild(strip, "tickerGame-1")
        var firstX = first.mapToItem(strip, 0, 0).x
        var secondX = second.mapToItem(strip, 0, 0).x
        var oldLayout = layoutDump(first)
        var games = JSON.parse(JSON.stringify(root.fixtureGames))
        games[0].awayScore = 10
        games[0].statusDetail = "Power play"
        games[1].awayScore = 21
        root.fixtureGames = games
        wait(80)
        closeTo(strip.motionOffset, pausedOffset, "Score publication restarted ticker motion")
        closeTo(findChild(strip, "tickerGame-0").mapToItem(strip, 0, 0).x, firstX, "First game moved on score update")
        closeTo(findChild(strip, "tickerGame-1").mapToItem(strip, 0, 0).x, secondX,
          "Later game moved when score gained a digit; old=" + JSON.stringify(oldLayout)
          + " new=" + JSON.stringify(layoutDump(findChild(strip, "tickerGame-0"))))
        check(strip.ticker.items[0].favorite && strip.ticker.items[0].isLive, "Favorite/live metadata lost before rendering")
        same(strip.ticker.items[0].displayDetail, "2nd 08:42", "Optional situation hid the primary period/clock")
        check(strip.ticker.items[0].tooltip.indexOf("Power play") !== -1, "Tooltip lost optional game situation")
        check(strip.ticker.items[0].tooltip.indexOf("NHL.com") !== -1, "Full source tooltip unavailable")

        mouseMove(pause, pause.width / 2, pause.height / 2)
        wait(40)
        mouseClick(pause, pause.width / 2, pause.height / 2)
        same(root.pauseCalls, 2)
        check(!strip.paused && strip.hoverPaused, "Resume lost the active hover stop")
        closeTo(strip.motionOffset, pausedOffset, "Resume snapped before pointer left")
        outside()
        wait(120)
        check(strip.motionOffset < pausedOffset - 1 && strip.motionOffset > pausedOffset - 20,
          "Resume restarted instead of continuing the same offset")
        strip.reducedMotion = true
        wait(40)
        check(!strip.motionRunning && !strip.paused, "Reduced motion became a manual pause")
        closeTo(strip.motionOffset, 0, "Reduced-motion static view does not start readably")
        wait(110)
        closeTo(strip.motionOffset, 0, "Reduced-motion strip is still moving")
        capture("ticker-static")

        first = findChild(strip, "tickerGame-0")
        mouseMove(first, Math.min(first.width - 2, 12), first.height / 2)
        wait(450)
        var sourceText = findText(window.contentItem, strip.ticker.items[0].tooltip)
        check(sourceText !== null, "Full matchup/source tooltip text did not render in the window")
        check(sourceText.width <= strip.width, "Full matchup tooltip exceeds the narrow viewport")
        check(sourceText.text.indexOf("NHL.com") !== -1, "Tooltip lost provider identity")
        mouseClick(first, Math.min(first.width - 2, 12), first.height / 2)
        wait(120)
        same(browserLines(), ["https://www.nhl.com/gamecenter/2026020001"], "Game source did not launch exactly once")
        same(root.panelCalls, 0, "Nested game click also opened scores")
        outside()
        strip.nativeTooltips = true
        mouseMove(first, Math.min(first.width - 2, 12), first.height / 2)
        wait(40)
        same(root.tooltipText, strip.ticker.items[0].tooltip, "Layer tooltip portal lost full matchup text")
        check(root.tooltipTarget === first, "Layer tooltip portal has the wrong anchor")
        outside()
        check(root.tooltipTarget === null, "Layer tooltip portal did not dismiss on leave")
        mouseClick(strip, 1, strip.height / 2)
        same(root.panelCalls, 1, "Ticker chrome did not open scores exactly once")
        var unsafe = JSON.parse(JSON.stringify(root.fixtureGames[0]))
        unsafe.link = "https://espn.com.evil.example/game"
        root.fixtureGames = [unsafe]
        wait(40)
        first = findChild(strip, "tickerGame-0")
        mouseClick(first, Math.min(first.width - 2, 12), first.height / 2)
        same(root.panelCalls, 2, "Unsafe/unlinked game did not keep the neutral panel action")
        same(browserLines().length, 1, "Unsafe source launched a browser")

        strip.reducedMotion = false
        window.width = 1400
        wait(50)
        check(!strip.contentOverflows && !strip.motionRunning, "A short ticker scrolls through mostly blank space")
        var fitted = findChild(strip, "tickerGame-0").mapToItem(strip, 0, 0).x
        wait(80)
        closeTo(findChild(strip, "tickerGame-0").mapToItem(strip, 0, 0).x, fitted,
          "Fitted games are not stable/readable")
        window.width = root.uiCase.width
        strip.reducedMotion = true
        wait(30)

        strip.enabled = false
        wait(20)
        check(!strip.visible && !strip.motionRunning, "Disabled ticker is still visible or moving")
        strip.enabled = true
        strip.tickerState = "offline"
        wait(20)
        check(!strip.hasTickerGames && !strip.motionRunning, "Offline state is moving a game row")
        capture("ticker-offline")
        console.log("TICKER_PRESENTATION_PASS " + root.uiCase.name)
        Qt.quit()
      } catch (error) {
        console.error("TICKER_PRESENTATION_FAIL " + root.uiCase.name + ": " + error.message)
        Qt.quit()
      }
    }
  }
}

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import QtTest as Test
import Quickshell
import qs.Commons as Commons
import "../../components" as Components

ShellRoot {
  id: root
  property var uiCase: ({width: 320, fontSize: 16})
  property var sample: ({games: []})
  property var requests: []
  function read(path) {
    var xhr = new XMLHttpRequest()
    xhr.open("GET", Qt.resolvedUrl(path), false); xhr.send()
    return xhr.responseText
  }
  Window {
    id: window
    visible: true
    width: root.uiCase.width
    height: 640
    color: Commons.Color.popups.background
    Components.MatchupScoreboard {
      id: board
      x: 16; y: 16; width: parent.width - 32
      game: null
      semanticPrefix: "probe"
      onTeamScheduleRequested: function(teamId) { root.requests = root.requests.concat([teamId]) }
    }
    Timer { interval: 200; running: true; onTriggered: checks.run() }
    Test.TestCase {
      id: checks
      when: false
      function check(value, message) { if (!value) throw new Error(message || "Check failed") }
      function same(actual, expected, message) { check(actual === expected, (message || "Value mismatch") + ": " + actual + " / " + expected) }
      function walk(item, predicate) {
        if (predicate(item)) return item
        var children = item.children || []
        for (var i = 0; i < children.length; i++) { var result = walk(children[i], predicate); if (result) return result }
        return null
      }
      function node(name) { return walk(board, function(item) { return item.objectName === name }) }
      function textNode(text) { return walk(board, function(item) { return "text" in item && item.text === text && "contentWidth" in item }) }
      function capture(name) {
        var done = false, saved = false
        board.grabToImage(function(result) { saved = result.saveToFile(Quickshell.env("SPORTRAY_TEST_CAPTURE") + "/" + name + ".png"); done = true })
        for (var attempt = 0; !done && attempt < 100; attempt++) wait(30)
        check(done && saved, "Capture failed: " + name)
      }
      function fits(text) {
        check(text && text.contentWidth <= text.width + 1, "Text overflows horizontally: " + (text ? text.text : "missing"))
        check(text.contentHeight <= text.height + 1, "Text overflows vertically: " + text.text)
      }
      function run() {
        try {
          root.uiCase = JSON.parse(root.read("ui-case.json"))
          root.sample = JSON.parse(root.read("sample-state.json"))
          Commons.Color.loadUserShell(""); Commons.Color.loadColors(root.read("theme/colors.toml")); Commons.Color.loadShell(root.read("theme/shell.toml"))
          Commons.Style.fontBaseSize = root.uiCase.fontSize; Commons.Style.cornerRadius = 8
          var game = JSON.parse(JSON.stringify(root.sample.games[0]))
          game.awayTeam.name = "University of North Carolina at Asheville Bulldogs"
          game.homeTeam.name = "Averylongunbrokenteamidentityforanarrowdisplay"
          game.awayScore = 9999; game.homeScore = 8888
          game.presentation = {awayIsFavorite: true, homeIsFavorite: false}
          board.game = game; wait(80)
          same(board.awayIsFavorite, true); same(board.homeIsFavorite, false)
          fits(node("probeScore0")); fits(node("probeScore1"))
          fits(textNode(game.awayTeam.name)); fits(textNode(game.homeTeam.name))
          capture("large-scores-long-names")
          var link = board.teamLink("away")
          link.forceActiveFocus(); keyClick(Qt.Key_Space); wait(30)
          same(root.requests[0], game.awayTeam.id, "Keyboard team route changed canonical identity")
          board.teamLinksEnabled = false; wait(20)
          check(!board.teamLink("away").available && !board.focusTeam(game.awayTeam.id), "Read-only scoreboards expose team actions")
          board.teamLinksEnabled = true
          var pregame = JSON.parse(JSON.stringify(game))
          pregame.status = "scheduled"; pregame.startTime = "2026-10-11T20:00:00Z"
          pregame.statusDetail = "Scheduled"; pregame.periodLabel = "Old third"; pregame.clock = "08:42"
          board.game = pregame; wait(40)
          same(node("probeStartTime").text, "4:00 PM")
          check(node("probeStartDate").text.indexOf("Oct 11") !== -1, "Exact local date missing")
          check(board.stateLabel.indexOf("Old third") === -1 && board.stateLabel.indexOf("08:42") === -1, "Pregame leaks retained live state")
          check(!node("probeScore0").visible && !node("probeScore1").visible, "Pregame displays scores")
          fits(node("probeStartTime")); fits(node("probeStartDate"))
          capture("scheduled")
          pregame.startTime = null; board.game = JSON.parse(JSON.stringify(pregame)); wait(30)
          same(node("probeStartTime").text, "Start time unavailable")
          fits(node("probeStartTime"))
          board.timeText = "Time TBD"; board.dateText = "Wed, Nov 25"; board.timeKnown = false; wait(30)
          same(node("probeStartTime").text, "Time TBD"); same(node("probeStartDate").text, "Wed, Nov 25")
          fits(node("probeStartTime")); fits(node("probeStartDate"))
          board.timeText = ""; board.dateText = ""
          for (var state of ["postponed", "canceled", "unknown", "final"]) {
            var administrative = JSON.parse(JSON.stringify(game)); administrative.status = state; administrative.statusDetail = null
            board.game = administrative; wait(20)
            check(board.stateLabel.indexOf("08:42") === -1, state + " leaks old clock")
            if (state !== "final") same(node("probeScore0").text, "—", state + " invents a result")
          }
          console.log("MATCHUP_SCOREBOARD_PASS " + root.uiCase.width + "/" + root.uiCase.fontSize)
        } catch (error) { console.error("MATCHUP_SCOREBOARD_FAIL " + String(error)) }
        Qt.quit()
      }
    }
  }
}

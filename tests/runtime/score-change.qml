pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import qs.Commons as Commons
import "../../components" as Components
import "../../model/LifecyclePolicy.js" as LifecyclePolicy

Scope {
  id: root
  property var uiCase: ({name:"light",width:400,fontSize:12})
  property var fixtureGame: null
  function read(path) {
    var request = new XMLHttpRequest()
    request.open("GET", path, false); request.send()
    return request.responseText
  }
  function game(away, home, id) {
    var value = JSON.parse(JSON.stringify(root.fixtureGame))
    value.providerGameId = id || "score-change-1"
    value.id = "nhl:" + value.providerGameId
    value.status = "live"; value.awayScore = away; value.homeScore = home
    return value
  }
  Component.onCompleted: {
    root.uiCase = JSON.parse(root.read(Qt.resolvedUrl("ui-case.json")))
    var sample = JSON.parse(root.read(Qt.resolvedUrl("sample-state.json")))
    root.fixtureGame = sample.games.filter(function(game) { return game.league === "nhl" })[0]
    Commons.Color.loadUserShell("")
    Commons.Color.loadColors(root.read(Qt.resolvedUrl("theme/colors.toml")))
    Commons.Color.loadShell(root.read(Qt.resolvedUrl("theme/shell.toml")))
    Commons.Style.cornerRadius = 8
    Commons.Style.fontBaseSize = root.uiCase.fontSize
    Commons.Style.fontFamily = "JetBrainsMono Nerd Font"
    startTimer.start()
  }
  Timer { id: startTimer; interval: 100; repeat: false; onTriggered: checks.start() }
  Window {
    id: window
    visible: true
    width: root.uiCase.width
    height: 180
    color: Commons.Color.popups.background
    Rectangle { anchors.fill: parent; color: Commons.Color.popups.background }
    Components.GameRow {
      id: row
      x: 12; y: 24
      width: window.width - 24
      game: root.fixtureGame ? root.game(1,0) : ({status:"unknown",awayTeam:null,homeTeam:null,presentation:{}})
      currentTime: Date.parse("2026-10-11T20:00:00Z")
    }
  }
  TestCase {
    id: checks
    name: "ScoreChangePresentation"
    when: false
    function check(value, message) { if (!value) throw new Error(message || "Score-change check failed") }
    function quiet(message) {
      check(row.awayScoreHighlight === 0 && row.homeScoreHighlight === 0, message || "Unexpected score pulse")
    }
    function settle() { wait(30) }
    function capture(name) {
      var done = false, saved = false
      window.contentItem.grabToImage(function(result) {
        saved = result.saveToFile(Quickshell.env("SPORTRAY_TEST_CAPTURE") + "/" + name + ".png")
        done = true
      })
      tryVerify(function() { return done },5000)
      check(saved,"Could not capture " + name)
    }
    function start() {
      try {
        wait(150)
        Commons.Style.reduceMotion = false
        settle()
        quiet("Initial binding or motion recovery pulsed")
        var height = row.height, width = row.width
        capture("score-baseline")
        row.game = root.game(2,0)
        tryVerify(function() { return row.awayScoreHighlight > 0 },1000)
        check(row.homeScoreHighlight === 0,"Unchanged home score pulsed")
        check(row.height === height && row.width === width,"Score feedback changed card geometry")
        capture("score-away-update")
        wait(240); quiet("Away pulse did not finish within its bounded duration")
        row.game = root.game(2,1)
        tryVerify(function() { return row.homeScoreHighlight > 0 },1000)
        check(row.awayScoreHighlight === 0,"Unchanged away score pulsed")
        capture("score-home-update")
        wait(240); quiet()
        var publication = root.game(2,1); publication.clock = "06:01"
        row.game = publication; settle(); quiet("Clock-only publication pulsed")
        row.game = root.game(3,1)
        tryVerify(function() { return row.awayScoreHighlight > 0 },1000)
        row.game = root.game(8,6,"recycled-2"); settle(); quiet("Recycled identity pulsed")
        row.game = root.game(8,7,"recycled-2")
        tryVerify(function() { return row.homeScoreHighlight > 0 },1000)
        row.stale = true; settle(); quiet("Stale state did not stop the pulse")
        row.game = root.game(9,7,"recycled-2"); settle(); quiet("Stale update pulsed")
        row.stale = false; settle(); quiet("Fresh recovery pulsed")
        row.visible = false
        row.game = root.game(10,7,"recycled-2"); settle(); quiet("Hidden item update pulsed")
        row.visible = true; settle(); quiet("Item reveal pulsed")
        window.visible = false
        row.game = root.game(11,7,"recycled-2"); settle(); quiet("Hidden window update pulsed")
        window.visible = true; settle(); quiet("Window reveal pulsed")
        row.game = root.game(12,7,"recycled-2")
        tryVerify(function() { return row.awayScoreHighlight > 0 },1000)
        Commons.Style.reduceMotion = true; settle(); quiet("Reduced motion did not stop the pulse")
        row.game = root.game(13,7,"recycled-2"); settle(); quiet("Reduced-motion update pulsed")
        capture("score-reduced-motion")
        Commons.Style.reduceMotion = false; settle(); quiet("Motion recovery pulsed")
        row.game = root.game(14,7,"recycled-2")
        tryVerify(function() { return row.awayScoreHighlight > 0 },1000)
        var unavailable = root.game(null,7,"recycled-2")
        row.game = unavailable; settle(); quiet("Unavailable score pulsed")
        row.game = root.game(15,7,"recycled-2"); settle(); quiet("First available score pulsed")
        var component = Qt.createComponent(Qt.resolvedUrl("plugin/components/GameRow.qml"))
        check(component.status === Component.Ready,component.errorString())
        var temporary = component.createObject(window.contentItem,{game:root.game(1,0),width:300})
        check(temporary !== null,"Could not create disposable score owner")
        wait(0)
        temporary.game = root.game(2,0)
        LifecyclePolicy.invalidate(temporary.scoreCallbackOwner)
        temporary.destroy(); wait(0)
        check(row.height === height && row.width === width,"Final feedback geometry changed")
        console.log("SCORE_CHANGE_PASS " + root.uiCase.name)
        Qt.quit()
      } catch (error) {
        console.error("SCORE_CHANGE_FAIL " + String(error) + " " + error.stack)
        Qt.quit()
      }
    }
  }
}

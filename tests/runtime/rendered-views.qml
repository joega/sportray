import QtQuick
import QtQuick.Window
import Quickshell
import "../../components" as Components
import "../../model/SettingsModel.js" as SettingsModel
import "../../model/GameDetailState.js" as GameDetailState
import "../../model/StandingsRows.js" as StandingsRows

// Real installed Omarchy UI types in an ordinary offscreen Qt window.
// Panel/KeyboardPanel needs a Wayland PanelWindow backend and is deliberately
// outside this fixture. This proves view rendering/bindings, not desktop input.
ShellRoot {
  id: root
  property var source: null
  property var standingsSamples: null
  property var selection: null
  property var leagueStates: []
  property int step: 0
  property int sampleIndex: 0
  property real savedScroll: 0
  property int renderCount: 0
  property int retries: 0
  readonly property double nowMs: source ? Date.parse(source.now) : Date.now()
  readonly property var detailState: GameDetailState.resolve(selection,
    root.leagueStates, source ? source.dateKey : "", root.nowMs)
  property var tableState: ({})
  readonly property var tableRows: StandingsRows.flatten(root.tableState, [])

  function require(value, message) { if (!value) throw new Error(message) }
  function jsonFile(path) {
    var request = new XMLHttpRequest()
    request.open("GET", Qt.resolvedUrl(path), false)
    request.send()
    return JSON.parse(request.responseText)
  }
  function game(key, linked) {
    var value = JSON.parse(JSON.stringify(source.games[key]))
    value.awayTeam.league = value.league
    value.homeTeam.league = value.league
    value.awayTeam.providerTeamId = value.awayTeam.id.split(":")[1]
    value.homeTeam.providerTeamId = value.homeTeam.id.split(":")[1]
    value.link = linked === false ? null : "https://www.nhl.com/gamecenter/game-1"
    // Long normalized local stats exercise actual scrolling and preserved focus.
    value.stats = {away: [], home: []}
    for (var i = 0; i < 8; i++) {
      value.stats.away.push({key: "stat-" + i, label: "Fixture stat " + i, value: String(i)})
      value.stats.home.push({key: "stat-" + i, label: "Fixture stat " + i, value: String(i + 1)})
    }
    return value
  }
  function slate(games, options) {
    root.leagueStates = [Object.assign({leagueId: "nhl", displayName: "NHL", games: games,
      hasData: true, loading: false, stale: false, errorCode: "", errorSummary: "",
      lastSuccessAt: source.lastSuccessAt}, options || {})]
  }
  function descendants(object, predicate, seen) {
    if (!object || seen.indexOf(object) !== -1 || seen.length > 2500) return null
    seen.push(object)
    if (predicate(object)) return object
    var keys = ["data", "children", "contentItem"]
    for (var i = 0; i < keys.length; i++) {
      var value = object[keys[i]]
      if (!value) continue
      if (typeof value.length === "number") {
        for (var j = 0; j < value.length; j++) {
          var found = descendants(value[j], predicate, seen)
          if (found) return found
        }
      } else {
        var foundItem = descendants(value, predicate, seen)
        if (foundItem) return foundItem
      }
    }
    return null
  }
  function capture(item, name, afterCapture) {
    renderCount++
    item.grabToImage(function(result) {
      if (!result.saveToFile(Quickshell.env("SPORTRAY_TEST_CAPTURE") + "/" + name + ".png")) {
        console.error("VIEWS_TEST FAIL capture " + name)
        return
      }
      root.renderCount--
      if (afterCapture) afterCapture()
    })
  }
  function scoreText(value) {
    return descendants(renderDetail, function(item) {
      return "text" in item && item.text === String(value) && "textFormat" in item
    }, [])
  }

  function advanceStandings() {
    root.sampleIndex++
    if (root.sampleIndex < root.standingsSamples.length)
      root.tableState = root.standingsSamples[root.sampleIndex].state
    else root.step++
  }

  QtObject {
    id: testStore
    property bool ready: true
    property string preservedRawStateText: ""
    property var watchedGames: []
    property var settings: SettingsModel.createDefaults()
    function isLeagueEnabled(league) { return league === "nhl" }
    function toggleWatch(value) { return false }
  }

  Window {
    id: renderWindow
    width: 400
    height: 360
    visible: true
    color: "#101315"
    Components.GameDetailView {
      id: renderDetail
      anchors.fill: parent
      visible: root.step < 6
      game: root.detailState.game
      updateMessage: root.detailState.message
      stale: root.detailState.stale
      settingsStore: testStore
      currentTime: root.nowMs
    }
    Components.StandingsStatus {
      id: renderStatus
      width: parent.width
      visible: root.step >= 6
      row: root.tableRows.length ? root.tableRows[0] : ({})
      currentTime: Date.parse("2026-11-24T12:05:00Z")
      onRetry: root.retries++
    }
  }

  Component.onCompleted: {
    try {
      source = jsonFile("../../fixtures/presentation/game-detail-state.json")
      standingsSamples = jsonFile("../../fixtures/presentation/standings-states.json").cases
      var initial = game("live")
      selection = {game: initial, dateKey: source.dateKey, lastSuccessAt: source.lastSuccessAt}
      slate([initial])
      poll.start()
    } catch (error) { console.error("VIEWS_TEST FAIL " + String(error)) }
  }

  Timer {
    id: poll
    interval: 80
    repeat: true
    onTriggered: {
      try {
        if (root.renderCount > 0) return
        var scroll = root.descendants(renderDetail,
          function(item) { return "contentY" in item && "contentHeight" in item }, [])
        require(scroll !== null, "rendered detail has no scroll surface")
        if (step === 0) {
          require(renderDetail.detail.participants[0].score === 1 && scoreText(1) !== null,
            "initial detail score not rendered")
          renderDetail.cursorIndex = 2
          var sourceAction = descendants(renderDetail,
            function(item) { return "openSource" in item && "hasCursor" in item }, [])
          var watchAction = descendants(renderDetail,
            function(item) { return "watchCount" in item && "hasCursor" in item }, [])
          require(sourceAction !== null && watchAction !== null, "detail actions absent")
          require(sourceAction.hasCursor && !watchAction.hasCursor,
            "source and Watch cursor highlights disagree with action index")
          renderDetail.cursorIndex = 1
          scroll.contentY = 25
          savedScroll = scroll.contentY
          require(savedScroll === 25, "rich fixture did not produce a scrollable detail")
          capture(renderDetail, "detail-live", function() {
            slate([game("scored")], {lastSuccessAt: "2026-11-24T20:01:00Z"})
            step++
          })
        } else if (step === 1) {
          require(renderDetail.game.awayScore === 2 && renderDetail.detail.participants[0].score === 2
            && scoreText(2) !== null, "live score text stayed frozen")
          require(renderDetail.cursorIndex === 1 && scroll.contentY === savedScroll,
            "refresh reset detail cursor or scroll")
          capture(renderDetail, "detail-scored", function() {
            slate([game("final")], {lastSuccessAt: "2026-11-24T20:02:00Z"})
            step++
          })
        } else if (step === 2) {
          require(renderDetail.game.status === "final", "final transition did not update detail")
          // Model callers retain the latest resolved snapshot on disappearance.
          // Panel integration is checked separately on a real Wayland backend.
          selection = {game: detailState.game, dateKey: source.dateKey,
            lastSuccessAt: detailState.lastSuccessAt}
          slate([], {lastSuccessAt: "2026-11-24T20:03:00Z"})
          step++
        } else if (step === 3) {
          require(detailState.missing && renderDetail.stale
            && renderDetail.game.status === "final" && renderDetail.game.awayScore === 3,
            "missing game lost latest retained detail")
          require(detailState.lastSuccessAt === "2026-11-24T20:02:00Z",
            "missing game adopted unrelated slate update time")
          require(renderDetail.updateMessage.indexOf("no longer") !== -1, "missing warning absent")
          capture(renderDetail, "detail-missing", function() {
            slate([game("scored")], {errorCode: "unavailable", stale: true})
            step++
          })
        } else if (step === 4) {
          require(renderDetail.stale && renderDetail.updateMessage.indexOf("temporarily unavailable") !== -1,
            "retained error warning absent")
          renderDetail.cursorIndex = 2
          slate([game("scored", false)])
          step++
        } else if (step === 5) {
          require(!renderDetail.sourceAvailable && renderDetail.cursorIndex === 0,
            "disappearing source action failed to restore Back cursor")
          var back = descendants(renderDetail, function(item) {
            return "text" in item && "hasCursor" in item && item.text === "Back"
          }, [])
          require(back !== null && back.hasCursor, "Back fallback lacks visible cursor")
          root.tableState = standingsSamples[0].state
          step++
        } else if (step === 6) {
          var sample = standingsSamples[sampleIndex]
          require(JSON.stringify(tableRows.map(function(row) { return row.kind }))
            === JSON.stringify(sample.kinds), "standings rows wrong: " + sample.name)
          if (sample.kinds[0] !== "standings-section") {
            require(renderStatus.message === sample.text && renderStatus.implicitHeight > 0,
              "standings text differs: " + sample.name + ": " + renderStatus.message)
            var before = root.retries
            renderStatus.activatePrimaryAction()
            require(root.retries === before + (sample.retry ? 1 : 0),
              "standings retry admission wrong: " + sample.name)
            capture(renderStatus, "standings-" + sampleIndex, root.advanceStandings)
          } else {
            require(!renderStatus.actionable, "healthy recovery retains retry")
            root.advanceStandings()
          }
        } else {
          console.log("VIEWS_TEST PASS")
          stop()
        }
      } catch (error) {
        console.error("VIEWS_TEST FAIL " + String(error))
        stop()
      }
    }
  }
}

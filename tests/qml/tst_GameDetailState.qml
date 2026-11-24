import QtQuick
import QtTest
import "../../model/GameDetailState.js" as GameDetailState

TestCase {
  id: testCase
  name: "GameDetailState"

  function init() { failOnWarning(/.?/) }

  function fixture() {
    var request = new XMLHttpRequest()
    request.open("GET", Qt.resolvedUrl("../../fixtures/presentation/game-detail-state.json"), false)
    request.send()
    return JSON.parse(request.responseText)
  }

  function test_projection_data() {
    return fixture().cases.map(function(sample) {
      return {tag: sample.name, sampleText: JSON.stringify(sample)}
    })
  }

  function statesFor(sample, source) {
    return sample.states.map(function(state) {
      var next = Object.assign({}, state)
      next.games = state.gameKeys.map(function(key) { return source.games[key] })
      delete next.gameKeys
      return next
    })
  }

  function test_projection(data) {
    var source = fixture()
    var sample = JSON.parse(data.sampleText)
    var selection = {game: source.games[sample.selectionGame], dateKey: source.dateKey,
      lastSuccessAt: "selectionLastSuccessAt" in sample ? sample.selectionLastSuccessAt : source.lastSuccessAt}
    var states = statesFor(sample, source)
    var before = JSON.stringify({selection: selection, states: states})
    var result = GameDetailState.resolve(selection, states,
      sample.selectedDateKey || source.dateKey, Date.parse(sample.now || source.now))
    compare(result.game, source.games[sample.expected.game])
    compare(result.stale, sample.expected.stale)
    compare(result.missing, sample.expected.missing)
    compare(result.loading, sample.expected.loading)
    compare(result.message, sample.expected.message)
    if ("lastSuccessAt" in sample.expected)
      compare(result.lastSuccessAt, sample.expected.lastSuccessAt)
    compare(JSON.stringify({selection: selection, states: states}), before)
    verify(result.message.indexOf("<b>") === -1)
  }

  function test_emptyOrInvalidSelection() {
    var empty = {game: null, stale: false, missing: false, loading: false,
      lastSuccessAt: "", message: ""}
    compare(GameDetailState.resolve(null, [], "2026-11-24", 0), empty)
    compare(GameDetailState.resolve({game: {}, dateKey: "2026-11-24"}, [], "2026-11-24", 0), empty)
    compare(GameDetailState.resolve({game: {isValid: true, id: "", league: "nhl"}}, [], "", 0), empty)
  }

  Component {
    id: consumerComponent
    QtObject {
      id: consumer
      property string selectionText: ""
      property string statesText: "[]"
      property string dateKey: "2026-11-24"
      property double nowMs: Date.parse("2026-11-24T20:02:00Z")
      readonly property var selection: selectionText ? JSON.parse(selectionText) : null
      readonly property var states: JSON.parse(statesText)
      readonly property var detailState: GameDetailState.resolve(selection, states, dateKey, nowMs)
    }
  }

  function test_bindingFollowsUpdatesThenRetainsLastResolvedSnapshot() {
    var source = fixture()
    var selection = {game: source.games.live, dateKey: source.dateKey, lastSuccessAt: source.lastSuccessAt}
    var consumer = consumerComponent.createObject(testCase, {
      selectionText: JSON.stringify(selection),
      statesText: JSON.stringify(statesFor(source.cases[0], source))
    })
    compare(consumer.detailState.game.awayScore, 2)
    selection.game = consumer.detailState.game
    selection.lastSuccessAt = consumer.detailState.lastSuccessAt
    consumer.selectionText = JSON.stringify(selection)
    consumer.statesText = JSON.stringify(statesFor(source.cases[2], source))
    compare(consumer.detailState.game.status, "final")
    compare(consumer.detailState.game.awayScore, 3)
    selection.game = consumer.detailState.game
    selection.lastSuccessAt = consumer.detailState.lastSuccessAt
    consumer.selectionText = JSON.stringify(selection)
    var missing = statesFor(source.cases[9], source)
    consumer.statesText = JSON.stringify(missing)
    compare(consumer.detailState.game.status, "final")
    compare(consumer.detailState.game.awayScore, 3)
    verify(consumer.detailState.missing)
    verify(consumer.detailState.stale)
    consumer.destroy()
  }

  function test_bindingClockMarksRetainedDetailStale() {
    var source = fixture()
    var consumer = consumerComponent.createObject(testCase, {
      selectionText: JSON.stringify({game: source.games.live, dateKey: source.dateKey}),
      statesText: JSON.stringify(statesFor(source.cases[0], source))
    })
    compare(consumer.detailState.stale, false)
    consumer.nowMs = Date.parse("2026-11-24T20:06:00Z")
    compare(consumer.detailState.stale, true)
    compare(consumer.detailState.message, "Showing last update · 6 min ago")
    consumer.destroy()
  }
}

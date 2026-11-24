import QtQuick
import QtTest
import "../../model/PanelPresentation.js" as PanelPresentation
import "../../model/ResultRows.js" as ResultRows
import "../../model/FavoritePresentation.js" as FavoritePresentation
import "../../model/ScoreboardModel.js" as ScoreboardModel
import "../../model/WatchPolicy.js" as WatchPolicy

TestCase {
  id: testCase
  name: "FollowingFreshness"

  function init() { failOnWarning(/.?/) }

  function test_projection_data() {
    var request = new XMLHttpRequest()
    request.open("GET", Qt.resolvedUrl("../../fixtures/presentation/following-freshness.json"), false)
    request.send()
    var fixture = JSON.parse(request.responseText)
    return fixture.cases.map(function(sample) {
      sample.tag = sample.name
      sample.now = Date.parse(fixture.now)
      return sample
    })
  }

  function test_projection(sample) {
    var composed = ScoreboardModel.compose(sample.states, sample.enabled, sample.favorites,
      FavoritePresentation.orderGames)
    var view = PanelPresentation.build(composed, sample.favorites,
      FavoritePresentation.orderGames, FavoritePresentation.isFavoriteGame,
      sample.followed, 0, sample.watches, sample.now, WatchPolicy.normalizeWatches).following
    var rows = ResultRows.flatten(view, "following", sample.dateLabel || "Today")
    compare(rows.filter(function(r) { return r.kind === "status" }).map(function(r) { return r.status.leagueId }), sample.statusLeagues)
    compare(rows.filter(function(r) { return r.kind === "game" }).map(function(r) { return r.game.id }), sample.gameIds)
    compare(rows.filter(function(r) { return r.kind === "game" }).map(function(r) { return r.stale }), sample.stale)
    compare(view.loading, sample.loading)
    compare(rows.some(function(r) { return r.kind === "loading" }), sample.loading && !sample.gameIds.length)
    compare(rows.filter(function(r) { return r.kind === "empty" }).map(function(r) { return r.title }),
      sample.emptyTitle ? [sample.emptyTitle] : [])
  }

  Component {
    id: clockConsumer
    QtObject {
      id: clockFixture
      property double nowMs: Date.parse("2026-11-23T23:10:00Z")
      property string sampleText: ""
      readonly property var sample: sampleText ? JSON.parse(sampleText) : null
      readonly property var view: clockFixture.sample ? PanelPresentation.build(
        ScoreboardModel.compose(clockFixture.sample.states, clockFixture.sample.enabled, clockFixture.sample.favorites, FavoritePresentation.orderGames),
        clockFixture.sample.favorites, FavoritePresentation.orderGames, FavoritePresentation.isFavoriteGame,
        clockFixture.sample.followed, 0, clockFixture.sample.watches, clockFixture.nowMs, WatchPolicy.normalizeWatches).following : null
    }
  }

  function test_clockExpiryRemovesWatchOnlyRowsAndNotices() {
    var sample = test_projection_data().filter(function(s) {
      return s.name === "watch-only retained game is visible with its freshness"
    })[0]
    // Parse inside the binding's engine context, matching the production JS
    // pipeline rather than createObject's QVariant conversion of nested arrays.
    var consumer = clockConsumer.createObject(testCase, {sampleText: JSON.stringify(sample)})
    compare(consumer.view.games.length, 1)
    compare(consumer.view.leagueStates.length, 1)
    consumer.nowMs = Date.parse("2026-11-23T23:12:00Z")
    compare(consumer.view.games.length, 0)
    compare(consumer.view.leagueStates.length, 0)
    consumer.destroy()
  }
}

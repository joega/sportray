import QtQuick
import QtTest

TestCase {
  id: testCase
  name: "StandingsFetch"
  property var fetchOwner: null

  function jsonFile(path) {
    var request = new XMLHttpRequest()
    request.open("GET", Qt.resolvedUrl(path), false)
    request.send()
    return JSON.parse(request.responseText)
  }

  function fixture(league) {
    return jsonFile("../../fixtures/espn/standings/" + league + ".json")
  }

  function init() {
    failOnWarning(/.?/)
    var component = Qt.createComponent(Qt.resolvedUrl("../../services/StandingsFetch.qml"))
    compare(component.status, Component.Ready, component.errorString())
    fetchOwner = component.createObject(testCase)
    verify(fetchOwner !== null)
  }

  function cleanup() {
    if (fetchOwner) fetchOwner.destroy()
    fetchOwner = null
    wait(0)
  }

  function test_currentResponse_data() {
    return ["nfl", "mlb", "nba", "eng.1", "usa.1"].map(function(league) {
      return {tag: league, league: league}
    })
  }

  function test_currentResponse(data) {
    var sample = fixture(data.league)
    var result = fetchOwner.parseBody(JSON.stringify(sample.payload), data.league)
    verify(result !== null)
    compare(result.errors.length, 0)
    compare(result.groups.map(function(g) { return g.label }), sample.expected.labels)
    compare(result.rows.map(function(r) { return r.team.id }), sample.expected.ids)
    compare(result.rows.map(function(r) { return r.rankKind }), sample.expected.rankKinds)
  }

  function test_nhlGroupsSurviveQmlImport() {
    var result = fetchOwner.parseBody(JSON.stringify(jsonFile("../../fixtures/nhl/standings.json")), "nhl")
    compare(result.groups.length, 2)
    compare(result.rows.length, 4)
    compare(result.rows[0].team.id, "nhl:12")
    compare(result.rows[0].rankKind, "rank")
  }

  function test_sameLeagueFailureRetainsOnlyItsLastGoodTable() {
    var sample = fixture("nfl")
    var process = findChild(fetchOwner, "fixtureProcess")
    verify(fetchOwner.load("nfl", false))
    verify(!fetchOwner.load("nfl", false))
    compare(process.starts, 1)
    compare(process.command[process.command.length - 1], sample.source)
    process.finish(0, JSON.stringify(sample.payload))
    verify(fetchOwner.hasData)
    var ids = fetchOwner.rows.map(function(r) { return r.team.id })
    verify(fetchOwner.load("nfl", true))
    process.finish(4, "")
    verify(fetchOwner.stale)
    compare(fetchOwner.rows.map(function(r) { return r.team.id }), ids)
    verify(fetchOwner.load("nfl", true))
    process.finish(0, "{}")
    verify(fetchOwner.hasData)
    verify(fetchOwner.stale)
    compare(fetchOwner.rows.map(function(r) { return r.team.id }), ids)
  }

  function test_switchFailureDoesNotShowAnotherLeaguesTeams() {
    var process = findChild(fetchOwner, "fixtureProcess")
    fetchOwner.load("nfl", false)
    process.finish(0, JSON.stringify(fixture("nfl").payload))
    verify(fetchOwner.hasData)
    verify(fetchOwner.load("eng.1", false))
    compare(fetchOwner.rows.length, 0)
    verify(!fetchOwner.hasData)
    process.finish(4, "")
    compare(fetchOwner.leagueId, "eng.1")
    compare(fetchOwner.rows.length, 0)
    verify(!fetchOwner.hasData)
    verify(fetchOwner.errorCode !== "")
    verify(fetchOwner.load("eng.1", true))
    process.finish(0, JSON.stringify(fixture("eng.1").payload))
    verify(fetchOwner.hasData)
    verify(!fetchOwner.stale)
    compare(fetchOwner.rows[0].team.id, fixture("eng.1").expected.ids[0])
  }

  function test_rapidSwitchWaitsForOldExitAndKeepsOnlyLatestTarget() {
    var process = findChild(fetchOwner, "fixtureProcess")
    fetchOwner.load("nfl", false)
    fetchOwner.load("nba", false)
    fetchOwner.load("eng.1", false)
    // Setting running=false requests termination; the fixture deliberately
    // emits the old stdout/exited later, as the real Process does.
    compare(process.starts, 1)
    compare(fetchOwner.requestLeagueId, "nfl")
    compare(process.command[process.command.length - 1], fixture("nfl").source)
    compare(fetchOwner.leagueId, "eng.1")
    process.finish(9, JSON.stringify(fixture("nfl").payload))
    compare(process.starts, 2)
    compare(fetchOwner.requestLeagueId, "eng.1")
    compare(process.command[process.command.length - 1], fixture("eng.1").source)
    compare(fetchOwner.rows.length, 0)
    verify(fetchOwner.loading)
    process.finish(0, JSON.stringify(fixture("eng.1").payload))
    verify(!fetchOwner.loading)
    compare(fetchOwner.rows.map(function(r) { return r.team.id }), fixture("eng.1").expected.ids)
  }

  function test_unsupportedClearsQueuedReplacement() {
    var process = findChild(fetchOwner, "fixtureProcess")
    fetchOwner.load("nfl", false)
    fetchOwner.load("nba", false)
    fetchOwner.load("unsupported", false)
    process.finish(0, JSON.stringify(fixture("nfl").payload))
    compare(process.starts, 1)
    compare(fetchOwner.pendingLeagueId, "")
    compare(fetchOwner.leagueId, "unsupported")
    compare(fetchOwner.errorCode, "unsupported")
    compare(fetchOwner.rows.length, 0)
  }

  function test_bodyAdmissionRemainsBounded() {
    compare(fetchOwner.parseBody("{", "nfl"), null)
    compare(fetchOwner.parseBody(new Array(699052).join("x"), "nfl"), null)
  }

  function test_unsupportedSwitchRejectsLateCompletion() {
    var process = findChild(fetchOwner, "fixtureProcess")
    fetchOwner.load("nfl", false)
    verify(!fetchOwner.load("unsupported", false))
    process.finish(0, JSON.stringify(fixture("nfl").payload))
    compare(fetchOwner.leagueId, "unsupported")
    compare(fetchOwner.errorCode, "unsupported")
    compare(fetchOwner.rows.length, 0)
    compare(fetchOwner.lastSuccessAt, "")
    verify(!fetchOwner.stale)
  }
}

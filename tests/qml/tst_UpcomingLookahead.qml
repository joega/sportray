import QtQuick
import QtTest

TestCase {
  id: testCase
  name: "UpcomingLookahead"
  property var fetchOwner: null
  property var scoreProcess: null
  property var lookaheadProcess: null

  function emptyPage(nextDate) {
    return JSON.stringify({gameWeek: [], nextStartDate: nextDate})
  }
  function jsonFile(name) {
    var request = new XMLHttpRequest()
    request.open("GET", Qt.resolvedUrl("../../fixtures/nhl/lookahead/" + name + ".json"), false)
    request.send()
    return request.responseText
  }
  function yieldNextPage() {
    fetchOwner.externalRequestBusy = true
    lookaheadProcess.finish(0, emptyPage("2026-08-21"))
    compare(fetchOwner.deferredLookaheadDateKey, "2026-08-21")
    compare(fetchOwner.lookaheadHopCount, 1)
    compare(lookaheadProcess.starts, 1)
    compare(lookaheadProcess.running, false)
    compare(fetchOwner.nextGameStatus, "loading")
  }

  function init() {
    failOnWarning(/.?/)
    var component = Qt.createComponent(Qt.resolvedUrl("../../services/LeagueFetch.qml"))
    compare(component.status, Component.Ready, component.errorString())
    fetchOwner = component.createObject(testCase, {
      leagueId: "nhl", displayName: "NHL", dateKey: "2026-08-19", leagueEnabled: true
    })
    verify(fetchOwner !== null)
    scoreProcess = findChild(fetchOwner, "fixtureProcess")
    verify(scoreProcess !== null)
    scoreProcess.objectName = "scoreProcess"
    lookaheadProcess = findChild(fetchOwner, "fixtureProcess")
    verify(lookaheadProcess !== null)
    verify(scoreProcess !== lookaheadProcess)
    fetchOwner.lookaheadEnabled = true
    compare(lookaheadProcess.running, true)
    compare(lookaheadProcess.starts, 1)
    compare(fetchOwner.lookaheadRequestDateKey, "2026-08-20")
    compare(fetchOwner.lookaheadHopCount, 1)
  }
  function cleanup() {
    if (fetchOwner) fetchOwner.destroy()
    wait(0)
    fetchOwner = null
    scoreProcess = null
    lookaheadProcess = null
    wait(0)
  }

  function test_admittedNextPageResumesAfterTeamScheduleUnlock() {
    yieldNextPage()
    fetchOwner.externalRequestBusy = false
    compare(lookaheadProcess.starts, 2)
    compare(lookaheadProcess.running, true)
    compare(fetchOwner.lookaheadRequestDateKey, "2026-08-21")
    compare(fetchOwner.lookaheadHopCount, 2)
    compare(fetchOwner.deferredLookaheadDateKey, "")
    lookaheadProcess.finish(0, jsonFile("valid-later"))
    compare(fetchOwner.nextGameStatus, "ready")
    compare(fetchOwner.nextGameDateKey, "2026-08-21")
  }

  function test_deferredHopKeepsTheOriginalEightHopBound() {
    fetchOwner.externalRequestBusy = true
    fetchOwner.lookaheadHopCount = 7
    lookaheadProcess.finish(0, emptyPage("2026-08-21"))
    compare(fetchOwner.deferredLookaheadDateKey, "2026-08-21")
    compare(fetchOwner.lookaheadHopCount, 7)
    fetchOwner.externalRequestBusy = false
    compare(fetchOwner.lookaheadHopCount, 8)
    compare(lookaheadProcess.starts, 2)
    lookaheadProcess.finish(0, emptyPage("2026-08-22"))
    compare(fetchOwner.nextGameStatus, "unavailable")
    compare(fetchOwner.deferredLookaheadDateKey, "")
    compare(lookaheadProcess.starts, 2)
  }

  function test_closingLookaheadAbandonsTheDeferredCursor() {
    yieldNextPage()
    fetchOwner.lookaheadEnabled = false
    compare(fetchOwner.deferredLookaheadDateKey, "")
    compare(fetchOwner.lookaheadHopCount, 0)
    fetchOwner.externalRequestBusy = false
    compare(lookaheadProcess.starts, 1)
    compare(fetchOwner.nextGameStatus, "idle")
  }

  function test_disablingLeagueAbandonsTheDeferredCursor() {
    yieldNextPage()
    fetchOwner.leagueEnabled = false
    compare(fetchOwner.deferredLookaheadDateKey, "")
    fetchOwner.externalRequestBusy = false
    compare(lookaheadProcess.starts, 1)
    compare(fetchOwner.nextGameStatus, "idle")
  }

  function test_changingDateCannotResumeTheOldPage() {
    yieldNextPage()
    fetchOwner.dateKey = "2026-09-01"
    compare(fetchOwner.deferredLookaheadDateKey, "")
    fetchOwner.externalRequestBusy = false
    compare(lookaheadProcess.starts, 1)
    compare(fetchOwner.lookaheadRequestDateKey, "")
    compare(scoreProcess.running, true)
  }

  function test_nonprogressingCursorIsRejectedBeforeDeferral() {
    fetchOwner.externalRequestBusy = true
    lookaheadProcess.finish(0, emptyPage("2026-08-20"))
    compare(fetchOwner.deferredLookaheadDateKey, "")
    compare(fetchOwner.nextGameStatus, "unavailable")
    fetchOwner.externalRequestBusy = false
    compare(lookaheadProcess.starts, 1)
  }
}

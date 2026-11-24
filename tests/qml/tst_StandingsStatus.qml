import QtQuick
import QtTest
import "../../model/StandingsRows.js" as StandingsRows

TestCase {
  id: testCase
  name: "StandingsStatus"
  property var consumer: null
  SignalSpy { id: retried; signalName: "retry" }
  function test_states_data() {
    var request = new XMLHttpRequest()
    request.open("GET", Qt.resolvedUrl("../../fixtures/presentation/standings-states.json"), false)
    request.send()
    return JSON.parse(request.responseText).cases.map(function(entry) {
      entry.tag = entry.name
      return entry
    })
  }
  function test_states(data) {
    failOnWarning(/.?/)
    var before = JSON.stringify(data.state)
    var rows = StandingsRows.flatten(data.state, [])
    compare(rows.map(function(row) { return row.kind }), data.kinds)
    compare(JSON.stringify(data.state), before)
    if (data.text === undefined) return
    var component = Qt.createComponent(Qt.resolvedUrl("../../components/StandingsStatus.qml"))
    compare(component.status, Component.Ready, component.errorString())
    consumer = component.createObject(testCase, {row: rows[0], width: 280,
      currentTime: Date.parse("2026-11-24T12:05:00Z")})
    verify(consumer !== null)
    compare(consumer.message, data.text)
    verify(consumer.implicitHeight > 0)
    compare(consumer.actionable, data.retry)
    retried.target = consumer
    consumer.activatePrimaryAction()
    compare(retried.count, data.retry ? 1 : 0)
  }
  function cleanup() {
    retried.target = null
    retried.clear()
    if (consumer) consumer.destroy()
    consumer = null
    wait(0)
  }
}

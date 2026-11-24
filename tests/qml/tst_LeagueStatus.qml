import QtQuick
import QtTest

TestCase {
  id: testCase
  name: "LeagueStatus"
  property var item: null

  SignalSpy { id: retrySpy; signalName: "retry" }

  function init() { failOnWarning(/.?/) }
  function cleanup() {
    retrySpy.target = null
    retrySpy.clear()
    if (item) item.destroy()
    item = null
    wait(0)
  }

  function test_retainedRetryKeepsStaleAgeVisibleAndDisablesRetry() {
    var component = Qt.createComponent(Qt.resolvedUrl("../../components/LeagueStatus.qml"))
    compare(component.status, Component.Ready, component.errorString())
    item = component.createObject(testCase, {width: 320,
      currentTime: Date.parse("2026-11-23T23:10:00Z"),
      status: {displayName: "NHL", stale: true, loading: true, lastSuccessAt: "2026-11-23T23:05:00Z"}})
    verify(item !== null)
    retrySpy.target = item
    var label = item.children.filter(function(child) { return typeof child.text === "string" })[0]
    compare(label.text, "NHL · showing last update · 5 min ago · refreshing…")
    verify(item.accessibleLabel.indexOf("stale scores") >= 0)
    verify(item.accessibleLabel.indexOf("5 min ago") >= 0)
    item.activatePrimaryAction()
    compare(retrySpy.count, 0)
    item.currentTime = Date.parse("2026-11-23T23:11:00Z")
    verify(label.text.indexOf("6 min ago") >= 0)
    item.status = {displayName: "NHL", stale: true, loading: false, lastSuccessAt: "2026-11-23T23:05:00Z"}
    verify(label.text.endsWith(" · retry"))
    item.activatePrimaryAction()
    compare(retrySpy.count, 1)
  }

  function test_partialWarningIsVisibleAndAccessible_data() {
    return [
      {tag: "first-partial", lastSuccessAt: null, loading: false, detail: "showing limited scores · retry"},
      {tag: "first-partial-refresh", lastSuccessAt: null, loading: true, detail: "showing limited scores · refreshing…"},
      {tag: "retained-partial", lastSuccessAt: "2026-11-23T23:05:00Z", loading: false, detail: "showing last update · 5 min ago · retry"},
      {tag: "retained-partial-refresh", lastSuccessAt: "2026-11-23T23:05:00Z", loading: true, detail: "showing last update · 5 min ago · refreshing…"}
    ]
  }

  function test_partialWarningIsVisibleAndAccessible(sample) {
    var component = Qt.createComponent(Qt.resolvedUrl("../../components/LeagueStatus.qml"))
    compare(component.status, Component.Ready, component.errorString())
    item = component.createObject(testCase, {width: 320,
      currentTime: Date.parse("2026-11-23T23:10:00Z"),
      status: {displayName: "NHL", stale: true, loading: sample.loading,
        errorCode: "partial-data", errorSummary: "Some scores could not be updated",
        lastSuccessAt: sample.lastSuccessAt}})
    verify(item !== null)
    var label = item.children.filter(function(child) { return typeof child.text === "string" })[0]
    compare(label.text, "NHL · Some scores could not be updated · " + sample.detail)
    verify(item.accessibleLabel.indexOf("Some scores could not be updated") >= 0)
    verify(item.accessibleLabel.endsWith(sample.detail))
    if (!sample.lastSuccessAt) verify(label.text.indexOf("last update") < 0)
    retrySpy.target = item
    item.activatePrimaryAction()
    compare(retrySpy.count, sample.loading ? 0 : 1)
  }
}

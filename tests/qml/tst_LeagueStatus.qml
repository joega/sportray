import QtQuick
import QtTest

TestCase {
  id: testCase
  visible: true
  name: "LeagueStatus"
  width: 360
  height: 320
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
    var label = findChild(item, "statusNoticeSummary")
    verify(label !== null)
    compare(label.text, "NHL · last update 5 min ago · updating…")
    compare(item.notice.severity, "warning")
    verify(!item.notice.canRetry)
    verify(item.accessibleLabel.indexOf("stale scores") >= 0)
    verify(item.accessibleLabel.indexOf("5 min ago") >= 0)
    item.activatePrimaryAction()
    compare(retrySpy.count, 0)
    item.currentTime = Date.parse("2026-11-23T23:11:00Z")
    verify(label.text.indexOf("6 min ago") >= 0)
    item.status = {displayName: "NHL", stale: true, loading: false, lastSuccessAt: "2026-11-23T23:05:00Z"}
    compare(label.text, "NHL · last update 6 min ago")
    verify(item.notice.canRetry)
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
    var label = findChild(item, "statusNoticeSummary")
    verify(label !== null)
    compare(label.text, "NHL · " + (sample.lastSuccessAt ? "last update 5 min ago" : "limited scores")
      + (sample.loading ? " · updating…" : ""))
    verify(item.notice.detail.indexOf("Some scores could not be updated") >= 0)
    compare(item.notice.severity, "warning")
    item.expanded = true
    var detail = findChild(item, "statusNoticeDetail")
    verify(detail !== null && detail.visible)
    verify(detail.text.indexOf("Some scores could not be updated") >= 0)
    verify(item.accessibleLabel.indexOf("Some scores could not be updated") >= 0)
    verify(item.accessibleLabel.endsWith(sample.detail))
    if (!sample.lastSuccessAt) verify(label.text.indexOf("last update") < 0)
    retrySpy.target = item
    item.activatePrimaryAction()
    compare(retrySpy.count, sample.loading ? 0 : 1)
  }

  function test_aggregateNamesAndAgeRemainVisibleAndAccessible() {
    var component = Qt.createComponent(Qt.resolvedUrl("../../components/LeagueStatus.qml"))
    compare(component.status, Component.Ready, component.errorString())
    item = component.createObject(testCase, {width: 320,
      currentTime: Date.parse("2026-11-23T23:10:00Z"),
      status: {displayName: "Following", hasData: true, loading: false, affectedLeagues: [
        {displayName: "NHL", leagueId: "nhl", stale: true, lastSuccessAt: "2026-11-23T23:05:00Z"},
        {displayName: "NFL", leagueId: "nfl", failed: true, errorSummary: "Scores unavailable"}]}})
    verify(item !== null)
    verify(item.notice.summary.indexOf("NHL, NFL") >= 0)
    verify(item.notice.summary.indexOf("5 min ago") >= 0)
    verify(item.accessibleLabel.indexOf("NHL, NFL") >= 0)
    item.expanded = true
    item.status = {displayName: "Following", hasData: true, loading: false, affectedLeagues: [
      {displayName: "NHL", leagueId: "nhl", stale: true, lastSuccessAt: "2026-11-23T23:05:00Z"}]}
    verify(item.expanded, "A recovering source collapsed aggregate details")
  }
}

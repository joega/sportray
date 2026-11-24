import QtQuick
import QtTest
import "../../model/NoticePresentation.js" as NoticePresentation

TestCase {
  id: testCase
  visible: true
  name: "StatusNotice"
  width: 360
  height: 320
  when: windowShown
  property var consumer: null
  readonly property double now: Date.parse("2026-11-24T12:10:00Z")
  SignalSpy { id: retried; signalName: "retryRequested" }
  SignalSpy { id: resized; signalName: "boundsChanged" }
  function init() { failOnWarning(/.?/) }
  function create(state) {
    var component = Qt.createComponent(Qt.resolvedUrl("../../components/StatusNotice.qml"))
    compare(component.status, Component.Ready, component.errorString())
    consumer = component.createObject(testCase, {width: 320, notice: NoticePresentation.noticeFor(state, now)})
    verify(consumer !== null)
    retried.target = consumer
    resized.target = consumer
    wait(0)
  }
  function cleanup() {
    retried.target = null; retried.clear()
    resized.target = null; resized.clear()
    if (consumer) consumer.destroy()
    consumer = null
    wait(0)
  }
  function test_detailsExpandInlineFromPointerAndStayAcrossRefresh() {
    create({kind: "scores", displayName: "NHL", stale: true, hasData: true,
      lastSuccessAt: "2026-11-24T12:05:00Z", errorSummary: "A request failed; retained scores are shown."})
    var before = consumer.height
    var details = findChild(consumer, "statusNoticeDetails")
    mouseClick(details, details.width / 2, details.height / 2)
    verify(consumer.expanded)
    verify(consumer.height > before)
    verify(findChild(consumer, "statusNoticeDetail").visible)
    compare(retried.count, 0)
    verify(resized.count > 0)
    consumer.notice = NoticePresentation.noticeFor({displayName: "NHL", stale: true, hasData: true,
      loading: true, lastSuccessAt: "2026-11-24T12:05:00Z"}, now)
    verify(consumer.expanded, "An ordinary refresh collapsed the requested explanation")
    verify(!consumer.notice.canRetry)
    verify(findChild(consumer, "statusNoticeSummary").text.indexOf("5 min ago") >= 0)
  }
  function test_nativeKeyboardReachesRetryAndFiresExactlyOnce() {
    create({displayName: "NHL", stale: true, lastSuccessAt: "2026-11-24T12:05:00Z"})
    var details = findChild(consumer, "statusNoticeDetails")
    mouseClick(details, details.width / 2, details.height / 2)
    keyClick(Qt.Key_Tab)
    var retry = findChild(consumer, "statusNoticeRetry")
    verify(retry.activeFocus)
    keyClick(Qt.Key_Return)
    compare(retried.count, 1)
    consumer.notice = NoticePresentation.noticeFor({displayName: "NHL", stale: true, loading: true,
      lastSuccessAt: "2026-11-24T12:05:00Z"}, now)
    verify(!consumer.retryIfAvailable())
    compare(retried.count, 1)
  }
  function test_virtualCursorSupportsBothActionsAndDoesNotRetryWhileLoading() {
    create({displayName: "NHL", failed: true, errorSummary: "Update failed"})
    compare(consumer.activeAction, "retry")
    consumer.moveCursor(-1)
    compare(consumer.activeAction, "details")
    verify(consumer.activateCursor())
    verify(consumer.expanded)
    compare(retried.count, 0)
    consumer.moveCursor(1)
    verify(consumer.activateCursor())
    compare(retried.count, 1)
    consumer.notice = NoticePresentation.noticeFor({displayName: "NHL", failed: true, loading: true,
      errorSummary: "Update failed"}, now)
    consumer.activeAction = "retry"
    verify(!consumer.activateCursor())
    compare(retried.count, 1)
  }
  function test_parentHidingDoesNotCollapseNoticeGeometry() {
    create({displayName: "NHL", failed: true, errorSummary: "Update failed"})
    var height = consumer.implicitHeight
    verify(height > 0)
    testCase.visible = false
    compare(consumer.implicitHeight, height)
    testCase.visible = true
    compare(consumer.implicitHeight, height)
  }
  function test_publicationGapIsNeutralAndCanDiscloseWithoutRetry() {
    create({kind: "schedule", hasData: true, partial: true, failed: false})
    compare(consumer.notice.severity, "info")
    verify(findChild(consumer, "statusNoticeDetails").visible)
    verify(!findChild(consumer, "statusNoticeRetry").visible)
    consumer.activatePrimaryAction()
    verify(consumer.expanded)
    compare(retried.count, 0)
  }
}

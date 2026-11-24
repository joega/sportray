import QtQuick
import QtQuick.Window
import QtTest as Test
import Quickshell
import qs.Commons as Commons
import "../../components" as Components
import "../../model/NoticePresentation.js" as NoticePresentation

ShellRoot {
  id: root
  property var uiCase: ({width: 400, fontSize: 12})
  property int retryCalls: 0
  readonly property double now: Date.parse("2026-11-24T12:10:00Z")
  function readText(path) {
    var request = new XMLHttpRequest()
    request.open("GET", Qt.resolvedUrl(path), false)
    request.send()
    return request.responseText
  }
  Window {
    id: window
    width: root.uiCase.width
    height: 640
    visible: true
    color: Commons.Color.popups.background
    Rectangle { anchors.fill: parent; color: Commons.Color.popups.background }
    Column {
      id: content
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 16
      spacing: 20
      Text {
        text: "Status presentation"
        textFormat: Text.PlainText
        color: Commons.Color.popups.text
        font.family: "Adwaita Sans"
        font.pixelSize: Commons.Style.font.subtitle
        font.bold: true
      }
      Components.StatusNotice {
        id: loadingNotice
        width: parent.width
        notice: NoticePresentation.noticeFor({loading: true}, root.now)
      }
      Components.StatusNotice {
        id: partialNotice
        width: parent.width
        notice: NoticePresentation.noticeFor({kind: "schedule", hasData: true, partial: true,
          failed: false, errorSummary: "Only listed games are shown. Unloaded or unpublished dates do not prove there are no games."}, root.now)
      }
      Components.StatusNotice {
        id: staleNotice
        width: parent.width
        notice: NoticePresentation.noticeFor({displayName: "NHL", hasData: true, stale: true,
          lastSuccessAt: "2026-11-24T12:05:00Z", errorSummary: "Scores could not be updated. Previously loaded games are shown."}, root.now)
        onRetryRequested: root.retryCalls++
      }
      Components.StatusNotice {
        id: aggregateNotice
        width: parent.width
        notice: NoticePresentation.noticeFor({kind: "following", hasData: true,
          affectedLeagues: [{displayName: "NBA", leagueId: "nba", stale: true, lastSuccessAt: "2026-11-24T12:00:00Z", errorSummary: "Request timed out."},
            {displayName: "NFL", leagueId: "nfl", failed: true, errorSummary: "Scores are unavailable."}]}, root.now)
      }
      Components.StatusNotice {
        id: failedNotice
        width: parent.width
        notice: NoticePresentation.noticeFor({kind: "standings", failed: true,
          errorSummary: "Standings could not be read. Try again."}, root.now)
      }
    }
    Test.TestCase {
      id: checks
      when: false
      function check(value, message) { if (!value) throw new Error(message) }
      function find(object, name) { return findChild(object, name) }
      function capture(name) {
        var done = false, saved = false
        window.contentItem.grabToImage(function(result) {
          saved = result.saveToFile(Quickshell.env("SPORTRAY_TEST_CAPTURE") + "/" + name + ".png")
          done = true
        }, Qt.size(window.width, window.height))
        for (var attempt = 0; attempt < 30 && !done; attempt++) wait(30)
        check(done && saved, "Native capture failed")
      }
      function run() {
        try {
          root.uiCase = JSON.parse(root.readText("ui-case.json"))
          Commons.Color.loadUserShell("")
          Commons.Color.loadColors(root.readText("theme/colors.toml"))
          Commons.Color.loadShell(root.readText("theme/shell.toml"))
          Commons.Style.fontFamily = "JetBrainsMono Nerd Font"
          Commons.Style.fontBaseSize = root.uiCase.fontSize
          Commons.Style.cornerRadius = 8
          wait(100)
          check(Commons.Style.fontBaseSize === root.uiCase.fontSize, "Case font size did not load")
          if (root.uiCase.theme === "catppuccin-latte")
            check(String(Commons.Color.popups.background) === "#eff1f5", "Light theme did not load")
          capture("notices")
          check(!loadingNotice.notice.canRetry, "First load incorrectly offers Retry")
          check(partialNotice.notice.severity === "info", "Publication gap became a red failure")
          check(!find(partialNotice, "statusNoticeRetry").visible, "Publication gap offers futile Retry")
          var details = find(staleNotice, "statusNoticeDetails")
          var before = staleNotice.height
          mouseClick(details, details.width / 2, details.height / 2)
          wait(20)
          check(staleNotice.expanded && staleNotice.height > before, "Pointer Details did not expand inline")
          check(find(staleNotice, "statusNoticeDetail").visible, "Expanded explanation is hidden")
          check(root.retryCalls === 0, "Details also retried")
          keyClick(Qt.Key_Tab)
          var retry = find(staleNotice, "statusNoticeRetry")
          check(retry.activeFocus, "Native Tab did not reach Retry")
          keyClick(Qt.Key_Return)
          check(root.retryCalls === 1, "Retry did not activate exactly once")
          staleNotice.notice = NoticePresentation.noticeFor({displayName: "NHL", hasData: true, stale: true,
            loading: true, lastSuccessAt: "2026-11-24T12:05:00Z"}, root.now)
          wait(20)
          check(staleNotice.expanded, "Refreshing collapsed explicitly opened details")
          check(staleNotice.notice.summary.indexOf("5 min ago") !== -1, "Refresh hid stale age")
          check(!retry.visible && !staleNotice.retryIfAvailable(), "Retry remained active during request")
          check(root.retryCalls === 1, "Disabled Retry leaked an action")
          check(aggregateNotice.notice.summary.indexOf("NBA, NFL") !== -1, "Aggregate hid affected leagues")
          check(aggregateNotice.notice.summary.indexOf("10 min ago") !== -1, "Aggregate hid retained age")
          for (var n of [loadingNotice, partialNotice, staleNotice, aggregateNotice, failedNotice]) {
            var summary = find(n, "statusNoticeSummary")
            check(summary.width > 0 && summary.x >= 0 && summary.x + summary.width <= n.width + 1,
              "Summary crosses notice width")
            for (var buttonName of ["statusNoticeDetails", "statusNoticeRetry"]) {
              var button = find(n, buttonName)
              if (!button.visible) continue
              var point = button.mapToItem(window.contentItem, 0, 0)
              check(point.x >= 0 && point.x + button.width <= window.width + 1, "Action crosses window width")
            }
          }
          capture("notices-expanded")
          console.log("STATUS_NOTICE_PASS " + root.uiCase.name)
          Qt.quit()
        } catch (error) {
          console.error("STATUS_NOTICE_FAIL " + String(error) + " " + error.stack)
          Qt.quit()
        }
      }
    }
    Timer { running: true; interval: 200; onTriggered: checks.run() }
  }
  Component.onCompleted: root.uiCase = JSON.parse(root.readText("ui-case.json"))
}

import QtQuick
import "../model/UiTypography.js" as Typography
import "../model/NoticePresentation.js" as NoticePresentation

Item {
  id: root

  required property var status
  property double currentTime: Date.now()
  signal retry()
  signal contentFocusRequested()
  property bool hasCursor: false
  width: parent ? parent.width : implicitWidth
  readonly property var notice: NoticePresentation.noticeFor({
    kind: "scores", displayName: root.status ? root.status.displayName || "" : "",
    loading: Boolean(root.status && root.status.loading),
    hasData: Boolean(root.status && (root.status.hasData || root.status.stale)),
    stale: Boolean(root.status && root.status.stale),
    partial: Boolean(root.status && root.status.errorCode === "partial-data"),
    errorCode: root.status ? root.status.errorCode || "" : "",
    errorSummary: root.status ? root.status.errorSummary || "" : "",
    affectedLeagues: root.status ? root.status.affectedLeagues || [] : [],
    lastSuccessAt: root.status ? root.status.lastSuccessAt || "" : ""
  }, root.currentTime)
  implicitHeight: noticeView.implicitHeight
  height: implicitHeight
  readonly property bool pointerPressed: noticeView.pointerPressed
  property alias expanded: noticeView.expanded
  function moveCursor(delta) { return noticeView.moveCursor(delta) }
  function activateCursor() { return noticeView.activateCursor() }

  activeFocusOnTab: false
  Keys.onReturnPressed: if (!root.status.loading) root.retry()
  Keys.onEnterPressed: if (!root.status.loading) root.retry()
  Keys.onSpacePressed: if (!root.status.loading) root.retry()

  readonly property string accessibleLabel: root.status.affectedLeagues && root.status.affectedLeagues.length
    ? root.notice.accessibleSummary : root.status.stale
    ? root.status.displayName + ", stale scores, " + root.staleText()
    : root.status.loading
      ? root.status.displayName + ", refreshing scores"
      : root.status.displayName + ", "
        + (root.status.errorSummary || "scores unavailable") + ". Retry scores"

  function activatePrimaryAction() {
    if (!root.status.loading) root.retry()
  }

  Accessible.name: root.accessibleLabel
  Accessible.role: root.status.loading ? Accessible.StaticText : Accessible.Button
  Accessible.onPressAction: root.activatePrimaryAction()

  StatusNotice {
    id: noticeView
    width: parent.width
    notice: root.notice
    hasCursor: root.hasCursor
    onRetryRequested: root.retry()
    onContentFocusRequested: root.contentFocusRequested()
  }

  function staleText() {
    var timestamp = root.status.lastSuccessAt
    var action = root.status.loading ? " · refreshing…" : " · retry"
    var warning = root.status.errorSummary ? root.status.errorSummary + " · " : ""
    if (typeof timestamp !== "string" || timestamp === "") return warning + "showing limited scores" + action
    var elapsed = Math.max(0, root.currentTime - new Date(timestamp).getTime())
    if (!isFinite(elapsed)) return warning + "showing limited scores" + action
    var minutes = Math.floor(elapsed / 60000)
    var age = minutes < 1 ? "less than a minute ago" : minutes + " min ago"
    return warning + "showing last update · " + age + action
  }
}

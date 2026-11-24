import QtQuick
import "../model/UiTypography.js" as Typography
import "../model/NoticePresentation.js" as NoticePresentation

Item {
  id: root
  property var row: ({})
  property double currentTime: Date.now()
  property bool hasCursor: false
  signal contentFocusRequested()
  readonly property bool actionable: Boolean(root.row && root.row.action && root.row.action.enabled)
    && root.row.loading !== true && root.row.kind !== "standings-loading"
  readonly property var notice: NoticePresentation.noticeFor({
    kind: "standings", displayName: "Standings", loading: root.row.kind === "standings-loading" || root.row.loading === true,
    hasData: root.row.stale === true || root.row.kind === "standings-empty" || root.row.kind === "standings-status" && root.row.loading === true,
    stale: root.row.stale === true, empty: root.row.kind === "standings-empty",
    failed: root.row.kind === "standings-status" && root.row.loading !== true,
    errorSummary: root.row.kind === "standings-status" && root.row.loading !== true ? root.row.label || "" : "",
    lastSuccessAt: root.row.lastSuccessAt || "", canRetry: root.actionable
  }, root.currentTime)
  readonly property bool pointerPressed: noticeView.pointerPressed
  property alias expanded: noticeView.expanded
  function moveCursor(delta) { return noticeView.moveCursor(delta) }
  function activateCursor() { return noticeView.activateCursor() }
  readonly property string message: {
    var value = root.row || {}
    var text = value.label || value.text || ""
    if (value.stale) {
      var updated = Date.parse(value.lastSuccessAt || "")
      var minutes = isFinite(updated) ? Math.floor(Math.max(0, root.currentTime - updated) / 60000) : -1
      text += " · showing last update · " + (minutes < 0 ? "age unavailable"
        : minutes < 1 ? "less than a minute ago" : minutes + " min ago")
    }
    if (value.action && (!value.loading || value.stale))
      text += value.loading ? " · refreshing…" : " · retry"
    return text
  }
  signal retry()
  implicitHeight: noticeView.implicitHeight
  function activatePrimaryAction() { if (root.actionable) root.retry() }
  Accessible.name: root.message
  Accessible.role: root.actionable ? Accessible.Button : Accessible.StaticText
  Accessible.onPressAction: root.activatePrimaryAction()
  Keys.onReturnPressed: root.activatePrimaryAction()
  Keys.onEnterPressed: root.activatePrimaryAction()
  Keys.onSpacePressed: root.activatePrimaryAction()

  StatusNotice {
    id: noticeView
    width: parent.width
    notice: root.notice
    hasCursor: root.hasCursor
    onRetryRequested: root.retry()
    onContentFocusRequested: root.contentFocusRequested()
  }
}

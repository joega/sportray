import QtQuick
import "../model/UiTypography.js" as Typography
import qs.Commons as Commons

Item {
  id: root

  required property var status
  property double currentTime: Date.now()
  signal retry()
  width: parent ? parent.width : implicitWidth
  implicitHeight: label.implicitHeight
  height: implicitHeight
  readonly property bool pointerPressed: retryMouse.pressed

  activeFocusOnTab: false
  Keys.onReturnPressed: if (!root.status.loading) root.retry()
  Keys.onEnterPressed: if (!root.status.loading) root.retry()
  Keys.onSpacePressed: if (!root.status.loading) root.retry()

  readonly property string accessibleLabel: root.status.stale
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

  Text {
    textFormat: Text.PlainText
    id: label
    width: parent.width
    text: root.status.stale
      ? root.status.displayName + " · " + root.staleText()
      : root.status.loading
        ? root.status.displayName + " · refreshing…"
        : root.status.displayName + " · "
          + (root.status.errorSummary || "scores unavailable") + " · retry"
    color: root.status.loading ? Qt.alpha(Commons.Color.popups.text, 0.85) : Commons.Color.urgent
    font.family: Typography.family
    font.pixelSize: Commons.Style.font.bodySmall
    wrapMode: Text.WordWrap
  }

  MouseArea {
    id: retryMouse
    anchors.fill: parent
    enabled: !root.status.loading
    onClicked: root.retry()
    cursorShape: Qt.PointingHandCursor
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

import QtQuick
import qs.Commons

Item {
  id: root

  required property var status
  signal retry()
  width: parent ? parent.width : implicitWidth
  implicitHeight: label.implicitHeight
  height: implicitHeight

  activeFocusOnTab: false
  Keys.onReturnPressed: if (!root.status.loading) root.retry()
  Keys.onEnterPressed: if (!root.status.loading) root.retry()
  Keys.onSpacePressed: if (!root.status.loading) root.retry()

  readonly property string accessibleLabel: root.status.loading
    ? root.status.displayName + ", refreshing scores"
    : root.status.stale
      ? root.status.displayName + ", stale scores. Retry scores"
      : root.status.displayName + ", "
        + (root.status.errorSummary || "scores unavailable") + ". Retry scores"

  function activatePrimaryAction() {
    if (!root.status.loading) root.retry()
  }

  Accessible.name: root.accessibleLabel
  Accessible.role: root.status.loading ? Accessible.StaticText : Accessible.Button

  Text {
    id: label
    width: parent.width
    text: root.status.loading
      ? root.status.displayName + " · refreshing…"
      : root.status.stale
        ? root.status.displayName + " · " + root.staleText()
        : root.status.displayName + " · "
          + (root.status.errorSummary || "scores unavailable") + " · retry"
    color: root.status.loading ? Color.muted : Color.urgent
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
    wrapMode: Text.WordWrap
  }

  MouseArea {
    anchors.fill: parent
    enabled: !root.status.loading
    onClicked: root.retry()
    cursorShape: Qt.PointingHandCursor
  }

  function staleText() {
    var timestamp = root.status.lastSuccessAt
    if (typeof timestamp !== "string" || timestamp === "") return "showing last update · retry"
    var elapsed = Math.max(0, Date.now() - new Date(timestamp).getTime())
    if (!isFinite(elapsed)) return "showing last update · retry"
    var minutes = Math.floor(elapsed / 60000)
    var age = minutes < 1 ? "less than a minute ago" : minutes + " min ago"
    return "showing last update · " + age + " · retry"
  }
}

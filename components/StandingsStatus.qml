import QtQuick
import qs.Commons as Commons

Item {
  id: root
  property var row: ({})
  property double currentTime: Date.now()
  readonly property bool actionable: Boolean(root.row && root.row.action && root.row.action.enabled)
  readonly property bool pointerPressed: retryMouse.pressed
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
  implicitHeight: label.implicitHeight
  function activatePrimaryAction() { if (root.actionable) root.retry() }
  Accessible.name: root.message
  Accessible.role: root.actionable ? Accessible.Button : Accessible.StaticText
  Accessible.onPressAction: root.activatePrimaryAction()
  Keys.onReturnPressed: root.activatePrimaryAction()
  Keys.onEnterPressed: root.activatePrimaryAction()
  Keys.onSpacePressed: root.activatePrimaryAction()

  Text {
    id: label
    textFormat: Text.PlainText
    width: parent.width
    text: root.message
    wrapMode: Text.WordWrap
    font.family: Commons.Style.font.family
    font.pixelSize: Commons.Style.font.bodySmall
    color: root.row && root.row.kind === "standings-status" && !root.row.loading
      ? Commons.Color.urgent : Commons.Color.muted
  }

  MouseArea {
    id: retryMouse
    anchors.fill: parent
    enabled: root.actionable
    cursorShape: Qt.PointingHandCursor
    onClicked: root.activatePrimaryAction()
  }
}

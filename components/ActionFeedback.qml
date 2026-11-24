import QtQuick
import qs.Commons as Commons
import qs.Ui
import "../model/UiTypography.js" as Typography

// Local action feedback floats above content without changing its scroll geometry.
Item {
  id: root
  property var action: null
  property bool canUndo: false
  property int pressedActionId: 0
  readonly property var lifetime: ({alive: true})
  signal undoRequested(int actionId)
  visible: Boolean(root.action)
  implicitHeight: root.action ? Math.max(message.implicitHeight, undoAction.implicitHeight)
    + Commons.Style.spacing.sm * 2 : 0
  height: implicitHeight
  Accessible.role: Accessible.StaticText
  Accessible.name: root.action ? root.action.summary || "" : ""
  Accessible.description: root.canUndo ? "Undo is available. Control Z." : ""
  Component.onDestruction: root.lifetime.alive = false

  BorderSurface {
    anchors.fill: parent
    color: Commons.Color.popups.background
    borderSpec: Commons.Border.controlSpec("normal", Commons.Color.popups.text, Commons.Color.accent)
    radius: Commons.Style.cornerRadius
  }
  Text {
    id: message
    x: Commons.Style.spacing.sm
    y: Commons.Style.spacing.sm
    width: Math.max(1, root.width - Commons.Style.spacing.sm * 2
      - (root.canUndo ? undoAction.width + Commons.Style.spacing.sm : 0))
    text: root.action ? root.action.summary || "" : ""
    textFormat: Text.PlainText
    color: root.action && root.action.severity === "error" ? Commons.Color.urgent : Commons.Color.popups.text
    font.family: Typography.family
    font.pixelSize: Commons.Style.font.bodySmall
    wrapMode: Text.WordWrap
  }
  SemanticActionButton {
    id: undoAction
    anchors.right: parent.right
    anchors.rightMargin: Commons.Style.spacing.sm
    anchors.verticalCenter: parent.verticalCenter
    visible: root.canUndo
    text: "Undo"
    tooltipText: "Undo last change (Ctrl+Z)"
    textFontSize: Commons.Style.font.bodySmall
    bordered: true
    focusable: false
    onPointerPressedChanged: {
      if (pointerPressed) root.pressedActionId = root.action ? root.action.id : 0
      else {
        var owner = root.lifetime
        var releasedId = root.pressedActionId
        Qt.callLater(function() {
          if (owner.alive && !undoAction.pointerPressed && root.pressedActionId === releasedId)
            root.pressedActionId = 0
        })
      }
    }
    onClicked: {
      var id = root.pressedActionId || (root.action ? root.action.id : 0)
      root.pressedActionId = 0
      if (root.canUndo && id) root.undoRequested(id)
    }
    Accessible.name: "Undo last change"
  }
}

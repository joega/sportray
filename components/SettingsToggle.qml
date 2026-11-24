import QtQuick
import qs.Commons
import qs.Ui
import "../model/UiTypography.js" as Typography

// Keep the native switch and keyboard route, with an open settings-row surface.
Toggle {
  id: root
  property bool pointerHovered: false
  fontFamily: Typography.family
  foreground: Color.popups.text
  titleSize: Style.font.body
  descriptionSize: Style.font.bodySmall
  color: activeFocus ? Style.focusFillFor(foreground, accent)
    : hasCursor || pointerHovered ? Style.hoverFillFor(foreground, accent) : "transparent"
  borderSpec: activeFocus ? Border.controlSpec("focus", foreground, accent)
    : hasCursor ? Border.controlSpec("hover-cursor", foreground, accent) : Border.none()
  onHovered: function(value) { root.pointerHovered = value }
  Accessible.name: label
  Accessible.description: description
  Accessible.role: Accessible.CheckBox
  Accessible.checkable: true
  Accessible.checked: checked
  Accessible.onToggleAction: if (root.enabled) root.clicked()

  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 1
    color: Color.popups.text
    opacity: 0.10
  }
}

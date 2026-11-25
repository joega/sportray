import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "../model/UiTypography.js" as Typography

// Keep the native switch and keyboard route inside a quiet settings surface.
Toggle {
  id: root
  PresentationTokens { id: visual }
  property bool pointerHovered: false
  fontFamily: Typography.family
  foreground: visual.ink
  titleSize: visual.body
  descriptionSize: Style.font.bodySmall
  color: activeFocus ? Style.focusFillFor(foreground, accent)
    : hasCursor || pointerHovered ? Style.hoverFillFor(foreground, accent) : visual.surface
  borderSpec: activeFocus ? Border.controlSpec("focus", foreground, accent)
    : hasCursor ? Border.controlSpec("hover-cursor", foreground, accent) : Border.none()
  radius: visual.radius
  onHovered: function(value) { root.pointerHovered = value }
  Accessible.name: label
  Accessible.description: description
  Accessible.role: Accessible.CheckBox
  Accessible.checkable: true
  Accessible.checked: checked
  Accessible.onToggleAction: if (root.enabled) root.clicked()

}

import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property string iconName: "neutral"
  property string fallbackText: ""
  property string text: ""
  property bool textBold: false
  property real textFontSize: Style.font.body
  property real textHorizontalPadding: Style.spacing.controlPaddingX
  property real textVerticalPadding: Style.spacing.controlPaddingY / 2
  property string tooltipText: ""
  property color foreground: Color.foreground
  property color hoverColor: foreground
  property string fontFamily: Style.font.family
  property real fontSize: Style.font.icon
  property real size: Math.max(Style.space(22), fontSize + Style.spacing.sm * 2)
  property bool focusable: false
  property bool hasCursor: false
  property bool bordered: false

  signal clicked()

  activeFocusOnTab: focusable
  Keys.onReturnPressed: if (focusable) root.clicked()
  Keys.onEnterPressed: if (focusable) root.clicked()
  Keys.onSpacePressed: if (focusable) root.clicked()

  implicitWidth: root.text === ""
    ? size : textLabel.implicitWidth + root.textHorizontalPadding * 2
  implicitHeight: root.text === ""
    ? size : Math.max(size, textLabel.implicitHeight + root.textVerticalPadding * 2)

  readonly property bool _showFocusRing: focusable && activeFocus
  readonly property bool _hot: (mouse.containsMouse || root.hasCursor) && root.enabled
  readonly property var _borderSpec: _showFocusRing
    ? Border.controlSpec("focus", hoverColor, hoverColor)
    : (_hot && bordered
      ? Border.controlSpec("hover-cursor", hoverColor, hoverColor)
      : (bordered ? Border.controlSpec("normal", foreground, Color.accent) : Border.none()))

  BorderSurface {
    anchors.fill: parent
    color: root._showFocusRing
      ? Style.focusFillFor(root.hoverColor, root.hoverColor)
      : (root._hot ? Style.hoverFillFor(root.hoverColor, root.hoverColor) : "transparent")
    borderSpec: root._borderSpec
    radius: Style.cornerRadius

    SemanticIcon {
      visible: root.text === ""
      anchors.fill: parent
      iconName: root.iconName
      fallbackText: root.fallbackText
      fontFamily: root.fontFamily
      fontSize: root.fontSize
      color: root.enabled
        ? (root._hot ? root.hoverColor : root.foreground)
        : Qt.darker(root.foreground, 2.0)
      decorative: true
    }

    Text {
      id: textLabel
      visible: root.text !== ""
      anchors.centerIn: parent
      text: root.text
      color: root.enabled
        ? (root._hot ? root.hoverColor : root.foreground)
        : Qt.darker(root.foreground, 2.0)
      font.family: root.fontFamily
      font.pixelSize: root.textFontSize
      font.bold: root.textBold
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    enabled: root.enabled
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: {
      if (root.focusable) root.forceActiveFocus()
      root.clicked()
    }
  }

  PanelToolTip {
    visible: root.tooltipText !== "" && mouse.containsMouse
    text: root.tooltipText
    fontFamily: root.fontFamily
  }

  Accessible.name: root.tooltipText
  Accessible.role: Accessible.Button
}

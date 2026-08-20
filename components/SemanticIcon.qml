import QtQuick
import qs.Commons
import "../model/Iconography.js" as Iconography

Item {
  id: root

  property string iconName: "neutral"
  property string fallbackText: Iconography.fallback(root.iconName)
  property string fontFamily: Style.font.family
  property real fontSize: Style.font.icon
  property color color: Color.foreground
  property bool decorative: true

  implicitWidth: glyph.implicitWidth
  implicitHeight: glyph.implicitHeight

  Text {
    id: glyph
    anchors.fill: parent
    text: Iconography.displayText(root.iconName, root.fontFamily)
      || root.fallbackText
    color: root.color
    font.family: root.fontFamily
    font.pixelSize: root.fontSize
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
    Accessible.ignored: root.decorative
  }
}

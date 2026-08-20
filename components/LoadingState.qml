import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property bool retained: false
  property string labelText: "Loading scores…"

  implicitHeight: loadingColumn.implicitHeight
  width: parent ? parent.width : implicitWidth

  Column {
    id: loadingColumn
    width: parent.width
    spacing: Style.spacing.sm

    Row {
      width: parent.width
      spacing: Style.spacing.sm

      SemanticIcon {
        width: Style.space(18)
        height: width
        iconName: "refresh"
        fontSize: Style.font.body
        color: Color.accent
        decorative: true
      }

      Text {
        width: parent.width - Style.space(18) - parent.spacing
        text: root.labelText
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        elide: Text.ElideRight
      }
    }

    Repeater {
      model: 2

      BorderSurface {
        required property int index
        width: loadingColumn.width
        height: Style.space(64)
        color: Util.alpha(Color.popups.text, 0.04)
        borderSpec: Border.controlSpec("normal", Color.popups.text, Color.accent)
        radius: Style.cornerRadius

        Column {
          anchors.fill: parent
          anchors.margins: Style.spacing.md
          spacing: Style.spacing.xs

          Rectangle {
            width: parent.width * (index === 0 ? 0.48 : 0.38)
            height: Style.space(10)
            radius: height / 2
            color: Util.alpha(Color.popups.text, 0.14)
          }

          Rectangle {
            width: parent.width * 0.72
            height: Style.space(8)
            radius: height / 2
            color: Util.alpha(Color.popups.text, 0.09)
          }
        }
      }
    }
  }
}

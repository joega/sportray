pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons as Commons
import "../model/UiTypography.js" as Typography

Column {
  id: root
  property var groups: []
  spacing: Commons.Style.spacing.lg
  Text {
    width: parent.width
    text: "Text fields and open menus keep their own keys."
    textFormat: Text.PlainText
    font.family: Typography.family
    font.pixelSize: Commons.Style.font.bodySmall
    color: Qt.alpha(Commons.Color.popups.text, 0.85)
    wrapMode: Text.WordWrap
  }
  Repeater {
    model: root.groups
    Column {
      id: group
      required property var modelData
      width: root.width
      spacing: Commons.Style.spacing.sm
      Text {
        width: parent.width
        text: group.modelData.title
        textFormat: Text.PlainText
        font.family: Typography.family
        font.pixelSize: Commons.Style.font.body
        font.bold: true
        color: Commons.Color.popups.text
      }
      Repeater {
        model: group.modelData.rows
        Item {
          id: shortcut
          required property var modelData
          width: group.width
          height: Math.max(keys.implicitHeight, description.implicitHeight)
          Text {
            id: keys
            width: Math.min(Commons.Style.space(114), shortcut.width * 0.43)
            text: shortcut.modelData.keys
            textFormat: Text.PlainText
            font.family: Typography.family
            font.pixelSize: Commons.Style.font.bodySmall
            font.weight: Font.DemiBold
            color: Commons.Color.popups.text
            wrapMode: Text.WordWrap
          }
          Text {
            id: description
            anchors.left: keys.right
            anchors.leftMargin: Commons.Style.spacing.md
            anchors.right: parent.right
            text: shortcut.modelData.description
            textFormat: Text.PlainText
            font.family: Typography.family
            font.pixelSize: Commons.Style.font.bodySmall
            color: Commons.Color.popups.text
            wrapMode: Text.WordWrap
          }
        }
      }
    }
  }
}

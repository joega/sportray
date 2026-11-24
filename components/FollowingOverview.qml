import QtQuick
import qs.Commons as Commons
import qs.Ui
import "../model/UiTypography.js" as Typography

Column {
  id: root
  property var projection: ({counts: {}, summary: "Your followed games", filterId: "all"})
  signal filterSelected(string filterId)
  spacing: Commons.Style.spacing.xs

  Text {
    width: parent.width
    text: root.projection.summary || "Your followed games"
    textFormat: Text.PlainText
    color: Qt.alpha(Commons.Color.popups.text, 0.85)
    font.family: Typography.family
    font.pixelSize: Commons.Style.font.caption
    wrapMode: Text.WordWrap
    Accessible.role: Accessible.StaticText
  }
  Flow {
    width: parent.width
    spacing: Commons.Style.spacing.xs
    Repeater {
      model: [{id: "all", label: "All"}, {id: "live", label: "Live"}, {id: "favorites", label: "Favorites"}]
      Button {
        required property var modelData
        text: modelData.label + " " + Number(root.projection.counts[modelData.id] || 0)
        fontFamily: Typography.family
        fontSize: Commons.Style.font.bodySmall
        verticalPadding: Commons.Style.spacing.xxs
        selected: root.projection.filterId === modelData.id
        active: selected
        focusable: true
        onClicked: root.filterSelected(modelData.id)
        Accessible.name: modelData.label + ", " + Number(root.projection.counts[modelData.id] || 0) + " games. Filter Following (F)"
        Accessible.role: Accessible.RadioButton
        Accessible.checkable: true
        Accessible.checked: selected
      }
    }
  }
}

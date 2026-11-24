import QtQuick
import qs.Commons
import "../model/UiTypography.js" as Typography
import "../model/StandingsPresentation.js" as Presentation

Column {
  id: root
  property string label: "Standings"
  property string leagueId: ""
  property bool seeded: false
  readonly property var columns: Presentation.columnsForLeague(root.leagueId)
  readonly property var geometry: Presentation.layout(width, Style.spaceReal(1), root.leagueId)
  spacing: Style.spacing.sm

  Text {
    width: parent.width
    text: root.label
    textFormat: Text.PlainText
    color: Color.popups.text
    font.family: Typography.family
    font.pixelSize: Style.font.body
    font.weight: Font.DemiBold
    wrapMode: Text.WordWrap
  }
  Row {
    width: parent.width - root.geometry.padding * 2
    x: root.geometry.padding
    spacing: root.geometry.gap
    Text {
      width: root.geometry.rankWidth
      text: root.seeded ? "Seed" : "#"
      textFormat: Text.PlainText
      color: Qt.alpha(Color.popups.text, 0.85)
      font.family: Typography.family
      font.pixelSize: Style.font.caption
      horizontalAlignment: Text.AlignHCenter
    }
    Text {
      width: root.geometry.teamWidth
      text: "Team"
      textFormat: Text.PlainText
      color: Qt.alpha(Color.popups.text, 0.85)
      font.family: Typography.family
      font.pixelSize: Style.font.caption
    }
    Row {
      width: root.geometry.metricsWidth
      Repeater {
        model: root.columns
        Text {
          required property var modelData
          width: root.geometry.metricsWidth / root.columns.length
          text: modelData.label
          textFormat: Text.PlainText
          color: Qt.alpha(Color.popups.text, 0.85)
          font.family: Typography.family
          font.pixelSize: Style.font.caption
          horizontalAlignment: Text.AlignRight
        }
      }
    }
    Item { width: root.geometry.favoriteWidth; height: 1 }
  }
}

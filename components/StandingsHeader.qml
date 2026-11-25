import QtQuick
import qs.Commons
import qs.Commons as Commons
import "../model/UiTypography.js" as Typography
import "../model/StandingsPresentation.js" as Presentation

Column {
  id: root
  PresentationTokens { id: visual }
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
    color: visual.ink
    font.family: Typography.family
    font.pixelSize: visual.section
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
      color: visual.muted
      font.family: Typography.family
      font.pixelSize: Style.font.bodySmall
      horizontalAlignment: Text.AlignHCenter
    }
    Text {
      width: root.geometry.teamWidth
      text: "Team"
      textFormat: Text.PlainText
      color: visual.muted
      font.family: Typography.family
      font.pixelSize: Style.font.bodySmall
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
          color: visual.muted
          font.family: Typography.family
          font.pixelSize: Style.font.bodySmall
          horizontalAlignment: Text.AlignRight
        }
      }
    }
    Item { width: root.geometry.favoriteWidth; height: 1 }
  }
}

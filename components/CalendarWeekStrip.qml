import QtQuick
import qs.Commons
import qs.Ui

// Calendar week-strip overview. Renders the pure per-day summaries projected
// by model/CalendarModel.js daySummaries(); this view performs no filtering,
// parsing, or date math. One bounded cell per cached day in the window.
Item {
  id: root

  property var summaries: []
  property string selectedDateKey: ""

  signal dateSelected(string dateKey)

  implicitHeight: rail.height

  function countLine(summary) {
    if (!summary || summary.hasGames !== true) return "No games"
    return summary.gameCount === 1 ? "1 game" : summary.gameCount + " games"
  }

  function accessibleName(summary) {
    if (!summary) return "Unknown day"
    return summary.weekday + " " + summary.month + " " + summary.dayOfMonth
      + ", " + countLine(summary)
      + (summary.hasFavoriteGames ? ", includes favorites" : "")
  }

  Row {
    id: rail
    width: parent.width
    height: Style.space(52)
    spacing: Style.spacing.xxs

    Repeater {
      model: root.summaries

      Item {
        id: cellHost
        required property var modelData
        readonly property bool selectedCell: modelData
          && modelData.dateKey === root.selectedDateKey
        width: Math.max(Style.space(40),
          (rail.width - rail.spacing * Math.max(0, root.summaries.length - 1))
            / Math.max(1, root.summaries.length))
        height: rail.height

        Button {
          id: cellButton
          anchors.fill: parent
          text: (modelData ? modelData.weekday + " " + modelData.dayOfMonth : "") + "\n"
            + root.countLine(modelData)
          selected: cellHost.selectedCell
          active: selected
          focusable: true
          fontSize: Style.font.caption
          verticalPadding: Style.spacing.xxs
          foreground: modelData && modelData.isToday && !cellHost.selectedCell
            ? Color.accent : Color.foreground
          onClicked: if (modelData) root.dateSelected(modelData.dateKey)
          Accessible.name: root.accessibleName(modelData)
          Accessible.role: Accessible.Button
        }

        Rectangle {
          visible: Boolean(modelData && modelData.hasFavoriteGames)
          width: Style.space(6)
          height: width
          radius: width / 2
          color: Color.accent
          anchors.top: parent.top
          anchors.right: parent.right
          anchors.margins: Style.space(6)
        }
      }
    }
  }
}

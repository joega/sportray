import QtQuick
import qs.Commons
import qs.Ui
import "../model/DateModel.js" as DateModel

Item {
  id: root

  property string selectedDateKey: ""
  property int radius: 2
  property bool compact: false

  signal dateSelected(string dateKey)

  readonly property var dates: DateModel.carouselDates(root.selectedDateKey,
    root.compact ? 1 : root.radius)

  implicitHeight: dateRail.height

  function selectDate(dateKey) {
    if (DateModel.isDateKey(dateKey)) root.dateSelected(dateKey)
  }

  Column {
    id: column
    anchors.fill: parent
    spacing: 0

    Row {
      id: dateRail
      width: parent.width
      height: Math.max(Style.space(48), Style.spacing.controlHeight)
      spacing: Style.spacing.xxs

      SemanticActionButton {
        id: previousButton
        iconName: "chevronLeft"
        fallbackText: "<"
        tooltipText: "Previous day"
        focusable: true
        size: dateRail.height
        onClicked: root.selectDate(DateModel.addDays(root.selectedDateKey, -1))
      }

      Repeater {
        model: root.dates

        Button {
          required property var modelData
          width: Math.max(Style.space(40), (dateRail.width - previousButton.width
            - nextButton.width - dateRail.spacing * 6) / root.dates.length)
          height: dateRail.height
          text: modelData.weekday + "\n" + modelData.day
          selected: modelData.key === root.selectedDateKey
          active: selected
          focusable: true
          fontSize: Style.font.caption
          verticalPadding: Style.spacing.xxs
          onClicked: root.selectDate(modelData.key)
          Accessible.name: modelData.weekday + " " + modelData.month + " " + modelData.day
          Accessible.role: Accessible.Button
        }
      }

      SemanticActionButton {
        id: nextButton
        iconName: "chevronRight"
        fallbackText: ">"
        tooltipText: "Next day"
        focusable: true
        size: dateRail.height
        onClicked: root.selectDate(DateModel.addDays(root.selectedDateKey, 1))
      }
    }
  }
}

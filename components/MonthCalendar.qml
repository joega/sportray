import QtQuick
import qs.Commons
import qs.Ui

// Focused 6-by-7 calendar surface. CalendarModel supplies every date and
// state; this component only renders bounded projections and emits intent.
Item {
  id: root

  property var gridState: ({cells: [], monthLabel: ""})
  property string selectedDateKey: ""
  property int focusedIndex: -1

  signal dateSelected(string dateKey)
  signal monthRequested(int delta)
  signal todayRequested()

  readonly property int columnCount: 7
  readonly property int rowCount: 6
  readonly property real cellHeight: Style.space(46)
  implicitHeight: controls.height + Style.spacing.xs + weekdays.height
    + Style.spacing.xs + calendarGrid.height

  function cellAt(index) {
    if (!calendarGrid || index < 0 || index >= calendarGrid.children.length) return null
    return calendarGrid.children[index]
  }

  function focusCell(index) {
    var cells = Array.isArray(root.gridState.cells) ? root.gridState.cells : []
    if (cells.length !== 42) return
    root.focusedIndex = Math.max(0, Math.min(cells.length - 1, index))
    var host = root.cellAt(root.focusedIndex)
    if (host && host.cellButton) host.cellButton.forceActiveFocus()
  }

  function focusSelected() {
    var cells = Array.isArray(root.gridState.cells) ? root.gridState.cells : []
    var index = cells.findIndex(function(cell) {
      return cell.dateKey === root.selectedDateKey
    })
    root.focusCell(index >= 0 ? index : 0)
  }

  function moveFocus(dx, dy) {
    var step = dy !== 0 ? dy * root.columnCount : dx
    root.focusCell(root.focusedIndex < 0 ? 0 : root.focusedIndex + step)
  }

  function activateFocused() {
    var cells = Array.isArray(root.gridState.cells) ? root.gridState.cells : []
    var cell = cells[root.focusedIndex]
    if (cell && typeof cell.dateKey === "string") root.dateSelected(cell.dateKey)
  }

  function countLine(cell) {
    if (!cell || cell.state === "unknown") return "Unknown"
    if (cell.state === "empty") return "No games"
    return cell.gameCount === 1 ? "1 game" : cell.gameCount + " games"
  }

  function accessibleName(cell) {
    if (!cell) return "Calendar day"
    return cell.weekday + " " + cell.month + " " + cell.dayOfMonth
      + ", " + root.countLine(cell)
      + (cell.hasFavoriteGames ? ", includes favorites" : "")
  }

  onGridStateChanged: root.focusSelected()
  onSelectedDateKeyChanged: if (root.focusedIndex < 0) root.focusSelected()

  Column {
    width: parent.width
    spacing: Style.spacing.xs

    Row {
      id: controls
      width: parent.width
      height: Math.max(Style.space(40), Style.spacing.controlHeight)
      spacing: Style.spacing.xs

      SemanticActionButton {
        iconName: "chevronLeft"
        fallbackText: "<"
        tooltipText: "Previous month"
        size: controls.height
        focusable: true
        onClicked: root.monthRequested(-1)
        Accessible.name: "Previous month"
        Accessible.role: Accessible.Button
      }

      Text {
        width: Math.max(0, controls.width - Style.space(150))
        height: controls.height
        text: root.gridState.monthLabel || "Calendar"
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.subtitle
        font.bold: true
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
      }

      SemanticActionButton {
        text: "Today"
        tooltipText: "Show today"
        focusable: true
        onClicked: root.todayRequested()
        Accessible.name: "Show today"
        Accessible.role: Accessible.Button
      }

      SemanticActionButton {
        iconName: "chevronRight"
        fallbackText: ">"
        tooltipText: "Next month"
        size: controls.height
        focusable: true
        onClicked: root.monthRequested(1)
        Accessible.name: "Next month"
        Accessible.role: Accessible.Button
      }
    }

    Row {
      id: weekdays
      width: parent.width
      height: Style.space(18)
      spacing: Style.spacing.xxs
      Repeater {
        model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        Text {
          required property string modelData
          width: (weekdays.width - weekdays.spacing * 6) / 7
          height: weekdays.height
          text: modelData
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
        }
      }
    }

    Grid {
      id: calendarGrid
      width: parent.width
      height: root.cellHeight * root.rowCount + spacing * (root.rowCount - 1)
      columns: root.columnCount
      rows: root.rowCount
      columnSpacing: Style.spacing.xxs
      rowSpacing: Style.spacing.xxs

      Repeater {
        model: root.gridState.cells || []
        Item {
          id: cellHost
          required property var modelData
          property alias cellButton: cellButton
          width: (calendarGrid.width - calendarGrid.columnSpacing * 6) / 7
          height: root.cellHeight

          Button {
            id: cellButton
            anchors.fill: parent
            text: (modelData ? modelData.dayOfMonth : "") + "\n"
              + root.countLine(modelData)
            selected: Boolean(modelData && modelData.isSelected)
            active: selected
            focusable: true
            fontSize: Style.font.caption
            verticalPadding: Style.spacing.xxs
            opacity: modelData && modelData.inMonth ? 1 : 0.58
            foreground: modelData && modelData.isToday && !selected
              ? Color.accent : Color.foreground
            onClicked: if (modelData) root.dateSelected(modelData.dateKey)
            Accessible.name: root.accessibleName(modelData)
            Accessible.role: Accessible.Button
          }

          Rectangle {
            visible: Boolean(modelData && modelData.hasFavoriteGames)
            width: Style.space(5)
            height: width
            radius: width / 2
            color: Color.accent
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Style.space(4)
          }
        }
      }
    }
  }
}

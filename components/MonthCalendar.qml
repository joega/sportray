import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui

// Vertically scrolling calendar surface. CalendarModel supplies every date and
// state; this component only renders bounded projections and emits intent.
Item {
  id: root
  clip: true

  property var gridState: ({cells: [], monthLabel: ""})
  property var pages: []
  property string selectedDateKey: ""
  property int focusedIndex: -1
  property bool edgeRequestPending: false
  property bool edgeRequestsSuppressed: true

  signal dateSelected(string dateKey)
  signal monthRequested(int delta)
  signal todayRequested()

  readonly property int columnCount: 7
  readonly property int rowCount: 6
  readonly property real cellHeight: Style.space(46)
  readonly property var weekRows: root.buildWeekRows()
  implicitHeight: controls.height + Style.spacing.xs + weekdays.height
    + Style.spacing.xs + Math.min(Style.space(6 * 46 + 5 * 2), weekList.height)

  function buildWeekRows() {
    var source = Array.isArray(root.pages) && root.pages.length > 0
      ? root.pages : [root.gridState]
    var rows = []
    source.forEach(function(page) {
      var cells = page && Array.isArray(page.cells) ? page.cells : []
      for (var offset = 0; offset + root.columnCount <= cells.length; offset += root.columnCount) {
        rows.push({
          monthKey: page.monthKey || "",
          monthLabel: page.monthLabel || "",
          cells: cells.slice(offset, offset + root.columnCount)
        })
      }
    })
    return rows
  }

  function cellAt(index) {
    if (!weekList || index < 0 || index >= weekList.contentItem.children.length) return null
    var weeks = weekList.contentItem.children
    // The middle page is the active month; pages on either side provide the
    // scroll runway and are not part of the focused 42-cell month.
    var weekIndex = (root.pages.length > 0 ? 6 : 0)
      + Math.floor(index / root.columnCount)
    var cellIndex = index % root.columnCount
    var week = weeks[weekIndex]
    return week && week.cellHosts ? week.cellHosts[cellIndex] : null
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
  onPagesChanged: {
    root.edgeRequestsSuppressed = true
    root.edgeRequestPending = false
    if (weekList && weekList.count > 0) weekList.positionViewAtIndex(weekList.count > 6 ? 6 : 0,
      ListView.Beginning)
    Qt.callLater(function() { root.edgeRequestsSuppressed = false })
  }
  onSelectedDateKeyChanged: if (root.focusedIndex < 0) root.focusSelected()

  Column {
    width: parent.width
    spacing: Style.spacing.xs

    Row {
      id: controls
      width: parent.width
      height: Math.max(Style.space(40), Style.spacing.controlHeight)
      spacing: Style.spacing.xs

      Text {
        width: Math.max(0, controls.width - Style.space(90))
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

    ListView {
      id: weekList
      width: parent.width
      height: root.cellHeight * 6 + Style.spacing.xxs * 5
      model: root.weekRows
      spacing: Style.spacing.xxs
      clip: true
      interactive: contentHeight > height
      boundsBehavior: Flickable.StopAtBounds
      ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

      onAtYBeginningChanged: if (atYBeginning && !root.edgeRequestsSuppressed
          && !root.edgeRequestPending && count > 6) {
        root.edgeRequestPending = true
        root.monthRequested(-1)
      }
      onAtYEndChanged: if (atYEnd && !root.edgeRequestsSuppressed
          && !root.edgeRequestPending && count > 6) {
        root.edgeRequestPending = true
        root.monthRequested(1)
      }

      delegate: Row {
          id: weekRow
          required property var modelData
          property var cellHosts: []
          width: weekList.width
          height: root.cellHeight
          spacing: Style.spacing.xxs

          Repeater {
            model: weekRow.modelData ? weekRow.modelData.cells : []
            delegate: Item {
              id: cellHost
              required property var modelData
              property alias cellButton: cellButton
              width: (weekRow.width - weekRow.spacing * 6) / 7
              height: root.cellHeight
              Component.onCompleted: weekRow.cellHosts.push(cellHost)

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
}

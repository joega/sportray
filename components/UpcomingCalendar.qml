import QtQuick
import QtQuick.Window
import QtQuick.Controls as QQC
import qs.Commons as Commons
import qs.Ui
import "../model/CalendarModel.js" as CalendarModel
import "../model/DateModel.js" as DateModel
import "../model/UiTypography.js" as Typography
import "../model/LifecyclePolicy.js" as LifecyclePolicy

// Calendar and team agenda presentation of normalized schedule entries. The shared schedule
// owner supplies coverage and data; this view emits navigation intent only.
FocusScope {
  id: root

  property var teamOptions: []
  property string teamId: ""
  property bool globalMode: root.teamId === ""
  property string selectedDateKey: ""
  property string todayDateKey: ""
  property string monthKey: ""
  property var scheduleState: ({})
  property var imageStore: null
  property string focusedDateKey: ""
  readonly property var callbackOwner: LifecyclePolicy.createOwnerState()
  readonly property string displayedMonthKey: CalendarModel.monthKey(root.monthKey
    || root.selectedDateKey || root.todayDateKey)
  readonly property var dateKeys: CalendarModel.monthDateKeys(root.displayedMonthKey)
  readonly property bool stateMatchesTeam: root.scheduleState !== null && root.scheduleState !== undefined
    && root.scheduleState.teamId === root.teamId
  readonly property bool loading: root.stateMatchesTeam && root.scheduleState.loading === true
  readonly property bool entriesOverflow: root.stateMatchesTeam && Array.isArray(root.scheduleState.entries)
    && root.scheduleState.entries.length > (root.globalMode ? 2048 : 256)
  readonly property string anchorDateKey: root.selectedDateKey || root.todayDateKey
  readonly property bool completeFromAnchor: root.stateMatchesTeam && root.scheduleState.hasData === true
    && root.scheduleState.loading !== true && root.scheduleState.stale !== true
    && root.scheduleState.partial !== true && DateModel.isDateKey(root.scheduleState.coverageStart || "")
    && root.scheduleState.coverageStart <= root.anchorDateKey
    && DateModel.isDateKey(root.scheduleState.coverageEnd || "")
    && (!root.nextEntry || root.nextEntry.dateKey <= root.scheduleState.coverageEnd)
  readonly property bool inputActive: teamScope.activeFocus || teamPicker.popupOpen
  readonly property var entries: root.sortedEntries()
  readonly property var upcomingEntries: root.entries.filter(function(entry) {
    var status = entry.game.status
    return entry.dateKey >= root.anchorDateKey
      && (status === "scheduled" || status === "live" || status === "intermission")
  })
  readonly property var nextEntry: root.upcomingEntries.length ? root.upcomingEntries[0] : null
  readonly property var laterEntries: root.upcomingEntries.slice(1)
  readonly property bool globalDayLoaded: root.globalMode && root.stateMatchesTeam
    && root.scheduleState.dateKey === (root.selectedDateKey || root.todayDateKey)
    && root.scheduleState.hasData === true
  readonly property var daySummaries: root.globalMode && root.stateMatchesTeam
    && Array.isArray(root.scheduleState.daySummaries) ? root.scheduleState.daySummaries.slice(0, 8) : []
  readonly property var selectedDayEntries: root.entriesOn(root.selectedDateKey || root.todayDateKey)
  readonly property var agendaEntries: root.globalMode ? root.selectedDayEntries : root.laterEntries
  readonly property string windowStartKey: root.stateMatchesTeam && DateModel.isDateKey(root.scheduleState.coverageStart || "")
    ? root.scheduleState.coverageStart : root.anchorDateKey
  readonly property real cellHeight: Math.max(Commons.Style.space(32), Commons.Style.font.body + Commons.Style.space(15))
  readonly property real cellWidth: Math.max(1, (root.width - Commons.Style.spacing.xxs * 6) / 7)
  readonly property bool requestFailed: root.stateMatchesTeam && (root.scheduleState.failed === true
    || (root.scheduleState.failed === undefined && !root.loading
      && root.scheduleState.hasData !== true && Boolean(root.scheduleState.errorSummary)))
  readonly property string statusMessage: {
    if (!root.teamOptions.length) return "Follow a league or team to see its games here."
    if (!root.stateMatchesTeam) return root.globalMode ? "Loading followed leagues…" : "Loading team schedule…"
    if (root.entriesOverflow) return "Schedule unavailable. Retry to load it again."
    if (root.scheduleState.errorSummary) return root.scheduleState.errorSummary
    if (root.loading) return root.scheduleState.hasData ? "Updating the listed games…"
      : root.globalMode ? "Loading games for this date…" : "Finding upcoming games…"
    if (root.scheduleState.stale) return "Showing the last listed games. Refresh to check for changes."
    if (root.scheduleState.partial) return "Some dates are not available yet. Listed games are still shown."
    if (root.globalMode && !root.globalDayLoaded) return "Select a day to load its games."
    if (root.scheduleState.hasData !== true)
      return root.entries.length ? "More games may be added to this schedule." : "Schedule is not available yet."
    if (!root.globalMode && !root.upcomingEntries.length) return "No upcoming games are listed in this schedule."
    return ""
  }

  signal teamSelected(string teamId)
  signal monthRequested(string monthKey)
  signal daySelected(string dateKey)
  signal windowRequested(string startDateKey)
  signal dateSelected(string dateKey)
  signal closeRequested()
  signal retryRequested()

  implicitWidth: Commons.Style.space(368)
  implicitHeight: contentColumn.implicitHeight
  clip: true

  function sortedEntries() {
    if (!root.stateMatchesTeam || !Array.isArray(root.scheduleState.entries)) return []
    // The data boundary rejects overflow rather than presenting it as complete.
    if (root.scheduleState.entries.length > (root.globalMode ? 2048 : 256)) return []
    if (root.globalMode && !root.globalDayLoaded) return []
    var seen = Object.create(null)
    return root.scheduleState.entries.filter(function(entry) {
      if (!entry || !entry.game || entry.game.isValid !== true
          || !DateModel.isDateKey(entry.dateKey) || !entry.game.id) return false
      var game = entry.game
      if (!root.globalMode && (!game.awayTeam || game.awayTeam.id !== root.teamId)
          && (!game.homeTeam || game.homeTeam.id !== root.teamId)) return false
      if (seen[game.id]) return false
      seen[game.id] = true
      return game.status !== "canceled" && game.status !== "malformed" && game.status !== "unknown"
    }).slice().sort(function(left, right) {
      if (left.dateKey !== right.dateKey) return left.dateKey < right.dateKey ? -1 : 1
      var leftTime = left.timeKnown === false ? Infinity : Date.parse(left.game.startTime)
      var rightTime = right.timeKnown === false ? Infinity : Date.parse(right.game.startTime)
      if (!isFinite(leftTime)) leftTime = Infinity
      if (!isFinite(rightTime)) rightTime = Infinity
      if (leftTime !== rightTime) return leftTime < rightTime ? -1 : 1
      return left.game.id < right.game.id ? -1 : left.game.id > right.game.id ? 1 : 0
    })
  }

  function entriesOn(dateKey) {
    return root.entries.filter(function(entry) { return entry.dateKey === dateKey })
  }

  function entryTime(entry) {
    if (!entry || entry.timeKnown === false) return "Time TBD"
    var value = new Date(entry.game.startTime)
    return isNaN(value.getTime()) ? "Time TBD" : Qt.formatDateTime(value, "h:mm AP")
  }

  function relativeLabel(dateKey) {
    var distance = DateModel.calendarDistance(dateKey, root.todayDateKey)
    if (distance === 0) return "Today"
    if (distance === 1) return "Tomorrow"
    return distance !== null && distance > 1 ? "In " + distance + " days" : ""
  }

  function teamLabel(team) {
    return team ? team.shortName || team.name || team.abbreviation || "Team unavailable" : "Team unavailable"
  }

  function selectedTeam(entry) {
    if (!entry) return null
    return entry.game.awayTeam && entry.game.awayTeam.id === root.teamId
      ? entry.game.awayTeam : entry.game.homeTeam
  }

  function opponent(entry) {
    if (!entry) return ""
    return entry.game.awayTeam && entry.game.awayTeam.id === root.teamId
      ? "at " + root.teamLabel(entry.game.homeTeam) : "vs " + root.teamLabel(entry.game.awayTeam)
  }

  function matchup(entry) {
    if (!entry) return ""
    return root.globalMode ? root.teamLabel(entry.game.awayTeam) + " at " + root.teamLabel(entry.game.homeTeam)
      : root.opponent(entry)
  }

  function agendaDetail(entry) {
    if (!entry) return ""
    var prefix = root.globalMode ? String(entry.game.league || "").toUpperCase() + " · "
      : DateModel.shortDateLabel(entry.dateKey) + " · "
    var status = entry.game.status
    return prefix + (status === "final" ? "Final" : status === "postponed" ? "Postponed"
      : status === "live" && !root.loading && root.scheduleState.stale !== true ? "Live" : root.entryTime(entry))
  }

  function changeWindow(delta) {
    var next = DateModel.addDays(root.windowStartKey, delta * 35)
    if (next) root.windowRequested(next)
  }

  function selectDay(dateKey) {
    if (!DateModel.isDateKey(dateKey)) return
    root.focusedDateKey = dateKey
    root.daySelected(dateKey)
  }

  function logoSource(entry) {
    var team = root.selectedTeam(entry)
    return team && team.logoUrl && root.imageStore ? root.imageStore.sourceFor(team.logoUrl) : ""
  }

  function daySummary(dateKey) {
    for (var index = 0; index < root.daySummaries.length; index++) {
      var summary = root.daySummaries[index]
      if (summary && summary.dateKey === dateKey) return summary
    }
    return null
  }

  function listedCount(dateKey) {
    var count = root.entriesOn(dateKey).length
    var summary = root.daySummary(dateKey)
    return Math.max(count, summary && Number(summary.count) > 0 ? Number(summary.count) : 0)
  }

  function cellName(dateKey) {
    var count = root.listedCount(dateKey)
    var summary = root.daySummary(dateKey)
    var currentDay = root.globalDayLoaded && dateKey === (root.selectedDateKey || root.todayDateKey)
    var loaded = currentDay || (summary && summary.loaded === true)
    var complete = (summary && summary.complete === true) || (currentDay
      && root.scheduleState.coverageComplete === true && root.scheduleState.stale !== true)
    var result = DateModel.shortDateLabel(dateKey)
    if (count) result += ", " + count + (count === 1 ? " listed game" : " listed games")
    else if (root.globalMode && loaded && !complete) result += ", no listed games; coverage incomplete"
    else if (root.globalMode && !complete) result += ", not loaded"
    else result += ", no listed game"
    if (dateKey === root.todayDateKey) result += ", today"
    if (dateKey === root.selectedDateKey) result += ", selected date"
    return result
  }

  function defer(callback) {
    var owner = root.callbackOwner
    var generation = LifecyclePolicy.captureGeneration(owner)
    Qt.callLater(function() {
      if (LifecyclePolicy.canRun(owner, generation) && root.visible) callback()
    })
  }

  function focusCalendar() {
    if (teamPicker.popupOpen) return
    if (!DateModel.isDateKey(root.focusedDateKey) || root.dateKeys.indexOf(root.focusedDateKey) === -1)
      root.focusedDateKey = root.dateKeys.indexOf(root.selectedDateKey) !== -1 ? root.selectedDateKey
        : root.dateKeys.indexOf(root.todayDateKey) !== -1 ? root.todayDateKey : root.displayedMonthKey
    calendarKeys.forceActiveFocus()
    if (root.globalMode) root.ensureVisible(dateGrid)
    else viewport.contentY = 0
  }

  function changeMonth(delta) {
    var next = CalendarModel.addMonths(root.displayedMonthKey, delta)
    if (!next) return
    root.focusedDateKey = next
    root.monthRequested(next)
    root.defer(root.focusCalendar)
  }

  function moveDate(delta) {
    var current = DateModel.isDateKey(root.focusedDateKey) ? root.focusedDateKey
      : root.selectedDateKey || root.todayDateKey || root.displayedMonthKey
    var next = DateModel.addDays(current, delta)
    if (!next) return
    root.focusedDateKey = next
    if (CalendarModel.monthKey(next) !== root.displayedMonthKey)
      root.monthRequested(CalendarModel.monthKey(next))
    root.defer(root.focusCalendar)
  }

  function ensureVisible(item) {
    if (!item) return
    var top = item.mapToItem(viewport, 0, 0).y
    var bottom = top + item.height
    if (top < 0) viewport.contentY = Math.max(0, viewport.contentY + top)
    else if (bottom > viewport.height)
      viewport.contentY = Math.max(0, Math.min(viewport.contentHeight - viewport.height,
        viewport.contentY + bottom - viewport.height))
  }

  function ownsItem(item) {
    for (var depth = 0; item && depth < 64; depth++, item = item.parent)
      if (item === root) return true
    return false
  }

  onSelectedDateKeyChanged: root.focusedDateKey = root.selectedDateKey
  onMonthKeyChanged: root.defer(root.focusCalendar)
  onTeamIdChanged: {
    root.focusedDateKey = root.selectedDateKey || root.todayDateKey
    // Native Dropdown updates its own value when selected. Keep subsequent
    // caller-owned selection changes visible after that binding is replaced.
    if (teamPicker && teamPicker.value !== root.teamId) teamPicker.value = root.teamId
  }
  onVisibleChanged: if (visible) root.defer(root.focusCalendar)
  Component.onCompleted: root.defer(root.focusCalendar)
  Component.onDestruction: LifecyclePolicy.invalidate(root.callbackOwner)

  Keys.priority: Keys.BeforeItem
  Keys.onPressed: function(event) {
    if (teamPicker.popupOpen) return
    if (event.key === Qt.Key_Escape) {
      root.closeRequested()
      event.accepted = true
      return
    }
    if (root.inputActive) return
    if (!root.globalMode) {
      if (event.key === Qt.Key_PageUp) root.changeWindow(-1)
      else if (event.key === Qt.Key_PageDown) root.changeWindow(1)
      else return
      event.accepted = true
      return
    }
    if (event.key === Qt.Key_PageUp) root.changeMonth(-1)
    else if (event.key === Qt.Key_PageDown) root.changeMonth(1)
    else if (event.key === Qt.Key_Left) root.moveDate(-1)
    else if (event.key === Qt.Key_Right) root.moveDate(1)
    else if (event.key === Qt.Key_Up) root.moveDate(-7)
    else if (event.key === Qt.Key_Down) root.moveDate(7)
    else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)
        && calendarKeys.activeFocus && DateModel.isDateKey(root.focusedDateKey))
      root.selectDay(root.focusedDateKey)
    else return
    event.accepted = true
  }

  Connections {
    target: root.Window.window
    function onActiveFocusItemChanged() {
      var window = root.Window.window
      if (window && root.ownsItem(window.activeFocusItem)) root.ensureVisible(window.activeFocusItem)
    }
  }

  Item { id: calendarKeys; focus: true; activeFocusOnTab: true }

  Flickable {
    id: viewport
    anchors.fill: parent
    contentWidth: width
    contentHeight: contentColumn.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height
    QQC.ScrollBar.vertical: QQC.ScrollBar { policy: QQC.ScrollBar.AsNeeded }

    Column {
      id: contentColumn
      width: viewport.width
      spacing: Commons.Style.spacing.md

      FocusScope {
        id: teamScope
        width: parent.width
        height: teamPicker.implicitHeight
        Dropdown {
          id: teamPicker
          anchors.fill: parent
          label: "Schedule"
          showLabel: false
          value: root.teamId
          options: root.teamOptions
          fontFamily: Typography.family
          onChanged: function(value) { root.teamSelected(value) }
          onPopupOpenChanged: if (!popupOpen) root.defer(root.focusCalendar)
          Accessible.name: "Choose all followed leagues or a team schedule"
          Accessible.role: Accessible.ComboBox
          Accessible.onPressAction: teamPicker.open()
        }
      }

      BorderSurface {
        id: nextCard
        width: parent.width
        height: root.nextEntry ? nextContent.implicitHeight + Commons.Style.spacing.lg * 2 : 0
        visible: !root.globalMode && root.nextEntry !== null
        color: Qt.alpha(Commons.Color.accent, 0.06)
        borderSpec: Commons.Border.none()
        radius: Commons.Style.cornerRadius
        Column {
          id: nextContent
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: Commons.Style.spacing.lg
          spacing: Commons.Style.spacing.sm
          Row {
            width: parent.width
            Text {
              width: parent.width / 2
              text: root.nextEntry && !root.loading && root.scheduleState.stale !== true
                  && root.nextEntry.game.status === "live" ? "Live now"
                : root.nextEntry && !root.loading && root.scheduleState.stale !== true
                  && root.nextEntry.game.status === "intermission" ? "Intermission"
                : root.completeFromAnchor ? "Next up" : "Next listed game"
              textFormat: Text.PlainText
              color: Commons.Color.accent
              font.family: Typography.family
              font.pixelSize: Commons.Style.font.bodySmall
              font.weight: Font.DemiBold
            }
            Text {
              width: parent.width / 2
              text: root.nextEntry ? root.relativeLabel(root.nextEntry.dateKey) : ""
              textFormat: Text.PlainText
              color: Qt.alpha(Commons.Color.popups.text, 0.85)
              font.family: Typography.family
              font.pixelSize: Commons.Style.font.bodySmall
              horizontalAlignment: Text.AlignRight
            }
          }
          Text {
            width: parent.width
            text: root.nextEntry ? root.teamLabel(root.selectedTeam(root.nextEntry)) + " " + root.opponent(root.nextEntry) : ""
            textFormat: Text.PlainText
            color: Commons.Color.popups.text
            font.family: Typography.family
            font.pixelSize: Commons.Style.font.body
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
          }
          Row {
            width: parent.width
            spacing: Commons.Style.spacing.sm
            Text {
              width: Math.max(0, parent.width - jumpButton.width - parent.spacing)
              anchors.verticalCenter: parent.verticalCenter
              text: root.nextEntry ? DateModel.shortDateLabel(root.nextEntry.dateKey) + " · " + root.entryTime(root.nextEntry) : ""
              textFormat: Text.PlainText
              color: Qt.alpha(Commons.Color.popups.text, 0.85)
              font.family: Typography.family
              font.pixelSize: Commons.Style.font.bodySmall
              wrapMode: Text.WordWrap
            }
            SemanticActionButton {
              id: jumpButton
              text: "View day"
              tooltipText: "Jump to the next listed game"
              textFontSize: Commons.Style.font.bodySmall
              focusable: true
              onClicked: if (root.nextEntry) root.dateSelected(root.nextEntry.dateKey)
            }
          }
        }
      }


      Row {
        id: teamRangeControls
        width: parent.width
        visible: !root.globalMode
        spacing: Commons.Style.spacing.sm
        SemanticActionButton {
          id: previousWindow
          iconName: "chevronLeft"
          size: Commons.Style.space(28)
          tooltipText: "Previous 35 days"
          focusable: true
          onClicked: root.changeWindow(-1)
        }
        Text {
          width: Math.max(0, parent.width - previousWindow.width - nextWindow.width - parent.spacing * 2)
          height: Math.max(previousWindow.height, implicitHeight)
          text: Qt.formatDate(DateModel.parseDateKey(root.windowStartKey), "MMM d") + " – "
            + Qt.formatDate(DateModel.parseDateKey(DateModel.addDays(root.windowStartKey, 34)), "MMM d, yyyy")
          textFormat: Text.PlainText
          color: Qt.alpha(Commons.Color.popups.text, 0.85)
          font.family: Typography.family
          font.pixelSize: Commons.Style.font.caption
          wrapMode: Text.WordWrap
          verticalAlignment: Text.AlignVCenter
          horizontalAlignment: Text.AlignHCenter
        }
        SemanticActionButton {
          id: nextWindow
          iconName: "chevronRight"
          size: Commons.Style.space(28)
          tooltipText: "Next 35 days"
          focusable: true
          onClicked: root.changeWindow(1)
        }
      }

      Row {
        visible: root.globalMode
        width: parent.width
        spacing: Commons.Style.spacing.sm
        Text {
          width: Math.max(0, parent.width - previousMonth.width - nextMonth.width - todayButton.width - parent.spacing * 3)
          height: previousMonth.height
          text: DateModel.isDateKey(root.displayedMonthKey)
            ? Qt.formatDate(DateModel.parseDateKey(root.displayedMonthKey), "MMMM yyyy") : "Calendar"
          textFormat: Text.PlainText
          color: Commons.Color.popups.text
          font.family: Typography.family
          font.pixelSize: Commons.Style.font.subtitle
          font.weight: Font.DemiBold
          verticalAlignment: Text.AlignVCenter
          elide: Text.ElideRight
        }
        SemanticActionButton {
          id: previousMonth
          iconName: "chevronLeft"
          size: Commons.Style.space(28)
          tooltipText: "Previous month"
          focusable: true
          onClicked: root.changeMonth(-1)
        }
        SemanticActionButton {
          id: todayButton
          text: "Today"
          textFontSize: Commons.Style.font.bodySmall
          tooltipText: "Return calendar to today"
          focusable: true
          onClicked: {
            root.selectDay(root.todayDateKey)
            root.defer(root.focusCalendar)
          }
        }
        SemanticActionButton {
          id: nextMonth
          iconName: "chevronRight"
          size: Commons.Style.space(28)
          tooltipText: "Next month"
          focusable: true
          onClicked: root.changeMonth(1)
        }
      }

      Row {
        visible: root.globalMode
        width: parent.width
        spacing: Commons.Style.spacing.xxs
        Repeater {
          model: ["M", "T", "W", "T", "F", "S", "S"]
          Text {
            required property string modelData
            width: root.cellWidth
            text: modelData
            textFormat: Text.PlainText
            color: Qt.alpha(Commons.Color.popups.text, 0.85)
            font.family: Typography.family
            font.pixelSize: Commons.Style.font.caption
            horizontalAlignment: Text.AlignHCenter
            Accessible.ignored: true
          }
        }
      }

      Grid {
        id: dateGrid
        visible: root.globalMode
        width: parent.width
        columns: 7
        rowSpacing: Commons.Style.spacing.xxs
        columnSpacing: Commons.Style.spacing.xxs
        Repeater {
          model: root.dateKeys
          BorderSurface {
            id: dayCell
            required property string modelData
            readonly property bool selectedDay: modelData === root.selectedDateKey
            readonly property bool today: modelData === root.todayDateKey
            readonly property bool inMonth: CalendarModel.monthKey(modelData) === root.displayedMonthKey
            readonly property bool hasCursor: calendarKeys.activeFocus && modelData === root.focusedDateKey
            width: root.cellWidth
            height: root.cellHeight
            color: selectedDay ? Commons.Style.selectedFillFor(Commons.Color.popups.text, Commons.Color.accent)
              : dayHover.hovered ? Commons.Style.hoverFillFor(Commons.Color.popups.text, Commons.Color.accent) : "transparent"
            borderSpec: hasCursor ? Commons.Border.controlSpec("focus", Commons.Color.popups.text, Commons.Color.accent)
              : today ? Commons.Border.controlSpec("normal", Commons.Color.popups.text, Commons.Color.accent) : Commons.Border.none()
            radius: Commons.Style.cornerRadius
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              y: Commons.Style.spacing.xxs
              text: String(Number(dayCell.modelData.slice(-2)))
              textFormat: Text.PlainText
              color: dayCell.inMonth ? Commons.Color.popups.text : Qt.alpha(Commons.Color.popups.text, 0.62)
              font.family: Typography.family
              font.pixelSize: Commons.Style.font.body
              font.weight: dayCell.selectedDay || dayCell.today ? Font.DemiBold : Font.Normal
            }
            Rectangle {
              width: Commons.Style.space(4)
              height: width
              radius: width / 2
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.bottom: parent.bottom
              anchors.bottomMargin: Commons.Style.spacing.xs
              color: Commons.Color.accent
              visible: root.listedCount(dayCell.modelData) > 0
            }
            HoverHandler { id: dayHover }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.selectDay(dayCell.modelData)
            }
            Accessible.name: root.cellName(modelData)
            Accessible.role: Accessible.Button
            Accessible.selected: selectedDay
            Accessible.onPressAction: root.selectDay(dayCell.modelData)
          }
        }
      }

      Row {
        visible: root.globalMode
        spacing: Commons.Style.spacing.sm
        Rectangle {
          width: Commons.Style.space(4)
          height: width
          radius: width / 2
          color: Commons.Color.accent
          anchors.verticalCenter: parent.verticalCenter
        }
        Text {
          text: "Loaded game day"
          textFormat: Text.PlainText
          color: Qt.alpha(Commons.Color.popups.text, 0.85)
          font.family: Typography.family
          font.pixelSize: Commons.Style.font.caption
        }
      }

      Text {
        width: parent.width
        visible: root.globalMode && root.statusMessage !== "Select a day to load its games."
        text: "Select a day to load its games."
        textFormat: Text.PlainText
        color: Qt.alpha(Commons.Color.popups.text, 0.85)
        font.family: Typography.family
        font.pixelSize: Commons.Style.font.caption
        wrapMode: Text.WordWrap
      }


      Text {
        width: parent.width
        visible: root.statusMessage !== ""
        text: root.statusMessage
        textFormat: Text.PlainText
        color: root.requestFailed || root.entriesOverflow ? Commons.Color.urgent : Qt.alpha(Commons.Color.popups.text, 0.85)
        font.family: Typography.family
        font.pixelSize: Commons.Style.font.bodySmall
        wrapMode: Text.WordWrap
      }
      SemanticActionButton {
        visible: root.stateMatchesTeam && (root.requestFailed
          || root.scheduleState.stale === true || root.entriesOverflow) && !root.loading
        height: visible ? implicitHeight : 0
        text: "Retry schedule"
        tooltipText: "Refresh this schedule"
        textFontSize: Commons.Style.font.bodySmall
        focusable: true
        onClicked: root.retryRequested()
      }


      Column {
        width: parent.width
        visible: root.globalMode || root.agendaEntries.length > 0
        spacing: Commons.Style.spacing.sm
        Text {
          width: parent.width
          text: root.globalMode ? DateModel.shortDateLabel(root.selectedDateKey || root.todayDateKey) : "Upcoming games"
          textFormat: Text.PlainText
          color: Qt.alpha(Commons.Color.popups.text, 0.85)
          font.family: Typography.family
          font.pixelSize: Commons.Style.font.caption
        }
        Text {
          width: parent.width
          visible: root.globalMode && root.globalDayLoaded && root.agendaEntries.length === 0 && !root.loading && !root.requestFailed
          text: "No games are listed in the loaded data."
          textFormat: Text.PlainText
          color: Qt.alpha(Commons.Color.popups.text, 0.85)
          font.family: Typography.family
          font.pixelSize: Commons.Style.font.bodySmall
          wrapMode: Text.WordWrap
        }
        SemanticActionButton {
          visible: root.globalMode
          text: "View day"
          tooltipText: "Open scores for the selected date"
          textFontSize: Commons.Style.font.bodySmall
          focusable: true
          onClicked: root.dateSelected(root.selectedDateKey || root.todayDateKey)
        }
        Repeater {
          model: root.agendaEntries
          Item {
            id: laterRow
            required property var modelData
            width: parent.width
            height: Math.max(Commons.Style.space(32), laterText.implicitHeight + Commons.Style.spacing.sm * 2)
            activeFocusOnTab: true
            Keys.onReturnPressed: root.dateSelected(laterRow.modelData.dateKey)
            Keys.onEnterPressed: root.dateSelected(laterRow.modelData.dateKey)
            Keys.onSpacePressed: root.dateSelected(laterRow.modelData.dateKey)
            BorderSurface {
              anchors.fill: parent
              color: laterRow.activeFocus ? Commons.Style.focusFillFor(Commons.Color.popups.text, Commons.Color.accent)
                : laterHover.hovered ? Commons.Style.hoverFillFor(Commons.Color.popups.text, Commons.Color.accent) : "transparent"
              borderSpec: laterRow.activeFocus ? Commons.Border.controlSpec("focus", Commons.Color.popups.text, Commons.Color.accent) : Commons.Border.none()
              radius: Commons.Style.cornerRadius
            }
            Column {
              id: laterText
              width: parent.width
              spacing: Commons.Style.spacing.xxs
              Text {
                width: parent.width
                text: root.agendaDetail(laterRow.modelData)
                textFormat: Text.PlainText
                color: Qt.alpha(Commons.Color.popups.text, 0.85)
                font.family: Typography.family
                font.pixelSize: Commons.Style.font.caption
                wrapMode: Text.WordWrap
              }
              Text {
                width: parent.width
                text: root.matchup(laterRow.modelData)
                textFormat: Text.PlainText
                color: Commons.Color.popups.text
                font.family: Typography.family
                font.pixelSize: Commons.Style.font.bodySmall
                wrapMode: Text.WordWrap
              }
            }
            Rectangle {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              height: 1
              color: Commons.Color.popups.text
              opacity: 0.10
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                laterRow.forceActiveFocus()
                root.dateSelected(laterRow.modelData.dateKey)
              }
            }
            HoverHandler { id: laterHover }
            Accessible.name: DateModel.shortDateLabel(modelData.dateKey) + ", " + root.agendaDetail(modelData) + ", " + root.matchup(modelData)
            Accessible.role: Accessible.Button
            Accessible.onPressAction: root.dateSelected(laterRow.modelData.dateKey)
          }
        }
      }
    }
  }
}

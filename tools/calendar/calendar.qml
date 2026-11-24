import QtQuick
import QtQuick.Window
import QtTest as Test
import Quickshell
import qs.Commons as Commons
import qs.Ui as Ui
import "../../components" as Components

ShellRoot {
  id: root
  property var fixture: null
  property var uiCase: ({width: 400, fontSize: 12})
  property var selectedDates: []
  property var previewDates: []
  property var requestedWindows: []
  property int monthCalls: 0
  property int closeCalls: 0
  property int retryCalls: 0

  function readText(path) {
    var request = new XMLHttpRequest()
    request.open("GET", Qt.resolvedUrl(path), false)
    request.send()
    return request.responseText
  }
  Window {
    id: window
    width: root.uiCase.width
    height: 640
    visible: true
    color: Commons.Color.popups.background
    Ui.BorderSurface {
      id: surface
      anchors.fill: parent
      color: Commons.Color.popups.background
      borderSpec: Commons.Border.surfaceSpec("popups", "border", Commons.Color.popups.border, 2)
      radius: Commons.Style.cornerRadius
      Components.UpcomingCalendar {
        id: calendar
        anchors.fill: parent
        anchors.margins: Commons.Style.space(16)
        teamOptions: root.fixture ? root.fixture.teamOptions : []
        teamId: ""
        todayDateKey: root.fixture ? root.fixture.today : ""
        selectedDateKey: todayDateKey
        monthKey: "2026-11-01"
        scheduleState: root.fixture ? root.fixture.states[teamId] : ({})
        onMonthRequested: function(month) { root.monthCalls++; calendar.monthKey = month }
        onTeamSelected: function(team) { calendar.teamId = team }
        onDaySelected: function(date) { root.previewDates = root.previewDates.concat([date]); calendar.selectedDateKey = date; calendar.monthKey = date.slice(0, 7) + "-01" }
        onWindowRequested: function(date) { root.requestedWindows = root.requestedWindows.concat([date]) }
        onDateSelected: function(date) { root.selectedDates = root.selectedDates.concat([date]) }
        onCloseRequested: root.closeCalls++
        onRetryRequested: root.retryCalls++
      }
    }
    Timer { interval: 300; running: true; onTriggered: checks.run() }
    Test.TestCase {
      id: checks
      when: false
      function check(value, message) { if (!value) throw new Error(message) }
      function same(actual, expected, message) { if (actual !== expected) throw new Error(message + ": " + actual + " != " + expected) }
      function find(object, predicate, seen) {
        if (!object || seen.indexOf(object) !== -1 || seen.length > 5000) return null
        seen.push(object)
        if (predicate(object)) return object
        for (var key of ["children", "data", "contentItem"]) {
          var value = object[key]
          if (!value) continue
          if (typeof value.length === "number") {
            for (var child of value) { var found = find(child, predicate, seen); if (found) return found }
          } else { var item = find(value, predicate, seen); if (item) return item }
        }
        return null
      }
      function text(object, value) { return find(object, function(item) { return item.visible && "text" in item && item.text === value }, []) }
      function capture(name) {
        var done = false, saved = false
        surface.grabToImage(function(result) {
          saved = result.saveToFile(Quickshell.env("SPORTRAY_TEST_CAPTURE") + "/" + name + ".png")
          done = true
        }, Qt.size(window.width * 2, window.height * 2))
        tryVerify(function() { return done }, 4000)
        check(saved, "capture failed: " + name)
      }
      function run() {
        try {
          root.uiCase = JSON.parse(root.readText("ui-case.json"))
          root.fixture = JSON.parse(root.readText("calendar-fixture.json"))
          Commons.Color.loadUserShell("")
          Commons.Color.loadColors(root.readText("theme/colors.toml"))
          Commons.Color.loadShell(root.readText("theme/shell.toml"))
          Commons.Style.fontFamily = "JetBrainsMono Nerd Font"
          Commons.Style.fontBaseSize = root.uiCase.fontSize
          Commons.Style.cornerRadius = 8
          wait(120)
          same(calendar.dateKeys.length, 42, "calendar cell count")
          check(calendar.globalMode, "calendar did not default to all followed leagues")
          same(calendar.agendaEntries.length, 2, "global agenda omitted followed-league game")
          check(text(calendar, "November 2026") !== null, "global month grid absent")
          check(text(calendar, "Next up") === null, "global view shows team next-game card")
          same(calendar.listedCount("2026-11-25"), 3, "cached viewed-day marker absent")
          check(calendar.cellName("2026-11-26").indexOf("not loaded") !== -1, "unknown date claimed empty")
          var emptyPartial = JSON.parse(JSON.stringify(root.fixture.states[""]))
          emptyPartial.entries = []
          emptyPartial.partial = true
          emptyPartial.daySummaries = [{dateKey: "2026-11-24", count: 0, complete: false, loaded: true}]
          calendar.scheduleState = emptyPartial
          wait(20)
          check(calendar.cellName("2026-11-24").indexOf("coverage incomplete") !== -1, "loaded partial day called not loaded or empty")
          calendar.scheduleState = Qt.binding(function() { return root.fixture ? root.fixture.states[calendar.teamId] : ({}) })
          wait(20)
          capture("calendar-global")
          var globalFixture = root.fixture.states[""]
          var many = JSON.parse(JSON.stringify(globalFixture))
          many.entries = []
          for (var gameIndex = 0; gameIndex < 257; gameIndex++) {
            var gameEntry = JSON.parse(JSON.stringify(globalFixture.entries[0]))
            gameEntry.game.id = "nhl:global-cap-" + gameIndex
            many.entries.push(gameEntry)
          }
          calendar.scheduleState = many
          wait(20)
          same(calendar.entries.length, 257, "global presentation inherited single-league cap")
          many = JSON.parse(JSON.stringify(many))
          while (many.entries.length < 2049) many.entries.push(many.entries[0])
          calendar.scheduleState = many
          wait(20)
          check(calendar.entriesOverflow && calendar.entries.length === 0, "global overflow was presented as complete")
          calendar.scheduleState = null
          wait(20)
          same(calendar.entries.length, 0, "null global state unsafe")
          calendar.scheduleState = Qt.binding(function() { return root.fixture ? root.fixture.states[calendar.teamId] : ({}) })
          wait(20)
          calendar.focusCalendar()
          keyClick(Qt.Key_Right)
          keyClick(Qt.Key_Return)
          same(root.previewDates[root.previewDates.length - 1], "2026-11-25", "global keyboard day preview")
          same(root.selectedDates.length, 0, "global day preview jumped to scores")
          check(text(calendar, "Select a day to load its games.") !== null, "unloaded date lacks load hint")
          check(text(calendar, "No games are listed in the loaded data.") === null, "unloaded date claimed empty")
          keyClick(Qt.Key_PageDown)
          wait(40)
          same(calendar.monthKey, "2026-12-01", "global keyboard month navigation")
          var today = find(calendar, function(item) { return item.visible && "tooltipText" in item && item.tooltipText === "Return calendar to today" }, [])
          check(today !== null, "global Today action absent")
          var explicitMonthCalls = root.monthCalls
          mouseClick(today, today.width / 2, today.height / 2, Qt.LeftButton, Qt.NoModifier, 20)
          same(root.previewDates[root.previewDates.length - 1], "2026-11-24", "Today did not preview today's games")
          same(root.monthCalls, explicitMonthCalls, "Today requested month and day twice")
          same(calendar.monthKey, "2026-11-01", "Today did not return current month")
          var adjacentDay = find(calendar, function(item) { return item.visible && "modelData" in item && item.modelData === "2026-12-01" && "borderSpec" in item }, [])
          check(adjacentDay !== null, "adjacent month date absent")
          mouseClick(adjacentDay, adjacentDay.width / 2, adjacentDay.height / 2, Qt.LeftButton, Qt.NoModifier, 20)
          same(root.previewDates[root.previewDates.length - 1], "2026-12-01", "adjacent month date did not preview")
          same(root.monthCalls, explicitMonthCalls, "adjacent date requested month and day twice")
          calendar.selectedDateKey = "2026-11-24"
          calendar.monthKey = "2026-11-01"
          wait(50)
          var picker = find(calendar, function(item) { return "popupOpen" in item && "options" in item && "open" in item }, [])
          calendar.focusCalendar()
          keyClick(Qt.Key_Tab)
          wait(40)
          check(calendar.inputActive, "Tab did not reach native selector")
          keyClick(Qt.Key_Return)
          wait(40)
          check(picker.popupOpen, "native selector did not open")
          keyClick(Qt.Key_Down)
          keyClick(Qt.Key_Return)
          wait(60)
          same(calendar.teamId, "nfl:2", "global-to-team native selection")
          check(!calendar.globalMode, "team selection retained global mode")
          check(!picker.popupOpen && !calendar.inputActive, "selector did not restore component input")
          check(text(calendar, "November 2026") === null, "team view retained full month grid")
          same(calendar.nextEntry.dateKey, "2026-12-06", "bye-week next game")
          same(calendar.laterEntries.length, 5, "team agenda truncated later games")
          check(text(calendar, "In 12 days") !== null, "relative next-game date absent")
          check(text(calendar, "Sun, Dec 13 · Time TBD") !== null, "TBD time invented a kickoff")
          var nextLabel = text(calendar, "Next up")
          check(nextLabel !== null, "team feature card missing")
          var feature = nextLabel.parent.parent.parent
          check(feature.y <= picker.height + Commons.Style.spacing.md + 1, "team next card is not directly below chooser")
          capture("calendar-team")
          var retained = JSON.parse(JSON.stringify(root.fixture.states["nfl:2"]))
          retained.loading = true
          calendar.scheduleState = retained
          wait(20)
          check(!calendar.completeFromAnchor && text(calendar, "Next listed game") !== null, "loading team data claims definitive next game")
          retained = JSON.parse(JSON.stringify(retained))
          retained.loading = false
          retained.stale = true
          retained.entries[0].game.status = "live"
          calendar.scheduleState = retained
          wait(20)
          check(!calendar.completeFromAnchor && text(calendar, "Live now") === null, "stale game claims current live status")
          calendar.scheduleState = Qt.binding(function() { return root.fixture ? root.fixture.states[calendar.teamId] : ({}) })
          wait(20)
          calendar.focusCalendar()
          keyClick(Qt.Key_PageDown)
          same(root.requestedWindows[root.requestedWindows.length - 1], "2026-12-29", "next 35-day window")
          keyClick(Qt.Key_PageUp)
          same(root.requestedWindows[root.requestedWindows.length - 1], "2026-10-20", "previous 35-day window")
          var jump = find(calendar, function(item) { return item.visible && "text" in item && item.text === "View day" && "clicked" in item }, [])
          check(jump !== null, "next-game jump absent")
          mouseClick(jump, jump.width / 2, jump.height / 2, Qt.LeftButton, Qt.NoModifier, 20)
          same(root.selectedDates[root.selectedDates.length - 1], "2026-12-06", "next game did not jump across month")
          calendar.focusCalendar()
          keyClick(Qt.Key_Tab)
          keyClick(Qt.Key_Return)
          wait(40)
          keyClick(Qt.Key_Down)
          keyClick(Qt.Key_Return)
          wait(60)
          same(calendar.teamId, "nhl:6", "native team choice")
          same(calendar.nextEntry.dateKey, "2026-11-25", "team schedule did not change")
          calendar.teamId = "nfl:2"
          same(picker.value, "nfl:2", "native selector retained wrong team")
          var partial = JSON.parse(JSON.stringify(root.fixture.states["nfl:2"]))
          partial.partial = true
          partial.errorSummary = "Some dates could not be refreshed. Listed games are retained."
          partial.failed = true
          calendar.scheduleState = partial
          wait(80)
          check(text(calendar, "Next listed game") !== null, "partial schedule claims authoritative next game")
          var retry = find(calendar, function(item) { return item.visible && "text" in item && item.text === "Retry schedule" && "clicked" in item }, [])
          check(retry !== null, "partial schedule has no recovery action")
          mouseClick(retry, retry.width / 2, retry.height / 2, Qt.LeftButton, Qt.NoModifier, 20)
          same(root.retryCalls, 1, "retry activation count")
          capture("calendar-partial")

          var laterFocus = null
          for (var attempt = 0; attempt < 20; attempt++) {
            keyClick(Qt.Key_Tab)
            wait(25)
            var active = window.activeFocusItem
            if (active && "modelData" in active && active.modelData && active.modelData.dateKey) {
              laterFocus = active
              break
            }
          }
          check(laterFocus !== null, "later games are not keyboard reachable")
          var scroll = find(calendar, function(item) { return "contentY" in item && "contentHeight" in item }, [])
          check(scroll !== null, "calendar lacks bounded scroll surface")
          var focusY = laterFocus.mapToItem(scroll, 0, 0).y
          check(focusY >= -1 && focusY + laterFocus.height <= scroll.height + 1, "focused agenda row remained outside viewport")
          var beforeActivate = root.selectedDates.length
          keyClick(Qt.Key_Return)
          same(root.selectedDates.length, beforeActivate + 1, "agenda keyboard activation count")
          same(root.selectedDates[root.selectedDates.length - 1], laterFocus.modelData.dateKey, "agenda jumped to the wrong date")

          var mixed = JSON.parse(JSON.stringify(root.fixture.states["nfl:2"]))
          var canceled = JSON.parse(JSON.stringify(mixed.entries[0]))
          canceled.game.id = "nfl:canceled-example"
          canceled.game.status = "canceled"
          canceled.dateKey = "2026-12-01"
          var final = JSON.parse(JSON.stringify(mixed.entries[0]))
          final.game.id = "nfl:final-example"
          final.game.status = "final"
          final.dateKey = "2026-11-25"
          var postponed = JSON.parse(JSON.stringify(mixed.entries[0]))
          postponed.game.id = "nfl:postponed-example"
          postponed.game.status = "postponed"
          postponed.dateKey = "2026-11-28"
          mixed.entries = [canceled, final, postponed, mixed.entries[0]].concat(mixed.entries)
          calendar.scheduleState = mixed
          wait(20)
          same(calendar.nextEntry.dateKey, "2026-12-06", "canceled/final/postponed game became the next scheduled game")
          same(calendar.upcomingEntries.length, 6, "duplicate schedule event remained in agenda")
          same(calendar.entriesOn("2026-12-01").length, 0, "canceled event left a game-day marker")

          calendar.scheduleState = {teamId: "nhl:6", hasData: true, entries: root.fixture.states["nhl:6"].entries}
          wait(20)
          same(calendar.entries.length, 0, "another team's retained data leaked")
          calendar.scheduleState = {teamId: "nfl:2", loading: true, hasData: false, entries: []}
          wait(20)
          check(text(calendar, "Finding upcoming games…") !== null, "loading message absent")
          check(calendar.nextEntry === null, "loading retained wrong next game")
          calendar.scheduleState = {teamId: "nfl:2", loading: false, hasData: true, entries: []}
          wait(20)
          check(text(calendar, "No upcoming games are listed in this schedule.") !== null, "empty schedule claims verified no-game days")
          calendar.focusCalendar()
          keyClick(Qt.Key_Escape)
          same(root.closeCalls, 1, "Escape did not close calendar")
          console.log("CALENDAR_CONCEPT_PASS " + root.uiCase.name)
        } catch (error) { console.error("CALENDAR_CONCEPT_FAIL " + String(error) + " " + error.stack) }
        Qt.quit()
      }
    }
  }
}

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
        teamId: "nfl:2"
        todayDateKey: root.fixture ? root.fixture.today : ""
        selectedDateKey: todayDateKey
        monthKey: "2026-11-01"
        scheduleState: root.fixture ? root.fixture.states[teamId] : ({})
        onMonthRequested: function(month) { root.monthCalls++; calendar.monthKey = month }
        onTeamSelected: function(team) { calendar.teamId = team }
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
          same(calendar.nextEntry.dateKey, "2026-12-06", "bye-week next game")
          same(calendar.laterEntries.length, 3, "later game count")
          check(text(calendar, "In 12 days") !== null, "relative next-game date absent")
          check(text(calendar, "Sun, Dec 13 · Time TBD") !== null, "TBD time invented a kickoff")
          capture("calendar-november")

          calendar.focusCalendar()
          keyClick(Qt.Key_Right)
          wait(40)
          same(calendar.focusedDateKey, "2026-11-25", "date arrow navigation")
          keyClick(Qt.Key_Return)
          same(root.selectedDates[root.selectedDates.length - 1], "2026-11-25", "keyboard day activation")
          keyClick(Qt.Key_PageDown)
          wait(80)
          same(calendar.monthKey, "2026-12-01", "keyboard month navigation")
          var jump = find(calendar, function(item) { return item.visible && "text" in item && item.text === "View day" && "clicked" in item }, [])
          check(jump !== null, "next-game jump absent")
          mouseClick(jump, jump.width / 2, jump.height / 2, Qt.LeftButton, Qt.NoModifier, 20)
          same(root.selectedDates[root.selectedDates.length - 1], "2026-12-06", "next game did not jump across month")
          capture("calendar-december")

          var picker = find(calendar, function(item) { return "popupOpen" in item && "options" in item && "open" in item }, [])
          check(picker !== null, "native team chooser absent")
          calendar.focusCalendar()
          keyClick(Qt.Key_Tab)
          wait(40)
          check(calendar.inputActive, "Tab did not reach the native team trigger")
          keyClick(Qt.Key_Return)
          wait(50)
          check(picker.popupOpen, "native team trigger did not open by Enter")
          keyClick(Qt.Key_Down)
          keyClick(Qt.Key_Return)
          wait(80)
          same(calendar.teamId, "nhl:6", "native team choice")
          check(!picker.popupOpen && !calendar.inputActive, "team chooser did not restore calendar input")
          same(calendar.nextEntry.dateKey, "2026-11-25", "team schedule did not change")

          calendar.teamId = "nfl:2"
          calendar.monthKey = "2026-11-01"
          same(picker.value, "nfl:2", "native selector retained the wrong team")
          var partial = JSON.parse(JSON.stringify(root.fixture.states["nfl:2"]))
          partial.partial = true
          partial.errorSummary = "Some dates could not be refreshed. Listed games are retained."
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
          same(calendar.upcomingEntries.length, 4, "duplicate schedule event remained in agenda")
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

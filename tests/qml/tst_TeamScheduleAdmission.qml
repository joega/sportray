import QtQuick
import QtTest

TestCase {
  id: testCase
  name: "TeamScheduleAdmission"
  property var service: null
  property var calendar: null
  property var process: null
  readonly property string first: "2026-11-24"
  readonly property string last: "2026-11-28"

  function init() {
    failOnWarning(/.?/)
    var component = Qt.createComponent(Qt.resolvedUrl("../../services/FetchService.qml"))
    compare(component.status, Component.Ready, component.errorString())
    service = component.createObject(testCase, {enabledLeagues: [], favoriteTeamIds: [], followedLeagueIds: [],
      settingsReady: false, panelOpen: false, selectedDateKey: first})
    verify(service !== null)
    calendar = service.children.filter(function(child) { return typeof child.requestGlobal === "function" })[0]
    verify(calendar !== undefined && calendar !== null)
    process = findChild(calendar, "fixtureProcess")
    verify(process !== null)
    service.enabledLeagues = ["nhl"]
    wait(0)
    settleDailyRequests()
    wait(0)
    compare(process.starts, 0)
  }
  function cleanup() {
    if (service) service.destroy()
    wait(0)
    service = null; calendar = null; process = null
    wait(0)
  }
  function json(path) {
    var request = new XMLHttpRequest()
    request.open("GET", Qt.resolvedUrl("../../fixtures/" + path), false)
    request.send()
    return request.responseText
  }
  function settleDailyRequests() {
    service.children.forEach(function(child) {
      if (!child || typeof child.refresh !== "function" || child.leagueId !== "nhl") return
      var daily = findChild(child, "fixtureProcess")
      if (daily && daily.running) daily.finish(0, json("globalcalendar/daily-nhl.json"))
    })
  }
  function ready() {
    service.settingsReady = true
    service.panelOpen = true
    wait(0)
    settleDailyRequests()
    wait(0)
  }
  function request(owner, teamId, start, end) {
    return service.requestUpcoming(owner || "team-route", teamId || "nhl:54", start || first, end || last, false)
  }
  function selectionIds() { return service.upcomingCatalogTeams.map(function(team) { return team.id }) }

  function test_settingsAndPanelGatesDoNotCreateTransientAdmission() {
    verify(!request())
    compare(service.transientScheduleTeamId, "")
    compare(process.starts, 0)
    service.settingsReady = true
    verify(!request())
    compare(service.transientScheduleOwner, "")
    compare(process.starts, 0)
    service.settingsReady = false
    service.panelOpen = true
    verify(!request())
    compare(service.transientScheduleTeamId, "")
    compare(process.starts, 0)
  }
  function test_canonicalNonFavoriteTeamUsesExistingSharedOwnerWithoutPreferences() {
    ready()
    var before = JSON.stringify({favorites: service.favoriteTeamIds, enabled: service.enabledLeagues, followed: service.followedLeagueIds})
    verify(selectionIds().indexOf("nhl:54") === -1)
    verify(request())
    compare(service.transientScheduleTeamId, "nhl:54")
    compare(service.transientScheduleOwner, "team-route")
    verify(selectionIds().indexOf("nhl:54") !== -1)
    compare(process.starts, 1)
    verify(process.command[process.command.length - 1].indexOf("/club-schedule/VGK/month/") !== -1)
    compare(calendar.upcomingState.owner, "team-route")
    process.finish(0, json("upcoming/nhl-vgk-2026-11.json"))
    verify(calendar.upcomingState.hasData)
    verify(calendar.upcomingState.entries.length > 0)
    compare(JSON.stringify({favorites: service.favoriteTeamIds, enabled: service.enabledLeagues, followed: service.followedLeagueIds}), before)
    verify(service.favoriteTeamIds.indexOf("nhl:54") === -1)
  }
  function test_invalidDisabledAndUnknownTeamsNeverStart() {
    ready()
    var before = process.starts
    for (var id of ["nhl:999999", "NHL:54", "nhl:54/../../", "nfl:2", "__proto__:1", ""]) {
      verify(!service.requestUpcoming("invalid", id, first, last, false))
      compare(process.starts, before)
      compare(service.transientScheduleTeamId, "")
    }
    verify(!service.requestUpcoming("", "nhl:54", first, last, false))
    compare(process.starts, before)
  }
  function test_dateAndRangeRejectionDoesNotReplaceAnActiveAdmission() {
    ready()
    verify(request("old", "nhl:54"))
    var command = process.command.slice()
    var starts = process.starts
    var before = JSON.stringify(selectionIds())
    for (var dates of [["invalid", last], [first, "2026-12-29"], [last, first], ["2026-02-30", last]]) {
      verify(!service.requestUpcoming("new-invalid", "nhl:6", dates[0], dates[1], false))
      compare(service.transientScheduleTeamId, "nhl:54")
      compare(service.transientScheduleOwner, "old")
      compare(calendar.upcomingState.owner, "old")
      compare(process.starts, starts)
      compare(process.command, command)
      compare(JSON.stringify(selectionIds()), before)
      verify(process.running)
    }
  }
  function test_exactThirtyFiveDayWindowRetainsRequestCountBound() {
    ready()
    verify(request("bounded", "nhl:54", first, "2026-12-28"))
    verify(calendar.upcomingPlan.requests.length > 0 && calendar.upcomingPlan.requests.length <= 8)
    compare(process.starts, 1)
    verify(!service.requestUpcoming("too-long", "nhl:6", first, "2026-12-29", false))
    compare(service.transientScheduleOwner, "bounded")
    compare(calendar.upcomingState.owner, "bounded")
    compare(process.starts, 1)
  }
  function test_transientAdmissionDoesNotRelaxNhlResponseBudget() {
    ready()
    verify(request())
    process.stdout.read("x".repeat(699051))
    compare(process.signalsSent.length, 1)
    compare(process.signalsSent[0], 9)
    verify(!process.running)
    compare(calendar.pendingBody, "")
    verify(calendar.upcomingLockedLeagues.indexOf("nhl") !== -1)
    process.finish(9, "late oversized bytes")
    verify(calendar.upcomingState.failed)
    verify(!calendar.upcomingState.loading)
    compare(calendar.upcomingLockedLeagues.length, 0)
  }
  function test_ownerSpecificCancelDoesNotRemoveAnotherRoutesAdmission() {
    ready()
    verify(request("owner"))
    verify(!service.cancelUpcoming("other"))
    compare(service.transientScheduleOwner, "owner")
    compare(service.transientScheduleTeamId, "nhl:54")
    verify(process.running)
    verify(service.cancelUpcoming("owner"))
    compare(service.transientScheduleOwner, "")
    compare(service.transientScheduleTeamId, "")
    verify(selectionIds().indexOf("nhl:54") === -1)
    verify(!process.running)
    verify(calendar.upcomingLockedLeagues.indexOf("nhl") !== -1)
    process.finish(0, "late canceled bytes")
    compare(calendar.upcomingLockedLeagues.length, 0)
    compare(calendar.upcomingState.entries.length, 0)
  }
  function test_replacementTeamWaitsForStoppedPhysicalChild() {
    ready()
    verify(request("first", "nhl:54"))
    verify(request("second", "nhl:6"))
    compare(process.starts, 1)
    verify(!process.running)
    compare(service.transientScheduleTeamId, "nhl:6")
    compare(calendar.upcomingState.owner, "second")
    verify(selectionIds().indexOf("nhl:54") === -1)
    process.stdout.read("late first team bytes")
    compare(calendar.pendingBody, "")
    process.finish(0, json("upcoming/nhl-vgk-2026-11.json"))
    tryCompare(process, "starts", 2)
    verify(process.running)
    verify(process.command[process.command.length - 1].indexOf("/club-schedule/BOS/month/") !== -1)
    compare(calendar.upcomingState.entries.length, 0)
  }
  function test_panelCloseClearsTransientAndPreservesPhysicalStopLock() {
    ready()
    verify(request())
    service.panelOpen = false
    compare(service.transientScheduleOwner, "")
    compare(service.transientScheduleTeamId, "")
    compare(selectionIds().length, 0)
    verify(!process.running)
    verify(calendar.upcomingLockedLeagues.indexOf("nhl") !== -1)
    verify(!request())
    process.finish(0, "late bytes")
    compare(calendar.upcomingLockedLeagues.length, 0)
    verify(!calendar.upcomingState.loading)
  }
  function test_cancelKeepsExplicitFavoriteCatalogWithoutWritingIt() {
    ready()
    service.favoriteTeamIds = ["nhl:6"]
    verify(request("transient", "nhl:54"))
    verify(selectionIds().indexOf("nhl:6") !== -1)
    verify(selectionIds().indexOf("nhl:54") !== -1)
    service.cancelUpcoming("transient")
    compare(service.favoriteTeamIds, ["nhl:6"])
    compare(selectionIds(), ["nhl:6"])
  }

  function test_disabledLeagueRevokesTransientAdmissionWithoutRevival() {
    ready()
    verify(request("route"))
    service.enabledLeagues = []
    compare(service.transientScheduleOwner, "")
    compare(service.transientScheduleTeamId, "")
    compare(selectionIds().length, 0)
    verify(!process.running)
    process.finish(0, "late disabled league data")
    service.enabledLeagues = ["nhl"]
    settleDailyRequests()
    wait(0)
    verify(selectionIds().indexOf("nhl:54") === -1,
      "Re-enabling a league revived an abandoned explicit team admission")
  }

  function test_settingsReadinessLossRevokesTransientAdmission() {
    ready()
    verify(request("route"))
    service.settingsReady = false
    compare(service.transientScheduleOwner, "")
    compare(service.transientScheduleTeamId, "")
    verify(!process.running)
    verify(!request())
    process.finish(0, "late unready data")
    service.settingsReady = true
    verify(selectionIds().indexOf("nhl:54") === -1)
  }

  function test_globalScopeReplacesTransientTeamWithoutChangingFavorites() {
    ready()
    service.followedLeagueIds = ["nhl"]
    verify(request("team-route"))
    verify(!service.requestGlobalCalendar("invalid-global", "invalid", false))
    compare(service.transientScheduleOwner, "team-route")
    compare(service.transientScheduleTeamId, "nhl:54")
    verify(service.requestGlobalCalendar("global-route", first, false))
    compare(service.transientScheduleOwner, "")
    compare(service.transientScheduleTeamId, "")
    verify(selectionIds().indexOf("nhl:54") === -1)
    compare(process.starts, 1)
    verify(!process.running)
    process.finish(0, "late team response")
    tryCompare(process, "starts", 2)
    compare(calendar.upcomingState.scope, "global")
    compare(calendar.upcomingState.owner, "global-route")
    verify(process.command[process.command.length - 1].indexOf("/v1/score/" + first) !== -1)
    compare(service.favoriteTeamIds.length, 0)
    verify(service.cancelUpcoming("global-route"))
    compare(service.transientScheduleTeamId, "")
  }
}

import QtQuick
import QtTest
import "../../providers/NhlTeamCatalog.js" as NhlTeams

TestCase {
  id: testCase
  name: "GlobalCalendarFetch"
  property var owner: null
  property var proc: null
  property var rawLengths: []
  property bool emulateDailyResume: false
  property bool dailyResumed: false
  readonly property string day: "2026-11-24"
  readonly property var allLeagues: ["nhl", "nfl", "mlb", "nba", "college-football", "mens-college-basketball", "eng.1", "usa.1"]

  function file(name) {
    var xhr = new XMLHttpRequest()
    xhr.open("GET", Qt.resolvedUrl("../../fixtures/globalcalendar/daily-" + name + ".json"), false)
    xhr.send()
    return JSON.parse(xhr.responseText)
  }
  function url() { return proc.command[proc.command.length - 1] }
  function bodyForCurrent(empty) {
    var request = owner.planWindows[owner.planIndex]
    if (request.kind !== "global-day") {
      var xhr = new XMLHttpRequest()
      xhr.open("GET", Qt.resolvedUrl("../../fixtures/upcoming/nhl-vgk-2026-11.json"), false)
      xhr.send()
      return xhr.responseText
    }
    var league = request.leagueId
    var aliases = {"college-football": "cfb", "mens-college-basketball": "ncaab", "eng.1": "epl", "usa.1": "mls"}
    var payload = file(aliases[league] || league)
    // Actual daily fixtures prove normalization. Empty envelopes below retain
    // provider identity, exercising other dates without invented normalized data.
    if (empty || ["mlb", "eng.1", "usa.1"].indexOf(league) !== -1) {
      if (league === "nhl") { payload.currentDate = request.dateKey; payload.games = [] }
      else if (league === "mlb") { payload.dates = []; payload.totalGames = 0 }
      else { payload.events = []; payload.day = {date: request.dateKey} }
    }
    return JSON.stringify(payload)
  }
  function finishPlan(empty) {
    var count = 0
    while (proc.running) {
      verify(count < 8, "One selected day exceeded eight sequential requests")
      proc.finish(0, bodyForCurrent(empty))
      count++
      wait(0)
    }
    verify(count > 0)
    verify(!owner.upcomingState.loading)
    compare(owner.pendingBody, "")
    return count
  }
  function request(date, force, token) { return owner.requestGlobal(token || "popup", date || day, force === true) }
  Connections {
    target: testCase.owner
    function onUpcomingLockedLeaguesChanged() {
      if (testCase.emulateDailyResume && testCase.owner.upcomingLockedLeagues.indexOf("nhl") === -1) {
        testCase.emulateDailyResume = false
        testCase.dailyResumed = true
        testCase.owner.upstreamBusyLeagues = ["nhl"]
      }
    }
    function onUpcomingStateChanged() { testCase.rawLengths = testCase.rawLengths.concat([testCase.owner.pendingBody.length]) }
  }
  function init() {
    failOnWarning(/.?/)
    rawLengths = []
    emulateDailyResume = false
    dailyResumed = false
    var component = Qt.createComponent(Qt.resolvedUrl("../../services/CalendarFetch.qml"))
    compare(component.status, Component.Ready, component.errorString())
    owner = component.createObject(testCase, {enabledLeagues: allLeagues,
      followedLeagueIds: ["nhl", "nba"], upcomingCatalogTeams: NhlTeams.listTeams().filter(function(team) { return team.id === "nhl:54" })})
    verify(owner !== null)
    proc = findChild(owner, "fixtureProcess")
    verify(proc !== null)
  }
  function cleanup() { if (owner) owner.destroy(); wait(0); owner = null; proc = null; wait(0) }

  function test_explicitOnlyNoFavoritesNeededNoFollowedNoRequest() {
    compare(proc.starts, 0)
    verify(!request())
    owner.upcomingEnabled = true
    wait(10)
    compare(proc.starts, 0)
    owner.followedLeagueIds = []
    verify(request())
    compare(proc.starts, 0)
    compare(owner.upcomingState.scope, "global")
    compare(owner.upcomingState.entries.length, 0)
    compare(owner.upcomingState.daySummaries.length, 0)
    verify(!owner.upcomingState.hasData && !owner.upcomingState.failed)
    verify(owner.upcomingState.errorSummary.indexOf("Follow a league") !== -1)
    compare(owner.calendarFeatureEnabled, false)
    compare(owner.rehydrationStatus, "idle")
  }
  function test_followedEnabledIntersectionIndependentOfFavoriteCatalog() {
    owner.upcomingEnabled = true
    owner.enabledLeagues = ["nhl", "nba"]
    owner.followedLeagueIds = ["nhl", "nfl"]
    verify(request())
    compare(owner.planWindows.length, 1)
    compare(owner.planWindows[0].leagueId, "nhl")
    owner.upcomingCatalogTeams = []
    compare(owner.upcomingCatalogTeams.length, 0)
    compare(finishPlan(false), 1)
    verify(owner.upcomingState.entries.length > 0)
    verify(owner.upcomingState.entries.every(function(entry) { return entry.game.league === "nhl" && entry.dateKey === day }))
  }
  function test_partialPositiveCacheAndRawBodyReleasedBeforePublication() {
    owner.upcomingEnabled = true
    verify(request())
    compare(finishPlan(false), 2)
    verify(owner.upcomingState.hasData && owner.upcomingState.partial)
    verify(!owner.upcomingState.failed && !owner.upcomingState.stale)
    verify(!owner.upcomingState.coverageComplete)
    verify(owner.upcomingState.entries.length >= 4)
    verify(rawLengths.length > 2 && rawLengths.every(function(length) { return length === 0 }))
    var starts = proc.starts
    verify(request(day, false, "reopened"))
    compare(proc.starts, starts)
    compare(owner.upcomingState.owner, "reopened")
    compare(owner.upcomingState.daySummaries.length, 1)
    compare(owner.upcomingState.daySummaries[0].dateKey, day)
    verify(owner.upcomingState.daySummaries[0].loaded && owner.upcomingState.daySummaries[0].partial)
    verify(!owner.upcomingState.daySummaries[0].complete)
  }
  function test_latestQueuedDateWaitsForPhysicalExitAndIgnoresLateBytes() {
    owner.upcomingEnabled = true
    verify(request(day, false, "old"))
    var oldBody = bodyForCurrent(false)
    var oldCommand = proc.command.slice()
    verify(request("2026-11-25", false, "middle"))
    verify(request("2026-11-26", false, "latest"))
    compare(proc.starts, 1)
    compare(proc.command, oldCommand)
    verify(!proc.running)
    proc.stdout.read("old invalid bytes")
    compare(owner.pendingBody, "")
    proc.finish(0, oldBody)
    compare(proc.starts, 2)
    compare(owner.upcomingState.owner, "latest")
    compare(owner.upcomingState.dateKey, "2026-11-26")
    compare(owner.upcomingState.entries.length, 0)
    finishPlan(true)
    verify(proc.commands.every(function(command, index) { return index === 0 || command[command.length - 1].indexOf("2026-11-25") === -1 }))
  }
  function test_globalAndTeamUseSamePhysicalSlot() {
    owner.upcomingEnabled = true
    verify(request())
    var oldBody = bodyForCurrent(false)
    verify(owner.requestUpcoming("team-popup", "nhl:54", day, "2026-11-28", false))
    compare(proc.starts, 1)
    compare(findChild(owner, "fixtureProcess"), proc)
    verify(owner.upcomingLockedLeagues.indexOf("nhl") !== -1)
    proc.finish(0, oldBody)
    compare(proc.starts, 2)
    compare(owner.upcomingState.teamId, "nhl:54")
    compare(owner.upcomingState.scope, "team")
    finishPlan(false)
    compare(owner.upcomingLockedLeagues.length, 0)
  }
  function test_membershipChangeCancelsWithoutOldCacheLeak() {
    owner.upcomingEnabled = true
    verify(request())
    var oldBody = bodyForCurrent(false)
    owner.followedLeagueIds = ["nba"]
    compare(owner.upcomingState.entries.length, 0)
    compare(owner.upcomingState.daySummaries.length, 0)
    verify(!owner.upcomingState.hasData)
    verify(!proc.running)
    compare(owner.upcomingOwner, "")
    verify(owner.upcomingLockedLeagues.indexOf("nhl") !== -1)
    verify(request())
    compare(proc.starts, 1)
    proc.finish(0, oldBody)
    compare(owner.planWindows.length, 1)
    compare(owner.planWindows[0].leagueId, "nba")
    finishPlan(false)
    verify(owner.upcomingState.entries.every(function(entry) { return entry.game.league === "nba" }))
    owner.enabledLeagues = ["nhl"]
    compare(owner.upcomingOwner, "")
    verify(request())
    compare(owner.upcomingState.entries.length, 0)
    verify(!owner.upcomingState.hasData)
  }
  function test_cancelOwnerAndUpstreamBusyLocksUntilExit() {
    owner.upcomingEnabled = true
    owner.upstreamBusyLeagues = ["nhl"]
    verify(request())
    compare(proc.starts, 0)
    compare(owner.upcomingLockedLeagues, ["nhl"])
    verify(!owner.cancelUpcoming("another-popup"))
    owner.upstreamBusyLeagues = []
    tryCompare(proc, "starts", 1)
    var oldBody = bodyForCurrent(false)
    verify(owner.cancelUpcoming("popup"))
    verify(!proc.running)
    verify(owner.upcomingLockedLeagues.indexOf("nhl") !== -1)
    proc.finish(0, oldBody)
    compare(owner.upcomingLockedLeagues.length, 0)
    compare(proc.starts, 1)
  }
  function test_cacheEightDatesAndRealTtl() {
    owner.upcomingEnabled = true
    owner.followedLeagueIds = ["nhl"]
    for (var i = 1; i <= 9; i++) {
      verify(request("2026-11-" + (i < 10 ? "0" : "") + i))
      finishPlan(true)
    }
    compare(owner.upcomingCacheOrder.length, 8)
    compare(Object.keys(owner.upcomingCache).length, 8)
    compare(owner.upcomingState.daySummaries.length, 8)
    var starts = proc.starts
    verify(request("2026-11-09"))
    compare(proc.starts, starts)
    var key = owner.upcomingCacheOrder[owner.upcomingCacheOrder.length - 1]
    owner.upcomingCache[key].updatedAtMs = 0
    verify(request("2026-11-09"))
    compare(proc.starts, starts + 1)
    finishPlan(true)
  }
  function test_eightRequestsAndAggregateCap() {
    owner.upcomingEnabled = true
    owner.followedLeagueIds = allLeagues
    verify(request())
    compare(owner.planWindows.length, 8)
    compare(finishPlan(false), 8)
    compare(proc.starts, 8)
    verify(owner.upcomingState.entries.length <= 2048)
    verify(!owner.upcomingState.failed)
    var entries = []
    for (var i = 0; i < 2048; i++) entries.push({game: {id: "nhl:bound-" + i}, dateKey: day, timeKnown: false})
    compare(owner.mergeUpcomingEntries([], entries).length, 2048)
    compare(owner.mergeUpcomingEntries(entries, [{game: {id: "nhl:overflow"}, dateKey: day}]), null)
  }
  function test_synchronousDailyResumeOnFinalUnlockDoesNotRepublishLoading() {
    owner.upcomingEnabled = true
    owner.followedLeagueIds = ["nhl"]
    verify(request())
    emulateDailyResume = true
    finishPlan(false)
    verify(dailyResumed, "Fixture did not synchronously resume the queued daily owner")
    verify(!owner.upcomingState.loading)
    compare(owner.planKind, "")
    verify(owner.upcomingState.hasData)
    wait(20)
    verify(!owner.upcomingState.loading, "Deferred pump re-opened a completed plan")
    var saved = owner.upcomingCache[owner.upcomingCacheOrder[0]]
    verify(saved && !saved.state.loading)
  }
  function test_membershipChangeClearsRetainedPositiveStateAndMarkersBeforeExit() {
    owner.upcomingEnabled = true
    owner.followedLeagueIds = ["nhl"]
    verify(request())
    finishPlan(false)
    verify(request())
    verify(owner.upcomingState.entries.length > 0 && owner.upcomingState.daySummaries.length > 0)
    verify(request(day, true))
    var lateBody = bodyForCurrent(false)
    verify(owner.upcomingState.entries.length > 0)
    owner.followedLeagueIds = ["nba"]
    compare(owner.upcomingState.entries.length, 0)
    compare(owner.upcomingState.daySummaries.length, 0)
    verify(!owner.upcomingState.hasData && !owner.upcomingState.failed)
    verify(!proc.running)
    verify(owner.upcomingLockedLeagues.indexOf("nhl") !== -1)
    proc.finish(0, lateBody)
    compare(owner.upcomingState.entries.length, 0)
    verify(request())
    finishPlan(false)
    verify(owner.upcomingState.entries.every(function(entry) { return entry.game.league === "nba" }))
    verify(owner.upcomingState.daySummaries.every(function(summary) { return summary.count <= owner.upcomingState.entries.length }))
  }
  function test_oversizeKillsOwnedProcessAndWaitsForExit() {
    owner.upcomingEnabled = true
    owner.followedLeagueIds = ["nhl"]
    verify(request())
    proc.stdout.read("x".repeat(699051))
    compare(proc.signalsSent[proc.signalsSent.length - 1], 9)
    verify(!proc.running)
    verify(owner.upcomingLockedLeagues.indexOf("nhl") !== -1)
    compare(owner.pendingBody, "")
    proc.finish(9, "late oversized suffix")
    verify(owner.upcomingState.failed)
    verify(!owner.upcomingState.loading && !owner.upcomingState.hasData)
    compare(owner.upcomingLockedLeagues.length, 0)
  }
}

import QtQuick
import QtTest
import "../../providers/NhlTeamCatalog.js" as NhlTeams
import "../../providers/EspnTeamCatalog.js" as EspnTeams

TestCase {
  id: testCase
  name: "UpcomingCalendarFetch"
  property var fetchOwner: null
  property var processRef: null
  property var rawLengthsAtPublication: []
  property int stoppedSignals: 0

  readonly property string vegasId: "nhl:54"
  readonly property string billsId: "nfl:2"
  readonly property string startDate: "2026-11-24"
  readonly property string endDate: "2026-11-28"

  function jsonFile(name) {
    var request = new XMLHttpRequest()
    request.open("GET", Qt.resolvedUrl("../../fixtures/upcoming/" + name + ".json"), false)
    request.send()
    return JSON.parse(request.responseText)
  }
  function catalog() {
    return NhlTeams.listTeams().filter(function(team) {
      return ["nhl:54", "nhl:6", "nhl:10"].indexOf(team.id) !== -1
    }).concat(EspnTeams.listTeams("nfl").filter(function(team) { return team.id === billsId }))
  }
  function currentUrl() { return processRef.command[processRef.command.length - 1] }
  function responseForUrl(url) {
    if (url.indexOf("/club-schedule/") !== -1) {
      var value = jsonFile("nhl-vgk-2026-11")
      var month = url.slice(url.lastIndexOf("/") + 1)
      if (month !== value.currentMonth) { value.currentMonth = month; value.games = [] }
      return JSON.stringify(value)
    }
    if (url.indexOf("/football/nfl/teams/2/schedule") !== -1)
      return JSON.stringify(jsonFile(url.indexOf("seasontype=2") !== -1
        ? "nfl-buf-2026-regular" : "nfl-buf-2026-post-unpublished"))
    throw new Error("Unexpected fixture request URL: " + url)
  }
  function finishPlan() {
    var completions = 0
    while (processRef.running) {
      verify(completions < 8, "A plan exceeded eight sequential requests")
      processRef.finish(0, responseForUrl(currentUrl()))
      completions++
      wait(0)
    }
    verify(completions > 0, "No real service request completed")
    verify(!fetchOwner.upcomingState.loading)
    compare(fetchOwner.pendingBody, "")
    return completions
  }
  function request(owner, teamId, first, last, force) {
    return fetchOwner.requestUpcoming(owner || "calendar", teamId || vegasId,
      first || startDate, last || endDate, force === true)
  }

  Connections {
    target: testCase.fetchOwner
    function onUpcomingStateChanged() {
      testCase.rawLengthsAtPublication = testCase.rawLengthsAtPublication.concat([
        testCase.fetchOwner.pendingBody.length
      ])
    }
  }
  Connections {
    target: testCase.processRef
    function onRunningChanged() { if (!testCase.processRef.running) testCase.stoppedSignals++ }
  }

  function init() {
    failOnWarning(/.?/)
    rawLengthsAtPublication = []
    stoppedSignals = 0
    var component = Qt.createComponent(Qt.resolvedUrl("../../services/CalendarFetch.qml"))
    compare(component.status, Component.Ready, component.errorString())
    // Native initialProperties converts the JS catalog into QVariantList.
    // Exercise that supported dependency boundary in the real Qt engine.
    fetchOwner = component.createObject(testCase, {upcomingCatalogTeams: catalog()})
    verify(fetchOwner !== null)
    compare(fetchOwner.upcomingCatalogTeams.length, catalog().length)
    processRef = findChild(fetchOwner, "fixtureProcess")
    verify(processRef !== null)
  }
  function cleanup() {
    if (fetchOwner) fetchOwner.destroy()
    wait(0)
    fetchOwner = null
    processRef = null
    wait(0)
  }

  function test_noStartupHydrationOrDormantCalendarAdmission() {
    compare(fetchOwner.calendarFeatureEnabled, false)
    compare(fetchOwner.calendarEnabled, false)
    compare(fetchOwner.upcomingEnabled, false)
    compare(processRef.starts, 0)
    verify(!request())
    verify(!fetchOwner.requestMonth("2026-11"))
    verify(!fetchOwner.requestRehydration("2026-11"))
    verify(!fetchOwner.requestBackground())
    fetchOwner.upcomingEnabled = true
    wait(20)
    compare(processRef.starts, 0)
    compare(fetchOwner.calendarFeatureEnabled, false)
    compare(fetchOwner.calendarEnabled, false)
    compare(fetchOwner.rehydrationStatus, "idle")
  }

  function test_explicitSelectedTeamUsesOnlySharedCalendarProcess() {
    fetchOwner.upcomingEnabled = true
    verify(request())
    compare(processRef.starts, 1)
    verify(processRef.running)
    verify(currentUrl().indexOf("/club-schedule/VGK/month/2026-11") !== -1)
    compare(findChild(fetchOwner, "fixtureProcess"), processRef)
    compare(fetchOwner.upcomingState.owner, "calendar")
    compare(fetchOwner.upcomingState.teamId, vegasId)
    finishPlan()
    verify(fetchOwner.upcomingState.hasData)
    verify(!fetchOwner.upcomingState.partial)
    verify(fetchOwner.upcomingState.entries.length > 0)
    compare(fetchOwner.upcomingState.coverageStart, startDate)
    compare(fetchOwner.upcomingState.coverageEnd, endDate)
    verify(fetchOwner.upcomingState.lastSuccessAt !== "")
    verify(fetchOwner.upcomingState.entries.every(function(entry) {
      return entry.game.awayTeam.id === vegasId || entry.game.homeTeam.id === vegasId
    }))
    verify(rawLengthsAtPublication.length > 1)
    verify(rawLengthsAtPublication.every(function(length) { return length === 0 }),
      "Raw provider body survived into a published schedule state")
    compare(fetchOwner.upcomingLockedLeagues.length, 0)
  }

  function test_latestQueuedIntentWaitsForOldExitAndRejectsLateBody() {
    fetchOwner.upcomingEnabled = true
    verify(request("old"))
    var oldCommand = processRef.command.slice()
    verify(request("middle", billsId, "2026-11-24", "2026-12-20"))
    verify(request("latest", vegasId, "2026-11-25", "2026-11-28"))
    compare(processRef.starts, 1)
    compare(processRef.command, oldCommand)
    verify(!processRef.running)
    compare(fetchOwner.upcomingState.owner, "latest")
    processRef.stdout.read("late cancelled bytes")
    compare(fetchOwner.pendingBody, "")
    processRef.finish(0, responseForUrl(oldCommand[oldCommand.length - 1]))
    compare(processRef.starts, 2)
    compare(fetchOwner.upcomingState.owner, "latest")
    compare(fetchOwner.upcomingState.teamId, vegasId)
    compare(fetchOwner.upcomingState.entries.length, 0)
    verify(processRef.running)
    finishPlan()
    verify(fetchOwner.upcomingState.entries.every(function(entry) { return entry.dateKey >= "2026-11-25" }))
    compare(processRef.commands.filter(function(command) {
      return command[command.length - 1].indexOf("/football/nfl/") !== -1
    }).length, 0)
  }

  function test_samePlanTransfersOwnerWithoutDuplicateRequest() {
    fetchOwner.upcomingEnabled = true
    verify(request("first"))
    verify(request("second"))
    compare(processRef.starts, 1)
    compare(fetchOwner.upcomingState.owner, "second")
    verify(!fetchOwner.cancelUpcoming("first"))
    verify(processRef.running)
    finishPlan()
    compare(fetchOwner.upcomingState.owner, "second")
  }

  function test_upstreamScoreSlotBlocksOnlyMatchingLeague() {
    fetchOwner.upcomingEnabled = true
    fetchOwner.upstreamBusyLeagues = ["nhl"]
    verify(request())
    compare(processRef.starts, 0)
    verify(fetchOwner.upcomingState.loading)
    compare(fetchOwner.upcomingLockedLeagues, ["nhl"])
    fetchOwner.upstreamBusyLeagues = ["nfl"]
    compare(processRef.starts, 1)
    verify(processRef.running)
    finishPlan()
    compare(fetchOwner.upcomingLockedLeagues, [])
  }

  function test_cancelBeforeUpstreamReleaseDoesNotStartLater() {
    fetchOwner.upcomingEnabled = true
    fetchOwner.upstreamBusyLeagues = ["nhl"]
    verify(request())
    verify(fetchOwner.cancelUpcoming("calendar"))
    fetchOwner.upstreamBusyLeagues = []
    wait(0)
    compare(processRef.starts, 0)
    verify(!fetchOwner.upcomingState.loading)
    compare(fetchOwner.upcomingLockedLeagues, [])
  }

  function test_cancellationKeepsPhysicalLeagueLockUntilExit() {
    fetchOwner.upcomingEnabled = true
    verify(request())
    compare(fetchOwner.upcomingLockedLeagues, ["nhl"])
    verify(fetchOwner.cancelUpcoming("calendar"))
    verify(!processRef.running)
    verify(!fetchOwner.upcomingState.loading)
    compare(fetchOwner.upcomingLockedLeagues, ["nhl"])
    processRef.finish(0, responseForUrl(currentUrl()))
    compare(fetchOwner.upcomingLockedLeagues, [])
    compare(fetchOwner.upcomingState.entries.length, 0)
    compare(processRef.starts, 1)
  }

  function test_disabledClearsQueuedIntentAndRejectsLateCompletion() {
    fetchOwner.upcomingEnabled = true
    verify(request("old"))
    verify(request("replacement", billsId, "2026-11-24", "2026-12-20"))
    fetchOwner.upcomingEnabled = false
    compare(processRef.starts, 1)
    verify(!fetchOwner.upcomingState.loading)
    compare(fetchOwner.upcomingLockedLeagues, ["nhl"])
    processRef.finish(0, responseForUrl(currentUrl()))
    compare(processRef.starts, 1)
    compare(fetchOwner.upcomingState.entries.length, 0)
    compare(fetchOwner.upcomingLockedLeagues, [])
    fetchOwner.upcomingEnabled = true
    wait(0)
    compare(processRef.starts, 1)
  }

  function test_removedFavoriteOrDisabledTeamCancelsItsRequest() {
    fetchOwner.upcomingEnabled = true
    verify(request())
    fetchOwner.upcomingCatalogTeams = catalog().filter(function(team) { return team.id !== vegasId })
    verify(!processRef.running)
    verify(!fetchOwner.upcomingState.loading)
    compare(fetchOwner.upcomingLockedLeagues, ["nhl"])
    processRef.finish(0, responseForUrl(currentUrl()))
    compare(processRef.starts, 1)
    compare(fetchOwner.upcomingLockedLeagues, [])
    compare(fetchOwner.upcomingState.entries.length, 0)
    verify(!request())
    compare(processRef.starts, 1)
  }

  function test_cacheHitForceAndExpiryUseRealCacheTimestamps() {
    fetchOwner.upcomingEnabled = true
    verify(request())
    finishPlan()
    var firstIds = fetchOwner.upcomingState.entries.map(function(entry) { return entry.game.id })
    var starts = processRef.starts
    verify(request("cache-hit"))
    compare(processRef.starts, starts)
    verify(!fetchOwner.upcomingState.loading)
    compare(fetchOwner.upcomingState.entries.map(function(entry) { return entry.game.id }), firstIds)
    verify(request("forced", vegasId, startDate, endDate, true))
    compare(processRef.starts, starts + 1)
    verify(fetchOwner.upcomingState.hasData && fetchOwner.upcomingState.stale)
    finishPlan()
    var keys = Object.keys(fetchOwner.upcomingCache)
    compare(keys.length, 1)
    compare(fetchOwner.upcomingCache[keys[0]].ttlMs, 15 * 60 * 1000)
    fetchOwner.upcomingCache[keys[0]].updatedAtMs = 0
    starts = processRef.starts
    verify(request("expired"))
    compare(processRef.starts, starts + 1)
    finishPlan()
  }

  function test_cacheNeverExceedsEightTeamWindows() {
    fetchOwner.upcomingEnabled = true
    for (var day = 2; day <= 10; day++) {
      var date = "2026-11-" + (day < 10 ? "0" : "") + day
      verify(request("bounded-cache", vegasId, date, date))
      finishPlan()
      verify(Object.keys(fetchOwner.upcomingCache).length <= 8)
      verify(fetchOwner.upcomingCacheOrder.length <= 8)
    }
    compare(Object.keys(fetchOwner.upcomingCache).length, 8)
    compare(fetchOwner.upcomingCacheOrder.length, 8)
    var starts = processRef.starts
    verify(request("last-hit", vegasId, "2026-11-10", "2026-11-10"))
    compare(processRef.starts, starts)
    verify(request("evicted", vegasId, "2026-11-02", "2026-11-02"))
    compare(processRef.starts, starts + 1)
    finishPlan()
  }

  function test_partialPublishedPhasePreservesDateWithUnknownTime() {
    fetchOwner.upcomingEnabled = true
    verify(request("football", billsId, "2027-01-01", "2027-01-20"))
    var completions = finishPlan()
    compare(completions, 3)
    verify(fetchOwner.upcomingState.hasData)
    verify(fetchOwner.upcomingState.partial)
    verify(fetchOwner.upcomingState.errorSummary !== "")
    var unknownTime = fetchOwner.upcomingState.entries.filter(function(entry) { return !entry.timeKnown })
    verify(unknownTime.length > 0)
    verify(unknownTime.some(function(entry) { return entry.dateKey === "2027-01-10" }))
    verify(!fetchOwner.upcomingState.coverageComplete)
    compare(processRef.starts, 3)
  }

  function test_failedForcedRefreshRetainsCorrectTeamAndMarksStale() {
    fetchOwner.upcomingEnabled = true
    verify(request())
    finishPlan()
    var ids = fetchOwner.upcomingState.entries.map(function(entry) { return entry.game.id })
    verify(request("retry", vegasId, startDate, endDate, true))
    processRef.finish(4, "")
    verify(!fetchOwner.upcomingState.loading)
    verify(fetchOwner.upcomingState.hasData)
    verify(fetchOwner.upcomingState.stale && fetchOwner.upcomingState.partial)
    compare(fetchOwner.upcomingState.entries.map(function(entry) { return entry.game.id }), ids)
    verify(fetchOwner.upcomingState.errorSummary.indexOf("failed") !== -1)
  }

  function test_incompleteAcceptedEmptyRefreshRetainsCachedPositiveGamesAsStale() {
    fetchOwner.upcomingEnabled = true
    verify(request())
    finishPlan()
    var savedIds = fetchOwner.upcomingState.entries.map(function(entry) { return entry.game.id })
    verify(savedIds.length > 0)
    verify(request("unpublished-refresh", vegasId, startDate, endDate, true))
    // A valid but unpublished club-month response is accepted and partial;
    // it cannot prove that previously listed games have disappeared.
    processRef.finish(0, JSON.stringify({currentMonth: "2026-11", games: []}))
    verify(!fetchOwner.upcomingState.loading)
    verify(fetchOwner.upcomingState.hasData)
    verify(fetchOwner.upcomingState.partial)
    verify(fetchOwner.upcomingState.stale)
    verify(!fetchOwner.upcomingState.coverageComplete)
    compare(fetchOwner.upcomingState.entries.map(function(entry) { return entry.game.id }), savedIds)
    compare(fetchOwner.pendingBody, "")
    verify(fetchOwner.upcomingState.errorSummary !== "")
  }

  function test_oversizedOwnedResponseKillsOnceAndPublishesFailureAfterExit() {
    fetchOwner.upcomingEnabled = true
    verify(request())
    var maximum = fetchOwner.planWindows[0].maxResponseChars
    processRef.stdout.read(new Array(maximum + 1).join("x"))
    compare(fetchOwner.pendingBody.length, maximum)
    processRef.stdout.read("x")
    compare(processRef.signalsSent, [9])
    verify(!processRef.running)
    compare(fetchOwner.pendingBody.length, maximum)
    processRef.stdout.read("ignored")
    compare(processRef.signalsSent, [9])
    verify(fetchOwner.upcomingState.loading)
    compare(fetchOwner.upcomingLockedLeagues, ["nhl"])
    processRef.finish(9, "")
    verify(!fetchOwner.upcomingState.loading)
    verify(!fetchOwner.upcomingState.hasData)
    verify(fetchOwner.upcomingState.partial)
    verify(fetchOwner.upcomingState.errorSummary !== "")
    compare(fetchOwner.pendingBody, "")
    compare(fetchOwner.upcomingLockedLeagues, [])
  }

  function test_oversizeTerminationCannotReuseSlotBeforeActualExit() {
    fetchOwner.upcomingEnabled = true
    verify(request("oversized"))
    var maximum = fetchOwner.planWindows[0].maxResponseChars
    processRef.stdout.read(new Array(maximum + 2).join("x"))
    compare(processRef.signalsSent, [9])
    verify(request("replacement", billsId, "2026-11-24", "2026-12-20"))
    compare(processRef.starts, 1, "Replacement reused a killed process before its exit event")
    processRef.finish(9, "late oversized bytes")
    compare(processRef.starts, 2)
    compare(fetchOwner.upcomingState.teamId, billsId)
    finishPlan()
  }

  function test_invalidOrUnadmittedRequestsNeverStartHelpers() {
    fetchOwner.upcomingEnabled = true
    verify(!fetchOwner.requestUpcoming("", vegasId, startDate, endDate, false))
    verify(!request("invalid-team", "nhl:999999"))
    verify(!request("invalid-date", vegasId, "2026-02-30", "2026-03-02"))
    verify(!request("reversed", vegasId, endDate, startDate))
    verify(!request("unbounded", vegasId, "2026-01-01", "2027-01-01"))
    compare(processRef.starts, 0)
    compare(fetchOwner.upcomingLockedLeagues, [])
  }

  function test_destroyStopsSharedProcessBeforeObjectDisappears() {
    fetchOwner.upcomingEnabled = true
    verify(request())
    var stopsBefore = stoppedSignals
    fetchOwner.destroy()
    wait(0)
    fetchOwner = null
    verify(stoppedSignals > stopsBefore, "Destroy did not stop the owned request")
    processRef = null
  }
  function test_crossLeagueHandoffKeepsLocksWhileUpstreamOwnerExits() {
    fetchOwner.upcomingEnabled = true
    verify(request("old"))
    var oldUrl = currentUrl()
    fetchOwner.upstreamBusyLeagues = ["nfl"]
    verify(request("queued", billsId, "2026-11-24", "2026-12-20"))
    compare(fetchOwner.upcomingLockedLeagues.slice().sort(), ["nfl", "nhl"])
    compare(processRef.starts, 1)
    processRef.finish(0, responseForUrl(oldUrl))
    compare(processRef.starts, 1, "Queued calendar overlapped an existing score request")
    compare(fetchOwner.upcomingLockedLeagues, ["nfl"])
    verify(fetchOwner.upcomingState.loading)
    fetchOwner.upstreamBusyLeagues = []
    compare(processRef.starts, 2)
    verify(currentUrl().indexOf("/football/nfl/") !== -1)
    finishPlan()
    compare(fetchOwner.upcomingLockedLeagues, [])
    compare(fetchOwner.upcomingState.teamId, billsId)
  }

  function test_cachedViewSurvivesCancelledOtherWindowLateExit() {
    fetchOwner.upcomingEnabled = true
    verify(request("cached"))
    finishPlan()
    var cachedIds = fetchOwner.upcomingState.entries.map(function(entry) { return entry.game.id })
    verify(request("different", vegasId, "2026-11-25", "2026-11-28"))
    var differentUrl = currentUrl()
    var starts = processRef.starts
    verify(request("restored", vegasId, startDate, endDate))
    compare(processRef.starts, starts)
    verify(!fetchOwner.upcomingState.loading)
    compare(fetchOwner.upcomingState.owner, "restored")
    compare(fetchOwner.upcomingState.entries.map(function(entry) { return entry.game.id }), cachedIds)
    compare(fetchOwner.upcomingLockedLeagues, ["nhl"])
    processRef.finish(0, responseForUrl(differentUrl))
    compare(processRef.starts, starts)
    compare(fetchOwner.upcomingState.owner, "restored")
    compare(fetchOwner.upcomingState.entries.map(function(entry) { return entry.game.id }), cachedIds)
    compare(fetchOwner.upcomingLockedLeagues, [])
  }

}

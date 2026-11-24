import QtQuick
import QtTest
import "../../model/SettingsModel.js" as SettingsModel
import "../../model/StateModel.js" as StateModel
import "../../model/TransitionDedupe.js" as TransitionDedupe
import "../../model/WatchPolicy.js" as WatchPolicy

TestCase {
  id: testCase
  name: "ActionFeedback"
  property var store: null
  property var process: null
  property var watcher: null

  function customSettings() {
    var value = SettingsModel.createDefaults()
    value.ticker = {enabled: false, position: "top", speed: "slow"}
    return value
  }
  function stateText(settings, watches) {
    return JSON.stringify(StateModel.createState(settings || customSettings(), TransitionDedupe.createDefaults(),
      SettingsModel, TransitionDedupe, Date.now(), watches || [], WatchPolicy))
  }
  function game(id) {
    return {id: "nhl:" + id, league: "nhl", providerGameId: String(id), isValid: true,
      status: "scheduled", startTime: new Date(Date.now() + 86400000).toISOString()}
  }
  function watch(id, delta) {
    var now = Date.now() + (delta || 0)
    return WatchPolicy.createWatch(game(id), new Date(now).toISOString(), now)
  }
  function load(settings, watches) {
    var text = stateText(settings, watches)
    process.finish(0, text)
    process.finish(0, text)
    compare(store.ready, true)
    compare(store.helperOperation, "")
  }
  function init() {
    failOnWarning(/.?/)
    var component = Qt.createComponent(Qt.resolvedUrl("../../services/SettingsStore.qml"))
    compare(component.status, Component.Ready, component.errorString())
    store = component.createObject(testCase)
    verify(store !== null)
    process = findChild(store, "fixtureProcess")
    watcher = findChild(store, "fixtureFileView")
    verify(process !== null && watcher !== null)
  }
  function cleanup() {
    if (store) store.destroy()
    store = null; process = null; watcher = null
    wait(0)
  }
  function test_initialAndRejectedActionsDoNotPublishFeedback() {
    compare(store.feedbackAction, null)
    compare(store.toggleFavoriteTeam("nhl:6"), false)
    compare(store.toggleWatch(game(8801)), false)
    load()
    compare(store.setFavoriteTeam("bad", true), false)
    compare(store.setFavoriteTeam("nhl:6", false), false)
    compare(store.feedbackAction, null)
    compare(process.starts, 2)
  }
  function test_favoriteUndoPreservesUnrelatedPreferencesAndIsNotRepeatable() {
    load()
    compare(store.toggleFavoriteTeam("nhl:6", "Boston Bruins"), true)
    verify(store.isFavoriteTeam("nhl:6"))
    verify(store.feedbackAction.summary.indexOf("Bruins") !== -1)
    verify(store.canUndoFeedback)
    var id = store.feedbackAction.id
    compare(store.setFavoriteTeam("nhl:6", true), false)
    compare(store.feedbackAction.id, id)
    compare(store.undoFeedback(id + 1), false)
    store.setTicker("speed", "fast")
    compare(store.undoFeedback(id), true)
    compare(store.isFavoriteTeam("nhl:6"), false)
    compare(store.settings.ticker, {enabled: false, position: "top", speed: "fast"})
    verify(store.feedbackAction.undone)
    compare(store.canUndoFeedback, false)
    compare(store.undoFeedback(), false)
  }
  function test_newActionReplacesPreviousToken() {
    load()
    verify(store.toggleFavoriteTeam("nhl:6"))
    var previous = store.feedbackAction.id
    verify(store.toggleWatch(game(8801), "Boston at Toronto"))
    verify(store.feedbackAction.id !== previous)
    compare(store.feedbackAction.kind, "watch")
    verify(store.feedbackAction.summary.indexOf("Boston at Toronto") !== -1)
    compare(store.undoFeedback(previous), false)
    verify(store.undoFeedback())
    verify(store.isFavoriteTeam("nhl:6"))
  }
  function test_queuedWatchesAdmitIntentAndToggleAgainstLatestPendingValue() {
    load()
    store.setTicker("speed", "fast")
    compare(store.helperOperation, "write")
    var starts = process.starts
    var selected = game(8801)
    compare(store.toggleWatch(selected), true)
    compare(store.watchedGames.length, 1)
    compare(store.pendingWrite.watchedGames.length, 1)
    compare(store.toggleWatch(selected), true)
    compare(store.watchedGames.length, 0)
    compare(store.pendingWrite.watchedGames.length, 0)
    compare(process.starts, starts)
    process.finish(0, "")
    compare(JSON.parse(process.command[4]).watchedGames.length, 0)
    compare(JSON.parse(process.command[4]).ticker.speed, "fast")
    process.finish(0, "")
    compare(store.writePending, false)
  }
  function test_removedWatchUndoRestoresExactRecord() {
    var original = watch(8801, -1000)
    load(null, [original])
    verify(store.toggleWatch(game(8801)))
    compare(store.watchedGames.length, 0)
    verify(store.canUndoFeedback)
    verify(store.undoFeedback())
    compare(store.watchedGames, [original])
  }
  function test_externalWatchRenewalInvalidatesUndo() {
    load()
    verify(store.toggleWatch(game(8801)))
    process.finish(0, "")
    var original = store.watchedGames[0]
    var renewed = Object.assign({}, original, {createdAt: new Date(Date.parse(original.createdAt) + 1).toISOString()})
    watcher.fileChanged()
    process.finish(0, stateText(null, [renewed]))
    compare(store.feedbackAction, null)
    compare(store.undoFeedback(), false)
    compare(store.watchedGames, [renewed])
  }
  function test_disabledLeaguePreventsRestoringRemovedWatch() {
    load(null, [watch(8801, -1000)])
    verify(store.toggleWatch(game(8801)))
    store.toggleLeague("nhl")
    compare(store.canUndoFeedback, false)
    compare(store.undoFeedback(), false)
    compare(store.watchedGames.length, 0)
  }
  function test_capacityAndTerminalGamesNeverPublishSuccess() {
    var watches = []
    for (var i = 0; i < 32; i++) watches.push(watch(i + 1, -1000))
    load(null, watches)
    compare(store.toggleWatch(game(8801)), false)
    var terminal = game(1); terminal.providerGameId = "8802"; terminal.status = "final"
    compare(store.toggleWatch(terminal), false)
    compare(store.feedbackAction, null)
    compare(process.starts, 2)
  }
  function test_favoriteCapacityIsRecheckedAtUndo() {
    var settings = customSettings()
    settings.favoriteTeamIds = ["nhl:6"]
    load(settings)
    verify(store.toggleFavoriteTeam("nhl:6"))
    var otherFavorites = []
    for (var i = 0; i < 32; i++) otherFavorites.push("nhl:" + (i + 100))
    store.settings = Object.assign({}, store.settings, {favoriteTeamIds: otherFavorites})
    compare(store.canUndoFeedback, false)
    compare(store.undoFeedback(), false)
    compare(store.settings.favoriteTeamIds.length, 32)
  }
  function test_expiredFeedbackCannotUndoAndIsCleared() {
    load()
    verify(store.toggleFavoriteTeam("nhl:6"))
    store.feedbackAction = Object.assign({}, store.feedbackAction, {expiresAt: Date.now() - 1})
    compare(store.canUndoFeedback, false)
    compare(store.undoFeedback(), false)
    tryCompare(store, "feedbackAction", null)
  }
  function test_removedWatchExpiryEndsUndoBeforeTheFeedbackMaximum() {
    var original = watch(8801, -1000)
    original.expiresAt = new Date(Date.now() + 100).toISOString()
    load(null, [original])
    verify(store.toggleWatch(game(8801)))
    verify(store.canUndoFeedback)
    tryCompare(store, "feedbackAction", null, 1000)
    compare(store.undoFeedback(), false)
    compare(store.watchedGames.length, 0)
  }
  function test_queuedFavoriteMergesOnlyItsFieldOverCompatibleRead() {
    load()
    watcher.fileChanged()
    compare(store.helperOperation, "read")
    verify(store.toggleFavoriteTeam("nhl:6"))
    var incoming = customSettings()
    incoming.favoriteTeamIds = ["nhl:12"]
    incoming.ticker = {enabled: true, position: "bottom", speed: "fast"}
    process.finish(0, stateText(incoming))
    compare(store.helperOperation, "write")
    compare(store.settings.favoriteTeamIds, ["nhl:12", "nhl:6"])
    compare(store.settings.ticker, incoming.ticker)
    compare(JSON.parse(process.command[4]).favoriteTeamIds, ["nhl:12", "nhl:6"])
    verify(store.undoFeedback())
    compare(store.settings.favoriteTeamIds, ["nhl:12"])
    compare(store.settings.ticker, incoming.ticker)
  }
  function test_queuedWatchPreservesUnrelatedExternalWatch() {
    load()
    watcher.fileChanged()
    verify(store.toggleWatch(game(8801)))
    process.finish(0, stateText(null, [watch(8802, -1000)]))
    compare(store.helperOperation, "write")
    compare(store.watchedGames.length, 2)
    verify(WatchPolicy.findWatch(store.watchedGames, game(8801)))
    verify(WatchPolicy.findWatch(store.watchedGames, game(8802)))
    verify(store.canUndoFeedback)
  }
  function test_queuedWatchDoesNotAddIntoExternallyDisabledLeague() {
    load()
    watcher.fileChanged()
    verify(store.toggleWatch(game(8801)))
    var incoming = customSettings()
    incoming.enabledLeagues = []
    process.finish(0, stateText(incoming))
    compare(store.settings.enabledLeagues.length, 0)
    compare(store.watchedGames.length, 0)
    compare(store.feedbackAction, null)
    compare(store.undoFeedback(), false)
  }
  function test_futureReadDropsQueuedIntentAndBlocksAllUiMutations() {
    load()
    watcher.fileChanged()
    verify(store.toggleFavoriteTeam("nhl:6"))
    var starts = process.starts
    var raw = '{"schemaVersion":99,"privateFutureField":true}'
    process.finish(0, raw)
    compare(store.preservedRawStateText, raw)
    compare(store.pendingWrite, null)
    compare(process.starts, starts)
    compare(store.feedbackAction, null)
    compare(store.toggleFavoriteTeam("nhl:6"), false)
    compare(store.toggleWatch(game(8801)), false)
    compare(store.setTicker("speed", "fast"), false)
    compare(store.undoFeedback(), false)
    compare(process.starts, starts)
  }
  function test_rejectedReadDropsQueuedIntentAndFeedback() {
    load()
    watcher.fileChanged()
    verify(store.toggleFavoriteTeam("nhl:6"))
    var starts = process.starts
    ignoreWarning("Sportray settings state rejected")
    process.finish(4, "")
    compare(store.loadStatus, "rejected")
    compare(store.pendingWrite, null)
    compare(store.feedbackAction, null)
    compare(store.canUndoFeedback, false)
    compare(store.undoFeedback(), false)
    compare(process.starts, starts)
  }
  function test_externalFavoriteChangeDoesNotGetOverwrittenByUndo() {
    load()
    verify(store.toggleFavoriteTeam("nhl:6"))
    process.finish(0, "")
    watcher.fileChanged()
    process.finish(0, stateText())
    compare(store.feedbackAction, null)
    compare(store.undoFeedback(), false)
    compare(store.settings.favoriteTeamIds.length, 0)
  }
  function test_shutdownClearsFeedbackAndRejectsNewIntents() {
    load()
    verify(store.toggleFavoriteTeam("nhl:6"))
    store.beginShutdown()
    compare(store.feedbackAction, null)
    compare(store.toggleFavoriteTeam("nhl:12"), false)
    compare(store.toggleWatch(game(8801)), false)
    compare(store.undoFeedback(), false)
  }
  function test_helperFailureDoesNotClaimSavedSuccessOrLeaveUndoEnabled() {
    load()
    verify(store.toggleFavoriteTeam("nhl:6"))
    ignoreWarning("Sportray settings helper failed write")
    process.finish(5, "")
    compare(store.feedbackAction.kind, "error")
    compare(store.feedbackAction.severity, "error")
    compare(store.canUndoFeedback, false)
    compare(store.undoFeedback(), false)
    compare(store.writePending, false)
  }
  function test_feedbackNeverEntersPersistentState() {
    load()
    verify(store.toggleFavoriteTeam("nhl:6"))
    var serialized = JSON.parse(process.command[4])
    compare(serialized.feedbackAction, undefined)
    compare(serialized.feedbackSerial, undefined)
    compare(serialized.expiresAt, undefined)
    compare(serialized.ticker, customSettings().ticker)
  }
}

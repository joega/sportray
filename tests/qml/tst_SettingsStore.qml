import QtQuick
import QtTest
import "../../model/SettingsModel.js" as SettingsModel
import "../../model/StateModel.js" as StateModel
import "../../model/TransitionDedupe.js" as TransitionDedupe
import "../../model/WatchPolicy.js" as WatchPolicy

TestCase {
  id: testCase
  name: "SettingsStore"
  property var store: null
  property var process: null
  property var watcher: null

  function stateText(speed) {
    var settings = SettingsModel.createDefaults()
    settings.ticker.speed = speed || "normal"
    return JSON.stringify(StateModel.createState(settings, TransitionDedupe.createDefaults(),
      SettingsModel, TransitionDedupe, Date.now(), [], WatchPolicy))
  }

  function init() {
    failOnWarning(/.?/)
    var component = Qt.createComponent(Qt.resolvedUrl("../../services/SettingsStore.qml"))
    compare(component.status, Component.Ready, component.errorString())
    store = component.createObject(testCase)
    verify(store !== null)
    process = findChild(store, "fixtureProcess")
    watcher = findChild(store, "fixtureFileView")
    verify(process !== null)
    verify(watcher !== null)
  }

  function cleanup() {
    if (store) store.destroy()
    store = null
    process = null
    watcher = null
    wait(0)
  }

  function test_startupUsesOnlyHelperForContents() {
    compare(watcher.preload, false)
    compare(watcher.watchChanges, true)
    compare(watcher.path, "/fixture-home/.local/state/omarchy/settings/sportray.json")
    compare(process.starts, 1)
    compare(process.command, ["/usr/bin/python3", store.helperPath, "read"])
    process.finish(0, stateText("slow"))
    compare(store.loadStatus, "valid")
    compare(store.settings.ticker.speed, "slow")
    compare(process.starts, 1)
  }

  function test_changeNotificationReloadsOnlyAfterActiveWrite() {
    process.finish(0, stateText("slow"))
    store.setTicker("speed", "fast")
    compare(store.helperOperation, "write")
    compare(JSON.parse(process.command[4]).ticker.speed, "fast")
    // File replacement notifications during a write coalesce into one read.
    watcher.fileChanged()
    watcher.fileChanged()
    compare(process.starts, 2)
    compare(store.readQueued, true)
    process.finish(0, "")
    compare(process.starts, 3)
    compare(store.helperOperation, "read")
    process.finish(0, stateText("normal"))
    compare(store.settings.ticker.speed, "normal")
    compare(store.readQueued, false)
    compare(process.starts, 3)
  }

  function test_notificationsKeepSerializedLatestWrite() {
    process.finish(0, stateText("slow"))
    store.setTicker("speed", "normal")
    store.setTicker("speed", "fast")
    watcher.fileChanged()
    compare(process.starts, 2)
    process.finish(0, "")
    compare(process.starts, 3)
    compare(store.helperOperation, "write")
    compare(JSON.parse(process.command[4]).ticker.speed, "fast")
    process.finish(0, "")
    compare(store.helperOperation, "read")
    process.finish(0, stateText("fast"))
    compare(store.settings.ticker.speed, "fast")
    compare(store.writePending, false)
    compare(store.pendingWrite, null)
  }

  function test_recovery_data() {
    return [
      {tag: "missing", code: 2, text: "", status: "missing"},
      {tag: "malformed", code: 0, text: "{invalid", status: "invalid-json"}
    ]
  }

  function test_recovery(data) {
    process.finish(data.code, data.text)
    compare(store.ready, true)
    compare(store.loadStatus, data.status)
    compare(store.recovered, true)
    compare(store.helperOperation, "write")
    compare(JSON.parse(process.command[4]).schemaVersion, 2)
    process.finish(0, "")
    // The real watcher supplies this signal after creation/replacement. Here
    // only its delivery into the actual store's helper path is under test.
    watcher.fileChanged()
    compare(store.helperOperation, "read")
    process.finish(0, stateText("slow"))
    compare(store.loadStatus, "valid")
    compare(store.settings.ticker.speed, "slow")
  }

  function test_futureStateRemainsOpaqueUntilCompatibleReload() {
    var future = " {\"schemaVersion\":99,\"privateFutureField\":true}\n"
    process.finish(0, future)
    compare(store.loadStatus, "unsupported-schema")
    compare(store.preservedRawStateText, future)
    store.setTicker("speed", "fast")
    compare(process.starts, 1)
    watcher.fileChanged()
    process.finish(0, stateText("slow"))
    compare(store.preservedRawStateText, "")
    compare(store.loadStatus, "valid")
    compare(store.settings.ticker.speed, "slow")
    store.setTicker("speed", "normal")
    compare(store.helperOperation, "write")
  }

  function test_rejectedObjectCannotBeOverwritten() {
    ignoreWarning("Sportray settings state rejected")
    process.finish(4, "")
    compare(store.loadStatus, "rejected")
    compare(store.ready, true)
    store.setTicker("speed", "fast")
    compare(process.starts, 1)
    compare(store.writePending, false)
    watcher.fileChanged()
    process.finish(0, stateText("slow"))
    compare(store.loadStatus, "valid")
    compare(store.preservedRawStateText, "")
  }
}

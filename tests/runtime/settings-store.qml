import QtQuick
import Quickshell

// Run by test-settings-store.py with an isolated HOME and runtime directory.
// Load only SettingsStore: no desktop shell, providers, windows or IPC hooks.
ShellRoot {
  id: root
  property var store: null
  property var watcher: null
  property string stage: "creation"
  property int ticks: 0

  function fail(message) {
    console.error("SETTINGS_TEST FAIL " + message)
    poll.stop()
  }

  Component.onCompleted: {
    // The Python runner copies this harness to the isolated config root.
    var component = Qt.createComponent(Qt.resolvedUrl("services/SettingsStore.qml"))
    if (component.status !== Component.Ready) {
      fail(component.errorString())
      return
    }
    store = component.createObject(root)
    if (!store) { fail("store creation"); return }
    // Inspect the existing metadata watcher without adding a production hook
    // or requesting FileView.text()/data(), which would itself initiate a read.
    for (var i = 0; i < store.data.length; i++) {
      var item = store.data[i]
      if ("watchChanges" in item && item.watchChanges === true) watcher = item
    }
    if (!watcher) { fail("watcher not found"); return }
    poll.start()
  }

  Timer {
    id: poll
    interval: 20
    repeat: true
    onTriggered: {
      if (++root.ticks > 400) { root.fail("timeout at " + root.stage); return }
      if (root.watcher.preload || root.watcher.loaded) {
        root.fail("FileView content preload at " + root.stage)
        return
      }
      if (!root.store.ready || root.store.helperOperation !== "" || root.store.writePending) return
      if (root.watcher.path !== root.store.statePath) { root.fail("watcher path not admitted"); return }
      if (root.stage === "creation" && root.store.loadStatus === "valid") {
        // Initial missing-file recovery writes defaults. A valid reload proves
        // the real parent-directory watcher delivered file-creation notification.
        root.stage = "atomic"
        console.log("SETTINGS_TEST created")
      } else if (root.stage === "atomic" && root.store.settings.ticker.speed === "slow") {
        root.stage = "change"
        console.log("SETTINGS_TEST atomic")
      } else if (root.stage === "change" && root.store.settings.ticker.speed === "fast") {
        root.stage = "rearm"
        console.log("SETTINGS_TEST changed")
      } else if (root.stage === "rearm" && root.store.settings.ticker.speed === "normal") {
        console.log("SETTINGS_TEST PASS")
        stop()
      }
    }
  }
}

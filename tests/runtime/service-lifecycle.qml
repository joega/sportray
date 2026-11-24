import QtQuick
import Quickshell
import Quickshell.Io
import "../../services" as Services

// A test-only command file coordinates assertions with the Python runner.
// Production owners and Quickshell.Io are real; only copied network helpers
// are replaced by fixed, local, sleeping fixtures in the isolated test home.
ShellRoot {
  id: root
  readonly property var service: Services.SportrayService
  property int sequence: -1
  property string phase: ""
  property string firstToken: ""
  property string secondToken: ""
  property var firstFetch: null
  property var firstStore: null
  property double releaseAt: 0

  function fail(message) {
    console.error("LIFECYCLE_TEST FAIL " + message)
    root.phase = "failed"
  }

  function require(condition, message) {
    if (!condition) throw new Error(message)
  }

  function stopped() {
    return !service.active && service.widgetCount === 0
      && service.fetchService === null && service.standingsService === null
      && service.notificationService === null && service.logoImageStore === null
  }

  function reply(message) { console.log("LIFECYCLE_TEST " + message) }

  function execute(command) {
    try {
      if (command.action === "inert") {
        require(stopped() && service.settingsStore === null, "singleton eagerly starts work")
        reply("inert")
      } else if (command.action === "acquire") {
        firstToken = service.acquireWidget()
        firstFetch = service.fetchService
        firstStore = service.settingsStore
        secondToken = service.acquireWidget()
        require(firstToken !== secondToken && service.widgetCount === 2, "consumer token count")
        require(firstFetch !== null && firstFetch === service.fetchService, "workers not shared")
        require(firstStore !== null && firstStore === service.settingsStore, "settings not shared")
        phase = "ready"
      } else if (command.action === "release-one") {
        service.releaseWidget(firstToken)
        service.releaseWidget(firstToken)
        require(service.widgetCount === 1 && service.fetchService === firstFetch,
          "one consumer or duplicate release tears down another consumer")
        reply("one-retained")
      } else if (command.action === "work") {
        // Mark the outgoing notification baseline without emitting an event.
        // A subsequent acquire must not inherit an earlier worker's games.
        service.notificationService.previousGames = [{id: "old-worker-sentinel"}]
        require(service.standingsService.load("nhl", false), "standings did not start")
        service.logoImageStore.sourceFor("https://a.espncdn.com/i/teamlogos/nhl/500/car.png")
        reply("work-started")
      } else if (command.action === "release-persist" || command.action === "release-stall") {
        service.settingsStore.setTicker("speed", "slow")
        service.settingsStore.setTicker("speed", "fast")
        require(service.settingsStore.writePending && service.settingsStore.pendingWrite !== null,
          "fixture did not queue settings writes")
        releaseAt = Date.now()
        service.releaseWidget(secondToken)
        require(stopped(), "last consumer retains periodic workers")
        require(service.settingsStore !== null && service.settingsStore.shuttingDown,
          "accepted writes were dropped immediately")
        phase = command.action === "release-stall" ? "stalled-drain" : "drain"
        reply("workers-stopped")
      } else if (command.action === "drain-reacquire") {
        service.settingsStore.setTicker("speed", "slow")
        service.settingsStore.setTicker("speed", "fast")
        var retainedStore = service.settingsStore
        service.releaseWidget(secondToken)
        require(stopped() && service.settingsStore === retainedStore, "drain precondition")
        firstToken = service.acquireWidget()
        service.releaseWidget(secondToken)
        require(service.widgetCount === 1 && service.fetchService !== null, "reacquire owner count")
        require(service.settingsStore === retainedStore && !retainedStore.shuttingDown,
          "reacquire duplicates settings or leaves watcher shut down")
        phase = "reacquired"
      } else if (command.action === "release-read") {
        service.settingsStore.reloadSettings()
        require(service.settingsStore.helperOperation === "read", "reload did not start")
        service.settingsStore.setTicker("speed", "slow")
        service.settingsStore.setTicker("speed", "normal")
        require(service.settingsStore.pendingWrite !== null, "read/write handoff not queued")
        service.releaseWidget(firstToken)
        require(stopped(), "read drain keeps periodic workers")
        phase = "read-drain"
        reply("workers-stopped")
      } else if (command.action === "rapid") {
        require(stopped() && service.settingsStore === null, "rapid teardown precondition")
        for (var i = 0; i < 4; i++) {
          var token = service.acquireWidget()
          service.fetchService.deferCallback(function() { root.fail("destroyed fetch callback ran") })
          service.releaseWidget(token)
        }
        phase = "rapid"
      }
    } catch (error) { fail(String(error)) }
  }

  FileView {
    id: control
    path: Quickshell.env("HOME") + "/control.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      var command = JSON.parse(text())
      if (command.sequence <= root.sequence) return
      root.sequence = command.sequence
      root.execute(command)
    }
  }

  Timer {
    interval: 20
    repeat: true
    running: true
    onTriggered: {
      try {
        if (phase === "ready" || phase === "reacquired") {
          var store = service.settingsStore
          if (!store || !store.ready || store.helperOperation !== "" || store.writePending) return
          require(service.notificationService.hasBaseline, "missing silent notification baseline")
          require(service.notificationService.previousGames.length === 0,
            "notification baseline survived worker teardown")
          require(service.notificationService.pendingDeliveries.length === 0,
            "startup replays notification deliveries")
          if (phase === "reacquired") require(store.settings.ticker.speed === "fast", "queued write lost")
          reply(phase)
          phase = ""
        } else if (phase === "drain" || phase === "stalled-drain" || phase === "read-drain") {
          require(stopped(), "worker restarted during settings drain")
          if (service.settingsStore !== null) return
          if (phase === "stalled-drain") require(Date.now() - releaseAt >= 2300,
            "stalled helper bypassed bounded drain window")
          reply(phase === "read-drain" ? "read-drained" : "drained")
          phase = ""
        } else if (phase === "rapid") {
          require(stopped() && service.settingsStore === null, "rapid teardown leaked owners")
          phase = ""
          reply("rapid-stopped")
        }
      } catch (error) { fail(String(error)) }
    }
  }
}

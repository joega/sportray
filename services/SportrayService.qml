pragma Singleton

import QtQuick
import "../model/DateModel.js" as DateModel
import "../model/MonitorOwnership.js" as MonitorOwnership
import "../model/AmbientGamesPolicy.js" as AmbientGamesPolicy

// Omarchy creates one bar-widget item per screen. This singleton is the only
// owner of stateful work, so those view instances cannot duplicate requests,
// notification transition baselines, or writes to the preference file.
Item {
  id: root

  property string selectedDateKey: DateModel.localDateKey(new Date())
  property string todayDateKey: DateModel.localDateKey(new Date())
  property var todayGames: []
  property double nowMs: Date.now()
  // Calendar remains in-tree for later rework but is not a production route.
  readonly property bool calendarFeatureEnabled: false
  property int nextPanelToken: 0
  property var panelContexts: MonitorOwnership.emptyContexts()
  readonly property bool panelOpen: MonitorOwnership.anyPanelOpen(root.panelContexts)
  readonly property string lookaheadLeagueId: MonitorOwnership.lookaheadLeagueId(root.panelContexts)
  property var widgetTokens: ({})
  property int nextWidgetToken: 0
  property bool drainingSettings: false
  readonly property int widgetCount: Object.keys(root.widgetTokens).length
  readonly property bool active: root.widgetCount > 0
  readonly property var settingsStore: settingsLoader.item
  readonly property var fetchService: workers.item ? workers.item.fetchService : null
  readonly property var standingsService: workers.item ? workers.item.standingsService : null
  readonly property var notificationService: workers.item ? workers.item.notificationService : null
  readonly property var logoImageStore: workers.item ? workers.item.logoImageStore : null
  readonly property var ambientGames: AmbientGamesPolicy.project(
    root.fetchService ? root.fetchService.games : [], root.selectedDateKey,
    root.todayDateKey, root.todayGames)
  readonly property string ambientTickerState: root.fetchService && root.fetchService.loading && !root.fetchService.hasData
    ? "loading" : root.fetchService && root.fetchService.errorCode !== "" && !root.fetchService.hasData
      ? "offline" : ambientGames.length > 0 ? "ready" : "empty"

  // QML singletons outlive widget Loaders. Only the coordinator survives the
  // last consumer; all periodic/network/notification work is loader-owned.
  function acquireWidget() {
    if (!root.active) {
      root.nowMs = Date.now()
      root.todayDateKey = DateModel.localDateKey(new Date(root.nowMs))
      root.selectedDateKey = root.todayDateKey
      root.todayGames = []
      if (root.settingsStore) root.settingsStore.resume()
    }
    var token = "widget-" + (++root.nextWidgetToken)
    var next = Object.assign({}, root.widgetTokens)
    next[token] = true
    root.widgetTokens = next
    root.drainingSettings = false
    settingsDeadline.stop()
    return token
  }

  function releaseWidget(token) {
    if (!root.widgetTokens[token]) return
    if (root.widgetCount === 1 && root.settingsStore) {
      // Finish already accepted writes, but stop watching/reading immediately.
      root.drainingSettings = root.settingsStore.writePending
        || root.settingsStore.pendingWrite !== null
      root.settingsStore.beginShutdown()
      if (root.drainingSettings) settingsDeadline.restart()
    }
    var next = Object.assign({}, root.widgetTokens)
    delete next[token]
    root.widgetTokens = next
    if (!root.active) {
      root.panelContexts = MonitorOwnership.emptyContexts()
      root.todayGames = []
      root.finishSettingsDrain()
    }
  }

  function finishSettingsDrain() {
    if (root.active || !root.drainingSettings) return
    if (!root.settingsStore || (!root.settingsStore.writePending
        && root.settingsStore.pendingWrite === null
        && root.settingsStore.helperOperation === "")) {
      root.drainingSettings = false
      settingsDeadline.stop()
    }
  }

  function registerPanel() {
    root.nextPanelToken += 1
    var token = "panel-" + root.nextPanelToken
    root.panelContexts = MonitorOwnership.updateContext(root.panelContexts, token, false, "")
    return token
  }

  function updatePanel(token, open, lookaheadLeague) {
    root.panelContexts = MonitorOwnership.updateContext(root.panelContexts, token, open, lookaheadLeague)
  }

  function unregisterPanel(token) {
    root.panelContexts = MonitorOwnership.removeContext(root.panelContexts, token)
  }

  function captureTodayGames() {
    if (root.selectedDateKey === root.todayDateKey && root.fetchService)
      root.todayGames = root.fetchService.games.slice()
  }

  Timer {
    id: settingsDeadline
    interval: 2500
    onTriggered: root.drainingSettings = false
  }

  Loader {
    id: settingsLoader
    active: root.active || root.drainingSettings
    sourceComponent: SettingsStore {}
  }

  Connections {
    target: root.settingsStore
    function onHelperOperationChanged() { Qt.callLater(root.finishSettingsDrain) }
    function onWritePendingChanged() { Qt.callLater(root.finishSettingsDrain) }
  }

  Loader {
    id: workers
    active: root.active
    sourceComponent: Item {
      readonly property var fetchService: fetchService
      readonly property var standingsService: standingsService
      readonly property var notificationService: notificationServiceImpl
      readonly property var logoImageStore: logoImageStoreImpl

      Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: {
          root.nowMs = Date.now()
          root.todayDateKey = DateModel.localDateKey(new Date(root.nowMs))
        }
      }

      FetchService {
        id: fetchService
        calendarFeatureEnabled: root.calendarFeatureEnabled
        settingsReady: root.settingsStore ? root.settingsStore.ready : false
        enabledLeagues: root.settingsStore && root.settingsStore.settings
          ? root.settingsStore.settings.enabledLeagues : []
        favoriteTeamIds: root.settingsStore && root.settingsStore.settings
          ? root.settingsStore.settings.favoriteTeamIds : []
        selectedDateKey: root.selectedDateKey
        lookaheadLeagueId: root.lookaheadLeagueId
        panelOpen: root.panelOpen
      }

      StandingsFetch { id: standingsService }

      NotificationService {
        id: notificationServiceImpl
        settingsStore: root.settingsStore
        games: root.selectedDateKey === root.todayDateKey ? fetchService.games : []
      }

      LogoImageStore { id: logoImageStoreImpl }
    }
  }

  Connections {
    target: root.fetchService
    function onGamesChanged() { root.captureTodayGames() }
  }
}

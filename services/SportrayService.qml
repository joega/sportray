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
  readonly property var settingsStore: settingsStore
  readonly property var fetchService: fetchService
  readonly property var standingsService: standingsService
  readonly property var notificationService: notificationServiceImpl
  readonly property var ambientGames: AmbientGamesPolicy.project(
    fetchService ? fetchService.games : [], root.selectedDateKey,
    root.todayDateKey, root.todayGames)
  readonly property string ambientTickerState: fetchService && fetchService.loading && !fetchService.hasData
    ? "loading" : fetchService && fetchService.errorCode !== "" && !fetchService.hasData
      ? "offline" : ambientGames.length > 0 ? "ready" : "empty"

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
    if (root.selectedDateKey === root.todayDateKey && fetchService)
      root.todayGames = fetchService.games.slice()
  }

  Timer {
    interval: 60000
    repeat: true
    running: true
    onTriggered: {
      root.nowMs = Date.now()
      root.todayDateKey = DateModel.localDateKey(new Date(root.nowMs))
    }
  }

  SettingsStore { id: settingsStore }

  FetchService {
    id: fetchService
    calendarFeatureEnabled: root.calendarFeatureEnabled
    settingsReady: settingsStore.ready
    enabledLeagues: settingsStore.settings ? settingsStore.settings.enabledLeagues : ["nhl"]
    favoriteTeamIds: settingsStore.settings ? settingsStore.settings.favoriteTeamIds : []
    selectedDateKey: root.selectedDateKey
    lookaheadLeagueId: root.lookaheadLeagueId
    panelOpen: root.panelOpen
  }

  StandingsFetch {
    id: standingsService
  }

  NotificationService {
    id: notificationServiceImpl
    settingsStore: settingsStore
    games: root.selectedDateKey === root.todayDateKey ? fetchService.games : []
  }

  Connections {
    target: fetchService
    function onGamesChanged() { root.captureTodayGames() }
  }
}

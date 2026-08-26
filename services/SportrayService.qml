pragma Singleton

import QtQuick
import "../model/DateModel.js" as DateModel
import "../model/MonitorOwnership.js" as MonitorOwnership

// Omarchy creates one bar-widget item per screen. This singleton is the only
// owner of stateful work, so those view instances cannot duplicate requests,
// notification transition baselines, or writes to the preference file.
Item {
  id: root

  property string selectedDateKey: DateModel.localDateKey(new Date())
  property string todayDateKey: DateModel.localDateKey(new Date())
  property double nowMs: Date.now()
  property int nextPanelToken: 0
  property var panelContexts: MonitorOwnership.emptyContexts()
  readonly property bool panelOpen: MonitorOwnership.anyPanelOpen(root.panelContexts)
  readonly property string lookaheadLeagueId: MonitorOwnership.lookaheadLeagueId(root.panelContexts)
  readonly property var settingsStore: settingsStore
  readonly property var fetchService: fetchService
  readonly property var standingsService: standingsService
  readonly property var notificationService: notificationServiceImpl

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
}

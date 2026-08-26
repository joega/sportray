import QtQuick
import qs.Commons
import qs.Ui
import "../model/WatchPolicy.js" as WatchPolicy

// The only watch control used by score rows and the local detail view. It
// owns presentation state, while SettingsStore remains the sole mutation and
// persistence boundary.
Item {
  id: root

  required property var game
  property var settingsStore: null
  property double currentTime: Date.now()
  property bool hasCursor: false
  readonly property var currentWatch: WatchPolicy.findWatch(
    root.settingsStore ? root.settingsStore.watchedGames : [], root.game)
  readonly property bool active: WatchPolicy.isActiveWatch(
    root.settingsStore ? root.settingsStore.watchedGames : [], root.game, root.currentTime)
  readonly property int watchCount: root.settingsStore && root.settingsStore.watchedGames
    ? root.settingsStore.watchedGames.length : 0
  readonly property bool validGame: Boolean(root.game && root.game.isValid === true
    && WatchPolicy.gameIdFor(root.game) && root.game.startTime)
  readonly property string disabledReason: {
    if (!root.validGame) return "Watch unavailable for this game"
    if (root.active) return ""
    if (!root.settingsStore || root.settingsStore.ready !== true)
      return "Settings are still loading"
    if (root.settingsStore.preservedRawStateText
        && root.settingsStore.preservedRawStateText.length > 0)
      return "Unsupported settings version"
    if (root.settingsStore.isLeagueEnabled
        && !root.settingsStore.isLeagueEnabled(root.game.league))
      return "Enable this league to watch the game"
    if (root.game.status === "final" || root.game.status === "canceled")
      return "Game has ended"
    if (root.watchCount >= WatchPolicy.MAX_WATCHES) return "Watch limit reached"
    return ""
  }
  readonly property bool available: root.active || root.disabledReason === ""
  readonly property string actionLabel: root.active ? "Remove watch" : "Watch game"
  readonly property string buttonText: root.active ? "Watching" : "Watch"
  readonly property bool pointerPressed: action.pointerPressed

  signal changed()

  implicitWidth: action.implicitWidth
  implicitHeight: action.implicitHeight
  width: implicitWidth
  height: implicitHeight

  function activate() {
    if (!root.available || !root.settingsStore
        || typeof root.settingsStore.toggleWatch !== "function") return
    if (root.settingsStore.toggleWatch(root.game)) root.changed()
  }

  function focusAction() {
    if (root.available) action.forceActiveFocus()
  }

  SemanticActionButton {
    id: action
    anchors.fill: parent
    text: root.buttonText
    tooltipText: root.available ? root.actionLabel : root.disabledReason
    textBold: true
    textFontSize: Style.font.bodySmall
    textHorizontalPadding: Style.spacing.xs
    textVerticalPadding: Style.spacing.xs
    focusable: true
    hasCursor: root.hasCursor
    enabled: root.available
    onClicked: root.activate()
    Accessible.name: root.available
      ? root.actionLabel : root.disabledReason
    Accessible.description: root.active
      ? "This game is included in watch notifications"
      : root.disabledReason
    Accessible.role: Accessible.Button
  }
}

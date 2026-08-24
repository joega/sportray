import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  required property var settingsStore
  required property var notificationService
  property int settingsRevision: 0
  property int cursorIndex: 0

  readonly property var preferenceOptions: [
    {key: "enabled", label: "Notifications", description: "Allow Sportray to send desktop notifications."},
    {key: "gameStart", label: "Game starts", description: "Notify when a favorite game becomes live."},
    {key: "scoreChange", label: "Score changes", description: "Notify when a favorite team's score changes."},
    {key: "gameFinal", label: "Game finals", description: "Notify when a favorite game ends."},
    {key: "pregameReminder", label: "Pregame reminders", description: "Remind before a favorite game starts."},
    {key: "closeGame", label: "Close-game alerts", description: "Alert when a favorite game reaches a one-score margin."}
  ]

  implicitHeight: settingsColumn.implicitHeight
  height: visible ? implicitHeight : 0
  width: parent ? parent.width : implicitWidth

  function notificationSettings() {
    var revision = root.settingsRevision
    if (!root.settingsStore || !root.settingsStore.settings)
      return null
    return root.settingsStore.settings.notifications || null
  }

  function isEnabled(key) {
    var notifications = root.notificationSettings()
    return notifications !== null && notifications[key] === true
  }

  function moveCursor(delta) {
    root.cursorIndex = Math.max(0, Math.min(root.preferenceOptions.length,
      root.cursorIndex + delta))
  }

  function cursorBounds() {
    var top = Style.font.bodySmall + Style.spacing.sm
      + root.cursorIndex * Style.space(64)
    return {top: top, bottom: top + Style.space(56)}
  }

  function activateCursor() {
    if (root.cursorIndex === root.preferenceOptions.length) {
      root.sendTestNotification()
      return
    }
    var option = root.preferenceOptions[root.cursorIndex]
    if (option && root.settingsStore && typeof root.settingsStore.toggleNotification === "function")
      root.settingsStore.toggleNotification(option.key)
  }

  function toggle(key) {
    if (root.settingsStore && typeof root.settingsStore.toggleNotification === "function")
      root.settingsStore.toggleNotification(key)
  }

  function sendTestNotification() {
    if (root.notificationService
        && typeof root.notificationService.sendTestNotification === "function")
      root.notificationService.sendTestNotification()
  }

  Column {
    id: settingsColumn
    width: parent.width
    spacing: Style.spacing.sm

    Text {
      width: parent.width
      text: "↑/↓ or j/k to move · Enter/Space to toggle · n to open"
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    Repeater {
      model: root.preferenceOptions

      delegate: Toggle {
        required property var modelData
        required property int index
        width: settingsColumn.width
        label: modelData.label
        description: modelData.description
        checked: root.isEnabled(modelData.key)
        hasCursor: index === root.cursorIndex
        onClicked: root.toggle(modelData.key)
      }
    }

    SemanticActionButton {
      width: settingsColumn.width
      height: Style.space(36)
      text: "Send test notification"
      hasCursor: root.cursorIndex === root.preferenceOptions.length
      textFontSize: Style.font.bodySmall
      textBold: true
      bordered: true
      tooltipText: "Send a test notification"
      onClicked: root.sendTestNotification()
      Accessible.name: "Send test notification"
      Accessible.role: Accessible.Button
    }

    Text {
      width: parent.width
      text: "Sends a preview even when alerts are disabled."
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }
  }
}

import QtQuick
import "../model/UiTypography.js" as Typography
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
    {key: "gameStart", label: "Game starts", description: "When a favorite or watched game goes live."},
    {key: "scoreChange", label: "Score changes", description: "When a favorite or watched game score changes."},
    {key: "gameFinal", label: "Game finals", description: "When a favorite or watched game ends."},
    {key: "pregameReminder", label: "Pregame reminders", description: "Before a favorite or watched game starts."},
    {key: "closeGame", label: "Close-game alerts", description: "When a favorite or watched game is within one score."}
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
    var item = root.cursorIndex === root.preferenceOptions.length
      ? testNotificationButton : preferenceRepeater.itemAt(root.cursorIndex)
    if (!item) return {top: 0, bottom: 0}
    var point = item.mapToItem(root, 0, 0)
    return {top: point.y, bottom: point.y + item.height}
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
      textFormat: Text.PlainText
      width: parent.width
      text: "Alerts for your favorite teams and watched games."
      color: Qt.alpha(Color.popups.text, 0.85)
      font.family: Typography.family
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    Repeater {
      id: preferenceRepeater
      model: root.preferenceOptions

      delegate: SettingsToggle {
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
      id: testNotificationButton
      width: settingsColumn.width
      height: Style.space(36)
      text: "Send test notification"
      hasCursor: root.cursorIndex === root.preferenceOptions.length
      textFontSize: Style.font.bodySmall
      textBold: true
      bordered: false
      tooltipText: "Send a test notification"
      onClicked: root.sendTestNotification()
      Accessible.name: "Send test notification"
      Accessible.role: Accessible.Button
    }

    Text {
      textFormat: Text.PlainText
      width: parent.width
      text: "Sends a preview even when alerts are disabled."
      color: Qt.alpha(Color.popups.text, 0.85)
      font.family: Typography.family
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }
  }
}

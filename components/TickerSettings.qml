import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root
  required property var settingsStore
  property int settingsRevision: 0
  property int cursorIndex: 0
  readonly property var options: [
    {key: "enabled", label: "Show ticker", description: "Keep the ambient score ticker visible."},
    {key: "position", label: "Screen position", description: "Choose the top or bottom screen edge."},
    {key: "speed", label: "Scroll speed", description: "Choose slow, normal, or fast movement."}
  ]
  implicitHeight: column.implicitHeight
  height: visible ? implicitHeight : 0
  width: parent ? parent.width : implicitWidth

  function ticker() {
    var revision = root.settingsRevision
    return root.settingsStore && root.settingsStore.settings
      ? root.settingsStore.settings.ticker : {enabled: true, position: "bottom", speed: "normal"}
  }
  function value(key) { return root.ticker()[key] }
  function label(option) {
    var value = root.value(option.key)
    if (option.key === "enabled") return value ? "On" : "Off"
    if (option.key === "position") return value === "top" ? "Top" : "Bottom"
    return value.charAt(0).toUpperCase() + value.slice(1)
  }
  function activate(option) {
    var current = root.value(option.key)
    var next = option.key === "enabled" ? !current
      : option.key === "position" ? (current === "bottom" ? "top" : "bottom")
      : (current === "slow" ? "normal" : current === "normal" ? "fast" : "slow")
    if (root.settingsStore && typeof root.settingsStore.setTicker === "function")
      root.settingsStore.setTicker(option.key, next)
  }
  function moveCursor(delta) { root.cursorIndex = Math.max(0, Math.min(root.options.length - 1, root.cursorIndex + delta)) }
  function cursorBounds() { return {top: Style.font.bodySmall + root.cursorIndex * Style.space(64), bottom: Style.font.bodySmall + root.cursorIndex * Style.space(64) + Style.space(56)} }
  function activateCursor() { root.activate(root.options[root.cursorIndex]) }

  Column {
    id: column
    width: parent.width
    spacing: Style.spacing.sm
    Text {
      width: parent.width
      text: "↑/↓ or j/k to move · Enter/Space to change"
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
    }
    Repeater {
      model: root.options
      delegate: SemanticActionButton {
        required property var modelData
        required property int index
        width: column.width
        height: Style.space(52)
        text: modelData.label + ": " + root.label(modelData)
        tooltipText: modelData.description
        hasCursor: root.cursorIndex === index
        bordered: true
        textFontSize: Style.font.bodySmall
        textBold: true
        onClicked: root.activate(modelData)
        Accessible.name: modelData.label + ", " + root.label(modelData)
        Accessible.role: Accessible.Button
      }
    }
  }
}

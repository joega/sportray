import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "../model/UiTypography.js" as Typography

Item {
  id: root
  PresentationTokens { id: visual }
  required property var settingsStore
  property int settingsRevision: 0
  property int cursorIndex: 0
  readonly property var options: [
    {key: "enabled", label: "Show ticker", description: "Keep scores visible along the screen edge."},
    {key: "position", label: "Screen position", description: "The ticker reserves space at this edge."},
    {key: "speed", label: "Scroll speed", description: "Pause or resume directly on the ticker."}
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
    var current = root.value(option.key)
    if (option.key === "enabled") return current ? "On" : "Off"
    return current.charAt(0).toUpperCase() + current.slice(1)
  }
  function choices(key) { return key === "position" ? ["top", "bottom"] : ["slow", "normal", "fast"] }
  function setValue(key, next) {
    if (root.settingsStore && typeof root.settingsStore.setTicker === "function")
      root.settingsStore.setTicker(key, next)
  }
  function activate(option) {
    var current = root.value(option.key)
    var next = option.key === "enabled" ? !current
      : option.key === "position" ? (current === "bottom" ? "top" : "bottom")
      : (current === "slow" ? "normal" : current === "normal" ? "fast" : "slow")
    root.setValue(option.key, next)
  }
  function moveCursor(delta) { root.cursorIndex = Math.max(0, Math.min(root.options.length - 1, root.cursorIndex + delta)) }
  function cursorBounds() {
    var item = root.cursorIndex === 0 ? visibilityToggle : optionRepeater.itemAt(root.cursorIndex - 1)
    if (!item) return {top: 0, bottom: 0}
    var point = item.mapToItem(root, 0, 0)
    return {top: point.y, bottom: point.y + item.height}
  }
  function activateCursor() { root.activate(root.options[root.cursorIndex]) }

  Column {
    id: column
    width: parent.width
    spacing: Style.spacing.md

    SettingsToggle {
      id: visibilityToggle
      width: column.width
      label: root.options[0].label
      description: root.options[0].description
      checked: root.value("enabled") === true
      hasCursor: root.cursorIndex === 0
      onClicked: { root.cursorIndex = 0; root.activate(root.options[0]) }
    }

    Repeater {
      id: optionRepeater
      model: root.options.slice(1)
      delegate: Item {
        id: optionGroup
        required property var modelData
        required property int index
        width: column.width
        height: optionColumn.implicitHeight + Style.space(24)

        Rectangle {
          anchors.fill: parent
          color: visual.surface
          radius: visual.radius
        }

        Column {
          id: optionColumn
          x: Style.space(12)
          y: Style.space(12)
          width: parent.width - x * 2
          spacing: Style.spacing.sm

          Text {
            width: parent.width
            text: optionGroup.modelData.label
            textFormat: Text.PlainText
            color: visual.ink
            font.family: Typography.family
            font.pixelSize: visual.body
            font.bold: true
          }
          Text {
            width: parent.width
            text: optionGroup.modelData.description
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            color: visual.muted
            font.family: Typography.family
            font.pixelSize: Style.font.bodySmall
          }
          Row {
            width: parent.width
            spacing: Style.spacing.xs
            Repeater {
              id: choiceRepeater
              model: root.choices(optionGroup.modelData.key)
              Button {
                required property string modelData
                width: (optionColumn.width - Style.spacing.xs * (choiceRepeater.count - 1)) / choiceRepeater.count
                fontFamily: Typography.family
                fontSize: Style.font.bodySmall
                text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                selected: root.value(optionGroup.modelData.key) === modelData
                foreground: selected ? visual.accent : visual.ink
                hasCursor: root.cursorIndex === optionGroup.index + 1 && selected
                focusable: true
                onClicked: {
                  root.cursorIndex = optionGroup.index + 1
                  root.setValue(optionGroup.modelData.key, modelData)
                }
                Accessible.name: optionGroup.modelData.label + ": " + text
                Accessible.role: Accessible.RadioButton
                Accessible.checkable: true
                Accessible.checked: selected
                Accessible.onPressAction: root.setValue(optionGroup.modelData.key, modelData)
              }
            }
          }
        }
      }
    }
  }
}

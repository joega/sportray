import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "model/Iconography.js" as Iconography
import "model/LifecyclePolicy.js" as LifecyclePolicy
import "services" as Services

BarWidget {
  id: root
  moduleName: "io.github.joega.sportray"

  readonly property string barIconName: panelLoader.item && panelLoader.item.barIconName
    ? panelLoader.item.barIconName : "soccerField"
  readonly property string barTooltipText: panelLoader.item && panelLoader.item.barTooltipText
    ? panelLoader.item.barTooltipText : "Sportray"
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item
    ? panelLoader.item.popoutSwitchClosing === true : false

  readonly property var sharedService: Services.SportrayService
  readonly property var settingsStore: root.sharedService.settingsStore
  // Horizontal panels follow the configured bar region while anchoring to the
  // real button, whose item tree lets KeyboardPanel resolve the correct screen
  // and overlay layer.
  property string barRegion: ""
  readonly property var callbackOwner: LifecyclePolicy.createOwnerState()

  function deferCallback(callback) {
    if (typeof callback !== "function") return
    var owner = root.callbackOwner
    var generation = LifecyclePolicy.captureGeneration(owner)
    Qt.callLater(function() {
      if (!LifecyclePolicy.canRun(owner, generation)) return
      callback()
    })
  }

  function resolveBarRegion() {
    var slots = root.bar && root.bar.moduleSlots ? root.bar.moduleSlots : []
    var moduleFallback = ""
    for (var i = 0; i < slots.length; i++) {
      var slot = slots[i]
      if (!slot) continue
      if (slot.moduleName === root.moduleName && !moduleFallback)
        moduleFallback = String(slot.region || "")
      if (slot.activeItem === root) {
        root.barRegion = String(slot.region || "")
        return
      }
    }
    // ModuleSlot registers after its Loader child is created. On a clean shell
    // start activeItem may not yet point back to this widget, but the module id
    // and configured region are already stable. All per-screen copies share
    // that configured region because Sportray disallows multiple instances.
    root.barRegion = moduleFallback
  }
  readonly property string barPosition: root.bar ? String(root.bar.position || "") : ""
  readonly property var panelAnchorItem: button

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("service" in target) target.service = root.sharedService
    if ("settingsStore" in target) target.settingsStore = root.settingsStore
    if ("barRegion" in target) target.barRegion = root.barRegion
    if ("anchorItem" in target) target.anchorItem = root.panelAnchorItem
    if ("hostWidget" in target) target.hostWidget = root
  }

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function togglePanel() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: {
    resolveBarRegion()
    injectPanel()
  }
  onSettingsChanged: injectPanel()
  onBarRegionChanged: injectPanel()
  onBarPositionChanged: injectPanel()

  Connections {
    target: root.bar
    function onModuleSlotsChanged() {
      root.resolveBarRegion()
      root.injectPanel()
    }
  }

  Component.onCompleted: {
    resolveBarRegion()
    root.deferCallback(function() {
      root.resolveBarRegion()
      root.injectPanel()
    })
  }

  Component.onDestruction: LifecyclePolicy.invalidate(root.callbackOwner)

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      root.deferCallback(root.injectPanel)
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: Iconography.displayText(root.barIconName, button.fontFamily)
    tooltipText: root.barTooltipText
    Accessible.name: root.barTooltipText
    Accessible.role: Accessible.Button

    Rectangle {
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.topMargin: Style.space(3)
      anchors.rightMargin: Style.space(3)
      width: Style.space(5)
      height: width
      radius: width / 2
      color: Color.accent
      visible: panelLoader.item && panelLoader.item.barHasLiveFavorite === true
      Accessible.ignored: true
    }

    onPressed: function(buttonId) {
      if (buttonId === Qt.LeftButton) root.togglePanel()
    }

  }
}

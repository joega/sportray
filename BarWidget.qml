import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "model/BarPresentation.js" as BarPresentation
import "model/CountdownProjectionPolicy.js" as CountdownProjectionPolicy
import "model/Iconography.js" as Iconography
import "model/LifecyclePolicy.js" as LifecyclePolicy
import "services" as Services

BarWidget {
  id: root
  moduleName: "io.github.joega.sportray"

  readonly property var barPresentation: BarPresentation.build({
    mode: BarPresentation.modeForBar(root.bar),
    state: panelLoader.item ? panelLoader.item.barState : null,
    countdown: root.barCountdownProjection,
    games: panelLoader.item ? panelLoader.item.normalizedGames : [],
    favoriteTeamIds: panelLoader.item ? panelLoader.item.favoriteTeamIds : [],
    fullText: panelLoader.item ? panelLoader.item.barScoreText : "",
    tooltipText: panelLoader.item ? panelLoader.item.barTooltipText : "",
    liveFavorite: panelLoader.item ? panelLoader.item.barHasLiveFavorite : false,
    loading: panelLoader.item && panelLoader.item.fetchService
      ? panelLoader.item.fetchService.loading : false,
    hasData: panelLoader.item && panelLoader.item.fetchService
      ? panelLoader.item.fetchService.hasData : false,
    errorCode: panelLoader.item && panelLoader.item.fetchService
      ? panelLoader.item.fetchService.errorCode : ""
  })
  readonly property var barCountdownProjection: panelLoader.item
    ? CountdownProjectionPolicy.project({
        todayDateKey: panelLoader.item.ambientTodayDateKey,
        selectedDateKey: panelLoader.item.selectedDateKey,
        nowMs: panelLoader.item.ambientNowMs,
        favoriteTeamIds: panelLoader.item.favoriteTeamIds,
        hasData: panelLoader.item.hasData,
        errorCode: panelLoader.item.fetchService
          ? panelLoader.item.fetchService.errorCode : "",
        game: panelLoader.item.barState
          && panelLoader.item.barState.kind === "favorite-upcoming"
          ? panelLoader.item.barState.game : null
      }) : null
  readonly property string barIconName: panelLoader.item && panelLoader.item.barIconName
    ? panelLoader.item.barIconName : "soccerField"
  readonly property string barTooltipText: root.barPresentation.tooltipText || "Sportray"
  readonly property string barLabelText: root.barPresentation.label || ""
  readonly property bool fullMode: root.barPresentation.mode === "full"
  readonly property bool barHasLiveFavorite: root.barPresentation.hasLiveFavorite === true
  readonly property bool barHasUpcomingFavorite: root.barPresentation.hasUpcomingFavorite === true
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
  // A wide panel opened from the right bar section should use the screen edge
  // as its horizontal anchor, rather than the first icon in that section.
  // Keep the normal trigger anchor for left/center sections and vertical bars.
  readonly property var panelAnchorItem: root.barRegion === "right"
    && root.bar && root.bar.vertical !== true
    ? rightEdgeAnchor : (root.fullMode ? fullButton : compactButton)

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

  implicitWidth: root.fullMode ? fullButton.implicitWidth : compactButton.implicitWidth
  implicitHeight: root.fullMode ? fullButton.implicitHeight : compactButton.implicitHeight

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

  TransformWatcher {
    id: panelAnchorWatcher
    a: fullButton.QsWindow.window ? fullButton.QsWindow.window.contentItem : null
    b: fullButton
  }

  // KeyboardPanel positions the card from the supplied item's center. This
  // one-pixel proxy at the bar window's right edge makes its existing clamp
  // produce a flush right edge without a host-specific alignment property.
  Item {
    id: rightEdgeAnchor
    visible: false
    width: 1
    height: root.height
    x: {
      panelAnchorWatcher.transform
      var window = fullButton.QsWindow.window
      if (!window || !window.contentItem) return root.width
      var position = fullButton.mapToItem(window.contentItem, 0, 0)
      return window.width - position.x
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
    id: compactButton
    anchors.fill: parent
    bar: root.bar
    text: Iconography.displayText(root.barIconName, compactButton.fontFamily)
    tooltipText: root.barTooltipText
    Accessible.name: root.barTooltipText
    Accessible.role: Accessible.Button
    visible: !root.fullMode

    Rectangle {
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.topMargin: Style.space(3)
      anchors.rightMargin: Style.space(3)
      width: Style.space(5)
      height: width
      radius: width / 2
      color: root.barHasLiveFavorite ? Color.urgent : Color.accent
      visible: root.barHasLiveFavorite || root.barHasUpcomingFavorite
      Accessible.ignored: true
    }

    onPressed: function(buttonId) {
      if (buttonId === Qt.LeftButton) root.togglePanel()
    }

  }

  BarIconButton {
    id: fullButton
    anchors.fill: parent
    bar: root.bar
    text: Iconography.displayText(root.barIconName, fullButton.fontFamily)
    tooltipText: root.barTooltipText
    Accessible.name: root.barTooltipText
    Accessible.role: Accessible.Button
    visible: root.fullMode

    Rectangle {
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.topMargin: Style.space(3)
      anchors.rightMargin: Style.space(3)
      width: Style.space(5)
      height: width
      radius: width / 2
      color: root.barHasLiveFavorite ? Color.urgent : Color.accent
      visible: root.barHasLiveFavorite || root.barHasUpcomingFavorite
      Accessible.ignored: true
    }

    onPressed: function(buttonId) {
      if (buttonId === Qt.LeftButton) root.togglePanel()
    }
  }
}

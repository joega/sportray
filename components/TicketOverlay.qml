import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons as Commons
import qs.Ui

PanelWindow {
  id: root

  required property QtObject bar
  required property var targetScreen
  property var hostWidget: null
  property var games: []
  property var favoriteTeamIds: []
  property string tickerState: "empty"
  property double nowMs: Date.now()
  property int tickerHeight: Commons.Style.space(32)
  property bool tickerEnabled: true
  property string tickerPosition: "bottom"
  property string tickerSpeed: "normal"
  property var imageStore: null
  property bool tickerPaused: false
  property Item tooltipTarget: null
  property string tooltipText: ""

  function showTickerTooltip(target, text) {
    root.tooltipTarget = target
    root.tooltipText = text
  }
  function hideTickerTooltip(target) {
    if (root.tooltipTarget !== target) return
    root.tooltipTarget = null
    root.tooltipText = ""
  }

  screen: root.targetScreen
  visible: !!root.targetScreen && root.tickerEnabled
  color: Commons.Color.background
  exclusionMode: ExclusionMode.Auto
  anchors.left: true
  anchors.right: true
  anchors.top: root.tickerPosition === "top"
  anchors.bottom: root.tickerPosition !== "top"
  implicitHeight: root.tickerEnabled ? root.tickerHeight : 0
  WlrLayershell.namespace: "io.github.joega.sportray-ticker"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  TicketStrip {
    anchors.fill: parent
    games: root.games
    favoriteTeamIds: root.favoriteTeamIds
    tickerState: root.tickerState
    nowMs: root.nowMs
    enabled: root.tickerEnabled
    paused: root.tickerPaused
    speed: root.tickerSpeed
    reducedMotion: Commons.Style.reduceMotion
    nativeTooltips: true
    imageStore: root.imageStore
    onPauseToggled: root.tickerPaused = !root.tickerPaused
    onPrimaryActionRequested: if (root.hostWidget) root.hostWidget.open()
    onTooltipRequested: function(target, text) { root.showTickerTooltip(target, text) }
    onTooltipDismissed: function(target) { root.hideTickerTooltip(target) }
  }

  // A QQC tooltip would be clipped by the 32px layer-shell window. Like the
  // installed bar, use a separate popup anchored to the actual hovered item.
  PopupWindow {
    id: tooltipWindow
    visible: root.visible && !!root.tooltipTarget && root.tooltipTarget.visible && root.tooltipText !== ""
    color: "transparent"
    mask: Region {}
    implicitWidth: Math.ceil(Math.min(tooltipLabel.implicitWidth + Commons.Style.spacing.sm * 2,
      Commons.Style.space(400), Math.max(1, root.width - Commons.Style.spacing.md * 2)))
    implicitHeight: Math.ceil(tooltipLabel.implicitHeight + Commons.Style.spacing.sm * 2)
    readonly property bool scaleReady: visible
      && Math.round(devicePixelRatio * 120) === Math.round(root.devicePixelRatio * 120)
    anchor {
      id: tooltipAnchor
      window: root
      adjustment: PopupAdjustment.Slide
      edges: Edges.Top | Edges.Left
      gravity: Edges.Bottom | Edges.Right
      rect.width: 1
      rect.height: 1
      onAnchoring: {
        var target = root.tooltipTarget
        if (!target) return
        var point = target.mapToItem(root.contentItem, target.width / 2 - tooltipWindow.implicitWidth / 2,
          root.tickerPosition === "top" ? target.height + Commons.Style.spacing.xs
            : -tooltipWindow.implicitHeight - Commons.Style.spacing.xs)
        tooltipAnchor.rect.x = Math.round(point.x)
        tooltipAnchor.rect.y = Math.round(point.y)
      }
    }
    BorderSurface {
      anchors.fill: parent
      opacity: tooltipWindow.scaleReady ? 1 : 0
      color: Commons.Color.tooltip.background
      borderSpec: Commons.Border.surfaceSpec("tooltip", "border", Commons.Color.tooltip.border, 1)
      radius: Commons.Style.cornerRadius
      Text {
        id: tooltipLabel
        x: Commons.Style.spacing.sm
        y: Commons.Style.spacing.sm
        width: Math.max(1, tooltipWindow.width - Commons.Style.spacing.sm * 2)
        text: root.tooltipText
        textFormat: Text.PlainText
        color: Commons.Color.tooltip.text
        font.family: Commons.Style.font.family
        font.pixelSize: Commons.Style.font.bodySmall
        wrapMode: Text.WordWrap
      }
    }
  }
}

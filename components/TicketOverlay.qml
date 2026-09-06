import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

PanelWindow {
  id: root

  required property QtObject bar
  required property var targetScreen
  property var hostWidget: null
  property var games: []
  property var favoriteTeamIds: []
  property string tickerState: "empty"
  property double nowMs: Date.now()
  property int tickerHeight: Style.space(32)
  property bool tickerEnabled: true
  property string tickerPosition: "bottom"
  property string tickerSpeed: "normal"
  property bool tickerPaused: false

  screen: root.targetScreen
  visible: !!root.targetScreen
  color: Color.background
  exclusionMode: ExclusionMode.Auto
  anchors.left: true
  anchors.right: true
  anchors.top: root.tickerPosition === "top"
  anchors.bottom: root.tickerPosition !== "top"
  implicitHeight: root.tickerHeight
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
    onPauseToggled: root.tickerPaused = !root.tickerPaused
    onPrimaryActionRequested: if (root.hostWidget) root.hostWidget.open()
  }
}

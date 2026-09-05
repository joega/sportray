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

  screen: root.targetScreen
  visible: !!root.targetScreen
  color: Color.background
  exclusionMode: ExclusionMode.Auto
  anchors { bottom: true; left: true; right: true }
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
    onPrimaryActionRequested: if (root.hostWidget) root.hostWidget.open()
  }
}

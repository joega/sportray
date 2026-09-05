import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "../model/TicketOverlayPolicy.js" as TicketOverlayPolicy

PanelWindow {
  id: root

  required property QtObject bar
  required property var targetScreen
  property bool panelOpen: false
  property real screenWidth: root.targetScreen ? root.targetScreen.width : 0
  property real screenHeight: root.targetScreen ? root.targetScreen.height : 0
  property real barSize: bar ? Number(bar.barSize || 0) : 0
  property var hostWidget: null
  property var ticketGame: null
  property string ticketState: "empty"
  property string label: ""
  property string errorCode: ""
  property string position: bar ? String(bar.position || "top") : "top"
  property int ticketWidth: Style.space(640)
  property int ticketHeight: Style.space(96)
  property int overlayMargin: 0

  screen: root.targetScreen
  visible: !!root.targetScreen && !root.panelOpen
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  anchors { top: true; bottom: true; left: true; right: true }
  WlrLayershell.namespace: "io.github.joega.sportray-ticket"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  mask: Region { item: card }

  // Keep the policy beside the shell so top and bottom geometry remain
  // deterministic even when the host bar has internal centering offsets.
  readonly property var ticketGeometry: TicketOverlayPolicy.geometry({
    position: root.position,
    screenWidth: root.screenWidth,
    screenHeight: root.screenHeight,
    barHeight: root.barSize,
    width: root.ticketWidth,
    height: root.ticketHeight,
    margin: root.overlayMargin,
    gap: 0,
    x: root.screenWidth / 2 - root.ticketWidth / 2
  })

  BorderSurface {
    id: card
    x: root.ticketGeometry.x
    y: root.ticketGeometry.y
    width: root.ticketWidth
    height: root.ticketHeight
    color: Color.popups.background
    borderSpec: Border.none()
    padding: 0

    TicketStrip {
      anchors.fill: parent
      leagueId: root.ticketGame && root.ticketGame.league
        ? String(root.ticketGame.league) : "following"
      game: root.ticketGame
      ticketState: root.ticketState
      label: root.label
      errorCode: root.errorCode
      compact: true
      onPrimaryActionRequested: if (root.hostWidget) root.hostWidget.open()
    }
  }
}

import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "../model/TicketOverlayPolicy.js" as TicketOverlayPolicy

KeyboardPanel {
  id: root

  required property Item anchorItem
  required property QtObject bar
  property string position: bar ? String(bar.position || "top") : "top"
  property int ticketWidth: Style.space(640)
  property int ticketHeight: Style.space(96)
  property int overlayMargin: 0

  owner: root
  open: true
  margin: root.overlayMargin
  gap: 0
  borderSpec: Border.none()
  centerOnBar: true
  contentWidth: root.ticketWidth
  contentHeight: root.ticketHeight

  // Keep the policy beside the shell so top and bottom geometry remain
  // deterministic even when the host bar has internal centering offsets.
  readonly property var ticketGeometry: TicketOverlayPolicy.geometry({
    position: root.position,
    screenWidth: root.screenW,
    screenHeight: root.screenH,
    barHeight: root.barH,
    width: root.contentWidth,
    height: root.contentHeight,
    margin: root.margin,
    gap: root.gap,
    x: root.screenW / 2 - root.contentWidth / 2
  })
}

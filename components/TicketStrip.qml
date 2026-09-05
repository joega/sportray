import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "../model/TicketPresentation.js" as TicketPresentation
import "../model/TicketLayout.js" as TicketLayout

Item {
  id: root

  property string leagueId: "following"
  property var game: null
  property string ticketState: ""
  property string label: ""
  property string errorCode: ""
  property bool compact: false
  property bool reducedMotion: false

  signal primaryActionRequested()

  readonly property var ticket: TicketPresentation.project({
    game: root.game,
    state: root.ticketState,
    league: root.leagueId,
    label: root.label,
    errorCode: root.errorCode
  })
  readonly property var ticketGeometry: TicketLayout.layout({
    width: root.width,
    padding: Style.spacing.md,
    gap: Style.spacing.sm,
    leading: Style.space(24),
    trailing: sourceButton.implicitWidth
  })

  width: parent ? parent.width : Style.space(640)
  height: Style.space(96)
  implicitHeight: height
  clip: true

  SportAtmosphere {
    anchors.fill: parent
    leagueId: root.leagueId
    reducedMotion: root.reducedMotion
  }

  Row {
    anchors.fill: parent
    anchors.margins: Style.spacing.md
    spacing: Style.spacing.sm

    SemanticIcon {
      width: Style.space(24)
      height: width
      anchors.verticalCenter: parent.verticalCenter
      iconName: "neutral"
      fontSize: Style.font.subtitle
      color: Color.accent
      decorative: true
    }

    TicketGameCard {
      width: Math.max(0, parent.width - sourceButton.implicitWidth - parent.spacing - Style.space(24))
      height: parent.height
      ticket: root.ticket
      compact: root.compact
      onPrimaryActionRequested: root.primaryActionRequested()
    }

    SemanticActionButton {
      id: sourceButton
      anchors.verticalCenter: parent.verticalCenter
      text: "Open"
      tooltipText: "Open game page"
      textFontSize: Style.font.bodySmall
      textHorizontalPadding: Style.spacing.xs
      textVerticalPadding: Style.spacing.xs
      focusable: true
      enabled: root.ticket && root.ticket.game && root.ticket.game.link
      onClicked: if (enabled) Quickshell.execDetached(["omarchy-launch-browser", root.ticket.game.link])
    }
  }
}

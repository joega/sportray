import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  required property var ticket
  property bool selected: false
  property bool compact: false

  signal primaryActionRequested()

  readonly property bool hasGame: root.ticket && root.ticket.game
  readonly property bool childActionPressed: sourceLink.pointerPressed
  readonly property string accessibleLabel: root.ticket
    ? root.ticket.label + ". " + root.ticket.status
      + (root.ticket.kind === "offline" ? ". Scores unavailable." : ".")
    : "Sports score"

  width: parent ? parent.width : implicitWidth
  implicitHeight: card.height
  height: implicitHeight

  function activatePrimaryAction() {
    if (root.hasGame) root.primaryActionRequested()
  }

  Accessible.name: root.accessibleLabel
  Accessible.role: root.hasGame ? Accessible.Button : Accessible.StaticText
  Accessible.onPressAction: root.activatePrimaryAction()

  Rectangle {
    id: card
    width: parent.width
    height: content.implicitHeight + Style.spacing.md * 2
    color: Color.popups.background
    border.width: root.selected ? Style.space(2) : Style.space(1)
    border.color: root.selected ? Color.accent : Color.popups.border
    radius: Style.cornerRadius
    clip: true

    Rectangle {
      anchors.fill: parent
      color: root.hasGame && root.ticket.game.homeTeam
        && root.ticket.game.homeTeam.primaryColor
        ? root.ticket.game.homeTeam.primaryColor : "transparent"
      opacity: color !== "transparent" ? 0.10 : 0
    }

    Column {
      id: content
      anchors.fill: parent
      anchors.margins: Style.spacing.md
      spacing: Style.spacing.xs

      Row {
        width: parent.width
        spacing: Style.spacing.sm

        Text {
          width: Math.max(0, parent.width - scoreLabel.implicitWidth - parent.spacing)
          text: root.ticket ? root.ticket.label : "Sportray"
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: root.compact ? Style.font.body : Style.font.subtitle
          font.bold: true
          elide: Text.ElideRight
        }

        Text {
          id: scoreLabel
          text: root.ticket ? root.ticket.score : "VS"
          color: root.ticket && root.ticket.kind === "live" ? Color.urgent : Color.accent
          font.family: Style.font.family
          font.pixelSize: root.compact ? Style.font.subtitle : Style.font.display
          font.bold: true
        }
      }

      Row {
        width: parent.width
        spacing: Style.spacing.xs

        Text {
          width: Math.max(0, parent.width - sourceLink.implicitWidth - parent.spacing)
          text: root.ticket ? root.ticket.status : "No games"
          color: root.ticket && root.ticket.kind === "offline" ? Color.urgent : Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          elide: Text.ElideRight
        }

        SourceLinkButton {
          id: sourceLink
          game: root.hasGame ? root.ticket.game : ({link: ""})
          visible: root.hasGame && game.link
          Accessible.name: visible ? "Open " + sourceLink.sourceName + " game page" : "External game page unavailable"
        }
      }
    }
  }

  TapHandler {
    enabled: root.hasGame && !root.childActionPressed
    onTapped: root.activatePrimaryAction()
  }
}

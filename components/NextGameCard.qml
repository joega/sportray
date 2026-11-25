import QtQuick
import qs.Commons as Commons
import qs.Ui
import "../model/DateModel.js" as DateModel
import "../model/Formatters.js" as Formatters
import "../model/UiTypography.js" as Typography

// The same matchup surface used by details, with the existing explicit day/source actions.
Item {
  id: root
  required property var game
  required property string dateKey
  property var imageStore: null
  property double currentTime: Date.now()
  signal jumpRequested()
  signal primaryActionRequested()
  readonly property bool childActionPressed: sourceLink.pointerPressed || jumpButton.pointerPressed
  readonly property string venueName: root.game.venue || ""
  PresentationTokens { id: visual }

  function activatePrimaryAction() { root.jumpRequested() }
  implicitHeight: card.height
  width: parent ? parent.width : implicitWidth
  Accessible.name: "Next game: " + Formatters.teamLabel(root.game.awayTeam)
    + " versus " + Formatters.teamLabel(root.game.homeTeam) + " on "
    + DateModel.shortDateLabel(root.dateKey) + ". "
    + (root.venueName ? "At " + root.venueName + ". " : "") + "View day."
  Accessible.role: Accessible.Button
  Accessible.onPressAction: root.activatePrimaryAction()

  BorderSurface {
    id: card
    width: parent.width
    height: cardColumn.implicitHeight + Commons.Style.spacing.md
    color: visual.feature
    borderSpec: Commons.Border.none()
    radius: visual.featureRadius
    clip: true
    Column {
      id: cardColumn
      width: parent.width
      spacing: Commons.Style.spacing.sm
      MatchupScoreboard {
        width: parent.width
        game: root.game
        imageStore: root.imageStore
        currentTime: root.currentTime
        teamLinksEnabled: false
        kickerText: "Next game" + (root.venueName ? " · " + root.venueName : "")
        dateText: DateModel.shortDateLabel(root.dateKey)
        showStatus: root.game.status !== "scheduled"
      }
      Rectangle {
        x: Commons.Style.spacing.lg
        width: parent.width - x * 2
        height: 1
        color: visual.line
      }
      Row {
        anchors.right: parent.right
        anchors.rightMargin: Commons.Style.spacing.md
        spacing: Commons.Style.spacing.sm
        SourceLinkButton { id: sourceLink; game: root.game }
        SemanticActionButton {
          id: jumpButton
          text: "View day"
          tooltipText: "Jump to the next game"
          textFontSize: Commons.Style.font.bodySmall
          foreground: visual.accent
          focusable: true
          onClicked: root.jumpRequested()
          Accessible.name: "View " + DateModel.shortDateLabel(root.dateKey)
        }
      }
    }
  }
}

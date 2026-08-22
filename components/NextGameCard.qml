import QtQuick
import qs.Commons
import qs.Ui
import "../model/DateModel.js" as DateModel
import "../model/Formatters.js" as Formatters

Item {
  id: root

  required property var game
  required property string dateKey

  signal jumpRequested()
  signal primaryActionRequested()
  readonly property bool childActionPressed: sourceLink.pointerPressed || jumpButton.pointerPressed

  function teamName(team) {
    if (!team) return "TBD"
    return team.name || team.shortName || team.abbreviation || "TBD"
  }

  function localStartTime(value) {
    if (typeof value !== "string") return "Time unavailable"
    var date = new Date(value)
    if (isNaN(date.getTime())) return "Time unavailable"
    return Qt.formatDateTime(date, "h:mm AP")
  }

  readonly property bool hasHomeTint: Boolean(root.game.homeTeam
    && root.game.homeTeam.primaryColor)
  readonly property color homeTint: root.hasHomeTint
    ? root.game.homeTeam.primaryColor : "transparent"
  readonly property string venueName: root.game.venue || ""

  implicitHeight: card.height
  width: parent ? parent.width : implicitWidth

  function activatePrimaryAction() {
    root.jumpRequested()
  }

  Accessible.name: "Next game: " + Formatters.teamLabel(root.game.awayTeam)
    + " versus " + Formatters.teamLabel(root.game.homeTeam) + " on "
    + DateModel.shortDateLabel(root.dateKey) + ". "
    + (root.venueName ? "At " + root.venueName + ". " : "") + "View day."
  Accessible.role: Accessible.Button

  BorderSurface {
    id: card
    width: parent.width
    height: cardColumn.implicitHeight + Style.spacing.md * 2
    color: Util.alpha(Color.popups.background, 0.86)
    borderSpec: Border.controlSpec("selected", Color.popups.text, Color.accent)
    radius: Style.cornerRadius
    clip: true

    Rectangle {
      anchors.fill: parent
      color: root.homeTint
      opacity: root.hasHomeTint ? 0.09 : 0
    }

    Rectangle {
      width: Math.max(Style.space(3), Style.spacing.xs)
      height: parent.height
      color: Color.accent
    }

    Column {
      id: cardColumn
      anchors.fill: parent
      anchors.leftMargin: Style.spacing.lg
      anchors.rightMargin: Style.spacing.md
      anchors.topMargin: Style.spacing.md
      anchors.bottomMargin: Style.spacing.md
      spacing: Style.spacing.sm

      Row {
        width: parent.width
        spacing: Style.spacing.sm

        SemanticIcon {
          width: Style.space(20)
          height: width
          iconName: "calendar"
          fontSize: Style.font.body
          color: Color.accent
        }

        Column {
          width: parent.width - Style.space(20) - parent.spacing
          spacing: Style.spacing.xxs

          Text {
            text: "NEXT GAME"
            color: Color.accent
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Text {
            text: DateModel.shortDateLabel(root.dateKey)
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.subtitle
            font.bold: true
          }
        }

      }

      Row {
        width: parent.width
        height: Math.max(Style.space(54), awayColumn.implicitHeight)
        spacing: Style.spacing.sm

        Column {
          id: awayColumn
          width: (parent.width - vsLabel.implicitWidth - parent.spacing * 2) / 2
          spacing: Style.spacing.xxs

          Text {
            width: parent.width
            text: Formatters.teamLabel(root.game.awayTeam)
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.subtitle
            font.bold: true
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            text: root.teamName(root.game.awayTeam)
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
          }

          Text {
            text: "AWAY"
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
          }
        }

        Text {
          id: vsLabel
          anchors.verticalCenter: parent.verticalCenter
          text: "VS"
          color: Color.accent
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
        }

        Column {
          width: (parent.width - vsLabel.implicitWidth - parent.spacing * 2) / 2
          spacing: Style.spacing.xxs

          Text {
            width: parent.width
            text: Formatters.teamLabel(root.game.homeTeam)
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.subtitle
            font.bold: true
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            text: root.teamName(root.game.homeTeam)
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
          }

          Text {
            text: "HOME"
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
          }
        }
      }

      Row {
        width: parent.width
        spacing: Style.spacing.sm

        Text {
          id: startTimeLabel
          anchors.verticalCenter: parent.verticalCenter
          text: root.localStartTime(root.game.startTime)
            + (root.venueName ? "   ·   " + root.venueName : "")
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
        }

        Item {
          width: Math.max(0, parent.width - startTimeLabel.implicitWidth
            - sourceLink.implicitWidth - jumpButton.implicitWidth - parent.spacing * 2)
          height: 1
        }

        SourceLinkButton {
          id: sourceLink
          game: root.game
        }

        SemanticActionButton {
          id: jumpButton
          text: "View day"
          tooltipText: "Jump to the next game"
          textBold: true
          textFontSize: Style.font.bodySmall
          textHorizontalPadding: Style.spacing.md
          textVerticalPadding: Style.spacing.xs
          focusable: true
          onClicked: root.jumpRequested()
          Accessible.name: "View " + DateModel.shortDateLabel(root.dateKey)
          Accessible.role: Accessible.Button
        }
      }
    }
  }
}

import QtQuick
import "../model/UiTypography.js" as Typography
import "../model/UiContrast.js" as UiContrast
import qs.Commons as Commons
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
  readonly property var paintedBackground: UiContrast.composite(
    Qt.alpha(root.homeTint, root.hasHomeTint ? 0.09 : 0),
    UiContrast.composite(card.color, Commons.Color.popups.background))

  function readable(preferred) {
    return UiContrast.foreground(preferred, Commons.Color.popups.text, root.paintedBackground)
  }

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
  Accessible.onPressAction: root.activatePrimaryAction()

  BorderSurface {
    id: card
    width: parent.width
    height: cardColumn.implicitHeight + Commons.Style.spacing.md * 2
    color: Commons.Util.alpha(Commons.Color.popups.background, 0.86)
    borderSpec: Commons.Border.controlSpec("selected", Commons.Color.popups.text, Commons.Color.accent)
    radius: Commons.Style.cornerRadius
    clip: true

    Rectangle {
      anchors.fill: parent
      color: root.homeTint
      opacity: root.hasHomeTint ? 0.09 : 0
    }

    Rectangle {
      width: Math.max(Commons.Style.space(3), Commons.Style.spacing.xs)
      height: parent.height
      color: Commons.Color.accent
    }

    Column {
      id: cardColumn
      anchors.fill: parent
      anchors.leftMargin: Commons.Style.spacing.lg
      anchors.rightMargin: Commons.Style.spacing.md
      anchors.topMargin: Commons.Style.spacing.md
      anchors.bottomMargin: Commons.Style.spacing.md
      spacing: Commons.Style.spacing.sm

      Row {
        width: parent.width
        spacing: Commons.Style.spacing.sm

        SemanticIcon {
          width: Commons.Style.space(20)
          height: width
          iconName: "calendar"
          fontSize: Commons.Style.font.body
          color: Commons.Color.accent
        }

        Column {
          width: parent.width - Commons.Style.space(20) - parent.spacing
          spacing: Commons.Style.spacing.xxs

          Text {
            textFormat: Text.PlainText
            text: "NEXT GAME"
            color: root.readable(Commons.Color.accent)
            font.family: Typography.family
            font.pixelSize: Commons.Style.font.caption
            font.bold: true
          }

          Text {
            textFormat: Text.PlainText
            text: DateModel.shortDateLabel(root.dateKey)
            color: Commons.Color.popups.text
            font.family: Typography.family
            font.pixelSize: Commons.Style.font.subtitle
            font.bold: true
          }
        }

      }

      Row {
        width: parent.width
        height: Math.max(Commons.Style.space(54), awayColumn.implicitHeight)
        spacing: Commons.Style.spacing.sm

        Column {
          id: awayColumn
          width: (parent.width - vsLabel.implicitWidth - parent.spacing * 2) / 2
          spacing: Commons.Style.spacing.xxs

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: Formatters.teamLabel(root.game.awayTeam)
            color: Commons.Color.popups.text
            font.family: Typography.family
            font.pixelSize: Commons.Style.font.subtitle
            font.bold: true
            elide: Text.ElideRight
          }

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: root.teamName(root.game.awayTeam)
            color: root.readable(Qt.alpha(Commons.Color.popups.text, 0.85))
            font.family: Typography.family
            font.pixelSize: Commons.Style.font.bodySmall
            elide: Text.ElideRight
          }

          Text {
            textFormat: Text.PlainText
            text: "AWAY"
            color: root.readable(Qt.alpha(Commons.Color.popups.text, 0.85))
            font.family: Typography.family
            font.pixelSize: Commons.Style.font.caption
          }
        }

        Text {
          textFormat: Text.PlainText
          id: vsLabel
          anchors.verticalCenter: parent.verticalCenter
          text: "VS"
          color: root.readable(Commons.Color.accent)
          font.family: Typography.family
          font.pixelSize: Commons.Style.font.caption
          font.bold: true
        }

        Column {
          width: (parent.width - vsLabel.implicitWidth - parent.spacing * 2) / 2
          spacing: Commons.Style.spacing.xxs

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: Formatters.teamLabel(root.game.homeTeam)
            color: Commons.Color.popups.text
            font.family: Typography.family
            font.pixelSize: Commons.Style.font.subtitle
            font.bold: true
            elide: Text.ElideRight
          }

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: root.teamName(root.game.homeTeam)
            color: root.readable(Qt.alpha(Commons.Color.popups.text, 0.85))
            font.family: Typography.family
            font.pixelSize: Commons.Style.font.bodySmall
            elide: Text.ElideRight
          }

          Text {
            textFormat: Text.PlainText
            text: "HOME"
            color: root.readable(Qt.alpha(Commons.Color.popups.text, 0.85))
            font.family: Typography.family
            font.pixelSize: Commons.Style.font.caption
          }
        }
      }

      Column {
        width: parent.width
        spacing: Commons.Style.spacing.sm
        Text {
          id: startTimeLabel
          width: parent.width
          text: root.localStartTime(root.game.startTime)
            + (root.venueName ? "   ·   " + root.venueName : "")
          textFormat: Text.PlainText
          color: root.readable(Qt.alpha(Commons.Color.popups.text, 0.85))
          font.family: Typography.family
          font.pixelSize: Commons.Style.font.bodySmall
          wrapMode: Text.WordWrap
        }
        Row {
          anchors.right: parent.right
          spacing: Commons.Style.spacing.sm
          SourceLinkButton {
            id: sourceLink
            game: root.game
          }
          SemanticActionButton {
            id: jumpButton
            text: "View day"
            tooltipText: "Jump to the next game"
            textFontSize: Commons.Style.font.bodySmall
            focusable: true
            onClicked: root.jumpRequested()
            Accessible.name: "View " + DateModel.shortDateLabel(root.dateKey)
          }
        }
      }
    }
  }
}

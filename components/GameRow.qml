import QtQuick
import qs.Commons
import qs.Ui
import "../model/Formatters.js" as Formatters
import "../model/GameRowLayout.js" as GameRowLayout

Item {
  id: root

  required property var game
  property bool stale: false
  property bool featured: false
  property bool selected: false
  readonly property bool childActionPressed: sourceLink.pointerPressed

  signal primaryActionRequested()

  width: parent ? parent.width : implicitWidth
  implicitHeight: card.height
  height: implicitHeight

  function localStartDateTime(value) {
    if (typeof value !== "string") return ""
    var date = new Date(value)
    if (isNaN(date.getTime())) return ""
    return Qt.formatDateTime(date, "MMM d, h:mm AP")
  }

  readonly property string awayLabel: Formatters.teamLabel(root.game.awayTeam)
  readonly property string homeLabel: Formatters.teamLabel(root.game.homeTeam)
  readonly property string awayScoreLabel: Formatters.formatScoreboardTeamScore(root.game, "away")
  readonly property string homeScoreLabel: Formatters.formatScoreboardTeamScore(root.game, "home")
  readonly property string detailLabel: Formatters.formatGameStateLabel(root.game, {
    includeStartTime: true,
    startTimeText: root.localStartDateTime(root.game.startTime),
    stale: root.stale
  })
  readonly property bool awayIsFavorite: Boolean(root.game.presentation
    && root.game.presentation.awayIsFavorite)
  readonly property bool homeIsFavorite: Boolean(root.game.presentation
    && root.game.presentation.homeIsFavorite)
  readonly property bool favorite: root.awayIsFavorite || root.homeIsFavorite
  readonly property bool live: root.game.status === "live" || root.game.status === "intermission"
  readonly property bool unavailable: root.game.status === "malformed" || root.game.status === "unknown"
  readonly property bool showLeagueContext: Boolean(root.game.presentation
    && root.game.presentation.showLeagueContext)
  readonly property string leagueLabel: root.game.presentation
    && root.game.presentation.leagueLabel ? root.game.presentation.leagueLabel : ""
  readonly property string stateLabel: root.detailLabel
  readonly property string venueName: root.game.venue || ""
  readonly property string detailWithVenueLabel: root.detailLabel
    + (root.venueName ? "   ·   " + root.venueName : "")
  readonly property bool hasHomeTint: Boolean(root.game.homeTeam
    && root.game.homeTeam.primaryColor)
  readonly property color homeTint: root.hasHomeTint
    ? root.game.homeTeam.primaryColor : "transparent"
  readonly property string accessibleLabel: root.awayLabel + " " + root.awayScoreLabel
    + " at " + root.homeLabel + " " + root.homeScoreLabel + ". "
    + (root.awayIsFavorite ? "Followed away team. " : "")
    + (root.homeIsFavorite ? "Followed home team. " : "")
    + root.stateLabel + ". " + (root.venueName ? "At " + root.venueName + ". " : "")
    + (root.showLeagueContext ? root.leagueLabel + ". " : "")
    + (root.game.link ? "Open external game page." : "External game page unavailable.")

  function activatePrimaryAction() {
    if (sourceLink.visible) sourceLink.openSource()
  }

  Accessible.name: root.accessibleLabel
  Accessible.description: root.detailLabel
  Accessible.role: Accessible.Button
  readonly property real logoSize: Style.space(root.featured ? 28 : 22)
  readonly property real scoreColumnWidth: Style.space(root.featured ? 58 : 52)

  BorderSurface {
    id: card
    width: parent.width
    clip: true
    height: row.implicitHeight + Style.spacing.md * 2
    color: root.featured ? Style.selectedFillFor(Color.popups.text, Color.accent)
      : Color.popups.background
    borderSpec: root.selected
      ? Border.controlSpec("focus", Color.popups.text, Color.accent)
      : root.featured
      ? Border.controlSpec("selected", Color.popups.text, Color.accent)
      : Border.controlSpec("normal", Color.popups.text, Color.popups.border)
    radius: Style.cornerRadius

    Rectangle {
      anchors.fill: parent
      color: root.homeTint
      opacity: root.hasHomeTint ? (root.featured ? 0.07 : 0.11) : 0
    }

    Column {
      id: row
      anchors.fill: parent
      anchors.margins: Style.spacing.md
      spacing: Style.spacing.xs

      Row {
        width: parent.width
        height: Math.max(root.logoSize, awayLabelText.implicitHeight)
        spacing: Style.spacing.sm

        Item {
          width: parent.width - root.scoreColumnWidth - parent.spacing
          height: parent.height

          Image {
            id: awayLogo
            width: root.logoSize
            height: root.logoSize
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            source: root.game.awayTeam && root.game.awayTeam.logoUrl
              ? root.game.awayTeam.logoUrl : ""
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            visible: status === Image.Ready
          }

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: root.logoSize
            text: root.awayLabel.slice(0, 3)
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            visible: !awayLogo.visible
          }

          Text {
            id: awayFavoriteMarker
            anchors.left: parent.left
            anchors.leftMargin: root.logoSize + Style.spacing.xs
            anchors.verticalCenter: parent.verticalCenter
            width: root.awayIsFavorite ? Style.space(14) : 0
            text: root.awayIsFavorite ? "★" : ""
            color: Color.accent
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            visible: root.awayIsFavorite
          }

          Text {
            id: awayLabelText
            anchors.left: parent.left
            anchors.leftMargin: root.logoSize + Style.spacing.xs
              + (root.awayIsFavorite ? Style.space(14) + Style.spacing.xs : 0)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.awayLabel
            color: Formatters.isWinningTeam(root.game, "away")
              ? Color.accent : Color.popups.text
            font.family: Style.font.family
            font.pixelSize: root.featured ? Style.font.subtitle : Style.font.body
            font.bold: root.awayIsFavorite || Formatters.isWinningTeam(root.game, "away")
            font.underline: root.awayIsFavorite
            elide: Text.ElideRight
          }
        }

        Text {
          width: root.scoreColumnWidth
          text: root.awayScoreLabel
          color: root.live ? Color.urgent : Color.popups.text
          font.family: Style.font.family
          font.pixelSize: root.featured ? Style.font.display : Style.font.subtitle
          font.bold: true
          horizontalAlignment: Text.AlignRight
          verticalAlignment: Text.AlignVCenter
        }
      }

      Row {
        width: parent.width
        height: Math.max(root.logoSize, homeLabelText.implicitHeight)
        spacing: Style.spacing.sm

        Item {
          width: parent.width - root.scoreColumnWidth - parent.spacing
          height: parent.height

          Image {
            id: homeLogo
            width: root.logoSize
            height: root.logoSize
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            source: root.game.homeTeam && root.game.homeTeam.logoUrl
              ? root.game.homeTeam.logoUrl : ""
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            visible: status === Image.Ready
          }

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: root.logoSize
            text: root.homeLabel.slice(0, 3)
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            visible: !homeLogo.visible
          }

          Text {
            id: homeFavoriteMarker
            anchors.left: parent.left
            anchors.leftMargin: root.logoSize + Style.spacing.xs
            anchors.verticalCenter: parent.verticalCenter
            width: root.homeIsFavorite ? Style.space(14) : 0
            text: root.homeIsFavorite ? "★" : ""
            color: Color.accent
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            visible: root.homeIsFavorite
          }

          Text {
            id: homeLabelText
            anchors.left: parent.left
            anchors.leftMargin: root.logoSize + Style.spacing.xs
              + (root.homeIsFavorite ? Style.space(14) + Style.spacing.xs : 0)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.homeLabel
            color: Formatters.isWinningTeam(root.game, "home")
              ? Color.accent : Color.popups.text
            font.family: Style.font.family
            font.pixelSize: root.featured ? Style.font.subtitle : Style.font.body
            font.bold: root.homeIsFavorite || Formatters.isWinningTeam(root.game, "home")
            font.underline: root.homeIsFavorite
            horizontalAlignment: Text.AlignLeft
            elide: Text.ElideRight
          }
        }

        Text {
          width: root.scoreColumnWidth
          text: root.homeScoreLabel
          color: root.live ? Color.urgent : Color.popups.text
          font.family: Style.font.family
          font.pixelSize: root.featured ? Style.font.display : Style.font.subtitle
          font.bold: true
          horizontalAlignment: Text.AlignRight
          verticalAlignment: Text.AlignVCenter
        }
      }

      Item {
        id: footer
        width: parent.width
        implicitHeight: Math.max(detailText.implicitHeight, sourceLink.implicitHeight)
        height: implicitHeight

        readonly property var footerGeometry: GameRowLayout.footerLayout(
          width,
          root.showLeagueContext && root.leagueLabel !== ""
            ? leagueContextText.implicitWidth : 0,
          root.favorite ? Style.space(14) : 0,
          sourceLink.visible ? sourceLink.implicitWidth : 0,
          Style.spacing.xs,
          Style.space(1))

        Item {
          id: footerContent
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.right: sourceLink.visible ? sourceLink.left : parent.right
          anchors.rightMargin: sourceLink.visible ? Style.spacing.xs : 0

          Row {
            id: footerMeta
            anchors.fill: parent
            spacing: Style.spacing.xs

            Text {
              id: leagueContextText
              visible: root.showLeagueContext && root.leagueLabel !== ""
                && footer.footerGeometry.contextWidth > 0
              width: footer.footerGeometry.contextWidth
              text: root.showLeagueContext && root.leagueLabel !== ""
                ? root.leagueLabel + " ·" : ""
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              elide: Text.ElideRight
            }

            SemanticIcon {
              visible: root.favorite && footer.footerGeometry.favoriteWidth > 0
              width: footer.footerGeometry.favoriteWidth
              height: Style.space(14)
              iconName: "star"
              fontSize: Style.font.bodySmall
              color: Color.accent
              decorative: true
            }

            Text {
              id: detailText
              width: footer.footerGeometry.detailWidth
              text: root.detailWithVenueLabel
              color: root.unavailable || root.stale || root.live
                || root.game.status === "postponed" || root.game.status === "canceled"
                ? Color.urgent : Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              font.bold: root.live || root.featured || root.stale
              elide: Text.ElideRight
            }
          }
        }

        SourceLinkButton {
          id: sourceLink
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          game: root.game
          Accessible.name: root.game.link ? "Open " + sourceLink.sourceName + " game page" : "External game page unavailable"
        }
      }

    }
  }
}

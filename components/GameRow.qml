import QtQuick
import "../model/UiTypography.js" as Typography
import qs.Commons
import qs.Ui
import "../model/Formatters.js" as Formatters

Item {
  id: root

  required property var game
  property var settingsStore: null
  property var imageStore: null
  readonly property string awayLogoSource: root.imageStore && root.game.awayTeam && root.game.awayTeam.logoUrl
    ? root.imageStore.sourceFor(root.game.awayTeam.logoUrl) : ""
  readonly property string homeLogoSource: root.imageStore && root.game.homeTeam && root.game.homeTeam.logoUrl
    ? root.imageStore.sourceFor(root.game.homeTeam.logoUrl) : ""
  property double currentTime: Date.now()
  property bool stale: false
  property bool featured: false
  property bool selected: false
  // Calendar rows pass an explicit bounded local-time label; the scoreboard
  // route keeps its own computed local start text.
  property string startTimeTextOverride: ""
  readonly property bool childActionPressed: sourceLink.pointerPressed || watchAction.pointerPressed

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

  function resolvedStartTimeText(value) {
    var override = root.startTimeTextOverride.trim()
    return override !== "" ? override : root.localStartDateTime(value)
  }

  readonly property string awayLabel: Formatters.teamLabel(root.game.awayTeam)
  readonly property string homeLabel: Formatters.teamLabel(root.game.homeTeam)
  readonly property string awayScoreLabel: Formatters.formatScoreboardTeamScore(root.game, "away")
  readonly property string homeScoreLabel: Formatters.formatScoreboardTeamScore(root.game, "home")
  readonly property string oddsSuffix: root.game
    && root.game.status === "scheduled" && root.game.odds
    && typeof root.game.odds.details === "string" && root.game.odds.details !== ""
    ? " · " + root.game.odds.details : ""
  readonly property string detailLabel: Formatters.formatGameStateLabel(root.game, {
    includeStartTime: root.game.status === "scheduled",
    startTimeText: root.resolvedStartTimeText(root.game.startTime),
    stale: root.stale
  }) + root.oddsSuffix
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
  readonly property string venueLabel: root.venueName ? "At " + root.venueName : ""
  readonly property string accessibleLabel: root.awayLabel + " " + root.awayScoreLabel
    + " at " + root.homeLabel + " " + root.homeScoreLabel + ". "
    + (root.awayIsFavorite ? "Followed away team. " : "")
    + (root.homeIsFavorite ? "Followed home team. " : "")
    + root.stateLabel + ". " + (root.venueName ? "At " + root.venueName + ". " : "")
    + (root.showLeagueContext ? root.leagueLabel + ". " : "")
    + (watchAction.active ? "Game is watched. " : "Game is not watched. ")
    + (root.game && root.game.isValid === true ? "View game details. " : "")
    + (root.game.link ? "Open external game page." : "External game page unavailable.")

  function activatePrimaryAction() {
    if (root.game && root.game.isValid === true) root.primaryActionRequested()
  }

  function openSource() {
    sourceLink.openSource()
  }

  Accessible.name: root.accessibleLabel
  Accessible.description: root.detailLabel
  Accessible.role: root.game && root.game.isValid === true ? Accessible.Button : Accessible.StaticText
  // The whole-row accessible action intentionally reuses the same guarded
  // local-detail route as the existing TapHandler/keyboard path; the nested
  // source button remains the only external-page route.
  Accessible.onPressAction: root.activatePrimaryAction()
  readonly property real logoSize: Style.space(24)
  readonly property real scoreColumnWidth: Style.space(58)

  BorderSurface {
    id: card
    width: parent.width
    clip: true
    height: row.implicitHeight + Style.spacing.md * 2
    color: "transparent"
    borderSpec: root.selected
      ? Border.controlSpec("focus", Color.popups.text, Color.accent)
      : Border.none()
    radius: 0

    Column {
      id: row
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Style.spacing.sm
      spacing: Style.spacing.xs

      Row {
        width: parent.width
        height: Math.max(root.logoSize, awayLabelText.implicitHeight)
        spacing: Style.spacing.sm

        Item {
          width: parent.width - root.scoreColumnWidth - parent.spacing
          height: parent.height

          Rectangle {
            anchors.fill: awayLogo
            anchors.margins: -Style.space(2)
            radius: Style.space(4)
            color: "#f5f5f5"
            visible: awayLogo.visible
          }

          Image {
            id: awayLogo
            width: root.logoSize
            height: root.logoSize
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            source: root.awayLogoSource
            sourceSize: Qt.size(root.logoSize * 2, root.logoSize * 2)
            cache: true
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            visible: status === Image.Ready
          }

          Text {
            textFormat: Text.PlainText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: root.logoSize
            text: root.awayLabel.slice(0, 3)
            color: Qt.alpha(Color.popups.text, 0.85)
            font.family: Typography.family
            font.pixelSize: Style.font.caption
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            visible: !awayLogo.visible
          }

          Text {
            textFormat: Text.PlainText
            id: awayFavoriteMarker
            anchors.left: parent.left
            anchors.leftMargin: root.logoSize + Style.spacing.xs
            anchors.verticalCenter: parent.verticalCenter
            width: root.awayIsFavorite ? Style.space(14) : 0
            text: root.awayIsFavorite ? "★" : ""
            color: Color.accent
            font.family: Typography.family
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
            textFormat: Text.PlainText
            color: Formatters.isWinningTeam(root.game, "away")
              ? Color.accent : Color.popups.text
            font.family: Typography.family
            font.pixelSize: Style.font.subtitle
            font.bold: root.awayIsFavorite || Formatters.isWinningTeam(root.game, "away")
            elide: Text.ElideRight
          }
        }

        Text {
          textFormat: Text.PlainText
          width: root.scoreColumnWidth
          text: root.awayScoreLabel
          color: Color.popups.text
          font.family: Typography.family
          font.pixelSize: Style.font.title
          font.features: ({"tnum": 1})
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

          Rectangle {
            anchors.fill: homeLogo
            anchors.margins: -Style.space(2)
            radius: Style.space(4)
            color: "#f5f5f5"
            visible: homeLogo.visible
          }

          Image {
            id: homeLogo
            width: root.logoSize
            height: root.logoSize
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            source: root.homeLogoSource
            sourceSize: Qt.size(root.logoSize * 2, root.logoSize * 2)
            cache: true
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            visible: status === Image.Ready
          }

          Text {
            textFormat: Text.PlainText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: root.logoSize
            text: root.homeLabel.slice(0, 3)
            color: Qt.alpha(Color.popups.text, 0.85)
            font.family: Typography.family
            font.pixelSize: Style.font.caption
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            visible: !homeLogo.visible
          }

          Text {
            textFormat: Text.PlainText
            id: homeFavoriteMarker
            anchors.left: parent.left
            anchors.leftMargin: root.logoSize + Style.spacing.xs
            anchors.verticalCenter: parent.verticalCenter
            width: root.homeIsFavorite ? Style.space(14) : 0
            text: root.homeIsFavorite ? "★" : ""
            color: Color.accent
            font.family: Typography.family
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
            textFormat: Text.PlainText
            color: Formatters.isWinningTeam(root.game, "home")
              ? Color.accent : Color.popups.text
            font.family: Typography.family
            font.pixelSize: Style.font.subtitle
            font.bold: root.homeIsFavorite || Formatters.isWinningTeam(root.game, "home")
            horizontalAlignment: Text.AlignLeft
            elide: Text.ElideRight
          }
        }

        Text {
          textFormat: Text.PlainText
          width: root.scoreColumnWidth
          text: root.homeScoreLabel
          color: Color.popups.text
          font.family: Typography.family
          font.pixelSize: Style.font.title
          font.features: ({"tnum": 1})
          font.bold: true
          horizontalAlignment: Text.AlignRight
          verticalAlignment: Text.AlignVCenter
        }
      }

      Column {
        id: footer
        width: parent.width
        spacing: Style.spacing.xxs

        Text {
          id: detailText
          width: parent.width
          text: (root.showLeagueContext && root.leagueLabel !== ""
            ? root.leagueLabel + " · " : "") + root.detailLabel
          textFormat: Text.PlainText
          color: root.unavailable || root.stale || root.game.status === "postponed"
            || root.game.status === "canceled" ? Color.urgent
            : root.live ? Color.accent : Qt.alpha(Color.popups.text, 0.85)
          font.family: Typography.family
          font.pixelSize: Style.font.bodySmall
          font.weight: root.live ? Font.DemiBold : Font.Normal
          wrapMode: Text.WordWrap
        }

        Row {
          id: actionsRow
          anchors.right: parent.right
          spacing: Style.spacing.sm

          WatchAction {
            id: watchAction
            game: root.game
            settingsStore: root.settingsStore
            currentTime: root.currentTime
          }

          SourceLinkButton {
            id: sourceLink
            game: root.game
            Accessible.name: root.game.link ? "Open " + sourceLink.sourceName + " game page" : "External game page unavailable"
          }
        }
      }
    }

    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: 1
      color: Color.popups.text
      opacity: 0.10
    }
  }
}

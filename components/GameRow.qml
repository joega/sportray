import QtQuick
import "../model/UiTypography.js" as Typography
import "../model/UiContrast.js" as UiContrast
import qs.Commons as Commons
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
  readonly property bool childActionPressed: gameActions.pointerPressed || awayLink.pointerPressed || homeLink.pointerPressed
  readonly property bool popupOpen: gameActions.popupOpen
  readonly property bool inputActive: gameActions.inputActive

  signal primaryActionRequested()
  signal teamScheduleRequested(string teamId)
  signal focusReturnRequested()

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
    stale: root.stale,
    now: root.currentTime
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
    + (root.awayIsFavorite ? "Favorite away team. " : "")
    + (root.homeIsFavorite ? "Favorite home team. " : "")
    + root.stateLabel + ". " + (root.venueName ? "At " + root.venueName + ". " : "")
    + (root.showLeagueContext ? root.leagueLabel + ". " : "")
    + (gameActions.alertsActive ? "Game alerts on. " : "")
    + (root.game && root.game.isValid === true ? "View game details. " : "")
    + (root.game.link ? "Open external game page." : "External game page unavailable.")

  function activatePrimaryAction() {
    if (root.game && root.game.isValid === true) root.primaryActionRequested()
  }

  function openSource() {
    gameActions.openSource()
  }

  function openActions() { gameActions.open() }
  function closeActions() { gameActions.close() }
  function focusActions() { return gameActions.focusTrigger() }
  function focusTeam(teamId) {
    var target = root.game.awayTeam && root.game.awayTeam.id === teamId ? awayLink
      : root.game.homeTeam && root.game.homeTeam.id === teamId ? homeLink : null
    if (!target || !target.available) return false
    target.forceActiveFocus()
    return true
  }

  Accessible.name: root.accessibleLabel
  Accessible.description: root.detailLabel
  Accessible.role: root.game && root.game.isValid === true ? Accessible.Button : Accessible.StaticText
  // The whole-row accessible action intentionally reuses the same guarded
  // local-detail route as the existing TapHandler/keyboard path; the nested
  // source button remains the only external-page route.
  Accessible.onPressAction: root.activatePrimaryAction()
  readonly property real logoSize: Commons.Style.space(20)
  readonly property real scoreColumnWidth: Commons.Style.space(44)

  BorderSurface {
    id: card
    width: parent.width
    clip: true
    height: row.implicitHeight + Commons.Style.space(12)
    color: "transparent"
    borderSpec: root.selected
      ? Commons.Border.controlSpec("focus", Commons.Color.popups.text, Commons.Color.accent)
      : Commons.Border.none()
    radius: 0

    Column {
      id: row
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Commons.Style.spacing.sm
      anchors.topMargin: Commons.Style.space(6)
      spacing: Commons.Style.spacing.xs

      Row {
        width: parent.width - gameActions.width - Commons.Style.spacing.xs
        height: Math.max(Commons.Style.space(24), awayLink.implicitHeight)
        spacing: Commons.Style.spacing.sm

        Item {
          width: parent.width - root.scoreColumnWidth - parent.spacing
          height: parent.height

          Rectangle {
            anchors.fill: awayLogo
            anchors.margins: -Commons.Style.space(2)
            radius: Commons.Style.space(4)
            color: awayLogo.visible ? "#f5f5f5" : Qt.alpha(Commons.Color.popups.text, 0.06)
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
            text: root.awayLabel.slice(0, 1)
            color: Qt.alpha(Commons.Color.popups.text, 0.85)
            font.family: Typography.family
            font.pixelSize: Commons.Style.font.caption
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            visible: !awayLogo.visible
          }

          Text {
            textFormat: Text.PlainText
            id: awayFavoriteMarker
            anchors.left: parent.left
            anchors.leftMargin: root.logoSize + Commons.Style.spacing.xs
            anchors.verticalCenter: parent.verticalCenter
            width: root.awayIsFavorite ? Commons.Style.space(14) : 0
            text: root.awayIsFavorite ? "★" : ""
            color: Commons.Color.accent
            font.family: Typography.family
            font.pixelSize: Commons.Style.font.bodySmall
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            visible: root.awayIsFavorite
          }

          TeamScheduleLink {
            id: awayLink
            anchors.left: parent.left
            anchors.leftMargin: root.logoSize + Commons.Style.spacing.xs
              + (root.awayIsFavorite ? Commons.Style.space(14) + Commons.Style.spacing.xs : 0)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            team: root.game.awayTeam
            text: root.awayLabel
            foreground: Formatters.isWinningTeam(root.game, "away")
              ? Commons.Color.accent : Commons.Color.popups.text
            fontSize: root.live ? Commons.Style.font.subtitle : Commons.Style.font.body
            bold: root.awayIsFavorite || Formatters.isWinningTeam(root.game, "away")
            onRequested: function(teamId) { root.teamScheduleRequested(teamId) }
          }
        }

        Text {
          textFormat: Text.PlainText
          width: root.scoreColumnWidth
          text: root.awayScoreLabel
          color: Commons.Color.popups.text
          font.family: Typography.family
          font.pixelSize: root.live ? Commons.Style.font.title : Commons.Style.font.subtitle
          font.features: ({"tnum": 1})
          font.bold: true
          horizontalAlignment: Text.AlignRight
          verticalAlignment: Text.AlignVCenter
        }
      }

      Row {
        width: parent.width - gameActions.width - Commons.Style.spacing.xs
        height: Math.max(Commons.Style.space(24), homeLink.implicitHeight)
        spacing: Commons.Style.spacing.sm

        Item {
          width: parent.width - root.scoreColumnWidth - parent.spacing
          height: parent.height

          Rectangle {
            anchors.fill: homeLogo
            anchors.margins: -Commons.Style.space(2)
            radius: Commons.Style.space(4)
            color: homeLogo.visible ? "#f5f5f5" : Qt.alpha(Commons.Color.popups.text, 0.06)
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
            text: root.homeLabel.slice(0, 1)
            color: Qt.alpha(Commons.Color.popups.text, 0.85)
            font.family: Typography.family
            font.pixelSize: Commons.Style.font.caption
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            visible: !homeLogo.visible
          }

          Text {
            textFormat: Text.PlainText
            id: homeFavoriteMarker
            anchors.left: parent.left
            anchors.leftMargin: root.logoSize + Commons.Style.spacing.xs
            anchors.verticalCenter: parent.verticalCenter
            width: root.homeIsFavorite ? Commons.Style.space(14) : 0
            text: root.homeIsFavorite ? "★" : ""
            color: Commons.Color.accent
            font.family: Typography.family
            font.pixelSize: Commons.Style.font.bodySmall
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            visible: root.homeIsFavorite
          }

          TeamScheduleLink {
            id: homeLink
            anchors.left: parent.left
            anchors.leftMargin: root.logoSize + Commons.Style.spacing.xs
              + (root.homeIsFavorite ? Commons.Style.space(14) + Commons.Style.spacing.xs : 0)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            team: root.game.homeTeam
            text: root.homeLabel
            foreground: Formatters.isWinningTeam(root.game, "home")
              ? Commons.Color.accent : Commons.Color.popups.text
            fontSize: root.live ? Commons.Style.font.subtitle : Commons.Style.font.body
            bold: root.homeIsFavorite || Formatters.isWinningTeam(root.game, "home")
            onRequested: function(teamId) { root.teamScheduleRequested(teamId) }
          }
        }

        Text {
          textFormat: Text.PlainText
          width: root.scoreColumnWidth
          text: root.homeScoreLabel
          color: Commons.Color.popups.text
          font.family: Typography.family
          font.pixelSize: root.live ? Commons.Style.font.title : Commons.Style.font.subtitle
          font.features: ({"tnum": 1})
          font.bold: true
          horizontalAlignment: Text.AlignRight
          verticalAlignment: Text.AlignVCenter
        }
      }

      Column {
        id: footer
        width: parent.width
        spacing: Commons.Style.spacing.xxs

        Text {
          id: detailText
          width: parent.width
          text: (root.showLeagueContext && root.leagueLabel !== ""
            ? root.leagueLabel + " · " : "") + root.detailLabel
            + (gameActions.alertsActive ? " · Alerts on" : "")
          textFormat: Text.PlainText
          color: root.unavailable || root.stale || root.game.status === "postponed"
            || root.game.status === "canceled" ? Commons.Color.urgent
            : root.live ? UiContrast.foreground(Commons.Color.accent, Commons.Color.popups.text, Commons.Color.popups.background)
            : Qt.alpha(Commons.Color.popups.text, 0.85)
          font.family: Typography.family
          font.pixelSize: Commons.Style.font.bodySmall
          font.weight: root.live ? Font.DemiBold : Font.Normal
          wrapMode: Text.WordWrap
        }


      }
    }

    GameActions {
      id: gameActions
      anchors.right: parent.right
      anchors.rightMargin: Commons.Style.spacing.sm
      y: Commons.Style.space(6) + Math.max(0, (Commons.Style.space(48) + Commons.Style.spacing.xs - height) / 2)
      width: implicitWidth
      height: implicitHeight
      game: root.game
      settingsStore: root.settingsStore
      currentTime: root.currentTime
      onTeamScheduleRequested: function(teamId) { root.teamScheduleRequested(teamId) }
      onFocusReturnRequested: root.focusReturnRequested()
    }

    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: 1
      color: Commons.Color.popups.text
      opacity: 0.10
    }
  }
}

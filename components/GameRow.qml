import QtQuick
import QtQuick.Window
import "../model/UiTypography.js" as Typography
import "../model/UiContrast.js" as UiContrast
import qs.Commons as Commons
import qs.Ui
import "../model/Formatters.js" as Formatters
import "../model/ScoreChangePresentation.js" as ScoreChangePresentation
import "../model/LifecyclePolicy.js" as LifecyclePolicy

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
  readonly property bool childActionPressed: gameActions.pointerPressed || featureDetails.pointerPressed
    || (root.featured ? featuredScoreboard.childActionPressed : awayLink.pointerPressed || homeLink.pointerPressed)
  readonly property bool popupOpen: gameActions.popupOpen
  readonly property bool inputActive: gameActions.inputActive
  property real awayScoreHighlight: 0
  property real homeScoreHighlight: 0
  property var scoreSnapshot: null
  property bool scoresInitialized: false
  property bool scoreReviewQueued: false
  readonly property var scoreCallbackOwner: LifecyclePolicy.createOwnerState()
  readonly property bool scorePulseAllowed: root.visible && root.Window.window !== null
    && root.Window.window.visible && !root.stale && !Commons.Style.reduceMotion

  function scoreOptions() {
    return {visible: root.scorePulseAllowed, stale: root.stale, reducedMotion: Commons.Style.reduceMotion}
  }
  function stopScorePulse() {
    awayScorePulse.stop()
    homeScorePulse.stop()
    root.awayScoreHighlight = 0
    root.homeScoreHighlight = 0
  }
  function queueScoreReview() {
    if (!root.scoresInitialized || root.scoreReviewQueued) return
    root.scoreReviewQueued = true
    var owner = root.scoreCallbackOwner
    var generation = owner.generation
    Qt.callLater(function() {
      if (!owner || owner.alive !== true || owner.generation !== generation) return
      root.scoreReviewQueued = false
      var result = ScoreChangePresentation.observe(root.scoreSnapshot, root.game, root.scoreOptions())
      if (!result.snapshot.eligible || !root.scoreSnapshot || root.scoreSnapshot.id !== result.snapshot.id)
        root.stopScorePulse()
      root.scoreSnapshot = result.snapshot
      if (result.awayChanged) { root.awayScoreHighlight = 1; awayScorePulse.restart() }
      if (result.homeChanged) { root.homeScoreHighlight = 1; homeScorePulse.restart() }
    })
  }
  onGameChanged: {
    if (root.scoresInitialized) {
      if (!root.game || !root.scoreSnapshot || root.game.id !== root.scoreSnapshot.id
          || !ScoreChangePresentation.snapshot(root.game, root.scoreOptions()).eligible) root.stopScorePulse()
      else {
        if (!ScoreChangePresentation.finiteScore(root.game.awayScore)) {
          awayScorePulse.stop(); root.awayScoreHighlight = 0
        }
        if (!ScoreChangePresentation.finiteScore(root.game.homeScore)) {
          homeScorePulse.stop(); root.homeScoreHighlight = 0
        }
      }
    }
    root.queueScoreReview()
  }
  onScorePulseAllowedChanged: if (root.scoresInitialized) {
    if (!root.scorePulseAllowed) {
      root.stopScorePulse()
      root.scoreSnapshot = ScoreChangePresentation.snapshot(root.game, root.scoreOptions())
    } else root.queueScoreReview()
  }
  Component.onCompleted: {
    root.scoresInitialized = true
    root.scoreSnapshot = ScoreChangePresentation.snapshot(root.game, root.scoreOptions())
  }
  Component.onDestruction: LifecyclePolicy.invalidate(root.scoreCallbackOwner)
  NumberAnimation {
    id: awayScorePulse
    target: root
    property: "awayScoreHighlight"
    from: 1
    to: 0
    duration: Commons.Style.duration(200)
    easing.type: Easing.OutCubic
  }
  NumberAnimation {
    id: homeScorePulse
    target: root
    property: "homeScoreHighlight"
    from: 1
    to: 0
    duration: Commons.Style.duration(200)
    easing.type: Easing.OutCubic
  }

  signal primaryActionRequested()
  signal teamScheduleRequested(string teamId)
  signal focusReturnRequested()

  width: parent ? parent.width : implicitWidth
  implicitHeight: root.featured ? featureColumn.implicitHeight : card.height
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
    if (root.featured) return featuredScoreboard.focusTeam(teamId)
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
  PresentationTokens { id: visual }

  Rectangle {
    anchors.fill: featureColumn
    visible: root.featured
    radius: visual.featureRadius
    color: visual.feature
    border.width: root.selected ? Math.max(1, Commons.Style.space(2)) : 0
    border.color: visual.accent
  }
  Column {
    id: featureColumn
    width: parent.width
    visible: root.featured
    spacing: 0
    MatchupScoreboard {
      id: featuredScoreboard
      width: parent.width
      game: root.game
      imageStore: root.imageStore
      currentTime: root.currentTime
      stale: root.stale
      selected: false
      awayScoreHighlight: root.awayScoreHighlight
      homeScoreHighlight: root.homeScoreHighlight
      onTeamScheduleRequested: function(teamId) { root.teamScheduleRequested(teamId) }
    }
    Rectangle { x: Commons.Style.space(14); width: parent.width-x*2; height: 1; color: visual.line }
    Item {
      id: featureFooter
      width: parent.width
      height: Math.max(featureDetails.implicitHeight, gameActions.implicitHeight) + Commons.Style.space(8)
      SemanticActionButton {
        id: featureDetails
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.rightMargin: gameActions.width + Commons.Style.spacing.sm
        anchors.verticalCenter: parent.verticalCenter
        text: "Game details  →"
        textBold: true
        textFontSize: Commons.Style.font.bodySmall
        foreground: visual.accent
        focusable: true
        tooltipText: root.game.isValid === true ? "View game details" : "Game details unavailable"
        enabled: root.game.isValid === true
        onClicked: root.activatePrimaryAction()
        Accessible.name: "View game details"
      }
    }
  }

  BorderSurface {
    id: card
    visible: !root.featured
    width: parent.width
    clip: true
    height: row.implicitHeight + Commons.Style.space(12)
    color: visual.surface
    borderSpec: root.selected
      ? Commons.Border.controlSpec("focus", Commons.Color.popups.text, Commons.Color.accent)
      : Commons.Border.none()
    radius: visual.radius

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
            text: root.game.awayTeam ? root.game.awayTeam.shortName || root.game.awayTeam.name || root.awayLabel : root.awayLabel
            foreground: visual.ink
            fontSize: visual.body
            bold: root.awayIsFavorite || Formatters.isWinningTeam(root.game, "away")
            onRequested: function(teamId) { root.teamScheduleRequested(teamId) }
          }
        }

        Text {
          id: awayScoreText
          textFormat: Text.PlainText
          width: root.scoreColumnWidth
          text: root.awayScoreLabel
          color: Commons.Color.popups.text
          font.family: Typography.family
            font.pixelSize: Commons.Style.font.heading
          font.features: ({"tnum": 1})
          font.bold: true
          horizontalAlignment: Text.AlignRight
          verticalAlignment: Text.AlignVCenter
          Rectangle {
            objectName: "awayScoreUpdateTint"
            anchors.fill: parent
            z: -1
            radius: Commons.Style.space(3)
            color: Qt.alpha(Commons.Color.accent, root.awayScoreHighlight * 0.12)
          }
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
            text: root.game.homeTeam ? root.game.homeTeam.shortName || root.game.homeTeam.name || root.homeLabel : root.homeLabel
            foreground: visual.ink
            fontSize: visual.body
            bold: root.homeIsFavorite || Formatters.isWinningTeam(root.game, "home")
            onRequested: function(teamId) { root.teamScheduleRequested(teamId) }
          }
        }

        Text {
          id: homeScoreText
          textFormat: Text.PlainText
          width: root.scoreColumnWidth
          text: root.homeScoreLabel
          color: Commons.Color.popups.text
          font.family: Typography.family
            font.pixelSize: Commons.Style.font.heading
          font.features: ({"tnum": 1})
          font.bold: true
          horizontalAlignment: Text.AlignRight
          verticalAlignment: Text.AlignVCenter
          Rectangle {
            objectName: "homeScoreUpdateTint"
            anchors.fill: parent
            z: -1
            radius: Commons.Style.space(3)
            color: Qt.alpha(Commons.Color.accent, root.homeScoreHighlight * 0.12)
          }
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
      parent: root.featured ? featureFooter : card
      anchors.right: parent.right
      anchors.rightMargin: Commons.Style.spacing.sm
      y: root.featured ? (featureFooter.height-height)/2
        : Commons.Style.space(6) + Math.max(0, (Commons.Style.space(48) + Commons.Style.spacing.xs - height) / 2)
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
      opacity: 0
    }
  }
}

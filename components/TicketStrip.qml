pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Commons
import "../model/TicketPresentation.js" as TicketPresentation
import "../model/PointerInteractionPolicy.js" as PointerInteractionPolicy
import "../providers/LeagueCatalog.js" as LeagueCatalog

Item {
  id: root

  property var games: []
  property var favoriteTeamIds: []
  property string tickerState: "empty"
  property double nowMs: Date.now()
  property bool reducedMotion: false
  // Tracks an in-progress per-game pointer press so the full-strip chrome
  // handler yields to the nested game target, mirroring the GameRow pattern.
  property bool gameActionPressed: false

  signal primaryActionRequested()

  // Guarded per-game source route: same HTTPS + provider-host allowlist as
  // SourceLinkButton.openSource over the GameModel.safeGameUrl hosts.
  function openTickerSource(url) {
    if (typeof url !== "string" || url.indexOf("https://") !== 0) return
    var lowered = url.toLowerCase()
    if (lowered.indexOf("espn.com") === -1 && lowered.indexOf("nhl.com") === -1
        && lowered.indexOf("mlb.com") === -1) return
    Quickshell.execDetached(["omarchy-launch-browser", url])
  }

  readonly property var ticker: TicketPresentation.build({
    games: root.games,
    favoriteTeamIds: root.favoriteTeamIds,
    state: root.tickerState,
    nowMs: root.nowMs,
    formatStartTime: function(value) {
      var date = new Date(value)
      return isNaN(date.getTime()) ? "UPCOMING" : Qt.formatTime(date, "h:mm AP")
    },
    leagueInfo: function(value) {
      var league = LeagueCatalog.getLeague(value)
      return league ? {
        label: league.displayName,
        sport: league.sport || (league.id === "nhl" ? "hockey" : "")
      } : null
    }
  })

  width: parent ? parent.width : 0
  height: Style.space(32)
  implicitHeight: height
  clip: true

  Rectangle {
    anchors.fill: parent
    color: Color.background
  }

  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: Style.space(1)
    color: Color.accent
  }

  // Declared before the scrolling content so it sits below the per-game
  // targets in stacking order; game presses are grabbed above while
  // unhandled chrome clicks fall through here and keep the panel action.
  MouseArea {
    id: stripMouse
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      if (!PointerInteractionPolicy.allowsRowActivation(root.gameActionPressed)) return
      root.primaryActionRequested()
    }
  }

  Item {
    id: tickerContent
    anchors.verticalCenter: parent.verticalCenter
    width: gameRow.visible ? gameRow.implicitWidth : statusText.implicitWidth
    height: root.height
    x: root.reducedMotion ? Style.spacing.md : root.width

    Text {
      id: statusText
      anchors.verticalCenter: parent.verticalCenter
      visible: !gameRow.visible
      text: root.ticker.text
      textFormat: Text.PlainText
      color: root.ticker.state === "offline" ? Color.urgent : Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      font.bold: true
    }

    Row {
      id: gameRow
      anchors.verticalCenter: parent.verticalCenter
      visible: Boolean(root.ticker.items && root.ticker.items.length > 0)
      spacing: Style.spacing.sm

      Repeater {
        model: root.ticker.items || []

        delegate: Row {
          id: gameItem
          required property var modelData
          required property int index
          height: root.height
          spacing: Style.spacing.xs

          readonly property string gameSourceUrl: typeof gameItem.modelData.sourceUrl === "string"
            ? gameItem.modelData.sourceUrl : ""
          readonly property bool hasGameSource: gameItem.gameSourceUrl !== ""

          Item {
            width: Style.space(56)
            height: 1
            visible: gameItem.index > 0 && gameItem.modelData.groupStart
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: gameItem.modelData.groupStart
              ? gameItem.modelData.leagueEmoji + "  " + gameItem.modelData.leagueLabel
              : "   " + (gameItem.modelData.separatorEmoji || gameItem.modelData.leagueEmoji || "•") + "   "
            color: Color.accent
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            font.bold: true
          }

          Row {
            id: gameHit
            height: root.height
            spacing: Style.spacing.xs

            Image {
              width: Style.space(18)
              height: width
              anchors.verticalCenter: parent.verticalCenter
              source: gameItem.modelData.awayLogoUrl
              sourceSize: Qt.size(Style.space(36), Style.space(36))
              fillMode: Image.PreserveAspectFit
              asynchronous: true
              visible: status === Image.Ready
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: gameItem.modelData.away + (gameItem.modelData.awayScore
                ? " " + gameItem.modelData.awayScore : "")
              textFormat: Text.PlainText
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: gameItem.modelData.divider
              textFormat: Text.PlainText
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }

            Image {
              width: Style.space(18)
              height: width
              anchors.verticalCenter: parent.verticalCenter
              source: gameItem.modelData.homeLogoUrl
              sourceSize: Qt.size(Style.space(36), Style.space(36))
              fillMode: Image.PreserveAspectFit
              asynchronous: true
              visible: status === Image.Ready
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: gameItem.modelData.home + (gameItem.modelData.homeScore
                ? " " + gameItem.modelData.homeScore : "")
              textFormat: Text.PlainText
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: gameItem.modelData.detail
              textFormat: Text.PlainText
              color: Color.foreground
              opacity: 0.82
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }

            // Per-game pointer target. Enabled only for games with a safe
            // provider URL so unsafe games stay neutral and fall through to
            // the full-strip panel action like other ticker chrome.
            MouseArea {
              id: gameMouse
              anchors.fill: parent
              enabled: gameItem.hasGameSource
              hoverEnabled: true
              cursorShape: gameItem.hasGameSource ? Qt.PointingHandCursor : Qt.ArrowCursor
              onPressed: root.gameActionPressed = true
              onReleased: root.gameActionPressed = false
              onCanceled: root.gameActionPressed = false
              onClicked: {
                root.gameActionPressed = false
                if (gameItem.hasGameSource) root.openTickerSource(gameItem.gameSourceUrl)
              }
            }

            Accessible.role: gameItem.hasGameSource ? Accessible.Button : Accessible.StaticText
            Accessible.name: gameItem.modelData.text
              + (gameItem.hasGameSource
                ? ". Open provider game page."
                : ". External game page unavailable.")
            Accessible.onPressAction: {
              if (gameItem.hasGameSource) root.openTickerSource(gameItem.gameSourceUrl)
            }
          }
        }
      }
    }

    NumberAnimation on x {
      running: root.visible && !root.reducedMotion && tickerContent.width > 0
      loops: Animation.Infinite
      duration: Math.max(12000, (root.width + tickerContent.width) * 24)
      from: root.width
      to: -tickerContent.width
      easing.type: Easing.Linear
    }
  }

  Accessible.name: root.ticker.text
  Accessible.role: Accessible.Button
  Accessible.onPressAction: root.primaryActionRequested()
}

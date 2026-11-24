pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Commons as Commons
import qs.Ui
import "../model/TicketPresentation.js" as TicketPresentation
import "../model/UiContrast.js" as UiContrast
import "../model/ProviderUrlPolicy.js" as ProviderUrlPolicy
import "../model/PointerInteractionPolicy.js" as PointerInteractionPolicy
import "../model/Iconography.js" as Iconography
import "../providers/LeagueCatalog.js" as LeagueCatalog

Item {
  id: root
  property var games: []
  property var favoriteTeamIds: []
  property string tickerState: "empty"
  property double nowMs: Date.now()
  property bool reducedMotion: false
  property bool enabled: true
  // Manual pause remains caller-owned. Hover never changes this preference.
  property bool paused: false
  property string speed: "normal"
  property var imageStore: null
  // Layer-shell hosts render tooltips in their own popup outside this strip.
  property bool nativeTooltips: false
  property bool gameActionPressed: false
  property real motionOffset: 0
  readonly property bool hoverPaused: tickerHover.hovered
  readonly property bool effectiveMotionPaused: root.paused || root.hoverPaused || root.reducedMotion
  readonly property bool hasTickerGames: Boolean(root.ticker.items && root.ticker.items.length)
  readonly property bool contentOverflows: gameRow.implicitWidth > tickerContent.width
  readonly property bool motionRunning: frameMotion.running && !frameMotion.paused
  readonly property real pixelsPerSecond: root.speed === "slow" ? 28 : root.speed === "fast" ? 62 : 42

  signal primaryActionRequested()
  signal pauseToggled()
  signal tooltipRequested(var target, string text)
  signal tooltipDismissed(var target)
  readonly property string pauseTooltipText: (root.paused ? "Resume ticker" : "Pause ticker")
    + (root.reducedMotion ? " · Reduced motion is enabled" : !root.contentOverflows
      ? " · All listed games fit on screen" : " · Hover pauses scrolling")
  onPauseTooltipTextChanged: if (root.nativeTooltips && pauseButton && pauseButton.hot)
    root.tooltipRequested(pauseButton, root.pauseTooltipText)

  function openTickerSource(url) {
    var safeUrl = ProviderUrlPolicy.safeGameUrl(url)
    if (!safeUrl) return
    Quickshell.execDetached(["omarchy-launch-browser", safeUrl])
  }

  readonly property var ticker: TicketPresentation.build({
    games: root.games, favoriteTeamIds: root.favoriteTeamIds,
    state: root.tickerState, nowMs: root.nowMs,
    formatStartTime: function(value) {
      var date = new Date(value)
      return isNaN(date.getTime()) ? "UPCOMING" : Qt.formatTime(date, "h:mm AP")
    },
    leagueInfo: function(value) {
      var league = LeagueCatalog.getLeague(value)
      return league ? {label: league.displayName,
        sport: league.sport || (league.id === "nhl" ? "hockey" : "")} : null
    }
  })

  width: parent ? parent.width : 0
  height: Commons.Style.space(32)
  visible: root.enabled
  implicitHeight: height
  clip: true

  // Manual/hover pause and ordinary score publications never reset the offset.
  // Reduced motion starts at a readable segment boundary.
  onReducedMotionChanged: if (root.reducedMotion) root.motionOffset = 0
  onTickerChanged: if (!root.hasTickerGames) root.motionOffset = 0
  FrameAnimation {
    id: frameMotion
    running: root.visible && root.enabled && root.hasTickerGames && root.contentOverflows
    paused: root.effectiveMotionPaused
    onTriggered: {
      var step = Math.min(0.05, Math.max(0, frameTime)) * root.pixelsPerSecond
      root.motionOffset -= step
      var span = gameRow.implicitWidth + Commons.Style.space(56)
      if (gameRow.implicitWidth > 0 && root.motionOffset <= -gameRow.implicitWidth)
        root.motionOffset += span
    }
  }

  Rectangle { anchors.fill: parent; color: Commons.Color.background }
  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: Math.max(1, Commons.Style.space(1))
    color: Commons.Color.accent
    opacity: 0.7
  }
  // Chrome is below individual controls, so nested actions fire only once.
  MouseArea {
    id: stripMouse
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      if (!PointerInteractionPolicy.allowsRowActivation(root.gameActionPressed)) return
      root.primaryActionRequested()
    }
  }
  HoverHandler { id: tickerHover; blocking: false }

  Item {
    id: controls
    anchors.left: parent.left
    anchors.leftMargin: Commons.Style.spacing.xs
    anchors.verticalCenter: parent.verticalCenter
    width: Commons.Style.space(36)
    height: root.height
    z: 3
    Button {
      id: pauseButton
      objectName: "tickerPause"
      anchors.centerIn: parent
      width: Commons.Style.space(30)
      height: Math.min(root.height - Commons.Style.spacing.xxs * 2, Commons.Style.space(28))
      text: root.paused ? "▶" : "Ⅱ"
      fontFamily: Commons.Style.font.family
      fontSize: Commons.Style.font.bodySmall
      foreground: Commons.Color.foreground
      bordered: true
      selected: root.paused
      tooltipText: root.nativeTooltips ? "" : root.pauseTooltipText
      onHovered: function(isHovered) {
        if (!root.nativeTooltips) return
        if (isHovered) root.tooltipRequested(pauseButton, root.pauseTooltipText)
        else root.tooltipDismissed(pauseButton)
      }
      onClicked: root.pauseToggled()
      Accessible.name: root.paused ? "Resume ticker" : "Pause ticker"
      Accessible.description: root.reducedMotion ? "Motion is disabled by the desktop reduced-motion setting."
        : root.paused ? "Scrolling is paused until resumed." : !root.contentOverflows
          ? "All listed games fit on screen." : "Hover over the ticker to pause scrolling."
      Accessible.role: Accessible.Button
      Accessible.checkable: true
      Accessible.checked: root.paused
    }
  }

  Item {
    id: tickerContent
    anchors.left: controls.right
    anchors.leftMargin: Commons.Style.spacing.sm
    anchors.right: parent.right
    height: root.height
    clip: true
    Text {
      id: statusText
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      visible: !root.hasTickerGames
      text: root.ticker.text
      textFormat: Text.PlainText
      color: root.ticker.state === "offline" ? Commons.Color.urgent : Commons.Color.foreground
      font.family: Commons.Style.font.family
      font.pixelSize: Commons.Style.font.bodySmall
      elide: Text.ElideRight
    }
    Item {
      id: tickerViewport
      x: root.contentOverflows ? root.motionOffset : 0
      width: gameRow.implicitWidth
      height: parent.height
      Row {
        id: gameRow
        anchors.verticalCenter: parent.verticalCenter
        visible: root.hasTickerGames
        spacing: Commons.Style.spacing.md
        Repeater {
          model: root.ticker.items || []
          delegate: Row {
            id: gameItem
            required property var modelData
            required property int index
            height: root.height
            spacing: Commons.Style.spacing.sm
            readonly property string gameSourceUrl: typeof gameItem.modelData.sourceUrl === "string"
              ? gameItem.modelData.sourceUrl : ""
            readonly property bool hasGameSource: gameItem.gameSourceUrl !== ""
            Rectangle {
              width: 1
              height: Commons.Style.space(14)
              anchors.verticalCenter: parent.verticalCenter
              color: Commons.Color.foreground
              opacity: 0.20
              visible: gameItem.index > 0
            }
            Row {
              visible: gameItem.modelData.groupStart
              anchors.verticalCenter: parent.verticalCenter
              spacing: Commons.Style.spacing.xs
              SemanticIcon {
                width: Commons.Style.space(16)
                height: width
                iconName: Iconography.iconNameForLeague(gameItem.modelData.leagueId)
                color: Commons.Color.accent
                fontSize: Commons.Style.font.bodySmall
                decorative: true
              }
              Text {
                text: gameItem.modelData.leagueLabel
                textFormat: Text.PlainText
                color: UiContrast.foreground(Commons.Color.accent, Commons.Color.foreground, Commons.Color.background)
                font.family: Commons.Style.font.family
                font.pixelSize: Commons.Style.font.caption
                font.weight: Font.DemiBold
              }
            }
            Item {
              id: gameHit
              objectName: "tickerGame-" + gameItem.index
              width: gameHitRow.implicitWidth
              height: root.height
              readonly property string awayLogoSource: root.imageStore
                ? root.imageStore.sourceFor(gameItem.modelData.awayLogoUrl) : ""
              readonly property string homeLogoSource: root.imageStore
                ? root.imageStore.sourceFor(gameItem.modelData.homeLogoUrl) : ""
              readonly property bool tooltipHovered: gameMouse.containsMouse || gameHover.hovered
              onTooltipHoveredChanged: {
                if (!root.nativeTooltips) return
                if (tooltipHovered) root.tooltipRequested(gameHit, gameItem.modelData.tooltip)
                else root.tooltipDismissed(gameHit)
              }
              Row {
                id: gameHitRow
                height: parent.height
                spacing: Commons.Style.spacing.xs
                Text {
                  visible: gameItem.modelData.favorite === true
                  anchors.verticalCenter: parent.verticalCenter
                  text: "★"
                  textFormat: Text.PlainText
                  color: Commons.Color.accent
                  font.family: Commons.Style.font.family
                  font.pixelSize: Commons.Style.font.caption
                  Accessible.ignored: true
                }
                Rectangle {
                  visible: gameHit.awayLogoSource !== ""
                  anchors.verticalCenter: parent.verticalCenter
                  width: Commons.Style.space(18)
                  height: width
                  color: "#f4f4f0"
                  radius: Commons.Style.space(2)
                  Image {
                    anchors.fill: parent
                    anchors.margins: Commons.Style.space(1)
                    source: gameHit.awayLogoSource
                    sourceSize: Qt.size(Commons.Style.space(36), Commons.Style.space(36))
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                  }
                }
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: gameItem.modelData.away
                  textFormat: Text.PlainText
                  color: Commons.Color.foreground
                  font.family: Commons.Style.font.family
                  font.pixelSize: Commons.Style.font.bodySmall
                }
                Text {
                  visible: gameItem.modelData.awayScore !== ""
                  anchors.verticalCenter: parent.verticalCenter
                  width: Math.max(scoreMetrics.averageCharacterWidth * 3, implicitWidth)
                  text: gameItem.modelData.awayScore
                  textFormat: Text.PlainText
                  color: Commons.Color.foreground
                  horizontalAlignment: Text.AlignRight
                  font.family: Commons.Style.font.family
                  font.pixelSize: Commons.Style.font.bodySmall
                  font.weight: Font.DemiBold
                }
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: gameItem.modelData.divider
                  textFormat: Text.PlainText
                  color: Qt.alpha(Commons.Color.foreground, 0.85)
                  font.family: Commons.Style.font.family
                  font.pixelSize: Commons.Style.font.bodySmall
                }
                Rectangle {
                  visible: gameHit.homeLogoSource !== ""
                  anchors.verticalCenter: parent.verticalCenter
                  width: Commons.Style.space(18)
                  height: width
                  color: "#f4f4f0"
                  radius: Commons.Style.space(2)
                  Image {
                    anchors.fill: parent
                    anchors.margins: Commons.Style.space(1)
                    source: gameHit.homeLogoSource
                    sourceSize: Qt.size(Commons.Style.space(36), Commons.Style.space(36))
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                  }
                }
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: gameItem.modelData.home
                  textFormat: Text.PlainText
                  color: Commons.Color.foreground
                  font.family: Commons.Style.font.family
                  font.pixelSize: Commons.Style.font.bodySmall
                }
                Text {
                  visible: gameItem.modelData.homeScore !== ""
                  anchors.verticalCenter: parent.verticalCenter
                  width: Math.max(scoreMetrics.averageCharacterWidth * 3, implicitWidth)
                  text: gameItem.modelData.homeScore
                  textFormat: Text.PlainText
                  color: Commons.Color.foreground
                  horizontalAlignment: Text.AlignRight
                  font.family: Commons.Style.font.family
                  font.pixelSize: Commons.Style.font.bodySmall
                  font.weight: Font.DemiBold
                }
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  width: scoreMetrics.averageCharacterWidth * 12
                  text: gameItem.modelData.displayDetail
                  textFormat: Text.PlainText
                  elide: Text.ElideRight
                  color: gameItem.modelData.isLive
                    ? UiContrast.foreground(Commons.Color.accent, Commons.Color.foreground, Commons.Color.background)
                    : Commons.Color.foreground
                  opacity: gameItem.modelData.isLive ? 1 : 0.85
                  font.family: Commons.Style.font.family
                  font.pixelSize: Commons.Style.font.caption
                  font.weight: gameItem.modelData.isLive ? Font.DemiBold : Font.Normal
                }
              }
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
              PanelToolTip {
                objectName: "tickerSourceTooltip-" + gameItem.index
                visible: !root.nativeTooltips && gameHit.tooltipHovered
                text: gameItem.modelData.tooltip
                width: Math.min(implicitWidth, Commons.Style.space(400),
                  Math.max(1, root.width - Commons.Style.spacing.md * 2))
              }
              HoverHandler { id: gameHover; blocking: false }
              Accessible.role: gameItem.hasGameSource ? Accessible.Button : Accessible.StaticText
              Accessible.name: (gameItem.modelData.favorite ? "Favorite game. " : "") + gameItem.modelData.tooltip
              Accessible.onPressAction: {
                if (gameItem.hasGameSource) root.openTickerSource(gameItem.gameSourceUrl)
              }
            }
          }
        }
      }
    }
  }
  FontMetrics { id: scoreMetrics; font.family: Commons.Style.font.family; font.pixelSize: Commons.Style.font.bodySmall }
  Accessible.name: root.ticker.text
  Accessible.description: root.paused ? "Ticker paused. Select a matchup to open its provider, or other space for scores."
    : "Hover to pause. Select a matchup to open its provider, or other space for scores."
  Accessible.role: Accessible.Button
  Accessible.onPressAction: root.primaryActionRequested()
}

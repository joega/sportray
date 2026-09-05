pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons
import "../model/TicketPresentation.js" as TicketPresentation
import "../providers/LeagueCatalog.js" as LeagueCatalog

Item {
  id: root

  property var games: []
  property var favoriteTeamIds: []
  property string tickerState: "empty"
  property double nowMs: Date.now()
  property bool reducedMotion: false

  signal primaryActionRequested()

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
          height: root.height
          spacing: Style.spacing.xs

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: gameItem.modelData.groupStart
              ? gameItem.modelData.leagueEmoji + "  " + gameItem.modelData.leagueLabel + "  |"
              : "•"
            color: Color.accent
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            font.bold: true
          }

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
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            font.bold: true
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: gameItem.modelData.divider
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
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            font.bold: true
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "|  " + gameItem.modelData.detail
            color: Color.foreground
            opacity: 0.82
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            font.bold: true
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

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.primaryActionRequested()
  }

  Accessible.name: root.ticker.text
  Accessible.role: Accessible.Button
  Accessible.onPressAction: root.primaryActionRequested()
}

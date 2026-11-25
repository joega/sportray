pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons as Commons
import "../model/UiTypography.js" as Typography
import "../model/GameDetailModel.js" as GameDetailModel
import "../model/Formatters.js" as Formatters

// Shared presentation of a normalized matchup. Owns no requests/preferences.
Rectangle {
  id: root
  required property var game
  property var detail: null
  property var imageStore: null
  property double currentTime: Date.now()
  property bool stale: false
  property bool selected: false
  property bool teamLinksEnabled: true
  property bool awayHasCursor: false
  property bool homeHasCursor: false
  property real awayScoreHighlight: 0
  property real homeScoreHighlight: 0
  property string semanticPrefix: "matchup"
  property string kickerText: ""
  property string dateText: ""
  property string timeText: ""
  property string statusText: ""
  property bool timeKnown: true
  property bool showContext: true
  property bool showStatus: true
  readonly property var normalized: root.detail || GameDetailModel.normalizeDetail(root.game)
  readonly property string state: root.normalized.status.state
  readonly property bool scheduled: root.state === "scheduled"
  readonly property bool live: root.state === "live" || root.state === "intermission"
  readonly property bool showScores: !root.scheduled
  readonly property bool awayIsFavorite: Boolean(root.game && root.game.presentation && root.game.presentation.awayIsFavorite)
  readonly property bool homeIsFavorite: Boolean(root.game && root.game.presentation && root.game.presentation.homeIsFavorite)
  readonly property var participants: root.normalized.participants
  readonly property var presentationStatus: root.state === "scheduled" || root.state === "final" || root.state === "postponed"
    || root.state === "canceled" || root.state === "unknown"
    ? {state: root.state, detail: root.normalized.status.detail} : root.normalized.status
  readonly property bool childActionPressed: awayTeamLink.pointerPressed || homeTeamLink.pointerPressed
  readonly property bool teamPointerPressed: root.childActionPressed
  readonly property string contextLabel: root.kickerText || (root.normalized.league
    ? root.normalized.league.toUpperCase() + (root.normalized.venue ? " · " + root.normalized.venue : "") : "")
  readonly property string stateLabel: root.statusText || (root.stale
    ? Formatters.formatGameStateLabel(root.game, {stale: true, now: root.currentTime})
    : Formatters.formatDetailStatus(root.presentationStatus))
  readonly property string startLabel: root.timeText || (root.timeKnown && root.normalized.timing.startTime
    ? Qt.formatDateTime(new Date(root.normalized.timing.startTime), "h:mm AP") : "Start time unavailable")
  readonly property bool startTimeAvailable: root.timeText !== "" || Boolean(root.timeKnown && root.normalized.timing.startTime)
  readonly property string startDateLabel: root.dateText || (root.normalized.timing.startTime
    ? Qt.formatDateTime(new Date(root.normalized.timing.startTime), "ddd, MMM d") : "")
  readonly property real innerWidth: Math.max(0, width - Commons.Style.space(28))
  readonly property int maximumScoreCharacters: Math.max(root.scoreText(0).length, root.scoreText(1).length)
  readonly property real sideWidth: innerWidth * (root.showScores && root.maximumScoreCharacters >= 4 ? .25 : .29)
  readonly property real middleWidth: Math.max(0, innerWidth - sideWidth * 2 - Commons.Style.space(8))

  signal teamScheduleRequested(string teamId)

  function participantName(index) {
    var participant = root.participants[index]
    var team = participant ? participant.team : null
    return team ? team.name || team.shortName || team.abbreviation || "Team unavailable" : "Team unavailable"
  }
  function teamLink(side) { return side === "away" || side === 0 ? awayTeamLink : homeTeamLink }
  function focusTeam(teamId) {
    if (!root.teamLinksEnabled) return false
    for (var i = 0; i < root.participants.length; i++) {
      if (root.participants[i].team && root.participants[i].team.id === teamId) {
        var target = root.teamLink(i)
        if (!target.available) return false
        target.forceActiveFocus()
        return true
      }
    }
    return false
  }
  function logoSource(index) {
    var participant = root.participants[index]
    var team = participant ? participant.team : null
    return root.imageStore && team && team.logoUrl ? root.imageStore.sourceFor(team.logoUrl) : ""
  }
  function scoreText(index) {
    // Scoreboard policy keeps administrative/missing data neutral, including
    // any retained raw scores on postponed or unknown games.
    return Formatters.formatScoreboardTeamScore({status: root.state,
      awayScore: root.participants[0].score, homeScore: root.participants[1].score}, index === 0 ? "away" : "home")
  }

  PresentationTokens { id: visual }
  color: visual.feature
  radius: visual.featureRadius
  border.width: root.selected ? Math.max(1, Commons.Style.space(2)) : 0
  border.color: visual.accent
  implicitHeight: content.implicitHeight + Commons.Style.space(28)
  height: implicitHeight

  component TeamMark: Item {
    id: mark
    property int side: 0
    width: Math.min(Commons.Style.space(46), root.sideWidth)
    height: width
    Rectangle {
      anchors.fill: parent
      radius: Commons.Style.space(9)
      color: "#f5f5f5"
      visible: logo.status === Image.Ready
    }
    Image {
      id: logo
      anchors.fill: parent
      anchors.margins: Commons.Style.space(3)
      source: root.logoSource(mark.side)
      sourceSize: Qt.size(width * 2, height * 2)
      fillMode: Image.PreserveAspectFit
      asynchronous: true
      cache: true
    }
    Text {
      anchors.fill: parent
      visible: logo.status !== Image.Ready
      text: Formatters.teamLabel(root.participants[mark.side] ? root.participants[mark.side].team : null).slice(0, 3)
      textFormat: Text.PlainText
      color: visual.muted
      font.family: Typography.family
      font.pixelSize: Commons.Style.font.subtitle
      font.bold: true
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
    }
    Text {
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.topMargin: -Commons.Style.space(3)
      visible: mark.side === 0 ? root.awayIsFavorite : root.homeIsFavorite
      text: "★"
      textFormat: Text.PlainText
      font.family: Typography.family
      font.pixelSize: Commons.Style.font.subtitle
      color: visual.accent
      Accessible.ignored: true
    }
  }

  Column {
    id: content
    x: Commons.Style.space(14)
    y: Commons.Style.space(14)
    width: root.innerWidth
    spacing: Commons.Style.space(10)
    Text {
      width: parent.width
      visible: root.showContext && text !== ""
      text: root.contextLabel
      textFormat: Text.PlainText
      font.family: Typography.family
      font.pixelSize: Commons.Style.font.bodySmall
      color: visual.muted
      wrapMode: Text.Wrap
    }
    Item {
      width: parent.width
      height: Math.max(awayIdentity.implicitHeight, homeIdentity.implicitHeight, scoreIdentity.implicitHeight)
      Column {
        id: awayIdentity
        width: root.sideWidth
        spacing: Commons.Style.space(5)
        TeamMark { side: 0; anchors.horizontalCenter: parent.horizontalCenter }
        TeamScheduleLink {
          id: awayTeamLink
          width: parent.width
          height: implicitHeight
          team: root.teamLinksEnabled ? root.participants[0].team : null
          text: root.participantName(0)
          foreground: visual.ink
          fontSize: visual.body
          bold: true
          wrap: true
          hasCursor: root.awayHasCursor
          Accessible.name: "Open " + root.participantName(0) + " schedule" + (root.awayIsFavorite ? ", favorite team" : "")
          onRequested: function(teamId) { root.teamScheduleRequested(teamId) }
        }
      }
      Column {
        id: scoreIdentity
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: root.middleWidth
        spacing: Commons.Style.space(4)
        Row {
          width: parent.width
          visible: root.showScores
          spacing: Commons.Style.space(3)
          Text {
            objectName: root.semanticPrefix + "Score0"
            width: (parent.width - dash.width - parent.spacing * 2) / 2
            height: Commons.Style.space(48)
            text: root.scoreText(0)
            textFormat: Text.PlainText
            color: visual.ink
            font.family: Typography.family
            font.pixelSize: Commons.Style.space(38)
            minimumPixelSize: Commons.Style.font.bodySmall
            fontSizeMode: Text.Fit
            font.features: ({"tnum": 1})
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Rectangle {
              objectName: "awayScoreUpdateTint"
              anchors.fill: parent
              z: -1
              radius: Commons.Style.space(4)
              color: Qt.alpha(visual.accent, root.awayScoreHighlight * .12)
            }
          }
          Text {
            id: dash
            width: Commons.Style.space(15)
            height: Commons.Style.space(48)
            text: "–"
            textFormat: Text.PlainText
            color: visual.muted
            font.family: Typography.family
            font.pixelSize: Commons.Style.space(22)
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
          }
          Text {
            objectName: root.semanticPrefix + "Score1"
            width: (parent.width - dash.width - parent.spacing * 2) / 2
            height: Commons.Style.space(48)
            text: root.scoreText(1)
            textFormat: Text.PlainText
            color: visual.ink
            font.family: Typography.family
            font.pixelSize: Commons.Style.space(38)
            minimumPixelSize: Commons.Style.font.bodySmall
            fontSizeMode: Text.Fit
            font.features: ({"tnum": 1})
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Rectangle {
              objectName: "homeScoreUpdateTint"
              anchors.fill: parent
              z: -1
              radius: Commons.Style.space(4)
              color: Qt.alpha(visual.accent, root.homeScoreHighlight * .12)
            }
          }
        }
        Text {
          objectName: root.semanticPrefix + "StartTime"
          width: parent.width
          height: root.startTimeAvailable ? Commons.Style.space(32) : implicitHeight
          visible: root.scheduled
          text: root.startLabel
          textFormat: Text.PlainText
          color: visual.ink
          font.family: Typography.family
          font.pixelSize: root.startTimeAvailable ? Commons.Style.space(23) : Commons.Style.font.subtitle
          minimumPixelSize: Commons.Style.font.bodySmall
          fontSizeMode: Text.Fit
          font.weight: Font.DemiBold
          horizontalAlignment: Text.AlignHCenter
          wrapMode: root.startTimeAvailable ? Text.NoWrap : Text.Wrap
        }
        Text {
          objectName: root.semanticPrefix + "StartDate"
          width: parent.width
          visible: root.scheduled && text !== ""
          text: root.startDateLabel
          textFormat: Text.PlainText
          color: visual.muted
          font.family: Typography.family
          font.pixelSize: Commons.Style.font.bodySmall
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.Wrap
        }
      }
      Column {
        id: homeIdentity
        anchors.right: parent.right
        width: root.sideWidth
        spacing: Commons.Style.space(5)
        TeamMark { side: 1; anchors.horizontalCenter: parent.horizontalCenter }
        TeamScheduleLink {
          id: homeTeamLink
          width: parent.width
          height: implicitHeight
          team: root.teamLinksEnabled ? root.participants[1].team : null
          text: root.participantName(1)
          foreground: visual.ink
          fontSize: visual.body
          bold: true
          wrap: true
          hasCursor: root.homeHasCursor
          Accessible.name: "Open " + root.participantName(1) + " schedule" + (root.homeIsFavorite ? ", favorite team" : "")
          onRequested: function(teamId) { root.teamScheduleRequested(teamId) }
        }
      }
    }
    Text {
      objectName: root.semanticPrefix + "Status"
      width: parent.width
      visible: root.showStatus
      text: root.stateLabel
      textFormat: Text.PlainText
      color: root.stale || root.state === "postponed" || root.state === "canceled" || root.state === "unknown"
        ? Commons.Color.urgent : root.live ? visual.accent : visual.muted
      font.family: Typography.family
      font.pixelSize: Commons.Style.font.bodySmall
      font.weight: root.live ? Font.DemiBold : Font.Normal
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.Wrap
    }
  }
}

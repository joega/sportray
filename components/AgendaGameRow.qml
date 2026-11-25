pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons as Commons
import qs.Ui
import "../model/AgendaPresentation.js" as AgendaPresentation
import "../model/DateModel.js" as DateModel
import "../model/UiTypography.js" as Typography
import "../model/UiContrast.js" as UiContrast

Item {
  id: root
  required property var modelData
  property string teamId: ""
  property string sectionLabel: ""
  property string timeText: ""
  property string leagueLabel: ""
  property bool stale: false
  property var imageStore: null
  readonly property var game: root.modelData && root.modelData.game ? root.modelData.game : ({})
  readonly property string gameId: root.game.id || ""
  readonly property string dateKey: root.modelData ? root.modelData.dateKey || "" : ""
  readonly property var date: AgendaPresentation.dateParts(root.dateKey)
  readonly property bool globalMode: root.teamId === ""
  readonly property var opposing: AgendaPresentation.opponent(root.modelData, root.teamId)
  readonly property string scoreText: AgendaPresentation.score(root.modelData)
  readonly property real dateWidth: Commons.Style.space(47)
  readonly property real timeWidth: Math.ceil(Math.max(clockMetrics.advanceWidth, tbdMetrics.advanceWidth) + Commons.Style.spacing.xs)
  readonly property bool stackedTime: body.width - root.dateWidth - root.timeWidth - Commons.Style.spacing.sm * 2 < Commons.Style.space(135)
  readonly property real labelWidth: Math.max(1, body.width - root.dateWidth - Commons.Style.spacing.sm
    - (root.stackedTime ? 0 : root.timeWidth + Commons.Style.spacing.sm))
  objectName: "agenda:" + root.gameId
  signal activated(string dateKey)
  PresentationTokens { id: visual }

  width: parent ? parent.width : implicitWidth
  implicitHeight: (root.sectionLabel ? groupLabel.implicitHeight + Commons.Style.spacing.md : 0) + body.height
  height: implicitHeight
  activeFocusOnTab: true
  Keys.onReturnPressed: root.activated(root.dateKey)
  Keys.onEnterPressed: root.activated(root.dateKey)
  Keys.onSpacePressed: root.activated(root.dateKey)
  Accessible.role: Accessible.Button
  Accessible.name: (root.sectionLabel ? root.sectionLabel + ". " : "")
    + DateModel.shortDateLabel(root.dateKey) + ", "
    + (root.globalMode ? AgendaPresentation.teamLabel(root.game.awayTeam) + " at " + AgendaPresentation.teamLabel(root.game.homeTeam)
      : root.opposing ? root.opposing.prefix + " " + AgendaPresentation.teamLabel(root.opposing.team) : "Matchup unavailable")
    + ", " + root.timeText + (root.scoreText ? ", " + root.scoreText : "") + (root.stale ? ". Retained schedule." : "") + ". View day."
  Accessible.onPressAction: root.activated(root.dateKey)

  TextMetrics { id: clockMetrics; text: "12:00 PM"; font.family: Typography.family; font.pixelSize: Commons.Style.font.caption }
  TextMetrics { id: tbdMetrics; text: "Time TBD"; font.family: Typography.family; font.pixelSize: Commons.Style.font.caption }

  Text {
    id: groupLabel
    width: parent.width
    visible: root.sectionLabel !== ""
    text: root.sectionLabel
    textFormat: Text.PlainText
    color: visual.ink
    font.family: Typography.family
    font.pixelSize: visual.section
    font.weight: Font.DemiBold
    Accessible.ignored: true
  }

  Item {
    id: body
    width: root.width
    y: root.sectionLabel ? groupLabel.implicitHeight + Commons.Style.spacing.md : 0
    height: Math.max(Commons.Style.space(68), dateColumn.implicitHeight + Commons.Style.spacing.md * 2,
      matchupColumn.implicitHeight + (root.stackedTime ? timeColumn.implicitHeight + Commons.Style.spacing.xs : 0)
        + Commons.Style.spacing.md * 2, timeColumn.implicitHeight + Commons.Style.spacing.md * 2)

    BorderSurface {
      id: surface
      anchors.fill: parent
      color: root.activeFocus ? Commons.Style.focusFillFor(Commons.Color.popups.text, Commons.Color.accent)
        : rowHover.hovered ? Commons.Style.hoverFillFor(Commons.Color.popups.text, Commons.Color.accent) : "transparent"
      borderSpec: root.activeFocus ? Commons.Border.controlSpec("focus", Commons.Color.popups.text, Commons.Color.accent) : Commons.Border.none()
      radius: visual.radius
    }

    Column {
      id: dateColumn
      objectName: "agendaDate"
      width: root.dateWidth
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      spacing: Commons.Style.spacing.xxs
      Text {
        width: parent.width
        text: root.globalMode ? root.leagueLabel : root.date ? root.date.weekday : "Date TBD"
        textFormat: Text.PlainText
        color: visual.muted
        font.family: Typography.family
        font.pixelSize: Commons.Style.font.caption
        font.weight: root.globalMode ? Font.DemiBold : Font.Normal
        wrapMode: Text.Wrap
      }
      Text {
        width: parent.width
        visible: !root.globalMode
        text: root.date ? String(root.date.day) : ""
        textFormat: Text.PlainText
        color: visual.ink
        font.family: Typography.family
        font.pixelSize: Math.round(Commons.Style.font.body * 1.667)
        font.weight: Font.DemiBold
      }
      Text {
        width: parent.width
        visible: !root.globalMode
        text: root.date ? root.date.monthLabel : ""
        textFormat: Text.PlainText
        color: visual.muted
        font.family: Typography.family
        font.pixelSize: Commons.Style.font.caption
      }
    }

    Column {
      id: matchupColumn
      objectName: "agendaMatchup"
      x: root.dateWidth + Commons.Style.spacing.sm
      width: root.labelWidth
      y: root.stackedTime ? (body.height - implicitHeight - timeColumn.implicitHeight - Commons.Style.spacing.xs) / 2
        : (body.height - implicitHeight) / 2
      spacing: Commons.Style.spacing.xxs
      Repeater {
        model: root.globalMode ? [{team: root.game.awayTeam, prefix: ""}, {team: root.game.homeTeam, prefix: "at"}]
          : [root.opposing || {team: null, prefix: ""}]
        Row {
          id: participant
          required property var modelData
          width: matchupColumn.width
          spacing: Commons.Style.spacing.xs
          height: Math.max(logoMark.height, participantName.implicitHeight)
          Item {
            id: logoMark
            width: Commons.Style.space(root.globalMode ? 24 : 30)
            height: width
            anchors.verticalCenter: parent.verticalCenter
            readonly property string source: root.imageStore && participant.modelData.team && participant.modelData.team.logoUrl
              ? root.imageStore.sourceFor(participant.modelData.team.logoUrl) : ""
            Rectangle { anchors.fill: parent; radius: Commons.Style.space(4); color: mark.status === Image.Ready ? "#f5f5f5" : Qt.alpha(Commons.Color.popups.text, 0.06) }
            Image {
              id: mark
              anchors.fill: parent
              anchors.margins: Commons.Style.space(1)
              source: logoMark.source
              sourceSize: Qt.size(width * 2, height * 2)
              fillMode: Image.PreserveAspectFit
              asynchronous: true
              visible: status === Image.Ready
            }
            Text {
              anchors.fill: parent
              visible: mark.status !== Image.Ready
              text: AgendaPresentation.teamLabel(participant.modelData.team).slice(0, 1)
              textFormat: Text.PlainText
              color: Commons.Color.popups.text
              font.family: Typography.family
              font.pixelSize: Commons.Style.font.caption
              font.weight: Font.DemiBold
              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
            }
          }
          Text {
            id: participantName
            width: Math.max(1, parent.width - logoMark.width - parent.spacing)
            anchors.verticalCenter: parent.verticalCenter
            text: (participant.modelData.prefix ? participant.modelData.prefix + " " : "") + AgendaPresentation.teamLabel(participant.modelData.team)
            textFormat: Text.PlainText
            color: Commons.Color.popups.text
            font.family: Typography.family
            font.pixelSize: visual.body
            font.weight: Font.Medium
            wrapMode: Text.Wrap
          }
        }
      }
    }

    Column {
      id: timeColumn
      objectName: "agendaTime"
      width: root.stackedTime ? root.labelWidth : root.timeWidth
      x: root.stackedTime ? matchupColumn.x : body.width - width
      y: root.stackedTime ? matchupColumn.y + matchupColumn.implicitHeight + Commons.Style.spacing.xs
        : (body.height - implicitHeight) / 2
      spacing: Commons.Style.spacing.xxs
      Text {
        width: parent.width
        visible: root.scoreText !== ""
        text: root.scoreText
        textFormat: Text.PlainText
        color: Commons.Color.popups.text
        font.family: Typography.family
        font.pixelSize: Commons.Style.font.body
        font.weight: Font.DemiBold
        font.features: ({"tnum": 1})
        horizontalAlignment: root.stackedTime ? Text.AlignLeft : Text.AlignRight
      }
      Text {
        width: parent.width
        text: root.timeText
        textFormat: Text.PlainText
        color: UiContrast.foreground(Qt.alpha(Commons.Color.popups.text, 0.85), Commons.Color.popups.text,
          UiContrast.composite(surface.color, Commons.Color.popups.background))
        font.family: Typography.family
        font.pixelSize: Commons.Style.font.caption
        font.features: ({"tnum": 1})
        horizontalAlignment: root.stackedTime ? Text.AlignLeft : Text.AlignRight
        wrapMode: Text.Wrap
      }
    }
    Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: visual.line }
    HoverHandler { id: rowHover }
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: { root.forceActiveFocus(); root.activated(root.dateKey) }
    }
  }
}

import QtQuick
import qs.Commons
import qs.Ui
import "../model/GameDetailModel.js" as GameDetailModel
import "../model/Formatters.js" as Formatters

Item {
  id: root

  property var game: null
  property int cursorIndex: 0
  signal backRequested()

  readonly property var sourceMetadata: sourceMetadataFor(root.game)
  readonly property var detail: GameDetailModel.normalizeDetail(root.game, root.sourceMetadata)
  readonly property bool sourceAvailable: Boolean(root.detail.source
    && typeof root.detail.source.url === "string" && root.detail.source.url !== "")

  implicitHeight: detailColumn.implicitHeight

  function sourceMetadataFor(value) {
    var url = value && typeof value.link === "string" ? value.link.toLowerCase() : ""
    if (url.indexOf("espn.com") !== -1) return {provider: "espn", label: "ESPN"}
    if (url.indexOf("nhl.com") !== -1) return {provider: "nhl", label: "NHL.com"}
    return {provider: null, label: null}
  }

  function valueOrDash(value) {
    return value === null || value === undefined || value === "" ? "—" : String(value)
  }

  function teamLabel(participant) {
    if (!participant || !participant.team) return "Team unavailable"
    return Formatters.teamLabel(participant.team)
  }

  function teamName(participant) {
    if (!participant || !participant.team) return "—"
    return participant.team.name || participant.team.shortName
      || participant.team.abbreviation || "—"
  }

  function scoreLabel(participant) {
    return participant ? root.valueOrDash(participant.score) : "—"
  }

  function stateLabel() {
    var state = root.detail.status ? root.detail.status.state : null
    if (!state || state === "unknown") return "Status unavailable"
    return state.charAt(0).toUpperCase() + state.slice(1)
  }

  function statusDetailLabel() {
    var status = root.detail.status || {}
    var values = []
    if (status.detail) values.push(status.detail)
    if (status.periodLabel && values.indexOf(status.periodLabel) === -1)
      values.push(status.periodLabel)
    if (status.clock) values.push(status.clock)
    return values.length > 0 ? values.join(" · ") : "—"
  }

  function timeLabel(value) {
    if (!value) return "—"
    var date = new Date(value)
    if (isNaN(date.getTime())) return "—"
    return Qt.formatDateTime(date, "MMM d, h:mm AP")
  }

  function moveCursor(delta) {
    var max = root.sourceAvailable ? 1 : 0
    root.cursorIndex = Math.max(0, Math.min(max, root.cursorIndex + delta))
    root.focusCursor()
  }

  function focusCursor() {
    root.deferFocus(function() {
      if (root.cursorIndex === 0) backButton.forceActiveFocus()
      else sourceLink.focusAction()
    })
  }

  function deferFocus(callback) {
    if (typeof callback !== "function") return
    Qt.callLater(function() {
      if (root.visible) callback()
    })
  }

  function resetCursor() {
    root.cursorIndex = 0
    root.focusCursor()
  }

  function activateCursor() {
    if (root.cursorIndex === 0) root.backRequested()
    else if (root.sourceAvailable) sourceLink.openSource()
  }

  Accessible.name: "Game details for " + root.teamLabel(root.detail.participants[0])
    + " at " + root.teamLabel(root.detail.participants[1])
  Accessible.role: Accessible.StaticText

  Column {
    id: detailColumn
    width: parent.width
    spacing: Style.spacing.md

    Row {
      width: parent.width
      spacing: Style.spacing.sm

      SemanticActionButton {
        id: backButton
        text: "Back"
        tooltipText: "Return to scores"
        textBold: true
        textFontSize: Style.font.bodySmall
        textVerticalPadding: Style.spacing.xs
        bordered: true
        focusable: true
        hasCursor: root.cursorIndex === 0
        onClicked: root.backRequested()
        Accessible.name: "Back to scores"
        Accessible.role: Accessible.Button
      }

      Column {
        width: parent.width - backButton.implicitWidth - parent.spacing
        spacing: Style.spacing.xxs

        Text {
          width: parent.width
          text: "GAME DETAILS"
          color: Color.accent
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
        }

        Text {
          width: parent.width
          text: root.valueOrDash(root.detail.league).toUpperCase()
            + " · " + root.valueOrDash(root.detail.source.label)
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          elide: Text.ElideRight
        }
      }
    }

    BorderSurface {
      width: parent.width
      height: detailCardColumn.implicitHeight + Style.spacing.lg * 2
      color: Color.popups.background
      borderSpec: Border.controlSpec("normal", Color.popups.text, Color.accent)
      radius: Style.cornerRadius

      Column {
        id: detailCardColumn
        anchors.fill: parent
        anchors.margins: Style.spacing.lg
        spacing: Style.spacing.md

        Row {
          width: parent.width
          spacing: Style.spacing.sm

          Text {
            width: parent.width - gameIdLabel.implicitWidth - parent.spacing
            text: root.valueOrDash(root.detail.id)
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.subtitle
            font.bold: true
            elide: Text.ElideRight
          }

          Text {
            id: gameIdLabel
            text: root.detail.providerGameId ? "#" + root.detail.providerGameId : "#—"
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
          }
        }

        Column {
          width: parent.width
          spacing: Style.spacing.xs

          Row {
            width: parent.width
            spacing: Style.spacing.sm

            Text {
              width: Style.space(44)
              text: "AWAY"
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Column {
              width: parent.width - scoreAway.implicitWidth - parent.spacing - Style.space(44)
              spacing: Style.spacing.xxs

              Text {
                width: parent.width
                text: root.teamLabel(root.detail.participants[0])
                color: Color.popups.text
                font.family: Style.font.family
                font.pixelSize: Style.font.subtitle
                font.bold: true
                elide: Text.ElideRight
              }

              Text {
                width: parent.width
                text: root.teamName(root.detail.participants[0])
                color: Color.muted
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
                elide: Text.ElideRight
              }
            }

            Text {
              id: scoreAway
              text: root.scoreLabel(root.detail.participants[0])
              color: Color.popups.text
              font.family: Style.font.family
              font.pixelSize: Style.font.display
              font.bold: true
              horizontalAlignment: Text.AlignRight
            }
          }

          Row {
            width: parent.width
            spacing: Style.spacing.sm

            Text {
              width: Style.space(44)
              text: "HOME"
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Column {
              width: parent.width - scoreHome.implicitWidth - parent.spacing - Style.space(44)
              spacing: Style.spacing.xxs

              Text {
                width: parent.width
                text: root.teamLabel(root.detail.participants[1])
                color: Color.popups.text
                font.family: Style.font.family
                font.pixelSize: Style.font.subtitle
                font.bold: true
                elide: Text.ElideRight
              }

              Text {
                width: parent.width
                text: root.teamName(root.detail.participants[1])
                color: Color.muted
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
                elide: Text.ElideRight
              }
            }

            Text {
              id: scoreHome
              text: root.scoreLabel(root.detail.participants[1])
              color: Color.popups.text
              font.family: Style.font.family
              font.pixelSize: Style.font.display
              font.bold: true
              horizontalAlignment: Text.AlignRight
            }
          }
        }

        Column {
          width: parent.width
          spacing: Style.spacing.xxs

          Text {
            width: parent.width
            text: root.stateLabel() + " · " + root.statusDetailLabel()
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            font.bold: true
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            text: "Start " + root.timeLabel(root.detail.timing.startTime)
              + "   ·   End " + root.timeLabel(root.detail.timing.endTime)
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            text: "Venue   " + root.valueOrDash(root.detail.venue)
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
          }
        }

        Row {
          width: parent.width
          spacing: Style.spacing.sm

          Text {
            width: parent.width - sourceLink.implicitWidth - parent.spacing
            text: root.valueOrDash(root.detail.source.label)
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            verticalAlignment: Text.AlignVCenter
          }

          SourceLinkButton {
            id: sourceLink
            game: root.game
            hasCursor: root.cursorIndex === 1
          }
        }
      }
    }
  }
}

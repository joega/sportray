import QtQuick
import Quickshell
import QtQuick.Controls as QQC
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

  function timeLabel(value) {
    if (!value) return "—"
    var date = new Date(value)
    if (isNaN(date.getTime())) return "—"
    return Qt.formatDateTime(date, "MMM d, h:mm AP")
  }

  function outcomeLabel() {
    var outcome = root.detail.outcome
    if (!outcome) return null
    if (outcome.winner === "draw") return "Draw · winning margin " + outcome.margin
    var winner = outcome.winner === "away"
      ? root.detail.participants[0] : root.detail.participants[1]
    return root.teamLabel(winner) + " won by " + outcome.margin
  }

  readonly property var linesData: root.detail.lines
  readonly property var statsData: root.detail.stats
  readonly property var situationData: root.detail.situation
  readonly property var oddsData: root.detail.odds
  readonly property var extraLinks: root.detail.links || []
  readonly property int linkCursorOffset: 1 + (root.sourceAvailable ? 1 : 0)
  readonly property int maxCursorIndex: root.linkCursorOffset + root.extraLinks.length - 1

  function openExternalUrl(url) {
    if (typeof url !== "string" || url.indexOf("https://") !== 0) return
    Quickshell.execDetached(["omarchy-launch-browser", url])
  }

  function statRows() {
    if (!root.statsData) return []
    return root.statsData.away.map(function(entry, index) {
      var homeEntry = root.statsData.home[index]
      return {
        label: entry.label,
        away: String(entry.value),
        home: homeEntry ? String(homeEntry.value) : "—"
      }
    })
  }

  function linePeriods() {
    if (!root.linesData) return []
    return root.linesData.away.map(function(entry) { return String(entry.period) })
  }

  function lineValues(side) {
    if (!root.linesData) return []
    var entries = side === "away" ? root.linesData.away : root.linesData.home
    return entries.map(function(entry) { return String(entry.value) })
  }

  function situationCountLabel() {
    if (!root.situationData) return "—"
    return root.situationData.balls + "-" + root.situationData.strikes
  }

  function situationOutsLabel() {
    return root.situationData ? String(root.situationData.outs) : "—"
  }

  function situationAccessibleBases() {
    if (!root.situationData) return "none"
    var names = []
    if (root.situationData.onFirst) names.push("first")
    if (root.situationData.onSecond) names.push("second")
    if (root.situationData.onThird) names.push("third")
    return names.length > 0 ? "runner on " + names.join(" and ") : "bases empty"
  }

  function oddsLabel() {
    if (!root.oddsData) return ""
    var label = root.oddsData.details
    if (root.oddsData.overUnder !== null) label += " · O/U " + root.oddsData.overUnder
    return label + " — " + root.oddsData.provider
  }

  function moveCursor(delta) {
    root.cursorIndex = Math.max(0, Math.min(root.maxCursorIndex, root.cursorIndex + delta))
    root.focusCursor()
  }

  function ensureVisible(item) {
    if (!item) return
    var top = item.mapToItem(detailScroll, 0, 0).y
    var bottom = top + item.height
    if (top < 0)
      detailScroll.contentY = Math.max(0, detailScroll.contentY + top)
    else if (bottom > detailScroll.height)
      detailScroll.contentY = Math.max(0,
        Math.min(detailScroll.contentHeight - detailScroll.height,
          detailScroll.contentY + bottom - detailScroll.height))
  }

  function focusCursor() {
    root.deferFocus(function() {
      var target = null
      if (root.cursorIndex === 0) {
        target = backButton
        target.forceActiveFocus()
      } else if (root.sourceAvailable && root.cursorIndex === 1) {
        target = sourceLink
        target.focusAction()
      } else {
        target = extraLinkButtons.itemAt(root.cursorIndex - root.linkCursorOffset)
        if (target) target.forceActiveFocus()
      }
      if (!target) return
      root.ensureVisible(target)
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
    detailScroll.contentY = 0
    root.focusCursor()
  }

  function activateCursor() {
    if (root.cursorIndex === 0) root.backRequested()
    else if (root.sourceAvailable && root.cursorIndex === 1) sourceLink.openSource()
    else {
      var link = root.extraLinks[root.cursorIndex - root.linkCursorOffset]
      if (link) root.openExternalUrl(link.url)
    }
  }

  Accessible.name: "Game details for " + root.teamLabel(root.detail.participants[0])
    + " at " + root.teamLabel(root.detail.participants[1])
  Accessible.role: Accessible.StaticText

  Flickable {
    id: detailScroll
    anchors.fill: parent
    contentWidth: width
    contentHeight: detailColumn.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.VerticalFlick
    interactive: contentHeight > height
    QQC.ScrollBar.vertical: QQC.ScrollBar { policy: QQC.ScrollBar.AsNeeded }

  Column {
    id: detailColumn
    width: detailScroll.width
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
              text: root.teamLabel(root.detail.participants[0]) + " at "
                + root.teamLabel(root.detail.participants[1])
              color: Color.popups.text
              font.family: Style.font.family
              font.pixelSize: Style.font.subtitle
              font.bold: true
              elide: Text.ElideRight
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
            text: Formatters.formatDetailStatus(root.detail.status)
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            font.bold: true
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            text: Formatters.formatDetailTiming(
              root.timeLabel(root.detail.timing.startTime),
              root.timeLabel(root.detail.timing.endTime))
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

          Text {
            width: parent.width
            text: "Outcome   " + root.valueOrDash(root.outcomeLabel())
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
          }
        }

        Column {
          width: parent.width
          visible: root.situationData !== null
          spacing: Style.spacing.xxs

          Text {
            width: parent.width
            text: "SITUATION"
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Row {
            width: parent.width
            spacing: Style.spacing.sm

            Text {
              width: Style.space(44)
              text: "COUNT"
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }

            Text {
              text: root.situationCountLabel()
              color: Color.popups.text
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }

            Text {
              width: Style.space(30)
              text: "OUT"
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }

            Text {
              text: root.situationOutsLabel()
              color: Color.popups.text
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }
          }

          Row {
            width: parent.width
            spacing: Style.spacing.sm

            Text {
              width: Style.space(44)
              text: "BASES"
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              Accessible.role: Accessible.StaticText
              Accessible.name: root.situationAccessibleBases()
            }

            Repeater {
              model: [
                {occupied: root.situationData ? root.situationData.onFirst : false},
                {occupied: root.situationData ? root.situationData.onSecond : false},
                {occupied: root.situationData ? root.situationData.onThird : false}
              ]

              delegate: Rectangle {
                required property var modelData
                width: Style.space(8)
                height: width
                radius: width / 2
                color: modelData.occupied ? Color.accent : "transparent"
                border.color: modelData.occupied ? Color.accent : Color.muted
                border.width: 1
              }
            }
          }

          Text {
            width: parent.width
            visible: Boolean(root.situationData && root.situationData.lastPlay)
            text: root.situationData && root.situationData.lastPlay
              ? "Last play   " + root.situationData.lastPlay : ""
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
          }
        }

        Column {
          width: parent.width
          spacing: Style.spacing.xxs

          Text {
            width: parent.width
            text: "SCORING BY "
              + Formatters.scoringPeriodUnit(root.detail.league).toUpperCase()
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Text {
            width: parent.width
            visible: !root.linesData
            text: "—"
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
          }

          Row {
            width: parent.width
            spacing: Style.spacing.sm

            Text {
              width: Style.space(44)
              text: "#"
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Repeater {
              model: root.linePeriods()

              delegate: Text {
                required property string modelData
                width: Style.space(30)
                text: modelData
                color: Color.muted
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
                horizontalAlignment: Text.AlignRight
              }
            }
          }

          Repeater {
            model: ["away", "home"]

            delegate: Row {
              id: linesSideRow
              required property string modelData
              width: parent.width
              spacing: Style.spacing.sm

              Text {
                width: Style.space(44)
                text: linesSideRow.modelData === "away" ? "AWAY" : "HOME"
                color: Color.muted
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
              }

              Repeater {
                model: root.lineValues(linesSideRow.modelData)

                delegate: Text {
                  required property string modelData
                  width: Style.space(30)
                  text: modelData
                  color: Color.popups.text
                  font.family: Style.font.family
                  font.pixelSize: Style.font.bodySmall
                  font.bold: true
                  horizontalAlignment: Text.AlignRight
                }
              }
            }
          }
        }

        Column {
          width: parent.width
          spacing: Style.spacing.xxs

          Text {
            width: parent.width
            text: "TEAM STATS"
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Text {
            width: parent.width
            visible: !root.statsData
            text: "—"
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
          }

          Repeater {
            model: root.statRows()

            delegate: Row {
              id: statRow
              required property var modelData
              width: parent.width
              spacing: Style.spacing.sm

              Text {
                width: parent.width - Style.space(44) * 2 - parent.spacing * 2
                text: statRow.modelData.label
                color: Color.muted
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                elide: Text.ElideRight
              }

              Text {
                width: Style.space(44)
                text: statRow.modelData.away
                color: Color.popups.text
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
                font.bold: true
                horizontalAlignment: Text.AlignRight
              }

              Text {
                width: Style.space(44)
                text: statRow.modelData.home
                color: Color.popups.text
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
                font.bold: true
                horizontalAlignment: Text.AlignRight
              }
            }
          }
        }

        Column {
          width: parent.width
          visible: root.oddsData !== null
          spacing: Style.spacing.xxs

          Text {
            width: parent.width
            text: "ODDS"
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Text {
            width: parent.width
            text: root.oddsLabel()
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            font.bold: true
            elide: Text.ElideRight
          }
        }

        Row {
          width: parent.width
          spacing: Style.spacing.sm

          Text {
            width: parent.width - actionsRow.implicitWidth - parent.spacing
            text: root.valueOrDash(root.detail.source.label)
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            verticalAlignment: Text.AlignVCenter
          }

          Row {
            id: actionsRow
            spacing: Style.spacing.xs

            SourceLinkButton {
              id: sourceLink
              game: root.game
              hasCursor: root.sourceAvailable && root.cursorIndex === 1
            }

            Repeater {
              id: extraLinkButtons
              model: root.extraLinks

              delegate: SemanticActionButton {
                id: extraLinkButton
                required property var modelData
                required property int index
                text: modelData.label
                tooltipText: "Open " + modelData.label + " page"
                textBold: true
                textFontSize: Style.font.bodySmall
                textHorizontalPadding: Style.spacing.xs
                textVerticalPadding: Style.spacing.xs
                focusable: true
                enabled: typeof modelData.url === "string"
                  && modelData.url.indexOf("https://") === 0
                hasCursor: root.cursorIndex === root.linkCursorOffset + extraLinkButton.index
                onClicked: root.openExternalUrl(modelData.url)
                Accessible.name: "Open " + modelData.label + " page"
                Accessible.role: Accessible.Button
              }
            }
          }
        }
      }
    }
  }
  }
}

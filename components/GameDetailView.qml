import QtQuick
import Quickshell
import QtQuick.Controls as QQC
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "../model/GameDetailModel.js" as GameDetailModel
import "../model/Formatters.js" as Formatters
import "../model/LifecyclePolicy.js" as LifecyclePolicy

Item {
  id: root

  property var game: null
  property string updateMessage: ""
  property bool stale: false
  property var settingsStore: null
  property double currentTime: Date.now()
  property int cursorIndex: 0
  readonly property var callbackOwner: LifecyclePolicy.createOwnerState()
  Component.onDestruction: LifecyclePolicy.invalidate(root.callbackOwner)
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
  readonly property int linkCursorOffset: 2 + (root.sourceAvailable ? 1 : 0)
  readonly property int maxCursorIndex: root.linkCursorOffset + root.extraLinks.length - 1

  onMaxCursorIndexChanged: {
    if (root.cursorIndex > root.maxCursorIndex) {
      // A refreshed sparse detail may remove the currently focused link.
      // Fall back to Back so Enter cannot activate a different game action.
      root.cursorIndex = 0
      if (root.visible) root.focusCursor()
    }
  }

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
      } else if (root.cursorIndex === 1) {
        target = watchAction
        target.focusAction()
      } else if (root.sourceAvailable && root.cursorIndex === 2) {
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
    var owner = root.callbackOwner
    var generation = LifecyclePolicy.captureGeneration(owner)
    Qt.callLater(function() {
      if (LifecyclePolicy.canRun(owner, generation) && root.visible) callback()
    })
  }

  function resetCursor() {
    root.cursorIndex = 0
    detailScroll.contentY = 0
    root.focusCursor()
  }

  function activateCursor() {
    if (root.cursorIndex === 0) root.backRequested()
    else if (root.cursorIndex === 1) watchAction.activate()
    else if (root.sourceAvailable && root.cursorIndex === 2) sourceLink.openSource()
    else {
      var link = root.extraLinks[root.cursorIndex - root.linkCursorOffset]
      if (link) root.openExternalUrl(link.url)
    }
  }

  Accessible.name: "Game details for " + root.teamLabel(root.detail.participants[0])
    + " at " + root.teamLabel(root.detail.participants[1]) + ". "
    + (watchAction.active ? "Game is watched." : "Game is not watched.")
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
              textFormat: Text.PlainText
              width: parent.width
              text: "GAME DETAILS"
              color: Commons.Color.accent
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Text {
              textFormat: Text.PlainText
              width: parent.width
              text: root.teamLabel(root.detail.participants[0]) + " at "
                + root.teamLabel(root.detail.participants[1])
              color: Commons.Color.popups.text
              font.family: Style.font.family
              font.pixelSize: Style.font.subtitle
              font.bold: true
              elide: Text.ElideRight
            }

            Text {
              textFormat: Text.PlainText
              width: parent.width
              text: root.valueOrDash(root.detail.league).toUpperCase()
                + " · " + root.valueOrDash(root.detail.source.label)
              color: Commons.Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              elide: Text.ElideRight
            }
          }
        }

    Text {
      textFormat: Text.PlainText
      width: parent.width
      visible: root.updateMessage !== ""
      text: root.updateMessage
      color: root.stale ? Commons.Color.urgent : Commons.Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
      Accessible.name: root.updateMessage
    }

    BorderSurface {
      width: parent.width
      height: detailCardColumn.implicitHeight + Style.spacing.lg * 2
      color: Commons.Color.popups.background
      borderSpec: Border.controlSpec("normal", Commons.Color.popups.text, Commons.Color.accent)
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
              textFormat: Text.PlainText
              width: Style.space(44)
              text: "AWAY"
              color: Commons.Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Column {
              width: parent.width - scoreAway.implicitWidth - parent.spacing - Style.space(44)
              spacing: Style.spacing.xxs

              Text {
                textFormat: Text.PlainText
                width: parent.width
                text: root.teamLabel(root.detail.participants[0])
                color: Commons.Color.popups.text
                font.family: Style.font.family
                font.pixelSize: Style.font.subtitle
                font.bold: true
                elide: Text.ElideRight
              }

              Text {
                textFormat: Text.PlainText
                width: parent.width
                text: root.teamName(root.detail.participants[0])
                color: Commons.Color.muted
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
                elide: Text.ElideRight
              }
            }

            Text {
              textFormat: Text.PlainText
              id: scoreAway
              text: root.scoreLabel(root.detail.participants[0])
              color: Commons.Color.popups.text
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
              textFormat: Text.PlainText
              width: Style.space(44)
              text: "HOME"
              color: Commons.Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Column {
              width: parent.width - scoreHome.implicitWidth - parent.spacing - Style.space(44)
              spacing: Style.spacing.xxs

              Text {
                textFormat: Text.PlainText
                width: parent.width
                text: root.teamLabel(root.detail.participants[1])
                color: Commons.Color.popups.text
                font.family: Style.font.family
                font.pixelSize: Style.font.subtitle
                font.bold: true
                elide: Text.ElideRight
              }

              Text {
                textFormat: Text.PlainText
                width: parent.width
                text: root.teamName(root.detail.participants[1])
                color: Commons.Color.muted
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
                elide: Text.ElideRight
              }
            }

            Text {
              textFormat: Text.PlainText
              id: scoreHome
              text: root.scoreLabel(root.detail.participants[1])
              color: Commons.Color.popups.text
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
            textFormat: Text.PlainText
            width: parent.width
            text: Formatters.formatDetailStatus(root.detail.status)
            color: Commons.Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            font.bold: true
            elide: Text.ElideRight
          }

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: Formatters.formatDetailTiming(
              root.timeLabel(root.detail.timing.startTime),
              root.timeLabel(root.detail.timing.endTime))
            color: Commons.Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
          }

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: "Venue   " + root.valueOrDash(root.detail.venue)
            color: Commons.Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
          }

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: "Outcome   " + root.valueOrDash(root.outcomeLabel())
            color: Commons.Color.muted
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
            textFormat: Text.PlainText
            width: parent.width
            text: "SITUATION"
            color: Commons.Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Row {
            width: parent.width
            spacing: Style.spacing.sm

            Text {
              textFormat: Text.PlainText
              width: Style.space(44)
              text: "COUNT"
              color: Commons.Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }

            Text {
              textFormat: Text.PlainText
              text: root.situationCountLabel()
              color: Commons.Color.popups.text
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }

            Text {
              textFormat: Text.PlainText
              width: Style.space(30)
              text: "OUT"
              color: Commons.Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }

            Text {
              textFormat: Text.PlainText
              text: root.situationOutsLabel()
              color: Commons.Color.popups.text
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }
          }

          Row {
            width: parent.width
            spacing: Style.spacing.sm

            Text {
              textFormat: Text.PlainText
              width: Style.space(44)
              text: "BASES"
              color: Commons.Color.muted
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
                color: modelData.occupied ? Commons.Color.accent : "transparent"
                border.color: modelData.occupied ? Commons.Color.accent : Commons.Color.muted
                border.width: 1
              }
            }
          }

          Text {
            textFormat: Text.PlainText
            width: parent.width
            visible: Boolean(root.situationData && root.situationData.lastPlay)
            text: root.situationData && root.situationData.lastPlay
              ? "Last play   " + root.situationData.lastPlay : ""
            color: Commons.Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
          }
        }

        Column {
          width: parent.width
          spacing: Style.spacing.xxs

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: "SCORING BY "
              + Formatters.scoringPeriodUnit(root.detail.league).toUpperCase()
            color: Commons.Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Text {
            textFormat: Text.PlainText
            width: parent.width
            visible: !root.linesData
            text: "—"
            color: Commons.Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
          }

          Row {
            width: parent.width
            spacing: Style.spacing.sm

            Text {
              textFormat: Text.PlainText
              width: Style.space(44)
              text: "#"
              color: Commons.Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Repeater {
              model: root.linePeriods()

              delegate: Text {
                textFormat: Text.PlainText
                required property string modelData
                width: Style.space(30)
                text: modelData
                color: Commons.Color.muted
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
                textFormat: Text.PlainText
                width: Style.space(44)
                text: linesSideRow.modelData === "away" ? "AWAY" : "HOME"
                color: Commons.Color.muted
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
              }

              Repeater {
                model: root.lineValues(linesSideRow.modelData)

                delegate: Text {
                  textFormat: Text.PlainText
                  required property string modelData
                  width: Style.space(30)
                  text: modelData
                  color: Commons.Color.popups.text
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
            textFormat: Text.PlainText
            width: parent.width
            text: "TEAM STATS"
            color: Commons.Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Text {
            textFormat: Text.PlainText
            width: parent.width
            visible: !root.statsData
            text: "—"
            color: Commons.Color.muted
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
                textFormat: Text.PlainText
                width: parent.width - Style.space(44) * 2 - parent.spacing * 2
                text: statRow.modelData.label
                color: Commons.Color.muted
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                elide: Text.ElideRight
              }

              Text {
                textFormat: Text.PlainText
                width: Style.space(44)
                text: statRow.modelData.away
                color: Commons.Color.popups.text
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
                font.bold: true
                horizontalAlignment: Text.AlignRight
              }

              Text {
                textFormat: Text.PlainText
                width: Style.space(44)
                text: statRow.modelData.home
                color: Commons.Color.popups.text
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
            textFormat: Text.PlainText
            width: parent.width
            text: "ODDS"
            color: Commons.Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: root.oddsLabel()
            color: Commons.Color.popups.text
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
            textFormat: Text.PlainText
            width: parent.width - actionsRow.implicitWidth - parent.spacing
            text: root.valueOrDash(root.detail.source.label)
            color: Commons.Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            verticalAlignment: Text.AlignVCenter
          }

          Row {
            id: actionsRow
            spacing: Style.spacing.xs

            WatchAction {
              id: watchAction
              game: root.game
              settingsStore: root.settingsStore
              currentTime: root.currentTime
              hasCursor: root.cursorIndex === 1
            }

            SourceLinkButton {
              id: sourceLink
              game: root.game
              hasCursor: root.sourceAvailable && root.cursorIndex === 2
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

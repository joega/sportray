import QtQuick
import "../model/UiTypography.js" as Typography
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
  property var imageStore: null
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
    if (url.indexOf("mlb.com") !== -1) return {provider: "mlb", label: "MLB.com"}
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
    if (outcome.winner === "draw") return "Draw"
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
    var next = Math.max(0, Math.min(root.maxCursorIndex, root.cursorIndex + delta))
    if (next === 1 && !watchAction.available)
      next = delta < 0 ? 0 : root.maxCursorIndex >= 2 ? 2 : 0
    root.cursorIndex = next
    root.focusCursor()
  }

  function scrollLines(delta) {
    if (!root.linesData || linesScroll.contentWidth <= linesScroll.width) return false
    root.ensureVisible(linesScroll)
    linesScroll.contentX = Math.max(0, Math.min(linesScroll.contentWidth - linesScroll.width,
      linesScroll.contentX + delta * Style.space(96)))
    return true
  }

  function scrollPage(direction) {
    detailScroll.contentY = Math.max(0, Math.min(detailScroll.contentHeight - detailScroll.height,
      detailScroll.contentY + direction * detailScroll.height * 0.8))
  }

  function scrollEdge(direction) {
    detailScroll.contentY = direction < 0 ? 0 : Math.max(0, detailScroll.contentHeight - detailScroll.height)
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
    linesScroll.contentX = 0
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
          textFontSize: Style.font.bodySmall
          focusable: true
          hasCursor: root.cursorIndex === 0
          onClicked: root.backRequested()
          Accessible.name: "Back to scores"
        }

        Text {
          width: Math.max(0, parent.width - backButton.width - parent.spacing)
          anchors.verticalCenter: parent.verticalCenter
          text: root.valueOrDash(root.detail.league).toUpperCase()
            + " · " + root.valueOrDash(root.detail.source.label)
          textFormat: Text.PlainText
          color: Qt.alpha(Commons.Color.popups.text, 0.85)
          font.family: Typography.family
          font.pixelSize: Style.font.bodySmall
          horizontalAlignment: Text.AlignRight
          elide: Text.ElideRight
        }
      }

      Text {
        width: parent.width
        visible: root.updateMessage !== ""
        text: root.updateMessage
        textFormat: Text.PlainText
        color: root.stale ? Commons.Color.urgent : Qt.alpha(Commons.Color.popups.text, 0.85)
        font.family: Typography.family
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
        Accessible.name: root.updateMessage
      }

      Column {
        width: parent.width
        spacing: Style.spacing.sm

        Repeater {
          model: root.detail.participants
          delegate: Row {
            id: participantRow
            required property var modelData
            required property int index
            readonly property string logoSource: root.imageStore && modelData.team && modelData.team.logoUrl
              ? root.imageStore.sourceFor(modelData.team.logoUrl) : ""
            width: parent.width
            spacing: Style.spacing.sm

            Item {
              width: Style.space(36)
              height: width
              anchors.verticalCenter: parent.verticalCenter
              Rectangle {
                anchors.fill: parent
                anchors.margins: -Style.space(2)
                radius: Style.space(4)
                color: "#f5f5f5"
                visible: participantLogo.visible
              }
              Image {
                id: participantLogo
                anchors.fill: parent
                source: participantRow.logoSource
                sourceSize: Qt.size(width * 2, height * 2)
                fillMode: Image.PreserveAspectFit
                visible: status === Image.Ready
                asynchronous: true
              }
              Text {
                anchors.centerIn: parent
                text: root.teamLabel(participantRow.modelData)
                textFormat: Text.PlainText
                visible: !participantLogo.visible
                color: Qt.alpha(Commons.Color.popups.text, 0.85)
                font.family: Typography.family
                font.pixelSize: Style.font.caption
              }
            }

            Column {
              width: Math.max(0, parent.width - teamScore.width
                - Style.space(36) - parent.spacing * 2)
              spacing: Style.spacing.xxs
              anchors.verticalCenter: parent.verticalCenter
              Text {
                width: parent.width
                text: root.teamName(participantRow.modelData)
                textFormat: Text.PlainText
                color: Commons.Color.popups.text
                font.family: Typography.family
                font.pixelSize: Style.font.subtitle
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
              }
              Text {
                text: participantRow.index === 0 ? "Away" : "Home"
                textFormat: Text.PlainText
                color: Qt.alpha(Commons.Color.popups.text, 0.85)
                font.family: Typography.family
                font.pixelSize: Style.font.caption
              }
            }

            Text {
              id: teamScore
              width: Style.space(64)
              anchors.verticalCenter: parent.verticalCenter
              text: root.scoreLabel(participantRow.modelData)
              textFormat: Text.PlainText
              color: Commons.Color.popups.text
              font.family: Typography.family
              font.pixelSize: Style.font.display
              font.features: ({"tnum": 1})
              font.bold: true
              horizontalAlignment: Text.AlignRight
            }
          }
        }

        Text {
          width: parent.width
          text: Formatters.formatDetailStatus(root.detail.status)
          textFormat: Text.PlainText
          color: root.stale ? Commons.Color.urgent : Commons.Color.accent
          font.family: Typography.family
          font.pixelSize: Style.font.body
          font.weight: Font.DemiBold
          wrapMode: Text.WordWrap
        }
      }

      Flow {
        width: parent.width
        spacing: Style.spacing.sm
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
            textFontSize: Style.font.bodySmall
            focusable: true
            enabled: typeof modelData.url === "string" && modelData.url.indexOf("https://") === 0
            hasCursor: root.cursorIndex === root.linkCursorOffset + extraLinkButton.index
            onClicked: root.openExternalUrl(modelData.url)
            Accessible.name: "Open " + modelData.label + " page"
          }
        }
      }

      Rectangle { width: parent.width; height: 1; color: Commons.Color.popups.text; opacity: 0.12 }

      Column {
        width: parent.width
        spacing: Style.spacing.xs
        Text {
          width: parent.width
          visible: Boolean(root.detail.timing.startTime)
          text: Formatters.formatDetailTiming(root.timeLabel(root.detail.timing.startTime),
            root.timeLabel(root.detail.timing.endTime))
          textFormat: Text.PlainText
          color: Qt.alpha(Commons.Color.popups.text, 0.85)
          font.family: Typography.family
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
        }
        Text {
          width: parent.width
          visible: Boolean(root.detail.venue)
          text: root.valueOrDash(root.detail.venue)
          textFormat: Text.PlainText
          color: Qt.alpha(Commons.Color.popups.text, 0.85)
          font.family: Typography.family
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
        }
        Text {
          width: parent.width
          visible: root.outcomeLabel() !== null
          text: root.valueOrDash(root.outcomeLabel())
          textFormat: Text.PlainText
          color: Commons.Color.popups.text
          font.family: Typography.family
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
        }
      }

      Column {
        width: parent.width
        visible: root.situationData !== null
        spacing: Style.spacing.sm
        Text {
          text: "Game situation"
          textFormat: Text.PlainText
          color: Commons.Color.popups.text
          font.family: Typography.family
          font.pixelSize: Style.font.body
          font.weight: Font.DemiBold
        }
        Text {
          width: parent.width
          text: "Count " + root.situationCountLabel() + " · " + root.situationOutsLabel() + " out"
          textFormat: Text.PlainText
          color: Commons.Color.popups.text
          font.family: Typography.family
          font.pixelSize: Style.font.bodySmall
        }
        Row {
          spacing: Style.spacing.sm
          Text {
            text: "Bases"
            textFormat: Text.PlainText
            color: Qt.alpha(Commons.Color.popups.text, 0.85)
            font.family: Typography.family
            font.pixelSize: Style.font.bodySmall
            Accessible.name: root.situationAccessibleBases()
          }
          Repeater {
            model: [root.situationData ? root.situationData.onFirst : false,
              root.situationData ? root.situationData.onSecond : false,
              root.situationData ? root.situationData.onThird : false]
            Rectangle {
              required property bool modelData
              width: Style.space(9)
              height: width
              anchors.verticalCenter: parent.verticalCenter
              rotation: 45
              color: modelData ? Commons.Color.accent : "transparent"
              border.color: modelData ? Commons.Color.accent : Qt.alpha(Commons.Color.popups.text, 0.85)
              border.width: 1
              Accessible.ignored: true
            }
          }
        }
        Text {
          width: parent.width
          visible: Boolean(root.situationData && root.situationData.lastPlay)
          text: root.situationData && root.situationData.lastPlay ? root.situationData.lastPlay : ""
          textFormat: Text.PlainText
          color: Commons.Color.popups.text
          font.family: Typography.family
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
        }
      }

      Column {
        width: parent.width
        visible: root.linesData !== null
        spacing: Style.spacing.sm
        Text {
          text: "Scoring by " + Formatters.scoringPeriodUnit(root.detail.league).toLowerCase()
          textFormat: Text.PlainText
          color: Commons.Color.popups.text
          font.family: Typography.family
          font.pixelSize: Style.font.body
          font.weight: Font.DemiBold
        }
        Flickable {
          id: linesScroll
          width: parent.width
          height: linesTable.implicitHeight + (contentWidth > width ? Style.space(10) : 0)
          contentWidth: Math.max(width, Style.space(48) + root.linePeriods().length * Style.space(32))
          contentHeight: linesTable.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          flickableDirection: Flickable.HorizontalFlick
          interactive: contentWidth > width
          QQC.ScrollBar.horizontal: QQC.ScrollBar { policy: QQC.ScrollBar.AsNeeded }
          Column {
            id: linesTable
            width: linesScroll.contentWidth
            spacing: Style.spacing.xs
            Row {
              width: parent.width
              Text {
                width: Style.space(48)
                text: "Team"
                textFormat: Text.PlainText
                color: Qt.alpha(Commons.Color.popups.text, 0.85)
                font.family: Typography.family
                font.pixelSize: Style.font.caption
              }
              Repeater {
                model: root.linePeriods()
                Text {
                  required property string modelData
                  width: (linesTable.width - Style.space(48)) / Math.max(1, root.linePeriods().length)
                  text: modelData
                  textFormat: Text.PlainText
                  color: Qt.alpha(Commons.Color.popups.text, 0.85)
                  font.family: Typography.family
                  font.pixelSize: Style.font.caption
                  horizontalAlignment: Text.AlignRight
                }
              }
            }
            Repeater {
              model: ["away", "home"]
              Row {
                id: linesSideRow
                required property string modelData
                width: linesTable.width
                Text {
                  width: Style.space(48)
                  text: root.teamLabel(root.detail.participants[linesSideRow.modelData === "away" ? 0 : 1])
                  textFormat: Text.PlainText
                  color: Commons.Color.popups.text
                  font.family: Typography.family
                  font.pixelSize: Style.font.bodySmall
                  elide: Text.ElideRight
                }
                Repeater {
                  model: root.lineValues(linesSideRow.modelData)
                  Text {
                    required property string modelData
                    width: (linesTable.width - Style.space(48)) / Math.max(1, root.linePeriods().length)
                    text: modelData
                    textFormat: Text.PlainText
                    color: Commons.Color.popups.text
                    font.family: Typography.family
                    font.pixelSize: Style.font.bodySmall
                    font.features: ({"tnum": 1})
                    horizontalAlignment: Text.AlignRight
                  }
                }
              }
            }
          }
        }
        Text {
          width: parent.width
          visible: linesScroll.contentWidth > linesScroll.width
          text: "← / → to see more " + Formatters.scoringPeriodUnit(root.detail.league).toLowerCase() + "s"
          textFormat: Text.PlainText
          color: Qt.alpha(Commons.Color.popups.text, 0.85)
          font.family: Typography.family
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }
      }

      Column {
        width: parent.width
        visible: root.statsData !== null
        spacing: Style.spacing.sm
        Row {
          width: parent.width
          Text {
            width: parent.width - Style.space(100)
            text: "Team stats"
            textFormat: Text.PlainText
            color: Commons.Color.popups.text
            font.family: Typography.family
            font.pixelSize: Style.font.body
            font.weight: Font.DemiBold
          }
          Repeater {
            model: root.detail.participants
            Text {
              required property var modelData
              width: Style.space(50)
              text: root.teamLabel(modelData)
              textFormat: Text.PlainText
              color: Qt.alpha(Commons.Color.popups.text, 0.85)
              font.family: Typography.family
              font.pixelSize: Style.font.caption
              horizontalAlignment: Text.AlignRight
              elide: Text.ElideRight
            }
          }
        }
        Repeater {
          model: root.statRows()
          Row {
            id: statRow
            required property var modelData
            width: parent.width
            Text {
              width: parent.width - Style.space(100)
              text: statRow.modelData.label
              textFormat: Text.PlainText
              color: Qt.alpha(Commons.Color.popups.text, 0.85)
              font.family: Typography.family
              font.pixelSize: Style.font.bodySmall
              wrapMode: Text.WordWrap
            }
            Repeater {
              model: [statRow.modelData.away, statRow.modelData.home]
              Text {
                required property string modelData
                width: Style.space(50)
                text: modelData
                textFormat: Text.PlainText
                color: Commons.Color.popups.text
                font.family: Typography.family
                font.pixelSize: Style.font.bodySmall
                font.features: ({"tnum": 1})
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
              }
            }
          }
        }
      }

      Column {
        width: parent.width
        visible: root.oddsData !== null && root.detail.status.state === "scheduled"
        spacing: Style.spacing.xs
        Text {
          text: "Pregame odds"
          textFormat: Text.PlainText
          color: Commons.Color.popups.text
          font.family: Typography.family
          font.pixelSize: Style.font.body
          font.weight: Font.DemiBold
        }
        Text {
          width: parent.width
          text: root.oddsLabel()
          textFormat: Text.PlainText
          color: Qt.alpha(Commons.Color.popups.text, 0.85)
          font.family: Typography.family
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
        }
      }
    }
  }
}

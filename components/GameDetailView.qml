pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import "../model/UiTypography.js" as Typography
import "../model/UiContrast.js" as UiContrast
import Quickshell
import QtQuick.Controls as QQC
import qs.Commons as Commons
import qs.Ui
import "../model/GameDetailModel.js" as GameDetailModel
import "../model/Formatters.js" as Formatters
import "../model/LifecyclePolicy.js" as LifecyclePolicy
import "../model/NoticePresentation.js" as NoticePresentation

Item {
  id: root

  property var game: null
  property var imageStore: null
  property string updateMessage: ""
  property bool stale: false
  property bool loading: false
  property string lastSuccessAt: ""
  property var settingsStore: null
  property double currentTime: Date.now()
  property int cursorIndex: 0
  property string focusId: "back"
  readonly property var callbackOwner: LifecyclePolicy.createOwnerState()
  Component.onDestruction: LifecyclePolicy.invalidate(root.callbackOwner)
  signal backRequested()
  signal teamScheduleRequested(string teamId)
  signal refreshRequested()

  readonly property var sourceMetadata: sourceMetadataFor(root.game)
  readonly property var detail: GameDetailModel.normalizeDetail(root.game, root.sourceMetadata)
  readonly property bool scheduledPresentation: root.detail.status.state === "scheduled"
  readonly property bool finalPresentation: root.detail.status.state === "final"
  readonly property bool livePresentation: root.detail.status.state === "live" || root.detail.status.state === "intermission"
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
  readonly property var updateNotice: NoticePresentation.noticeFor({
    kind: "detail", hasData: Boolean(root.game && root.game.isValid === true),
    loading: root.loading, stale: root.stale, lastSuccessAt: root.lastSuccessAt,
    errorSummary: root.stale ? root.updateMessage : "", failed: root.stale,
    canRetry: root.stale && !root.loading
  }, root.currentTime)
  readonly property var cursorActions: root.buildCursorActions()
  readonly property int linkCursorOffset: 4 + (root.sourceAvailable ? 1 : 0)
  readonly property int maxCursorIndex: root.cursorActions.length - 1

  function buildCursorActions() {
    var participants = root.detail.participants
    var actions = [{id: "back", enabled: true},
      {id: "away-schedule", enabled: Boolean(participants[0] && participants[0].team && participants[0].team.id)},
      {id: "home-schedule", enabled: Boolean(participants[1] && participants[1].team && participants[1].team.id)},
      {id: "watch", enabled: Boolean(watchAction && watchAction.available)}]
    if (root.sourceAvailable) actions.push({id: "source", enabled: true})
    root.extraLinks.forEach(function(link, index) {
      actions.push({id: "link:" + link.url, extraIndex: index,
        enabled: typeof link.url === "string" && link.url.indexOf("https://") === 0})
    })
    if (root.updateNotice.visible && root.updateNotice.detail)
      actions.push({id: "status-details", enabled: true})
    if (root.updateNotice.visible && root.updateNotice.canRetry)
      actions.push({id: "status-retry", enabled: true})
    return actions
  }
  function indexForFocusId(id) {
    for (var i = 0; i < root.cursorActions.length; i++)
      if (root.cursorActions[i].id === id && root.cursorActions[i].enabled) return i
    return -1
  }
  onCursorIndexChanged: {
    if (root.cursorIndex < 0 || root.cursorIndex >= root.cursorActions.length) root.cursorIndex = 0
    var action = root.cursorActions[root.cursorIndex]
    if (action) root.focusId = action.id
  }
  onCursorActionsChanged: {
    var index = root.indexForFocusId(root.focusId)
    if (index < 0) index = 0
    if (root.cursorIndex !== index) root.cursorIndex = index
    else if (root.cursorActions[index]) root.focusId = root.cursorActions[index].id
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
    var step = delta < 0 ? -1 : 1
    for (var next = root.cursorIndex + step; next >= 0 && next <= root.maxCursorIndex; next += step) {
      if (root.cursorActions[next].enabled) {
        root.cursorIndex = next
        root.focusCursor()
        return
      }
    }
  }

  function scrollLines(delta) {
    if (!root.linesData || linesScroll.contentWidth <= linesScroll.width) return false
    root.ensureVisible(linesScroll)
    linesScroll.contentX = Math.max(0, Math.min(linesScroll.contentWidth - linesScroll.width,
      linesScroll.contentX + delta * Commons.Style.space(96)))
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

  function targetForAction(action) {
    if (!action) return null
    if (action.id === "back") return backButton
    if (action.id === "away-schedule" || action.id === "home-schedule") {
      var row = participantRows.itemAt(action.id === "away-schedule" ? 0 : 1)
      return row ? row.teamLink : null
    }
    if (action.id === "watch") return watchAction
    if (action.id === "source") return sourceLink
    if (action.id === "status-details" || action.id === "status-retry") return detailNotice
    return typeof action.extraIndex === "number" ? extraLinkButtons.itemAt(action.extraIndex) : null
  }
  function focusAction(ensureViewport) {
    var action = root.cursorActions[root.cursorIndex]
    var target = root.targetForAction(action)
    if (!target) return
    if (action.id === "watch" || action.id === "source") target.focusAction()
    else if (action.id === "status-details" || action.id === "status-retry") {
      detailNotice.activeAction = action.id === "status-details" ? "details" : "retry"
      detailNotice.forceActiveFocus()
    } else target.forceActiveFocus()
    if (ensureViewport) root.ensureVisible(target)
  }
  function focusCursor() { root.deferFocus(function() { root.focusAction(true) }) }
  function syncFocusId(item) {
    if (!root.visible || !item) return
    for (var i = 0; i < root.cursorActions.length; i++) {
      var action = root.cursorActions[i]
      if (!action.enabled) continue
      if (action.id === "status-details" && detailNotice.activeAction !== "details"
          || action.id === "status-retry" && detailNotice.activeAction !== "retry") continue
      var target = root.targetForAction(action)
      for (var ancestor = item, depth = 0; ancestor && depth < 64; ancestor = ancestor.parent, depth++) {
        if (ancestor === target) {
          root.cursorIndex = i
          return
        }
        if (ancestor === root) break
      }
    }
  }
  Connections {
    target: root.Window.window
    function onActiveFocusItemChanged() {
      if (root.Window.window) root.syncFocusId(root.Window.window.activeFocusItem)
    }
  }
  function captureContext() {
    return {scrollY: detailScroll.contentY, linesX: linesScroll.contentX,
      focusId: root.focusId, cursorIndex: root.cursorIndex,
      noticeExpanded: detailNotice.expanded, noticeAction: detailNotice.activeAction}
  }
  function restoreContext(snapshot) {
    if (!snapshot || typeof snapshot !== "object") return false
    var index = root.indexForFocusId(snapshot.focusId)
    root.cursorIndex = index >= 0 ? index : 0
    root.deferFocus(function() {
      detailNotice.expanded = snapshot.noticeExpanded === true && Boolean(root.updateNotice.detail)
      if (detailNotice.actions.indexOf(snapshot.noticeAction) !== -1)
        detailNotice.activeAction = snapshot.noticeAction
      root.focusAction(false)
      detailScroll.contentY = Math.max(0, Math.min(detailScroll.contentHeight - detailScroll.height,
        typeof snapshot.scrollY === "number" && isFinite(snapshot.scrollY) ? snapshot.scrollY : 0))
      linesScroll.contentX = Math.max(0, Math.min(linesScroll.contentWidth - linesScroll.width,
        typeof snapshot.linesX === "number" && isFinite(snapshot.linesX) ? snapshot.linesX : 0))
    })
    return true
  }

  function deferFocus(callback) {
    if (typeof callback !== "function") return
    var owner = root.callbackOwner
    var generation = LifecyclePolicy.captureGeneration(owner)
    Qt.callLater(function() {
      if (!owner || owner.alive !== true || owner.generation !== generation) return
      if (root.visible) callback()
    })
  }

  function resetCursor() {
    root.cursorIndex = 0
    detailScroll.contentY = 0
    linesScroll.contentX = 0
    root.focusCursor()
  }

  function requestTeam(index) {
    var participant = root.detail.participants[index]
    if (!participant || !participant.team || !participant.team.id) return
    var cursor = root.indexForFocusId(index === 0 ? "away-schedule" : "home-schedule")
    if (cursor >= 0) root.cursorIndex = cursor
    root.teamScheduleRequested(participant.team.id)
  }
  function activateCursor() {
    var action = root.cursorActions[root.cursorIndex]
    if (!action || !action.enabled) return
    if (action.id === "back") root.backRequested()
    else if (action.id === "away-schedule") root.requestTeam(0)
    else if (action.id === "home-schedule") root.requestTeam(1)
    else if (action.id === "watch") watchAction.activate()
    else if (action.id === "source") sourceLink.openSource()
    else if (action.id === "status-details" || action.id === "status-retry") {
      detailNotice.activeAction = action.id === "status-details" ? "details" : "retry"
      detailNotice.activateCursor()
    } else {
      var link = root.extraLinks[action.extraIndex]
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
      spacing: Commons.Style.spacing.md

      Row {
        width: parent.width
        spacing: Commons.Style.spacing.sm

        SemanticActionButton {
          id: backButton
          text: "Back"
          tooltipText: "Return to scores"
          textFontSize: Commons.Style.font.bodySmall
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
          font.pixelSize: Commons.Style.font.bodySmall
          horizontalAlignment: Text.AlignRight
          elide: Text.ElideRight
        }
      }

      StatusNotice {
        id: detailNotice
        width: parent.width
        notice: root.updateNotice
        hasCursor: root.focusId === "status-details" || root.focusId === "status-retry"
        onRetryRequested: root.refreshRequested()
        onContentFocusRequested: {
          var index = root.indexForFocusId(detailNotice.activeAction === "retry" ? "status-retry" : "status-details")
          if (index >= 0) root.cursorIndex = index
        }
        onBoundsChanged: {
          if (detailNotice.activeFocus) root.ensureVisible(detailNotice)
        }
      }

      Column {
        objectName: "detailHero"
        width: parent.width
        spacing: Commons.Style.spacing.sm

        Repeater {
          id: participantRows
          model: root.detail.participants
          delegate: Row {
            id: participantRow
            required property var modelData
            required property int index
            property alias teamLink: participantTeamLink
            readonly property string logoSource: root.imageStore && modelData.team && modelData.team.logoUrl
              ? root.imageStore.sourceFor(modelData.team.logoUrl) : ""
            width: parent.width
            spacing: Commons.Style.spacing.sm

            Item {
              width: Commons.Style.space(36)
              height: width
              anchors.verticalCenter: parent.verticalCenter
              Rectangle {
                anchors.fill: parent
                anchors.margins: -Commons.Style.space(2)
                radius: Commons.Style.space(4)
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
                width: parent.width
                text: participantRow.modelData.team ? root.teamLabel(participantRow.modelData).slice(0, 3) : "?"
                textFormat: Text.PlainText
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                visible: !participantLogo.visible
                color: Qt.alpha(Commons.Color.popups.text, 0.85)
                font.family: Typography.family
                font.pixelSize: Commons.Style.font.caption
              }
            }

            Column {
              width: Math.max(0, parent.width - teamScore.width
                - Commons.Style.space(36) - parent.spacing * 2)
              spacing: Commons.Style.spacing.xxs
              anchors.verticalCenter: parent.verticalCenter
              TeamScheduleLink {
                id: participantTeamLink
                width: parent.width
                height: implicitHeight
                team: participantRow.modelData.team
                text: root.teamName(participantRow.modelData)
                foreground: Commons.Color.popups.text
                fontSize: Commons.Style.font.subtitle
                bold: true
                wrap: true
                hasCursor: root.focusId === (participantRow.index === 0 ? "away-schedule" : "home-schedule")
                onRequested: root.requestTeam(participantRow.index)
              }
              Text {
                text: participantRow.index === 0 ? "Away" : "Home"
                textFormat: Text.PlainText
                color: Qt.alpha(Commons.Color.popups.text, 0.85)
                font.family: Typography.family
                font.pixelSize: Commons.Style.font.caption
              }
            }

            Text {
              id: teamScore
              objectName: "detailScore" + participantRow.index
              visible: !root.scheduledPresentation
              width: root.scheduledPresentation ? 0 : Commons.Style.space(64)
              anchors.verticalCenter: parent.verticalCenter
              text: root.scoreLabel(participantRow.modelData)
              textFormat: Text.PlainText
              color: Commons.Color.popups.text
              font.family: Typography.family
              font.pixelSize: Commons.Style.font.display
              font.features: ({"tnum": 1})
              font.bold: true
              horizontalAlignment: Text.AlignRight
            }
          }
        }

        Text {
          objectName: "detailStatus"
          width: parent.width
          text: Formatters.formatDetailStatus(root.detail.status)
          textFormat: Text.PlainText
          color: root.stale ? Commons.Color.urgent : root.livePresentation
            ? UiContrast.foreground(Commons.Color.accent, Commons.Color.popups.text, Commons.Color.popups.background)
            : Qt.alpha(Commons.Color.popups.text, 0.85)
          font.family: Typography.family
          font.pixelSize: root.scheduledPresentation ? Commons.Style.font.bodySmall : Commons.Style.font.body
          font.weight: root.livePresentation ? Font.DemiBold : Font.Normal
          wrapMode: Text.WordWrap
        }
        Text {
          objectName: "detailOutcome"
          width: parent.width
          visible: root.finalPresentation && root.outcomeLabel() !== null
          text: root.outcomeLabel() || ""
          textFormat: Text.PlainText
          color: Commons.Color.popups.text
          font.family: Typography.family
          font.pixelSize: Commons.Style.font.subtitle
          font.weight: Font.DemiBold
          wrapMode: Text.WordWrap
        }
      }

      Column {
        objectName: "detailPregame"
        width: parent.width
        visible: root.scheduledPresentation
        spacing: Commons.Style.spacing.sm
        Text {
          objectName: "detailStartTime"
          width: parent.width
          text: root.detail.timing.startTime ? root.timeLabel(root.detail.timing.startTime) : "Start time unavailable"
          textFormat: Text.PlainText
          color: Commons.Color.popups.text
          font.family: Typography.family
          font.pixelSize: Commons.Style.font.subtitle
          font.weight: Font.DemiBold
          wrapMode: Text.WordWrap
        }
        Text {
          width: parent.width
          visible: Boolean(root.detail.venue)
          text: root.detail.venue || ""
          textFormat: Text.PlainText
          color: Qt.alpha(Commons.Color.popups.text, 0.85)
          font.family: Typography.family
          font.pixelSize: Commons.Style.font.bodySmall
          wrapMode: Text.WordWrap
        }
        Column {
          width: parent.width
          visible: root.oddsData !== null
          spacing: Commons.Style.spacing.xs
          Text {
            text: "Pregame odds"
            textFormat: Text.PlainText
            color: Commons.Color.popups.text
            font.family: Typography.family
            font.pixelSize: Commons.Style.font.bodySmall
            font.weight: Font.DemiBold
          }
          Text {
            width: parent.width
            text: root.oddsLabel()
            textFormat: Text.PlainText
            color: Qt.alpha(Commons.Color.popups.text, 0.85)
            font.family: Typography.family
            font.pixelSize: Commons.Style.font.bodySmall
            wrapMode: Text.WordWrap
          }
        }
      }

      Flow {
        objectName: "detailActions"
        width: parent.width
        spacing: Commons.Style.spacing.sm
        WatchAction {
          id: watchAction
          game: root.game
          settingsStore: root.settingsStore
          currentTime: root.currentTime
          hasCursor: root.focusId === "watch"
        }
        SourceLinkButton {
          id: sourceLink
          game: root.game
          hasCursor: root.focusId === "source"
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
            textFontSize: Commons.Style.font.bodySmall
            focusable: true
            enabled: typeof modelData.url === "string" && modelData.url.indexOf("https://") === 0
            hasCursor: root.focusId === "link:" + modelData.url
            onClicked: root.openExternalUrl(modelData.url)
            Accessible.name: "Open " + modelData.label + " page"
          }
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        visible: !root.scheduledPresentation || root.linesData !== null || root.statsData !== null || root.situationData !== null
        color: Commons.Color.popups.text
        opacity: 0.12
      }


      Column {
        width: parent.width
        visible: root.situationData !== null
        spacing: Commons.Style.spacing.sm
        Text {
          text: root.finalPresentation ? "Last game situation" : "Game situation"
          textFormat: Text.PlainText
          color: Commons.Color.popups.text
          font.family: Typography.family
          font.pixelSize: Commons.Style.font.body
          font.weight: Font.DemiBold
        }
        Text {
          width: parent.width
          text: "Count " + root.situationCountLabel() + " · " + root.situationOutsLabel() + " out"
          textFormat: Text.PlainText
          color: Commons.Color.popups.text
          font.family: Typography.family
          font.pixelSize: Commons.Style.font.bodySmall
        }
        Row {
          spacing: Commons.Style.spacing.sm
          Text {
            text: "Bases"
            textFormat: Text.PlainText
            color: Qt.alpha(Commons.Color.popups.text, 0.85)
            font.family: Typography.family
            font.pixelSize: Commons.Style.font.bodySmall
            Accessible.name: root.situationAccessibleBases()
          }
          Repeater {
            model: [root.situationData ? root.situationData.onFirst : false,
              root.situationData ? root.situationData.onSecond : false,
              root.situationData ? root.situationData.onThird : false]
            Rectangle {
              required property bool modelData
              width: Commons.Style.space(9)
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
          font.pixelSize: Commons.Style.font.bodySmall
          wrapMode: Text.WordWrap
        }
      }

      Column {
        width: parent.width
        visible: root.linesData !== null
        spacing: Commons.Style.spacing.sm
        Text {
          text: "Scoring by " + Formatters.scoringPeriodUnit(root.detail.league).toLowerCase()
          textFormat: Text.PlainText
          color: Commons.Color.popups.text
          font.family: Typography.family
          font.pixelSize: Commons.Style.font.body
          font.weight: Font.DemiBold
        }
        Flickable {
          id: linesScroll
          width: parent.width
          height: linesTable.implicitHeight + (contentWidth > width ? Commons.Style.space(10) : 0)
          contentWidth: Math.max(width, Commons.Style.space(48) + root.linePeriods().length * Commons.Style.space(32))
          contentHeight: linesTable.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          flickableDirection: Flickable.HorizontalFlick
          interactive: contentWidth > width
          QQC.ScrollBar.horizontal: QQC.ScrollBar { policy: QQC.ScrollBar.AsNeeded }
          Column {
            id: linesTable
            width: linesScroll.contentWidth
            spacing: Commons.Style.spacing.xs
            Row {
              width: parent.width
              Text {
                width: Commons.Style.space(48)
                text: "Team"
                textFormat: Text.PlainText
                color: Qt.alpha(Commons.Color.popups.text, 0.85)
                font.family: Typography.family
                font.pixelSize: Commons.Style.font.caption
              }
              Repeater {
                model: root.linePeriods()
                Text {
                  required property string modelData
                  width: (linesTable.width - Commons.Style.space(48)) / Math.max(1, root.linePeriods().length)
                  text: modelData
                  textFormat: Text.PlainText
                  color: Qt.alpha(Commons.Color.popups.text, 0.85)
                  font.family: Typography.family
                  font.pixelSize: Commons.Style.font.caption
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
                  width: Commons.Style.space(48)
                  text: root.teamLabel(root.detail.participants[linesSideRow.modelData === "away" ? 0 : 1])
                  textFormat: Text.PlainText
                  color: Commons.Color.popups.text
                  font.family: Typography.family
                  font.pixelSize: Commons.Style.font.bodySmall
                  elide: Text.ElideRight
                }
                Repeater {
                  model: root.lineValues(linesSideRow.modelData)
                  Text {
                    required property string modelData
                    width: (linesTable.width - Commons.Style.space(48)) / Math.max(1, root.linePeriods().length)
                    text: modelData
                    textFormat: Text.PlainText
                    color: Commons.Color.popups.text
                    font.family: Typography.family
                    font.pixelSize: Commons.Style.font.bodySmall
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
          font.pixelSize: Commons.Style.font.caption
          wrapMode: Text.WordWrap
        }
      }

      Column {
        width: parent.width
        visible: root.statsData !== null
        spacing: Commons.Style.spacing.sm
        Row {
          width: parent.width
          Text {
            width: parent.width - Commons.Style.space(100)
            text: "Team stats"
            textFormat: Text.PlainText
            color: Commons.Color.popups.text
            font.family: Typography.family
            font.pixelSize: Commons.Style.font.body
            font.weight: Font.DemiBold
          }
          Repeater {
            model: root.detail.participants
            Text {
              required property var modelData
              width: Commons.Style.space(50)
              text: root.teamLabel(modelData)
              textFormat: Text.PlainText
              color: Qt.alpha(Commons.Color.popups.text, 0.85)
              font.family: Typography.family
              font.pixelSize: Commons.Style.font.caption
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
              width: parent.width - Commons.Style.space(100)
              text: statRow.modelData.label
              textFormat: Text.PlainText
              color: Qt.alpha(Commons.Color.popups.text, 0.85)
              font.family: Typography.family
              font.pixelSize: Commons.Style.font.bodySmall
              wrapMode: Text.WordWrap
            }
            Repeater {
              model: [statRow.modelData.away, statRow.modelData.home]
              Text {
                required property string modelData
                width: Commons.Style.space(50)
                text: modelData
                textFormat: Text.PlainText
                color: Commons.Color.popups.text
                font.family: Typography.family
                font.pixelSize: Commons.Style.font.bodySmall
                font.features: ({"tnum": 1})
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
              }
            }
          }
        }
      }

      Column {
        objectName: "detailMetadata"
        width: parent.width
        visible: !root.scheduledPresentation && Boolean(root.detail.timing.startTime || root.detail.timing.endTime || root.detail.venue)
        spacing: Commons.Style.spacing.xs
        Text {
          width: parent.width
          visible: Boolean(root.detail.timing.startTime)
          text: Formatters.formatDetailTiming(root.timeLabel(root.detail.timing.startTime),
            root.timeLabel(root.detail.timing.endTime))
          textFormat: Text.PlainText
          color: Qt.alpha(Commons.Color.popups.text, 0.85)
          font.family: Typography.family
          font.pixelSize: Commons.Style.font.bodySmall
          wrapMode: Text.WordWrap
        }
        Text {
          width: parent.width
          visible: Boolean(root.detail.venue)
          text: root.valueOrDash(root.detail.venue)
          textFormat: Text.PlainText
          color: Qt.alpha(Commons.Color.popups.text, 0.85)
          font.family: Typography.family
          font.pixelSize: Commons.Style.font.bodySmall
          wrapMode: Text.WordWrap
        }
      }

    }
  }
}

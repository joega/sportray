import QtQuick
import QtQuick.Controls as QQC
import qs.Commons as Commons
import qs.Ui
import "../model/UiTypography.js" as Typography
import "../model/Formatters.js" as Formatters

Item {
  id: root
  required property var game
  property var settingsStore: null
  property double currentTime: Date.now()
  readonly property bool alertsActive: watchAction.active
  readonly property bool popupOpen: popup.opened
  readonly property bool inputActive: popup.opened
  readonly property bool pointerPressed: trigger.pointerPressed || popup.opened
  property int cursorIndex: 0
  property string menuGameId: ""
  signal teamScheduleRequested(string teamId)
  signal focusReturnRequested()
  implicitWidth: Commons.Style.space(28)
  implicitHeight: Commons.Style.space(28)
  readonly property var actions: [
    {kind: "away", label: "View " + root.teamName(root.game.awayTeam) + " schedule", enabled: Boolean(root.game.awayTeam && root.game.awayTeam.id)},
    {kind: "home", label: "View " + root.teamName(root.game.homeTeam) + " schedule", enabled: Boolean(root.game.homeTeam && root.game.homeTeam.id)},
    {kind: "alerts", label: watchAction.available ? watchAction.actionLabel : "Game alerts unavailable", enabled: watchAction.available},
    {kind: "source", label: sourceLink.sourceUrl !== "" ? "Open " + sourceLink.sourceName + " game page" : "External game page unavailable", enabled: sourceLink.sourceUrl !== ""}
  ]
  function teamName(team) { return team ? team.name || team.shortName || Formatters.teamLabel(team) : "team" }
  function firstEnabled() {
    for (var i = 0; i < root.actions.length; i++) if (root.actions[i].enabled) return i
    return -1
  }
  function moveCursor(delta) {
    for (var i = root.cursorIndex + delta; i >= 0 && i < root.actions.length; i += delta) {
      if (root.actions[i].enabled) { root.cursorIndex = i; return }
    }
  }
  function activate(index) {
    if (index < 0 || index >= root.actions.length || !root.actions[index].enabled) return
    var kind = root.actions[index].kind
    popup.close()
    if (kind === "away") root.teamScheduleRequested(root.game.awayTeam.id)
    else if (kind === "home") root.teamScheduleRequested(root.game.homeTeam.id)
    else if (kind === "alerts") watchAction.activate()
    else if (kind === "source") sourceLink.openSource()
  }
  function open() {
    if (!root.game || root.game.isValid !== true) return
    root.menuGameId = root.game.id || ""
    popup.open()
  }
  function close() { popup.close() }
  function openSource() { sourceLink.openSource() }
  onGameChanged: if (popup && popup.opened && (!root.game || root.game.id !== root.menuGameId)) popup.close()
  onVisibleChanged: if (!visible && popup && popup.opened) popup.close()
  function focusTrigger() {
    if (!trigger.enabled) return false
    trigger.forceActiveFocus()
    return true
  }
  function positionPopup() {
    var overlay = popup.parent
    if (!overlay) return
    var point = trigger.mapToItem(overlay, trigger.width, trigger.height)
    popup.x = Math.max(0, Math.min(overlay.width - popup.width, point.x - popup.width))
    popup.y = Math.max(0, Math.min(overlay.height - popup.height, point.y + Commons.Style.spacing.xxs))
  }
  // Reuse the established mutation/source boundaries without painting an
  // additional footer or adding hidden controls to focus traversal.
  WatchAction { id: watchAction; visible: false; game: root.game; settingsStore: root.settingsStore; currentTime: root.currentTime }
  SourceLinkButton { id: sourceLink; visible: false; game: root.game }
  SemanticActionButton {
    id: trigger
    anchors.fill: parent
    size: root.implicitHeight
    iconName: "overflow"
    fallbackText: "…"
    tooltipText: root.alertsActive ? "Game actions · alerts on" : "Game actions"
    focusable: true
    enabled: root.game && root.game.isValid === true
    selected: popup.opened
    onClicked: popup.opened ? popup.close() : root.open()
    Accessible.name: root.alertsActive ? "Game actions. Alerts on" : "Game actions"
    Accessible.role: Accessible.Button
  }
  QQC.Popup {
    id: popup
    parent: QQC.Overlay.overlay
    modal: true
    focus: true
    padding: Commons.Style.spacing.sm
    width: Math.min(Commons.Style.space(320), parent ? parent.width : Commons.Style.space(320))
    implicitHeight: menuContent.implicitHeight + padding * 2
    closePolicy: QQC.Popup.CloseOnEscape | QQC.Popup.CloseOnPressOutside
    QQC.Overlay.modal: Item {}
    background: BorderSurface {
      color: Commons.Color.popups.background
      borderSpec: Commons.Border.surfaceSpec("popups", "border", Commons.Color.popups.border, Math.max(1, Commons.Style.space(2)))
      radius: Commons.Style.cornerRadius
    }
    onAboutToShow: root.positionPopup()
    onOpened: { root.positionPopup(); root.cursorIndex = root.firstEnabled(); menuContent.forceActiveFocus() }
    onClosed: root.focusReturnRequested()
    contentItem: FocusScope {
      id: menuContent
      implicitHeight: menuColumn.implicitHeight
      Keys.priority: Keys.BeforeItem
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) popup.close()
        else if (event.key === Qt.Key_Down || event.text === "j") root.moveCursor(1)
        else if (event.key === Qt.Key_Up || event.text === "k") root.moveCursor(-1)
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) root.activate(root.cursorIndex)
        else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) root.moveCursor(event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1 : 1)
        else return
        event.accepted = true
      }
      Column {
        id: menuColumn
        width: parent.width
        spacing: Commons.Style.spacing.xxs
        Text {
          width: parent.width
          text: "Game actions"
          textFormat: Text.PlainText
          color: Qt.alpha(Commons.Color.popups.text, 0.85)
          font.family: Typography.family
          font.pixelSize: Commons.Style.font.caption
          leftPadding: Commons.Style.spacing.sm
          topPadding: Commons.Style.spacing.xs
          bottomPadding: Commons.Style.spacing.xs
        }
        Repeater {
          model: root.actions
          QQC.ItemDelegate {
            id: menuAction
            required property var modelData
            required property int index
            width: menuColumn.width
            text: modelData.label
            font.family: Typography.family
            font.pixelSize: Commons.Style.font.bodySmall
            enabled: modelData.enabled
            opacity: enabled ? 1 : 0.45
            focusPolicy: Qt.NoFocus
            hoverEnabled: true
            padding: Commons.Style.spacing.sm
            implicitHeight: Math.max(Commons.Style.space(32), actionLabel.implicitHeight + padding * 2)
            contentItem: Text {
              id: actionLabel
              text: menuAction.text
              textFormat: Text.PlainText
              color: Commons.Color.popups.text
              font: menuAction.font
              wrapMode: Text.WordWrap
              verticalAlignment: Text.AlignVCenter
            }
            background: BorderSurface {
              readonly property bool selectedAction: menuContent.activeFocus && root.cursorIndex === menuAction.index
              color: selectedAction ? Commons.Style.focusFillFor(Commons.Color.popups.text, Commons.Color.accent)
                : menuAction.hovered ? Commons.Style.hoverFillFor(Commons.Color.popups.text, Commons.Color.accent) : "transparent"
              borderSpec: selectedAction ? Commons.Border.controlSpec("focus", Commons.Color.popups.text, Commons.Color.accent) : Commons.Border.none()
              radius: Commons.Style.cornerRadius
            }
            onHoveredChanged: if (hovered && enabled) root.cursorIndex = index
            onClicked: root.activate(index)
            Accessible.name: modelData.label
            Accessible.role: Accessible.Button
          }
        }
        Text {
          width: parent.width
          visible: !watchAction.available
          text: watchAction.disabledReason
          textFormat: Text.PlainText
          color: Qt.alpha(Commons.Color.popups.text, 0.85)
          font.family: Typography.family
          font.pixelSize: Commons.Style.font.caption
          wrapMode: Text.WordWrap
          leftPadding: Commons.Style.spacing.sm
          rightPadding: Commons.Style.spacing.sm
          topPadding: Commons.Style.spacing.xs
          bottomPadding: Commons.Style.spacing.xs
        }
      }
    }
  }
}

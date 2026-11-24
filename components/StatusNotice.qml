import QtQuick
import qs.Commons as Commons
import "../model/UiTypography.js" as Typography

// A quiet inline notice with independently reachable Details and Retry links.
// All display strings are plain text; trust state comes from NoticePresentation.
FocusScope {
  id: root
  property var notice: ({visible: false})
  property bool expanded: false
  property string activeAction: ""
  property string noticeIdentity: ""
  property bool hasCursor: false
  readonly property real fontSize: Commons.Style.font.bodySmall
  readonly property real gap: Math.max(4, Math.round(root.fontSize * 0.45))
  readonly property var actions: (root.notice && root.notice.detail ? ["details"] : [])
    .concat(root.notice && root.notice.canRetry ? ["retry"] : [])
  readonly property bool pointerPressed: detailsMouse.pressed || retryMouse.pressed
  readonly property color foreground: root.notice && root.notice.severity === "error"
    ? Commons.Color.urgent : Commons.Color.popups.text
  signal retryRequested()
  signal contentFocusRequested()
  signal boundsChanged()

  visible: Boolean(root.notice && root.notice.visible)
  implicitHeight: root.notice && root.notice.visible
    ? header.height + (root.expanded && detailText.text ? root.gap + detailText.implicitHeight : 0) : 0
  height: implicitHeight
  Accessible.role: Accessible.StaticText
  Accessible.name: root.notice ? root.notice.accessibleSummary || root.notice.summary || "" : ""
  onImplicitHeightChanged: root.boundsChanged()
  onNoticeChanged: {
    var identity = root.notice ? root.notice.id || "" : ""
    if (identity !== root.noticeIdentity) {
      root.noticeIdentity = identity
      root.expanded = false
    }
    if (root.actions.indexOf(root.activeAction) === -1)
      root.activeAction = root.notice && root.notice.canRetry ? "retry"
        : root.actions.length ? root.actions[0] : ""
    if (retryAction.activeFocus && !(root.notice && root.notice.canRetry)) {
      if (root.notice && root.notice.detail) detailsAction.forceActiveFocus()
      else root.forceActiveFocus()
    }
  }

  function moveCursor(delta) {
    if (!root.actions.length) return false
    var index = root.actions.indexOf(root.activeAction)
    root.activeAction = root.actions[Math.max(0, Math.min(root.actions.length - 1,
      (index < 0 ? 0 : index) + (delta < 0 ? -1 : 1)))]
    if (root.activeFocus) {
      if (root.activeAction === "details") detailsAction.forceActiveFocus()
      else retryAction.forceActiveFocus()
    }
    return true
  }
  function retryIfAvailable() {
    if (!root.notice || root.notice.canRetry !== true) return false
    root.retryRequested()
    return true
  }
  function activateCursor() {
    if (root.activeAction === "details" && root.notice && root.notice.detail) {
      root.expanded = !root.expanded
      root.boundsChanged()
      return true
    }
    if (root.activeAction === "retry" && root.notice && root.notice.canRetry) {
      root.retryRequested()
      return true
    }
    return false
  }
  function activatePrimaryAction() {
    if (root.notice && root.notice.canRetry) { root.retryRequested(); return true }
    if (root.notice && root.notice.detail) { root.expanded = !root.expanded; return true }
    return false
  }
  Keys.onReturnPressed: root.activateCursor()
  Keys.onEnterPressed: root.activateCursor()
  Keys.onSpacePressed: root.activateCursor()
  Keys.onLeftPressed: root.moveCursor(-1)
  Keys.onRightPressed: root.moveCursor(1)

  Item {
    id: header
    width: parent.width
    height: Math.max(summaryText.implicitHeight, root.actions.length > 0 ? actionRow.height : 0)
    Text {
      id: summaryText
      objectName: "statusNoticeSummary"
      width: Math.max(0, parent.width - (root.actions.length > 0 ? actionRow.width + root.gap : 0))
      anchors.verticalCenter: parent.verticalCenter
      text: root.notice ? root.notice.summary || "" : ""
      textFormat: Text.PlainText
      color: root.foreground
      font.family: Typography.family
      font.pixelSize: root.fontSize
      font.weight: root.notice && root.notice.severity === "error" ? Font.DemiBold : Font.Normal
      wrapMode: Text.WordWrap
    }
    Row {
      id: actionRow
      anchors.right: parent.right
      anchors.top: parent.top
      height: Math.max(24, Math.round(root.fontSize * 1.8))
      spacing: root.gap
      visible: root.actions.length > 0
      Item {
        id: detailsAction
        objectName: "statusNoticeDetails"
        visible: Boolean(root.notice && root.notice.detail)
        width: root.notice && root.notice.detail ? detailsLabel.implicitWidth + root.gap : 0
        height: parent.height
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: root.expanded ? "Hide status details" : "Show status details"
        Accessible.description: root.expanded ? "Details are expanded" : "Details are collapsed"
        Accessible.onPressAction: { root.activeAction = "details"; root.activateCursor() }
        Keys.onReturnPressed: { root.activeAction = "details"; root.activateCursor() }
        Keys.onEnterPressed: { root.activeAction = "details"; root.activateCursor() }
        Keys.onSpacePressed: { root.activeAction = "details"; root.activateCursor() }
        Rectangle {
          anchors.fill: parent
          color: "transparent"
          radius: 3
          border.width: detailsAction.activeFocus || root.hasCursor && root.activeAction === "details" ? 1 : 0
          border.color: root.foreground
        }
        Text {
          id: detailsLabel
          anchors.centerIn: parent
          text: "Details"
          textFormat: Text.PlainText
          color: Commons.Color.popups.text
          font.family: Typography.family
          font.pixelSize: root.fontSize
          font.underline: detailsMouse.containsMouse || detailsAction.activeFocus || root.expanded
        }
        MouseArea {
          id: detailsMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            root.activeAction = "details"
            detailsAction.forceActiveFocus()
            root.activateCursor()
            root.contentFocusRequested()
          }
        }
      }
      Item {
        id: retryAction
        objectName: "statusNoticeRetry"
        visible: Boolean(root.notice && root.notice.canRetry)
        width: root.notice && root.notice.canRetry ? retryLabel.implicitWidth + root.gap : 0
        height: parent.height
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: "Retry update"
        Accessible.onPressAction: root.retryIfAvailable()
        Keys.onReturnPressed: root.retryIfAvailable()
        Keys.onEnterPressed: root.retryIfAvailable()
        Keys.onSpacePressed: root.retryIfAvailable()
        Rectangle {
          anchors.fill: parent
          color: "transparent"
          radius: 3
          border.width: retryAction.activeFocus || root.hasCursor && root.activeAction === "retry" ? 1 : 0
          border.color: root.foreground
        }
        Text {
          id: retryLabel
          anchors.centerIn: parent
          text: "Retry"
          textFormat: Text.PlainText
          color: Commons.Color.popups.text
          font.family: Typography.family
          font.pixelSize: root.fontSize
          font.underline: retryMouse.containsMouse || retryAction.activeFocus
        }
        MouseArea {
          id: retryMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            root.activeAction = "retry"
            retryAction.forceActiveFocus()
            root.retryIfAvailable()
            root.contentFocusRequested()
          }
        }
      }
    }
  }
  Text {
    id: detailText
    objectName: "statusNoticeDetail"
    width: parent.width
    y: header.height + root.gap
    visible: root.expanded
    text: root.notice ? root.notice.detail || "" : ""
    textFormat: Text.PlainText
    color: Commons.Color.popups.text
    opacity: 0.85
    font.family: Typography.family
    font.pixelSize: root.fontSize
    wrapMode: Text.WordWrap
  }
}

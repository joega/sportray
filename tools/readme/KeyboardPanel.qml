import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui as Ui

// Capture-only host wrapper. Native border, padding and content are retained;
// desktop anchoring and layer-shell focus are replaced by an offscreen item.
Item {
  id: root
  property var anchorItem: null
  property var owner: null
  property var bar: null
  property bool open: false
  property var focusTarget: null
  property bool centerOnBar: false
  property int margin: 0
  property int gap: 0
  property int contentWidth: 400
  property int contentHeight: 640
  readonly property var screen: ({width: 1920, height: 1080})
  default property alias contentItem: holder.children
  width: contentWidth
  height: contentHeight
  function fittedContentWidth(value) { return Math.min(value, root.parent ? root.parent.width : value) }
  function fittedContentHeight(value, maximum) { return Math.min(value, maximum || 640) }
  Ui.BorderSurface {
    id: card
    anchors.fill: parent
    color: Commons.Color.popups.background
    borderSpec: Border.surfaceSpec("popups", "border", Commons.Color.popups.border, Math.max(1, Style.space(2)))
    padding: Style.spacing.popupPadding
    radius: Style.cornerRadius
    Item {
      id: holder
      x: card.contentLeftInset
      y: card.contentTopInset
      width: root.width - card.contentLeftInset - card.contentRightInset
      height: root.height - card.contentTopInset - card.contentBottomInset
    }
  }
}

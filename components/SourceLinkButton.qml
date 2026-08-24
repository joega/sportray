import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

Item {
  id: root

  required property var game

  readonly property string sourceUrl: root.game && typeof root.game.link === "string"
    ? root.game.link : ""
  readonly property string sourceName: {
    var url = root.sourceUrl.toLowerCase()
    if (url.indexOf("espn.com") !== -1) return "ESPN"
    if (url.indexOf("nhl.com") !== -1) return "NHL.com"
    return "Source"
  }
  property bool hasCursor: false

  implicitWidth: action.implicitWidth
  implicitHeight: action.implicitHeight
  width: implicitWidth
  height: implicitHeight
  visible: root.sourceUrl !== ""
  readonly property bool pointerPressed: action.pointerPressed

  function openSource() {
    if (root.sourceUrl === "") return
    Quickshell.execDetached(["omarchy-launch-browser", root.sourceUrl])
  }

  function focusAction() {
    if (root.sourceUrl !== "") action.forceActiveFocus()
  }

  SemanticActionButton {
    id: action
    anchors.fill: parent
    text: root.sourceName
    tooltipText: "Open " + root.sourceName + " game page"
    textBold: true
    textFontSize: Style.font.bodySmall
    textHorizontalPadding: Style.spacing.xs
    textVerticalPadding: Style.spacing.xs
    focusable: true
    hasCursor: root.hasCursor
    enabled: root.sourceUrl !== ""
    Accessible.name: root.sourceUrl !== ""
      ? "Open " + root.sourceName + " game page"
      : "External game page unavailable"
    onClicked: root.openSource()
  }
}

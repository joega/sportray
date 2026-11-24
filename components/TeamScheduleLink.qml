import QtQuick
import qs.Commons as Commons
import qs.Ui
import "../model/UiTypography.js" as Typography
import "../model/UiContrast.js" as UiContrast

Item {
  id: root
  property var team: null
  property string text: "TBD"
  property color foreground: Commons.Color.popups.text
  property real fontSize: Commons.Style.font.body
  property bool bold: false
  property bool wrap: false
  property bool hasCursor: false
  readonly property bool available: root.team && typeof root.team.id === "string" && root.team.id !== ""
  readonly property string scheduleTeamId: root.available ? root.team.id : ""
  readonly property bool pointerPressed: pointer.pressed
  readonly property string teamName: root.team && (root.team.name || root.team.shortName)
    ? root.team.name || root.team.shortName : root.text
  signal requested(string teamId)
  activeFocusOnTab: root.available
  implicitHeight: Math.max(Commons.Style.space(24), label.implicitHeight)
  function activate() { if (root.available) root.requested(root.team.id) }
  Keys.onReturnPressed: root.activate()
  Keys.onEnterPressed: root.activate()
  Keys.onSpacePressed: root.activate()
  BorderSurface {
    id: focusSurface
    anchors.fill: parent
    color: root.activeFocus || root.hasCursor ? Commons.Style.focusFillFor(root.foreground, Commons.Color.accent) : "transparent"
    borderSpec: root.activeFocus || root.hasCursor ? Commons.Border.controlSpec("focus", root.foreground, Commons.Color.accent) : Commons.Border.none()
    radius: Commons.Style.cornerRadius
  }
  Text {
    id: label
    anchors.fill: parent
    text: root.text
    textFormat: Text.PlainText
    color: UiContrast.foreground(pointer.containsMouse && root.available ? Commons.Color.accent : root.foreground,
      Commons.Color.popups.text, UiContrast.composite(focusSurface.color, Commons.Color.popups.background))
    font.family: Typography.family
    font.pixelSize: root.fontSize
    font.bold: root.bold
    font.underline: pointer.containsMouse && root.available
    verticalAlignment: Text.AlignVCenter
    wrapMode: root.wrap ? Text.WordWrap : Text.NoWrap
    elide: root.wrap ? Text.ElideNone : Text.ElideRight
  }
  MouseArea {
    id: pointer
    property string pressedTeamId: ""
    anchors.fill: parent
    enabled: root.available
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onPressed: pressedTeamId = root.scheduleTeamId
    onClicked: {
      if (pressedTeamId !== root.scheduleTeamId) return
      root.forceActiveFocus()
      root.activate()
    }
  }
  PanelToolTip {
    visible: pointer.containsMouse && root.available
    text: root.teamName + " schedule"
    fontFamily: Typography.family
  }
  Accessible.name: root.available ? "Open " + root.teamName + " schedule" : root.teamName
  Accessible.role: root.available ? Accessible.Button : Accessible.StaticText
  Accessible.onPressAction: root.activate()
}

import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  required property var standing
  property bool favorite: false
  property var settings: null
  property bool selected: false
  readonly property bool childActionPressed: rowMouse.pressed

  width: parent ? parent.width : implicitWidth
  implicitHeight: card.height
  height: implicitHeight

  function valueOrDash(value) {
    return value === null || value === undefined || value === "" ? "—" : String(value)
  }

  function teamLabel() {
    var team = root.standing && root.standing.team ? root.standing.team : {}
    return team.name || team.shortName || team.abbreviation || "Unnamed team"
  }

  function recordLabel() {
    if (root.standing && root.standing.recordLabel) return root.standing.recordLabel
    var standing = root.standing || {}
    if (standing.wins === null || standing.losses === null) return ""
    var result = String(standing.wins) + "-" + String(standing.losses)
    if (standing.draws !== null && standing.draws !== undefined) result += "-" + String(standing.draws)
    else if (standing.ties !== null && standing.ties !== undefined) result += "-" + String(standing.ties)
    return result
  }

  function activatePrimaryAction() {
    if (root.settings && root.standing && root.standing.team
        && typeof root.settings.toggleFavoriteTeam === "function")
      root.settings.toggleFavoriteTeam(root.standing.team.id)
  }

  Accessible.name: root.teamLabel() + ", rank " + root.valueOrDash(root.standing.rank)
    + (root.recordLabel() ? ", record " + root.recordLabel() : "")
    + (root.favorite ? ", selected favorite team" : ", not selected")
  Accessible.role: Accessible.CheckBox
  Accessible.checkable: true
  Accessible.checked: root.favorite
  Accessible.onToggleAction: root.activatePrimaryAction()

  BorderSurface {
    id: card
    width: parent.width
    height: row.implicitHeight + Style.spacing.sm * 2
    color: root.favorite ? Style.selectedFillFor(Color.popups.text, Color.accent) : "transparent"
    borderSpec: root.selected
      ? Border.controlSpec("focus", Color.popups.text, Color.accent)
      : Border.controlSpec("normal", Color.popups.text, Color.popups.border)
    radius: Style.cornerRadius

    Row {
      id: row
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.leftMargin: Style.spacing.sm
      anchors.rightMargin: Style.spacing.sm
      spacing: Style.spacing.sm
      height: Style.space(40)

      Text {
        width: Style.space(24)
        anchors.verticalCenter: parent.verticalCenter
        text: root.valueOrDash(root.standing.rank)
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        horizontalAlignment: Text.AlignHCenter
      }

      Item {
        width: parent.width - Style.space(24) - metrics.width - parent.spacing * 3
        height: parent.height

        Image {
          id: logo
          width: Style.space(26)
          height: width
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          source: root.standing.team && root.standing.team.logoUrl
            ? root.standing.team.logoUrl : ""
          fillMode: Image.PreserveAspectFit
          asynchronous: true
          visible: status === Image.Ready
        }

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(26)
          text: root.standing.team && root.standing.team.abbreviation
            ? root.standing.team.abbreviation : "?"
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
          horizontalAlignment: Text.AlignHCenter
          visible: !logo.visible
        }

        Text {
          anchors.left: parent.left
          anchors.leftMargin: Style.space(26) + Style.spacing.xs
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          text: root.teamLabel()
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          font.bold: root.favorite
          elide: Text.ElideRight
        }
      }

      Row {
        id: metrics
        width: Math.min(parent.width * 0.42, Style.space(178))
        height: parent.height
        spacing: Style.spacing.xs

        Repeater {
          model: [
            {label: "GP", value: root.standing.played},
            {label: "W", value: root.standing.wins},
            {label: "L", value: root.standing.losses},
            {label: "PTS", value: root.standing.points}
          ]

          Column {
            required property var modelData
            width: (metrics.width - metrics.spacing * 3) / 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Text {
              width: parent.width
              text: modelData.label
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              horizontalAlignment: Text.AlignHCenter
            }

            Text {
              width: parent.width
              text: root.valueOrDash(modelData.value)
              color: Color.popups.text
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              font.bold: true
              horizontalAlignment: Text.AlignHCenter
            }
          }
        }
      }
    }

    MouseArea {
      id: rowMouse
      anchors.fill: parent
      onClicked: root.activatePrimaryAction()
      cursorShape: Qt.PointingHandCursor
    }
  }
}

import QtQuick
import QtQuick.Controls as QQC
import qs.Commons
import qs.Ui
import "../model/TeamPickerModel.js" as PickerModel

Item {
  id: root

  required property var teams
  required property var leagues
  property var settings: null
  property int settingsRevision: 0
  property int cursorIndex: 0
  property string query: ""
  property string leagueFilter: "all"

  readonly property var favoriteIds: {
    var revision = root.settingsRevision
    var value = root.settings && root.settings.settings
      ? root.settings.settings.favoriteTeamIds : []
    return Array.isArray(value) ? value.slice() : []
  }
  readonly property var visibleTeams: PickerModel.filterAndOrderTeams(
    root.teams, root.query, root.leagueFilter, root.favoriteIds)
  readonly property int selectedCount: PickerModel.selectedCount(root.teams, root.favoriteIds)
  readonly property bool inputActive: searchInput.activeFocus

  signal escapeRequested()

  QQC.Action {
    enabled: root.inputActive
    shortcut: "Escape"
    onTriggered: root.escapeRequested()
  }

  implicitHeight: pickerColumn.implicitHeight
  height: visible ? implicitHeight : 0
  width: parent ? parent.width : implicitWidth

  function isFavorite(team) {
    return team && typeof team.id === "string"
      && root.favoriteIds.indexOf(team.id.toLowerCase()) !== -1
  }

  function moveCursor(delta) {
    if (root.visibleTeams.length === 0) return
    root.cursorIndex = PickerModel.clampCursor(root.cursorIndex, delta, root.visibleTeams.length)
    teamList.positionViewAtIndex(root.cursorIndex, ListView.Contain)
    Qt.callLater(root.ensureCursorVisible)
  }

  function activateCursor() {
    var team = PickerModel.teamAt(root.visibleTeams, root.cursorIndex)
    if (!team) return
    if (root.settings && typeof root.settings.toggleFavoriteTeam === "function")
      root.settings.toggleFavoriteTeam(team.id)
  }

  function activateIndex(index) {
    root.cursorIndex = PickerModel.clampCursor(index, 0, root.visibleTeams.length)
    root.activateCursor()
  }

  function focusSearch() {
    searchInput.forceActiveFocus()
  }

  function cursorBounds() {
    var item = teamList.itemAtIndex(root.cursorIndex)
    var top = teamList.y + (item ? item.y : root.cursorIndex * Style.space(48))
    return {top: top, bottom: top + (item ? item.height : Style.space(48))}
  }

  function clearSearch() {
    root.query = ""
    searchInput.text = ""
    root.cursorIndex = 0
    teamList.contentY = 0
  }

  function setLeagueFilter(value) {
    root.leagueFilter = value || "all"
    root.cursorIndex = 0
    teamList.contentY = 0
  }

  onVisibleTeamsChanged: {
    if (root.cursorIndex >= root.visibleTeams.length)
      root.cursorIndex = Math.max(0, root.visibleTeams.length - 1)
  }

  // The custom TextInput can retain active focus while the nested settings
  // destination is hidden. Release it explicitly so the panel key catcher
  // receives the next shortcut after Escape/Back returns to scores.
  onVisibleChanged: if (!root.visible) searchInput.focus = false

  Column {
    id: pickerColumn
    width: parent.width
    spacing: Style.spacing.sm

    Text {
      width: parent.width
      text: root.selectedCount + " selected · selected teams stay at the top"
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    Row {
      width: parent.width
      spacing: Style.spacing.sm

      TextField {
        id: searchInput
        width: parent.width - clearButton.width - parent.spacing
        placeholderText: "Search teams"
        onTextChanged: {
          if (root.query !== text) root.query = text
          root.cursorIndex = 0
          teamList.contentY = 0
        }
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            root.escapeRequested()
            event.accepted = true
          }
        }
      }

      Button {
        id: clearButton
        visible: root.query !== ""
        text: "Clear"
        focusable: true
        onClicked: root.clearSearch()
        Accessible.name: "Clear team search"
        Accessible.role: Accessible.Button
      }
    }

    Text {
      width: parent.width
      text: "League"
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.bold: true
    }

    Flow {
      width: parent.width
      spacing: Style.spacing.xs

      Button {
        text: "All"
        selected: root.leagueFilter === "all"
        focusable: true
        onClicked: root.setLeagueFilter("all")
      }

      Repeater {
        model: root.leagues

        Button {
          required property var modelData
          text: modelData ? (modelData.displayName || modelData.name || modelData.id) : ""
          selected: modelData && root.leagueFilter === modelData.id
          focusable: true
          onClicked: root.setLeagueFilter(modelData ? modelData.id : "all")
        }
      }
    }

    Text {
      width: parent.width
      text: root.visibleTeams.length === 0 ? "No teams match this search." : "Teams"
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }

    ListView {
      id: teamList
      width: parent.width
      height: Math.min(contentHeight, Style.space(360))
      clip: true
      spacing: Style.spacing.xs
      model: root.visibleTeams
      boundsBehavior: Flickable.StopAtBounds
      interactive: contentHeight > height
      QQC.ScrollBar.vertical: QQC.ScrollBar { policy: QQC.ScrollBar.AsNeeded }

      delegate: Item {
        required property var modelData
        required property int index
        width: teamList.width
        height: Style.space(48)

        BorderSurface {
          anchors.fill: parent
          radius: Style.cornerRadius
          color: index === root.cursorIndex
            ? Style.hoverFillFor(Color.popups.text, Color.accent)
            : root.isFavorite(modelData)
              ? Style.selectedFillFor(Color.popups.text, Color.accent)
              : "transparent"
          borderSpec: Border.controlSpec(index === root.cursorIndex ? "focus" : "normal",
            Color.popups.text, Color.accent)

          Row {
            anchors.fill: parent
            anchors.leftMargin: Style.spacing.md
            anchors.rightMargin: Style.spacing.md
            spacing: Style.spacing.sm

            Item {
              width: Style.space(28)
              height: Style.space(28)
              anchors.verticalCenter: parent.verticalCenter

              Image {
                id: logo
                anchors.fill: parent
                visible: modelData.logoUrl !== null && status !== Image.Error
                source: modelData.logoUrl || ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
              }

              Text {
                anchors.fill: parent
                visible: !logo.visible || logo.status !== Image.Ready
                text: modelData.abbreviation || "?"
                color: Color.muted
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
              }
            }

            Column {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width - favoriteMark.width - Style.space(28) - 2 * parent.spacing
              spacing: 0

              Text {
                width: parent.width
                text: modelData.name || modelData.shortName || modelData.abbreviation || "Unnamed team"
                color: Color.popups.text
                font.family: Style.font.family
                font.pixelSize: Style.font.body
                elide: Text.ElideRight
              }

              Text {
                width: parent.width
                text: (modelData.league || "").toUpperCase()
                color: Color.muted
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }
            }

            SemanticIcon {
              id: favoriteMark
              width: Style.space(18)
              height: Style.space(18)
              anchors.verticalCenter: parent.verticalCenter
              iconName: root.isFavorite(modelData) ? "star" : "starOutline"
              fontSize: Style.font.title
              color: root.isFavorite(modelData) ? Color.accent : Color.muted
              decorative: true
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: root.cursorIndex = index
            onClicked: root.activateIndex(index)
          }

          Accessible.name: (modelData.name || modelData.shortName || modelData.abbreviation || "Unnamed team")
            + (root.isFavorite(modelData) ? ", selected favorite team" : ", not selected")
          Accessible.role: Accessible.CheckBox
          Accessible.checked: root.isFavorite(modelData)
        }
      }
    }
  }
}

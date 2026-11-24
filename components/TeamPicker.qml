import QtQuick
import "../model/UiTypography.js" as Typography
import QtQuick.Controls as QQC
import qs.Commons
import qs.Ui
import "../model/TeamPickerModel.js" as PickerModel
import "../model/LifecyclePolicy.js" as LifecyclePolicy

Item {
  id: root

  required property var teams
  required property var leagues
  property var settings: null
  property int settingsRevision: 0
  property int cursorIndex: 0
  property string query: ""
  property string leagueFilter: "all"
  property var callbackOwner: null
  property var imageStore: null
  readonly property var localCallbackOwner: LifecyclePolicy.createOwnerState()

  readonly property var favoriteIds: {
    var revision = root.settingsRevision
    var value = root.settings && root.settings.settings
      ? root.settings.settings.favoriteTeamIds : []
    return Array.isArray(value) ? value.slice() : []
  }
  readonly property var visibleTeams: PickerModel.filterAndOrderTeams(
    root.teams, root.query, root.leagueFilter, root.favoriteIds, root.leagues)
  readonly property int selectedCount: PickerModel.selectedCount(root.teams, root.favoriteIds)
  readonly property bool inputActive: searchInput.activeFocus || clearButton.activeFocus
    || filterFocus.activeFocus || leagueFilterPicker.popupOpen

  signal escapeRequested()
  signal browseRequested()

  QQC.Action {
    enabled: searchInput.activeFocus && !leagueFilterPicker.popupOpen
    shortcut: "Escape"
    onTriggered: root.escapeRequested()
  }

  implicitHeight: pickerColumn.implicitHeight
  height: visible ? implicitHeight : 0
  width: parent ? parent.width : implicitWidth

  function leagueName(id) {
    for (var i = 0; i < root.leagues.length; i++) {
      var league = root.leagues[i]
      if (league && league.id === id) return league.displayName || league.name || id
    }
    return id || ""
  }

  function leagueOptions() {
    var result = [{value: "all", label: "All leagues"}]
    for (var i = 0; i < root.leagues.length; i++) {
      var league = root.leagues[i]
      if (league && league.id) result.push({value: league.id, label: root.leagueName(league.id)})
    }
    return result
  }

  function isFavorite(team) {
    return team && typeof team.id === "string"
      && root.favoriteIds.indexOf(team.id.toLowerCase()) !== -1
  }

  function moveCursor(delta) {
    if (root.visibleTeams.length === 0) return
    root.cursorIndex = PickerModel.clampCursor(root.cursorIndex, delta, root.visibleTeams.length)
    teamList.positionViewAtIndex(root.cursorIndex, ListView.Contain)
    root.deferCallback(root.ensureCursorVisible)
  }

  function ensureCursorVisible() {
    teamList.positionViewAtIndex(root.cursorIndex, ListView.Contain)
  }

  function deferCallback(callback) {
    if (typeof callback !== "function") return
    var owner = root.callbackOwner || root.localCallbackOwner
    var generation = LifecyclePolicy.captureGeneration(owner)
    Qt.callLater(function() {
      if (!LifecyclePolicy.canRun(owner, generation)) return
      callback()
    })
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

  function browseTeams() {
    searchInput.focus = false
    root.browseRequested()
  }

  function openLeagueFilter() {
    leagueFilterPicker.open()
  }

  function cursorBounds() {
    var item = teamList.itemAtIndex(root.cursorIndex)
    var point = item ? item.mapToItem(root, 0, 0) : teamList.mapToItem(root, 0, 0)
    return {top: point.y, bottom: point.y + (item ? item.height : teamList.height)}
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
  onVisibleChanged: if (!root.visible) {
    searchInput.focus = false
    leagueFilterPicker.close()
  }

  Component.onDestruction: LifecyclePolicy.invalidate(root.localCallbackOwner)

  Column {
    id: pickerColumn
    width: parent.width
    spacing: Style.spacing.sm

    Text {
      textFormat: Text.PlainText
      width: parent.width
      text: root.selectedCount + " selected · selected teams stay at the top"
      color: Qt.alpha(Color.popups.text, 0.85)
      font.family: Typography.family
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    Row {
      width: parent.width
      spacing: Style.spacing.sm

      TextField {
        id: searchInput
        width: parent.width - (clearButton.visible ? clearButton.width + parent.spacing : 0)
        placeholderText: "Search teams"
        font.family: Typography.family
        Accessible.name: "Search favorite teams"
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
          } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Return
              || event.key === Qt.Key_Enter) {
            root.browseTeams()
            event.accepted = true
          }
        }
      }

      Button {
        id: clearButton
        visible: root.query !== ""
        text: "Clear"
        fontFamily: Typography.family
        focusable: true
        onClicked: root.clearSearch()
        Accessible.name: "Clear team search"
        Accessible.role: Accessible.Button
      }
    }

    FocusScope {
      id: filterFocus
      width: parent.width
      height: leagueFilterPicker.implicitHeight
      Dropdown {
        id: leagueFilterPicker
        anchors.fill: parent
        label: "League"
        showLabel: false
        value: root.leagueFilter
        options: root.leagueOptions()
        fontFamily: Typography.family
        onChanged: function(value) { root.setLeagueFilter(value) }
        onPopupOpenChanged: if (!popupOpen && root.visible) root.browseTeams()
        Accessible.name: "Filter favorite teams by league"
        Accessible.role: Accessible.ComboBox
        Accessible.onPressAction: leagueFilterPicker.open()
      }
    }

    Text {
      textFormat: Text.PlainText
      width: parent.width
      text: root.visibleTeams.length === 0 ? "No teams match this search."
        : "↓ Browse teams · F Filter league · / Search"
      wrapMode: Text.WordWrap
      color: Qt.alpha(Color.popups.text, 0.85)
      font.family: Typography.family
      font.pixelSize: Style.font.caption
    }

    ListView {
      id: teamList
      width: parent.width
      height: Math.min(contentHeight, Style.space(360))
      clip: true
      spacing: 0
      model: root.visibleTeams
      boundsBehavior: Flickable.StopAtBounds
      interactive: contentHeight > height
      QQC.ScrollBar.vertical: QQC.ScrollBar { policy: QQC.ScrollBar.AsNeeded }

      delegate: Item {
        id: teamDelegate
        required property var modelData
        required property int index
        readonly property string logoSource: root.imageStore && modelData.logoUrl
          ? root.imageStore.sourceFor(modelData.logoUrl) : ""
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
          borderSpec: index === root.cursorIndex
            ? Border.controlSpec("hover-cursor", Color.popups.text, Color.accent) : Border.none()

          Row {
            anchors.fill: parent
            anchors.leftMargin: Style.spacing.md
            anchors.rightMargin: Style.spacing.md
            spacing: Style.spacing.sm

            Item {
              width: Style.space(28)
              height: Style.space(28)
              anchors.verticalCenter: parent.verticalCenter

              Rectangle {
                anchors.fill: parent
                anchors.margins: -Style.space(2)
                radius: Style.space(4)
                color: "#f5f5f5"
                visible: logo.status === Image.Ready
              }
              Image {
                id: logo
                anchors.fill: parent
                visible: modelData.logoUrl !== null && status !== Image.Error
                source: teamDelegate.logoSource
                fillMode: Image.PreserveAspectFit
                asynchronous: true
              }

              Text {
                textFormat: Text.PlainText
                anchors.fill: parent
                visible: !logo.visible || logo.status !== Image.Ready
                text: modelData.abbreviation || "?"
                color: Qt.alpha(Color.popups.text, 0.85)
                font.family: Typography.family
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
                textFormat: Text.PlainText
                width: parent.width
                text: modelData.name || modelData.shortName || modelData.abbreviation || "Unnamed team"
                color: Color.popups.text
                font.family: Typography.family
                font.pixelSize: Style.font.body
                elide: Text.ElideRight
              }

              Text {
                textFormat: Text.PlainText
                width: parent.width
                text: root.leagueName(modelData.league)
                color: Qt.alpha(Color.popups.text, 0.85)
                font.family: Typography.family
                font.pixelSize: Style.font.caption
                elide: Text.ElideRight
              }
            }

            SemanticIcon {
              id: favoriteMark
              width: Style.space(18)
              height: Style.space(18)
              anchors.verticalCenter: parent.verticalCenter
              iconName: root.isFavorite(modelData) ? "star" : "starOutline"
              fontSize: Style.font.title
              color: root.isFavorite(modelData) ? Color.accent : Qt.alpha(Color.popups.text, 0.85)
              decorative: true
            }
          }

          Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Color.popups.text
            opacity: 0.10
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
          Accessible.checkable: true
          Accessible.checked: root.isFavorite(modelData)
          Accessible.onToggleAction: root.activateIndex(index)
        }
      }
    }
  }
}

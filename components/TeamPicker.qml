import QtQuick
import "../model/UiTypography.js" as Typography
import "../model/UiContrast.js" as UiContrast
import QtQuick.Controls as QQC
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "../model/TeamPickerModel.js" as PickerModel
import "../model/LifecyclePolicy.js" as LifecyclePolicy

Item {
  id: root
  PresentationTokens { id: visual }

  required property var teams
  required property var leagues
  property var settings: null
  property int settingsRevision: 0
  property int cursorIndex: 0
  property string query: ""
  property string leagueFilter: "all"
  property var callbackOwner: null
  property var imageStore: null
  property bool setupGuideVisible: false
  property bool setupGuidePending: false
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
  readonly property int disabledSelectedCount: {
    var revision = root.settingsRevision
    var count = 0
    for (var i = 0; i < root.teams.length; i++)
      if (root.isFavorite(root.teams[i]) && !root.teamLeagueEnabled(root.teams[i])) count++
    return count
  }
  readonly property bool inputActive: searchInput.activeFocus || clearButton.activeFocus
    || filterFocus.activeFocus || leagueFilterPicker.popupOpen || reviewLeaguesButton.activeFocus

  signal escapeRequested()
  signal browseRequested()
  signal reviewLeaguesRequested()

  QQC.Action {
    enabled: root.inputActive && !leagueFilterPicker.popupOpen
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

  function teamLeagueEnabled(team) {
    if (!team) return false
    if (root.settings && typeof root.settings.isLeagueEnabled === "function")
      return root.settings.isLeagueEnabled(team.league)
    for (var i = 0; i < root.leagues.length; i++)
      if (root.leagues[i] && root.leagues[i].id === team.league)
        return root.leagues[i].enabledByDefault === true
    return false
  }

  function beginSession() {
    root.setupGuidePending = Boolean(root.settings && root.settings.ready === false)
    root.setupGuideVisible = !root.setupGuidePending && root.selectedCount === 0
  }

  function resolveSetupGuide() {
    if (!root.setupGuidePending || !root.settings || root.settings.ready === false) return
    root.setupGuidePending = false
    root.setupGuideVisible = root.selectedCount === 0
  }

  Connections {
    target: root.settings
    ignoreUnknownSignals: true
    function onReadyChanged() { root.resolveSetupGuide() }
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
      if (!owner || owner.alive !== true || owner.generation !== generation) return
      callback()
    })
  }

  function activateCursor() {
    var team = PickerModel.teamAt(root.visibleTeams, root.cursorIndex)
    if (!team) return
    if (root.settings && typeof root.settings.toggleFavoriteTeam === "function") {
      var changed = root.settings.toggleFavoriteTeam(team.id, team.name || team.shortName || team.abbreviation || "Team")
      if (changed === false) return
      // Favoriting reorders the list. Keep the cursor on the team the user
      // just changed rather than silently selecting the replacement index.
      root.deferCallback(function() {
        for (var i = 0; i < root.visibleTeams.length; i++) {
          if (root.visibleTeams[i].id === team.id) {
            root.cursorIndex = i
            root.ensureCursorVisible()
            return
          }
        }
      })
    }
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
    clearButton.focus = false
    reviewLeaguesButton.focus = false
    filterFocus.focus = false
    leagueFilterPicker.close()
  }

  Component.onDestruction: LifecyclePolicy.invalidate(root.localCallbackOwner)

  Column {
    id: pickerColumn
    width: parent.width
    spacing: Style.spacing.sm

    Column {
      id: setupGuide
      width: parent.width
      visible: root.setupGuideVisible
      spacing: Style.spacing.xxs
      height: setupTitle.implicitHeight + setupBody.implicitHeight + spacing
      Text {
        id: setupTitle
        width: parent.width
        text: "Choose your teams"
        textFormat: Text.PlainText
        color: visual.ink
        font.family: Typography.family
        font.pixelSize: visual.section
        font.weight: Font.DemiBold
      }
      Text {
        id: setupBody
        width: parent.width
        text: "Star teams to collect their games in Following. Enable their leagues for scores."
        textFormat: Text.PlainText
        color: visual.muted
        font.family: Typography.family
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.Wrap
      }
    }

    Item {
      id: selectedSummary
      width: parent.width
      height: Math.max(selectedLabels.height, reviewLeaguesButton.height)
      Column {
        id: selectedLabels
        anchors.left: parent.left
        anchors.right: reviewLeaguesButton.left
        anchors.rightMargin: Style.spacing.sm
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spacing.xxs
        height: selectedTotal.implicitHeight + (root.disabledSelectedCount > 0 ? selectedWarning.implicitHeight + spacing : 0)
        Text {
          id: selectedTotal
          width: parent.width
          text: root.selectedCount + " selected"
          textFormat: Text.PlainText
          color: visual.ink
          font.family: Typography.family
          font.pixelSize: Style.font.body
          font.weight: Font.DemiBold
          wrapMode: Text.Wrap
        }
        Text {
          id: selectedWarning
          width: parent.width
          visible: root.disabledSelectedCount > 0
          text: root.disabledSelectedCount + (root.disabledSelectedCount === 1 ? " needs league enabled" : " need leagues enabled")
          textFormat: Text.PlainText
          color: visual.muted
          font.family: Typography.family
          font.pixelSize: Style.font.caption
          wrapMode: Text.Wrap
        }
      }
      SemanticActionButton {
        id: reviewLeaguesButton
        objectName: "reviewLeaguesButton"
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: "Review leagues"
        foreground: visual.accent
        textFontSize: Style.font.caption
        tooltipText: "Review which leagues load scores and appear in Following (V)"
        focusable: true
        onClicked: root.reviewLeaguesRequested()
      }
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
        : "↓ Browse · F Filter · / Search · V Leagues"
      wrapMode: Text.WordWrap
      color: visual.muted
      font.family: Typography.family
      font.pixelSize: Style.font.caption
    }

    ListView {
      id: teamList
      objectName: "setupTeamList"
      width: parent.width
      // Guide/summary and results share a viewport budget. Large text grows
      // the rows inside this area, not the unscrollable outer settings page.
      height: Math.min(contentHeight, Math.max(Style.space(96), Math.min(360, Style.space(360))
        - (root.setupGuideVisible ? setupGuide.height + pickerColumn.spacing : 0)
        - selectedSummary.height - pickerColumn.spacing))
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
        height: Style.space(52)

        BorderSurface {
          id: teamSurface
          anchors.fill: parent
          radius: visual.radius
          color: index === root.cursorIndex
            ? Style.hoverFillFor(Commons.Color.popups.text, Commons.Color.accent)
            : root.isFavorite(modelData)
              ? visual.feature
              : visual.surface
          borderSpec: index === root.cursorIndex
            ? Border.controlSpec("hover-cursor", Commons.Color.popups.text, Commons.Color.accent) : Border.none()

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
                color: UiContrast.foreground(Qt.alpha(Commons.Color.popups.text, 0.85), Commons.Color.popups.text,
                  UiContrast.composite(teamSurface.color, Commons.Color.popups.background))
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
                color: visual.ink
                font.family: Typography.family
                font.pixelSize: visual.body
                font.weight: Font.Medium
                elide: Text.ElideRight
              }

              Text {
                textFormat: Text.PlainText
                width: parent.width
                text: root.leagueName(modelData.league) + (root.isFavorite(modelData) && !root.teamLeagueEnabled(modelData) ? " · league disabled" : "")
                color: UiContrast.foreground(Qt.alpha(Commons.Color.popups.text, 0.85), Commons.Color.popups.text,
                  UiContrast.composite(teamSurface.color, Commons.Color.popups.background))
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
              color: root.isFavorite(modelData) ? visual.accent : visual.muted
              decorative: true
            }
          }

          Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Style.spacing.md
            anchors.rightMargin: Style.spacing.md
            anchors.bottom: parent.bottom
            height: 1
            color: visual.line
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: root.cursorIndex = index
            onClicked: root.activateIndex(index)
          }

          Accessible.name: (modelData.name || modelData.shortName || modelData.abbreviation || "Unnamed team")
            + (root.isFavorite(modelData) ? ", selected favorite team" : ", not selected")
            + (root.isFavorite(modelData) && !root.teamLeagueEnabled(modelData) ? ". League disabled; enable it in Review leagues for scores." : "")
          Accessible.role: Accessible.CheckBox
          Accessible.checkable: true
          Accessible.checked: root.isFavorite(modelData)
          Accessible.onToggleAction: root.activateIndex(index)
        }
      }
    }
  }
}

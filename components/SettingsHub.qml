import QtQuick
import "../model/UiTypography.js" as Typography
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "../model/LifecyclePolicy.js" as LifecyclePolicy

Item {
  id: root

  required property var settingsStore
  property var imageStore: null
  required property var teams
  required property var leagues
  required property var notificationService
  property int settingsRevision: 0
  property string destination: "sports"
  property int sectionCursor: 0
  property bool contentFocused: false
  property bool compact: false
  property var callbackOwner: null
  readonly property var localCallbackOwner: LifecyclePolicy.createOwnerState()

  readonly property var destinations: [
    {id: "sports", label: "Sports & leagues", shortLabel: "Sports"},
    {id: "teams", label: "Favorite teams", shortLabel: "Teams"},
    {id: "notifications", label: "Notifications", shortLabel: "Alerts"},
    {id: "ticker", label: "Ticker", shortLabel: "Ticker"}
  ]
  readonly property bool inputActive: favoriteTeams.inputActive
  readonly property bool contentHasFocus: root.contentFocused

  signal escapeRequested()
  signal contentBoundsRequested(real top, real bottom)
  signal contentFocusRequested()

  function handleTextKey(text) {
    if (root.destination !== "teams" || root.inputActive) return false
    if ((text === "v" || text === "V") && root.contentFocused) {
      root.reviewLeagues()
      return true
    }
    if (text === "f" || text === "F") {
      root.contentFocused = true
      favoriteTeams.openLeagueFilter()
      return true
    }
    if (text === "/") {
      root.contentFocused = true
      favoriteTeams.focusSearch()
      return true
    }
    return false
  }

  function reviewLeagues() {
    root.selectDestination("sports")
    root.contentFocusRequested()
    root.deferCallback(root.ensureCursorVisible)
  }

  implicitHeight: hubColumn.implicitHeight
  height: visible ? implicitHeight : 0
  width: parent ? parent.width : implicitWidth

  function destinationIndex(value) {
    for (var i = 0; i < root.destinations.length; i++)
      if (root.destinations[i].id === value) return i
    return 0
  }

  function selectDestination(value) {
    var index = root.destinationIndex(value)
    root.sectionCursor = index
    root.destination = root.destinations[index].id
    root.contentFocused = true
    root.deferCallback(root.focusContent)
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

  function moveCursor(dx, dy) {
    if (dx !== 0) {
      root.sectionCursor = Math.max(0, Math.min(root.destinations.length - 1,
        root.sectionCursor + dx))
      root.contentFocused = false
      return
    }
    if (!root.contentFocused) {
      root.sectionCursor = Math.max(0, Math.min(root.destinations.length - 1,
        root.sectionCursor + dy))
      return
    }
    if (root.destination === "sports") sportsSettings.moveCursor(dy)
    else if (root.destination === "teams") favoriteTeams.moveCursor(dy)
    else if (root.destination === "notifications") notificationSettings.moveCursor(dy)
    else tickerSettings.moveCursor(dy)
    root.deferCallback(root.ensureCursorVisible)
  }

  function activateCursor() {
    if (!root.contentFocused) {
      root.selectDestination(root.destinations[root.sectionCursor].id)
      return
    }
    if (root.destination === "sports") sportsSettings.activateCursor()
    else if (root.destination === "teams") favoriteTeams.activateCursor()
    else if (root.destination === "notifications") notificationSettings.activateCursor()
    else tickerSettings.activateCursor()
  }

  function focusContent() {
    root.contentFocused = true
    if (root.destination === "teams") favoriteTeams.focusSearch()
  }

  function ensureCursorVisible() {
    var content = root.destination === "teams" ? favoriteTeams
      : root.destination === "sports" ? sportsSettings
      : root.destination === "notifications" ? notificationSettings : tickerSettings
    var bounds = content.cursorBounds()
    var origin = content.mapToItem(root, 0, 0)
    root.contentBoundsRequested(origin.y + bounds.top, origin.y + bounds.bottom)
  }

  function reset(destination) {
    favoriteTeams.beginSession()
    root.destination = destination || "sports"
    root.sectionCursor = root.destinationIndex(root.destination)
    root.contentFocused = false
  }

  Component.onDestruction: LifecyclePolicy.invalidate(root.localCallbackOwner)

  Column {
    id: hubColumn
    width: parent.width
    spacing: Style.spacing.sm

    Item {
      id: sectionTabBlock
      width: parent.width
      height: sectionTabs.height + sectionDivider.height

      Row {
        id: sectionTabs
        width: parent.width
        spacing: 0

        Repeater {
          model: root.destinations

          Button {
            id: tabButton
            required property var modelData
            required property int index
            width: sectionTabs.width / root.destinations.length
            text: modelData.shortLabel
            selected: root.destination === modelData.id
            foreground: root.destination === modelData.id ? Commons.Color.popups.text : Qt.alpha(Commons.Color.popups.text, 0.85)
            hasCursor: !root.contentFocused && root.sectionCursor === index
            focusable: true
            fontFamily: Typography.family
            fontSize: Style.font.body
            horizontalPadding: Style.spacing.xs
            radius: 0
            color: activeFocus ? Style.focusFillFor(foreground, Commons.Color.accent)
              : hot ? Style.hoverFillFor(foreground, Commons.Color.accent) : "transparent"
            borderSpec: activeFocus ? Border.controlSpec("focus", foreground, Commons.Color.accent)
              : hasCursor ? Border.controlSpec("hover-cursor", foreground, Commons.Color.accent) : Border.none()
            onClicked: root.selectDestination(modelData.id)
            Accessible.name: modelData.label
            Accessible.role: Accessible.PageTab
            Accessible.selected: root.destination === modelData.id

            Rectangle {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              height: Math.max(1, Style.normalBorderWidth)
              color: root.destination === tabButton.modelData.id ? Commons.Color.accent : "transparent"
            }
          }
        }
      }

      Rectangle {
        id: sectionDivider
        y: sectionTabs.height
        width: parent.width
        height: Math.max(1, Style.normalBorderWidth)
        color: Commons.Color.popups.border
      }
    }

    SportsSettings {
      id: sportsSettings
      width: hubColumn.width
      visible: root.destination === "sports"
      leagues: root.leagues
      settingsStore: root.settingsStore
      settingsRevision: root.settingsRevision
    }

    TeamPicker {
      id: favoriteTeams
      width: hubColumn.width
      visible: root.destination === "teams"
      teams: root.teams
      leagues: root.leagues
      settings: root.settingsStore
      settingsRevision: root.settingsRevision
      callbackOwner: root.callbackOwner
      imageStore: root.imageStore
      onEscapeRequested: root.escapeRequested()
      onBrowseRequested: {
        root.contentFocused = true
        root.contentFocusRequested()
      }
      onReviewLeaguesRequested: root.reviewLeagues()
    }

    SettingsView {
      id: notificationSettings
      width: hubColumn.width
      visible: root.destination === "notifications"
      settingsStore: root.settingsStore
      notificationService: root.notificationService
      settingsRevision: root.settingsRevision
    }

    TickerSettings {
      id: tickerSettings
      width: hubColumn.width
      visible: root.destination === "ticker"
      settingsStore: root.settingsStore
      settingsRevision: root.settingsRevision
    }
  }
}

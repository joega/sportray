import QtQuick
import QtQuick.Shapes
import qs.Commons
import qs.Ui
import "../model/LifecyclePolicy.js" as LifecyclePolicy

Item {
  id: root

  required property var settingsStore
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
    {id: "notifications", label: "Notifications", shortLabel: "Alerts"}
  ]
  readonly property bool inputActive: favoriteTeams.inputActive
  readonly property bool contentHasFocus: root.contentFocused

  signal escapeRequested()
  signal contentBoundsRequested(real top, real bottom)

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
      if (!LifecyclePolicy.canRun(owner, generation)) return
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
    else notificationSettings.moveCursor(dy)
    root.deferCallback(root.ensureCursorVisible)
  }

  function activateCursor() {
    if (!root.contentFocused) {
      root.selectDestination(root.destinations[root.sectionCursor].id)
      return
    }
    if (root.destination === "sports") sportsSettings.activateCursor()
    else if (root.destination === "teams") favoriteTeams.activateCursor()
    else notificationSettings.activateCursor()
  }

  function focusContent() {
    root.contentFocused = true
    if (root.destination === "teams") favoriteTeams.focusSearch()
  }

  function ensureCursorVisible() {
    var bounds = root.destination === "teams" ? favoriteTeams.cursorBounds()
      : root.destination === "sports" ? sportsSettings.cursorBounds()
      : notificationSettings.cursorBounds()
    root.contentBoundsRequested(bounds.top, bounds.bottom)
  }

  function reset(destination) {
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
            text: root.compact ? modelData.shortLabel : modelData.label
            selected: false
            foreground: root.destination === modelData.id ? Color.popups.text : Color.muted
            hasCursor: !root.contentFocused && root.sectionCursor === index
            focusable: true
            fontSize: Style.font.bodySmall
            horizontalPadding: Style.spacing.xs
            radius: 0
            color: "transparent"
            borderSpec: Border.none()
            onClicked: root.selectDestination(modelData.id)
            Accessible.name: modelData.label
            Accessible.role: Accessible.Button

            readonly property bool tabSurfaceVisible: tabButton.hasCursor || tabButton.activeFocus || tabHover.hovered
            readonly property bool tabSurfaceFocused: tabButton.activeFocus
            readonly property real tabSurfaceRadius: Math.min(Style.cornerRadius, tabButton.width / 2, tabButton.height / 2)
            readonly property var tabSurfaceBorder: Border.controlSpec(
              tabSurfaceFocused ? "focus" : "hover-cursor", tabButton.foreground, tabButton.accent)
            readonly property color tabSurfaceFill: tabSurfaceFocused
              ? Style.focusFillFor(tabButton.foreground, tabButton.accent)
              : Style.hoverFillFor(tabButton.foreground, tabButton.accent)

            HoverHandler {
              id: tabHover
            }

            Shape {
              anchors.fill: parent
              z: 0
              visible: tabButton.tabSurfaceVisible
              preferredRendererType: Shape.CurveRenderer

              ShapePath {
                fillColor: tabButton.tabSurfaceFill
                strokeColor: Border.color(tabButton.tabSurfaceBorder)
                strokeWidth: Math.max(1, Border.uniformWidth(tabButton.tabSurfaceBorder))

                PathMove { x: tabButton.tabSurfaceRadius; y: 0 }
                PathLine { x: tabButton.width - tabButton.tabSurfaceRadius; y: 0 }
                PathArc {
                  x: tabButton.width
                  y: tabButton.tabSurfaceRadius
                  radiusX: tabButton.tabSurfaceRadius
                  radiusY: tabButton.tabSurfaceRadius
                  direction: PathArc.Clockwise
                }
                PathLine { x: tabButton.width; y: tabButton.height }
                PathLine { x: 0; y: tabButton.height }
                PathLine { x: 0; y: tabButton.tabSurfaceRadius }
                PathArc {
                  x: tabButton.tabSurfaceRadius
                  y: 0
                  radiusX: tabButton.tabSurfaceRadius
                  radiusY: tabButton.tabSurfaceRadius
                  direction: PathArc.Clockwise
                }
              }
            }

            Rectangle {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              height: Math.max(1, Style.normalBorderWidth)
              color: root.destination === tabButton.modelData.id ? Color.accent : "transparent"
            }
          }
        }
      }

      Rectangle {
        id: sectionDivider
        y: sectionTabs.height
        width: parent.width
        height: Math.max(1, Style.normalBorderWidth)
        color: Color.popups.border
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
      onEscapeRequested: root.escapeRequested()
    }

    SettingsView {
      id: notificationSettings
      width: hubColumn.width
      visible: root.destination === "notifications"
      settingsStore: root.settingsStore
      notificationService: root.notificationService
      settingsRevision: root.settingsRevision
    }
  }
}

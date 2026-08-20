import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  required property var leagues
  required property var settingsStore
  property int settingsRevision: 0
  property int cursorIndex: 0

  implicitHeight: sportsColumn.implicitHeight
  height: visible ? implicitHeight : 0
  width: parent ? parent.width : implicitWidth

  function isEnabled(league) {
    var revision = root.settingsRevision
    return league && root.settingsStore && typeof root.settingsStore.isLeagueEnabled === "function"
      ? root.settingsStore.isLeagueEnabled(league.id) : Boolean(league && league.enabledByDefault)
  }

  function moveCursor(delta) {
    if (root.leagues.length === 0) return
    root.cursorIndex = Math.max(0, Math.min(root.leagues.length - 1,
      root.cursorIndex + delta))
  }

  function cursorBounds() {
    var top = Style.font.caption + Style.spacing.sm
      + root.cursorIndex * Style.space(64)
    return {top: top, bottom: top + Style.space(56)}
  }

  function activateCursor() {
    var league = root.leagues[root.cursorIndex]
    if (league && root.settingsStore && typeof root.settingsStore.toggleLeague === "function")
      root.settingsStore.toggleLeague(league.id)
  }

  function toggle(league) {
    if (league && root.settingsStore && typeof root.settingsStore.toggleLeague === "function")
      root.settingsStore.toggleLeague(league.id)
  }

  Column {
    id: sportsColumn
    width: parent.width
    spacing: Style.spacing.sm

    Text {
      width: parent.width
      text: {
        var revision = root.settingsRevision
        var count = 0
        for (var i = 0; i < root.leagues.length; i++) if (root.isEnabled(root.leagues[i])) count++
        return count + " of " + root.leagues.length + " enabled"
      }
      color: Color.accent
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }

    Repeater {
      model: root.leagues

      Toggle {
        required property var modelData
        required property int index
        width: sportsColumn.width
        label: modelData ? (modelData.displayName || modelData.name || modelData.id) : ""
        description: modelData && modelData.id === "nhl" ? "Default scoreboard" : "Include this league in Sportray"
        checked: root.isEnabled(modelData)
        hasCursor: index === root.cursorIndex
        onClicked: root.toggle(modelData)
      }
    }
  }
}

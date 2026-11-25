import QtQuick
import "../model/UiTypography.js" as Typography
import "../model/UiContrast.js" as UiContrast
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Item {
  id: root
  PresentationTokens { id: visual }

  required property var leagues
  required property var settingsStore
  property int settingsRevision: 0
  property int cursorIndex: 0

  readonly property int actionsPerLeague: 4

  implicitHeight: sportsColumn.implicitHeight
  height: visible ? implicitHeight : 0
  width: parent ? parent.width : implicitWidth

  function isEnabled(league) {
    var revision = root.settingsRevision
    return league && root.settingsStore && typeof root.settingsStore.isLeagueEnabled === "function"
      ? root.settingsStore.isLeagueEnabled(league.id) : Boolean(league && league.enabledByDefault)
  }

  function isFollowed(league) {
    var revision = root.settingsRevision
    return league && root.settingsStore && root.settingsStore.settings
      && Array.isArray(root.settingsStore.settings.followedLeagueIds)
      ? root.settingsStore.settings.followedLeagueIds.indexOf(String(league.id).toLowerCase()) !== -1
      : false
  }

  function followedIndex(league) {
    if (!league || !root.settingsStore || !root.settingsStore.settings) return -1
    var revision = root.settingsRevision
    var followed = root.settingsStore.settings.followedLeagueIds
    return Array.isArray(followed) ? followed.indexOf(String(league.id).toLowerCase()) : -1
  }

  function moveCursor(delta) {
    var count = root.leagues.length * root.actionsPerLeague
    if (count === 0) return
    root.cursorIndex = Math.max(0, Math.min(count - 1, root.cursorIndex + delta))
  }

  function cursorBounds() {
    var item = leagueRepeater.itemAt(Math.floor(root.cursorIndex / root.actionsPerLeague))
    if (!item) return {top: 0, bottom: 0}
    var point = item.mapToItem(root, 0, 0)
    return {top: point.y, bottom: point.y + item.height}
  }

  function activateCursor() {
    var leagueIndex = Math.floor(root.cursorIndex / root.actionsPerLeague)
    var action = root.cursorIndex % root.actionsPerLeague
    var league = root.leagues[leagueIndex]
    if (!league || !root.settingsStore) return
    if (action === 0 && typeof root.settingsStore.toggleLeague === "function")
      root.settingsStore.toggleLeague(league.id)
    else if (action === 1 && root.isEnabled(league) && typeof root.settingsStore.toggleFollowedLeague === "function")
      root.settingsStore.toggleFollowedLeague(league.id)
    else if (action === 2 && root.isFollowed(league) && root.followedIndex(league) > 0 && typeof root.settingsStore.moveFollowedLeague === "function")
      root.settingsStore.moveFollowedLeague(league.id, "up")
    else if (action === 3 && root.isFollowed(league)
        && root.followedIndex(league) < root.settingsStore.settings.followedLeagueIds.length - 1 && typeof root.settingsStore.moveFollowedLeague === "function")
      root.settingsStore.moveFollowedLeague(league.id, "down")
  }

  function toggle(league) {
    if (league && root.settingsStore && typeof root.settingsStore.toggleLeague === "function")
      root.settingsStore.toggleLeague(league.id)
  }

  function toggleFollow(league) {
    if (league && root.settingsStore && typeof root.settingsStore.toggleFollowedLeague === "function")
      root.settingsStore.toggleFollowedLeague(league.id)
  }

  function moveFollow(league, direction) {
    if (league && root.settingsStore && typeof root.settingsStore.moveFollowedLeague === "function")
      root.settingsStore.moveFollowedLeague(league.id, direction)
  }

  Column {
    id: sportsColumn
    width: parent.width
    spacing: Style.spacing.md

      Text {
      textFormat: Text.PlainText
      width: parent.width
      text: {
        var revision = root.settingsRevision
        var count = 0
        for (var i = 0; i < root.leagues.length; i++) if (root.isEnabled(root.leagues[i])) count++
        var followed = root.settingsStore && root.settingsStore.settings
          && Array.isArray(root.settingsStore.settings.followedLeagueIds)
          ? root.settingsStore.settings.followedLeagueIds.length : 0
        return count + " of " + root.leagues.length + " enabled · " + followed + " followed"
      }
      color: visual.accent
      font.family: Typography.family
      font.pixelSize: Style.font.bodySmall
    }

    Text {
      width: parent.width
      text: "Enable: load scores and show the league.\nFollow: add its games to Following and Calendar."
      textFormat: Text.PlainText
      wrapMode: Text.WordWrap
      color: visual.muted
      font.family: Typography.family
      font.pixelSize: Style.font.bodySmall
    }

    Repeater {
      id: leagueRepeater
      model: root.leagues

      Item {
        required property var modelData
        required property int index
        width: sportsColumn.width
        height: leagueColumn.implicitHeight + Style.space(24)

        Rectangle {
          anchors.fill: parent
          color: visual.surface
          radius: visual.radius
        }

        Column {
          id: leagueColumn
          x: Style.space(12)
          y: Style.space(12)
          width: parent.width - x * 2
          spacing: Style.spacing.xs

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: modelData ? (modelData.displayName || modelData.name || modelData.id) : ""
            color: visual.ink
            font.family: Typography.family
            font.pixelSize: visual.body
            font.bold: true
          }

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: root.isEnabled(modelData)
              ? (root.isFollowed(modelData) ? "Enabled · followed" : "Enabled · not followed")
              : "Disabled · unavailable in navigation"
            color: visual.muted
            font.family: Typography.family
            font.pixelSize: Style.font.caption
          }

          Row {
            width: parent.width
            spacing: Style.spacing.xs

            SemanticActionButton {
              width: (parent.width - Style.space(64) - parent.spacing * 3) / 2
              text: root.isEnabled(modelData) ? "Enabled" : "Enable"
              selected: root.isEnabled(modelData)
              textFontSize: Style.font.bodySmall
              textBold: true
              focusable: true
              bordered: false
              hasCursor: root.cursorIndex === index * root.actionsPerLeague
              tooltipText: root.isEnabled(modelData) ? "Disable league" : "Enable league"
              onClicked: root.toggle(modelData)
              Accessible.name: root.isEnabled(modelData) ? "Disable " + modelData.displayName
                : "Enable " + modelData.displayName
              Accessible.role: Accessible.CheckBox
              Accessible.checkable: true
              Accessible.checked: root.isEnabled(modelData)
              Accessible.onToggleAction: root.toggle(modelData)
            }

            SemanticActionButton {
              width: (parent.width - Style.space(64) - parent.spacing * 3) / 2
              text: root.isFollowed(modelData) ? "Following" : "Follow"
              selected: root.isFollowed(modelData)
              foreground: visual.ink
              textFontSize: Style.font.bodySmall
              textBold: true
              focusable: true
              bordered: false
              enabled: root.isEnabled(modelData)
              hasCursor: root.cursorIndex === index * root.actionsPerLeague + 1
              tooltipText: enabled ? (root.isFollowed(modelData) ? "Unfollow league" : "Follow league")
                : "Enable league before following"
              onClicked: root.toggleFollow(modelData)
              Accessible.name: enabled ? (root.isFollowed(modelData) ? "Unfollow " : "Follow ")
                + modelData.displayName : "Follow unavailable until enabled"
              Accessible.role: Accessible.CheckBox
              Accessible.checkable: true
              Accessible.checked: root.isFollowed(modelData)
              Accessible.onToggleAction: if (root.isEnabled(modelData)) root.toggleFollow(modelData)
            }

            SemanticActionButton {
              width: Style.space(32)
              text: "↑"
              textFontSize: Style.font.caption
              textBold: true
              focusable: true
              bordered: false
              enabled: root.isFollowed(modelData) && root.followedIndex(modelData) > 0
              hasCursor: root.cursorIndex === index * root.actionsPerLeague + 2
              tooltipText: enabled ? "Move league up" : "Move up unavailable"
              onClicked: root.moveFollow(modelData, "up")
              Accessible.name: "Move " + modelData.displayName + " up"
              Accessible.role: Accessible.Button
            }

            SemanticActionButton {
              width: Style.space(32)
              text: "↓"
              textFontSize: Style.font.caption
              textBold: true
              focusable: true
              bordered: false
              enabled: root.isFollowed(modelData)
                && root.followedIndex(modelData) < root.settingsStore.settings.followedLeagueIds.length - 1
              hasCursor: root.cursorIndex === index * root.actionsPerLeague + 3
              tooltipText: enabled ? "Move league down" : "Move down unavailable"
              onClicked: root.moveFollow(modelData, "down")
              Accessible.name: "Move " + modelData.displayName + " down"
              Accessible.role: Accessible.Button
            }
          }
        }
      }
    }
  }
}

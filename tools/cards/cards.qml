pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import QtTest as Test
import Quickshell
import qs.Commons as Commons
import qs.Ui as Ui
import "../../components" as Components
import "../../model/WatchPolicy.js" as WatchPolicy
import "../../model/PointerInteractionPolicy.js" as PointerPolicy

ShellRoot {
  id: root
  property var fixture: null
  property var logoSources: ({})
  property var uiCase: ({name: "light", width: 400, fontSize: 12})
  property int details: 0
  property var teams: []
  property int returns: 0
  property int refreshes: 0
  property string mode: "cards"
  function readText(path) {
    var xhr = new XMLHttpRequest()
    xhr.open("GET", Qt.resolvedUrl(path), false); xhr.send(); return xhr.responseText
  }
  QtObject { id: logos; function sourceFor(url) { return root.logoSources[url] || "" } }
  QtObject {
    id: store
    property bool ready: true
    property var watchedGames: []
    property int watchCalls: 0
    property int favoriteCalls: 0
    function toggleFavoriteTeam(id) { favoriteCalls++ }
    function isLeagueEnabled(league) { return true }
    function toggleWatch(game) {
      watchCalls++
      watchedGames = WatchPolicy.findWatch(watchedGames, game) ? []
        : [WatchPolicy.createWatch(game, root.fixture.now, Date.parse(root.fixture.now))]
      return true
    }
  }
  Window {
    id: window
    width: root.uiCase.width
    height: 640
    visible: true
    color: Commons.Color.popups.background
    Ui.BorderSurface {
      id: surface
      anchors.fill: parent
      color: Commons.Color.popups.background
      borderSpec: Commons.Border.surfaceSpec("popups", "border", Commons.Color.popups.border, 2)
      Column {
        id: cards
        visible: root.mode === "cards"
        x: Commons.Style.space(16)
        y: Commons.Style.space(16)
        width: parent.width - Commons.Style.space(32)
        spacing: Commons.Style.spacing.md
        Repeater {
          id: cardRepeater
          model: root.fixture ? root.fixture.games : []
          Item {
            id: wrapper
            required property var modelData
            required property int index
            width: cards.width
            height: card.implicitHeight
            property alias card: card
            Components.GameRow {
              id: card
              width: parent.width
              game: wrapper.modelData
              settingsStore: store
              imageStore: logos
              currentTime: root.fixture ? Date.parse(root.fixture.now) : Date.now()
              onPrimaryActionRequested: root.details++
              onTeamScheduleRequested: function(teamId) { root.teams = root.teams.concat([teamId]) }
              onFocusReturnRequested: { root.returns++; catcher.forceActiveFocus() }
            }
            TapHandler {
              enabled: PointerPolicy.allowsRowActivation(card.childActionPressed)
              onTapped: if (PointerPolicy.allowsRowActivation(card.childActionPressed)) card.activatePrimaryAction()
            }
          }
        }
      }
      Column {
        x: -2000
        width: cards.width
        Repeater {
          id: baselineRepeater
          model: root.fixture ? root.fixture.games : []
          Components.BaselineGameRow {
            required property var modelData
            width: cards.width
            game: modelData
            settingsStore: store
            imageStore: logos
            currentTime: root.fixture ? Date.parse(root.fixture.now) : Date.now()
          }
        }
      }
      Ui.PanelKeyCatcher {
        id: detailCatcher
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Commons.Style.space(16)
        height: Math.min(Commons.Style.space(320), parent.height - Commons.Style.space(32))
        visible: root.mode === "detail"
        onMoveRequested: function(dx, dy) { detail.moveCursor(dy !== 0 ? dy : dx) }
        onActivateRequested: detail.activateCursor()
        onCloseRequested: root.mode = "cards"
        Components.GameDetailView {
          id: detail
          anchors.fill: parent
          visible: root.mode === "detail"
          game: root.fixture ? root.fixture.detail : null
          imageStore: logos
          settingsStore: store
          currentTime: root.fixture ? Date.parse(root.fixture.now) : Date.now()
          lastSuccessAt: root.fixture ? root.fixture.now : ""
          onTeamScheduleRequested: function(teamId) { root.teams = root.teams.concat([teamId]) }
          onRefreshRequested: root.refreshes++
        }
      }
      Components.StandingsRow {
        id: standing
        x: Commons.Style.space(16)
        y: Commons.Style.space(16)
        width: parent.width - Commons.Style.space(32)
        visible: root.mode === "standings"
        standing: root.fixture ? root.fixture.standing : ({team: {}, league: "nhl"})
        settings: store
        imageStore: logos
        onTeamScheduleRequested: function(teamId) { root.teams = root.teams.concat([teamId]) }
      }
      Item {
        id: catcher
        focus: true
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && event.modifiers & Qt.ShiftModifier)) {
            cardRepeater.itemAt(0).card.openActions(); event.accepted = true
          }
        }
      }
    }
    Timer { interval: 300; running: true; onTriggered: checks.run() }
    Test.TestCase {
      id: checks
      when: false
      function check(value, message) { if (!value) throw new Error(message) }
      function same(actual, expected, message) { if (actual !== expected) throw new Error(message + ": " + actual + " != " + expected) }
      function find(object, predicate, seen) {
        if (!object || seen.indexOf(object) !== -1 || seen.length > 5000) return null
        seen.push(object)
        if (predicate(object)) return object
        for (var key of ["children", "data", "contentItem"]) {
          var value = object[key]
          if (!value) continue
          if (typeof value.length === "number") {
            for (var child of value) { var found = find(child, predicate, seen); if (found) return found }
          } else { var item = find(value, predicate, seen); if (item) return item }
        }
        return null
      }
      function capture(name) {
        var done = false, saved = false
        var target = name === "menu" ? window.contentItem : surface
        target.grabToImage(function(result) {
          saved = result.saveToFile(Quickshell.env("SPORTRAY_TEST_CAPTURE") + "/" + name + ".png"); done = true
        }, Qt.size(window.width * 2, window.height * 2))
        tryVerify(function() { return done }, 4000); check(saved, "capture failed: " + name)
      }
      function run() {
        try {
          root.uiCase = JSON.parse(root.readText("ui-case.json"))
          root.fixture = JSON.parse(root.readText("cards-fixture.json"))
          root.logoSources = JSON.parse(root.readText("logos.json"))
          Commons.Color.loadUserShell("")
          Commons.Color.loadColors(root.readText("theme/colors.toml")); Commons.Color.loadShell(root.readText("theme/shell.toml"))
          Commons.Style.fontFamily = "JetBrainsMono Nerd Font"; Commons.Style.fontBaseSize = root.uiCase.fontSize; Commons.Style.cornerRadius = 8
          wait(120)
          var live = cardRepeater.itemAt(0).card
          var scheduled = cardRepeater.itemAt(1).card
          var final = cardRepeater.itemAt(2).card
          var longCard = cardRepeater.itemAt(3).card
          var oldScheduled = baselineRepeater.itemAt(1)
          var oldLive = baselineRepeater.itemAt(0)
          var view = 640 - 164
          var oldCount = Math.floor((view + Commons.Style.spacing.md) / (oldScheduled.height + Commons.Style.spacing.md))
          var newCount = Math.floor((view - 48 + Commons.Style.spacing.md) / (scheduled.height + Commons.Style.spacing.md))
          console.log("CARDS_METRICS " + JSON.stringify({case:root.uiCase.name, oldScheduled:oldScheduled.height, scheduled:scheduled.height,
            oldLive:oldLive.height, live:live.height, oldCount:oldCount, newCountIncluding48pxControls:newCount}))
          check(scheduled.height < oldScheduled.height, "Scheduled card was not shorter")
          if (root.uiCase.name === "light") check(newCount >= oldCount + 1, "New controls erased card density gain")
          var status = find(longCard, function(item) { return "wrapMode" in item && item.text && item.text.indexOf("deliberately long") !== -1 }, [])
          check(status !== null && status.width > longCard.width - Commons.Style.space(24), "Status lost full card width")
          check(status.height >= status.implicitHeight - 1, "Long status clipped")
          capture("cards")
          // The exact parent TapHandler policy must not also activate details
          // for team links or the always-visible action trigger.
          var team = find(live, function(item) { return "team" in item && "requested" in item && item.team && item.team.id === live.game.awayTeam.id }, [])
          check(team !== null, "Away team route absent")
          mouseClick(team, team.width / 2, team.height / 2, Qt.LeftButton, Qt.NoModifier, 20)
          same(root.teams.length, 1, "Team click did not route once")
          same(root.details, 0, "Team click also opened details")
          mouseClick(live, live.width - Commons.Style.space(42), live.height - Commons.Style.space(10), Qt.LeftButton, Qt.NoModifier, 20)
          same(root.details, 1, "Card background did not open local details exactly once")
          var actions = find(live, function(item) { return "cursorIndex" in item && "actions" in item && "alertsActive" in item }, [])
          var trigger = find(actions, function(item) { return "tooltipText" in item && item.tooltipText === "Game actions" }, [])
          check(trigger !== null, "Always-visible Game actions trigger absent")
          mouseClick(trigger, trigger.width / 2, trigger.height / 2, Qt.LeftButton, Qt.NoModifier, 20)
          wait(30)
          check(live.popupOpen, "Trigger did not open native action popup")
          same(root.details, 1, "Menu trigger also opened details")
          capture("menu")
          keyClick(Qt.Key_Escape); wait(30)
          check(!live.popupOpen && root.returns > 0, "Escape did not close only menu and return focus")
          catcher.forceActiveFocus(); keyClick(Qt.Key_F10, Qt.ShiftModifier); wait(30)
          check(live.popupOpen, "Shift+F10 did not open game actions")
          keyClick(Qt.Key_Escape); wait(20)
          catcher.forceActiveFocus(); keyClick(Qt.Key_Menu); wait(30)
          check(live.popupOpen, "Keyboard menu key did not open actions")
          keyClick(Qt.Key_Down); keyClick(Qt.Key_Down); keyClick(Qt.Key_Return); wait(30)
          same(store.watchCalls, 1, "Alert keyboard route did not toggle exactly once")
          same(root.details, 1, "Alert menu route also opened details")
          check(actions.alertsActive, "Active watch is not reflected")
          check(find(live, function(item) { return "text" in item && item.text && item.text.indexOf("Alerts on") !== -1 }, []) !== null,
            "Active watch status not visibly labeled")
          live.openActions(); wait(30)
          keyClick(Qt.Key_Down); keyClick(Qt.Key_Down); keyClick(Qt.Key_Down); keyClick(Qt.Key_Return); wait(50)
          check(!live.popupOpen, "Explicit source route did not close menu")
          same(root.details, 1, "Source menu route also opened details")
          live.openActions(); wait(30); keyClick(Qt.Key_Return); wait(30)
          same(root.teams.length, 2, "Keyboard team schedule route absent")
          same(root.details, 1, "Keyboard team schedule route opened details")
          final.openActions(); wait(30)
          var ended = find(window.contentItem, function(item) { return item.visible && "text" in item && item.text === "Game has ended" }, [])
          check(ended !== null, "Disabled alert reason is not visible")
          keyClick(Qt.Key_Down); keyClick(Qt.Key_Down); keyClick(Qt.Key_Return); wait(30)
          same(store.watchCalls, 1, "Disabled final-game alert activated")
          live.openActions(); wait(20)
          var originalLive = live.game
          live.game = Object.assign({}, originalLive, {awayScore: originalLive.awayScore + 1})
          wait(20)
          check(live.popupOpen, "Same-game update dismissed actions")
          live.game = Object.assign({}, originalLive, {id: "nfl:replacement-card", providerGameId: "replacement-card"})
          wait(20)
          check(!live.popupOpen, "A replaced game retained an old open action menu")
          live.game = originalLive
          root.mode = "detail"
          detail.resetCursor(); wait(50)
          same(detail.focusId, "back", "Detail reset focus is not semantic Back")
          keyClick(Qt.Key_Down); wait(30)
          same(detail.focusId, "away-schedule", "Away schedule is not keyboard reachable")
          var teamsBefore = root.teams.length
          keyClick(Qt.Key_Return); wait(30)
          same(root.teams.length, teamsBefore + 1, "Detail keyboard schedule did not emit exactly once")
          same(root.teams[root.teams.length - 1], root.fixture.detail.awayTeam.id, "Detail emitted wrong canonical team")
          keyClick(Qt.Key_Down); wait(30)
          same(detail.focusId, "home-schedule", "Home schedule is not keyboard reachable")
          keyClick(Qt.Key_Return); wait(30)
          same(root.teams.length, teamsBefore + 2, "Detail home schedule did not emit exactly once")
          same(root.teams[root.teams.length - 1], root.fixture.detail.homeTeam.id, "Detail home emitted wrong canonical team")
          detail.scrollLines(1); detail.scrollPage(1); wait(20)
          var saved = detail.captureContext()
          check(saved.scrollY > 0 && saved.linesX > 0, "Rich detail context did not overflow: " + JSON.stringify(saved) + " lines=" + detail.linesData.away.length)
          detail.resetCursor(); wait(30)
          detail.restoreContext(saved); wait(50)
          var restored = detail.captureContext()
          same(restored.focusId, saved.focusId, "Detail action identity not restored")
          check(Math.abs(restored.scrollY - saved.scrollY) < 1 && Math.abs(restored.linesX - saved.linesX) < 1,
            "Detail viewport was not restored exactly")
          detail.stale = true
          detail.updateMessage = "The score provider could not update this game. Saved scores are shown."
          wait(30)
          var retry = detail.indexForFocusId("status-retry")
          check(retry >= 0, "Retained detail has no retry cursor")
          detail.cursorIndex = retry
          detail.focusCursor(); wait(30)
          keyClick(Qt.Key_Return); wait(30)
          same(root.refreshes, 1, "Detail retry did not activate once")
          detail.loading = true; wait(30)
          same(detail.indexForFocusId("status-retry"), -1, "Loading retained detail exposes Retry")
          detail.loading = false; detail.stale = false; detail.updateMessage = "Updated"; wait(30)
          same(detail.indexForFocusId("status-details"), -1, "Healthy detail creates updated-message noise")
          detail.resetCursor(); wait(30)
          capture("detail-links")
          root.mode = "standings"; wait(40)
          teamsBefore = root.teams.length
          var standingLink = find(standing, function(item) { return "scheduleTeamId" in item && item.scheduleTeamId !== "" }, [])
          check(standingLink !== null, "Standings team link absent")
          mouseClick(standingLink, standingLink.width / 2, standingLink.height / 2, Qt.LeftButton, Qt.NoModifier, 20)
          same(root.teams.length, teamsBefore + 1, "Standings team click did not route once")
          same(store.favoriteCalls, 0, "Standings team link toggled favorite")
          var star = find(standing, function(item) { return "iconName" in item && item.iconName === "starOutline" }, [])
          check(star !== null, "Standings star absent")
          mouseClick(star, star.width / 2, star.height / 2, Qt.LeftButton, Qt.NoModifier, 20)
          same(store.favoriteCalls, 1, "Standings favorite star did not toggle exactly once")
          same(root.teams.length, teamsBefore + 1, "Star also opened team schedule")
          standing.activatePrimaryAction()
          same(root.teams.length, teamsBefore + 2, "Standing row keyboard action is not schedule")
          same(store.favoriteCalls, 1, "Standing primary action changed favorite")
          console.log("CARDS_PASS " + root.uiCase.name)
          Qt.quit()
        } catch (error) { console.error("CARDS_FAIL " + error.message + "\n" + error.stack); Qt.quit() }
      }
    }
  }
}

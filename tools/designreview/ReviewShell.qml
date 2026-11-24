pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import QtTest as Test
import Quickshell
import qs.Commons as Commons

ShellRoot {
    id: root
    property bool ready: false
    property var sample: ({
            games: [],
            standings: {
                rows: []
            }
        })
    property var logos: ({})
    property var review: ({
            capture: true,
            width: 420,
            fontSize: 12
        })
    function read(path) {
        var request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl(path), false);
        request.send();
        if (!request.responseText)
            throw new Error("Missing preview input: " + path);
        return request.responseText;
    }
    Window {
        id: window
        title: "Sportray · Design preview"
        flags: Qt.Window | Qt.Dialog
        visible: root.ready
        width: root.review.capture ? board.width : root.review.width + 40
        height: root.review.capture ? board.height : 800
        color: Commons.Color.background
        minimumWidth: 360
        minimumHeight: 500
        onClosing: Qt.quit()
        Item {
            id: board
            width: root.review.width * 3 + 96
            height: 830
            visible: root.review.capture
            Rectangle {
                anchors.fill: parent
                color: Commons.Color.background
            }
            Column {
                x: 24
                y: 18
                spacing: 5
                Text {
                    text: "Sportray"
                    textFormat: Text.PlainText
                    font.family: "Adwaita Sans"
                    font.pixelSize: 23
                    font.weight: Font.Bold
                    color: Commons.Color.popups.text
                }
                Text {
                    text: "A calmer scoreboard. Your teams, front and center."
                    textFormat: Text.PlainText
                    font.family: "Adwaita Sans"
                    font.pixelSize: 12
                    color: Commons.Color.popups.text
                }
            }
            Repeater {
                id: panels
                model: root.ready ? ["scores", "detail", "team"] : []
                ReviewPanel {
                    required property string modelData
                    required property int index
                    x: 24 + index * (width + 24)
                    y: 80
                    width: root.review.width
                    height: 726
                    sample: root.sample
                    logos: root.logos
                    typeScale: root.review.fontSize / 12
                    page: modelData
                }
            }
        }
        ReviewPanel {
            id: live
            visible: !root.review.capture
            anchors.centerIn: parent
            width: Math.min(root.review.width, parent.width - 24)
            height: parent.height - 24
            sample: root.sample
            logos: root.logos
            typeScale: root.review.fontSize / 12
            focus: visible
        }
        Timer {
            interval: 200
            running: true
            onTriggered: {
                try {
                    root.review = JSON.parse(root.read("review.json"));
                    root.sample = JSON.parse(root.read("sample-state.json"));
                    root.logos = JSON.parse(root.read("logos.json"));
                    Commons.Color.loadUserShell("");
                    Commons.Color.loadColors(root.read("theme/colors.toml"));
                    Commons.Color.loadShell(root.read("theme/shell.toml"));
                    root.ready = true;
                    if (root.review.capture)
                        checks.run();
                    else {
                        live.forceActiveFocus();
                        console.log("DESIGN_PREVIEW_READY");
                    }
                } catch (error) {
                    console.error("DESIGN_PREVIEW_FAIL " + String(error));
                    Qt.quit();
                }
            }
        }
        Test.TestCase {
            id: checks
            when: false
            function check(value, message) {
                if (!value)
                    throw new Error(message || "Check failed");
            }
            function equal(actual, expected) {
                check(actual === expected, "Expected " + expected + ", got " + actual);
            }
            function capture(item, name) {
                var done = false, saved = false;
                item.grabToImage(function (result) {
                    saved = result.saveToFile(Quickshell.env("SPORTRAY_REVIEW_OUTPUT") + "/" + name + ".png");
                    done = true;
                });
                for (var attempt = 0; !done && attempt < 100; attempt++)
                    wait(50);
                check(done && saved, name + " was not captured");
            }
            function activate(panel, name) {
                var button = findChild(panel, name);
                check(button !== null, "Missing control " + name);
                mouseClick(button, button.width / 2, button.height / 2);
                wait(100);
            }
            function run() {
                try {
                    wait(300);
                    equal(panels.count, 3);
                    var scores = panels.itemAt(0), detail = panels.itemAt(1), team = panels.itemAt(2);
                    equal(scores.remainingGames.length, 3);
                    check(scores.remainingGames.every(function (game) {
                        return game.id !== scores.featured.id;
                    }));
                    capture(scores, "following");
                    capture(detail, "details");
                    capture(team, "team-schedule");
                    capture(board, "direction");
                    activate(scores, "featuredDetails");
                    equal(scores.page, "detail");
                    activate(scores, "teamScheduleButton");
                    equal(scores.page, "team");
                activate(scores, "nextFixtureDetails");
                equal(scores.page, "detail");
                equal(scores.currentGame.status, "scheduled");
                equal(scores.currentGame.awayTeam.abbreviation, "BOS");
                equal(scores.currentGame.homeTeam.abbreviation, "NYR");
                capture(scores, "upcoming-details");
                activate(scores, "backButton");
                equal(scores.page, "team");
                    activate(scores, "backButton");
                    equal(scores.page, "detail");
                    activate(scores, "backButton");
                    equal(scores.page, "scores");
                    activate(scores, "nav-calendar");
                    equal(scores.page, "calendar");
                    capture(scores, "calendar");
                    activate(scores, "nav-standings");
                    equal(scores.page, "standings");
                    capture(scores, "standings");
                    scores.reset();
                    scores.forceActiveFocus();
                    var primary = findChild(scores, "featuredDetails");
                    primary.forceActiveFocus();
                    keyClick(Qt.Key_Space);
                    wait(100);
                    equal(scores.page, "detail");
                    scores.forceActiveFocus();
                    keyClick(Qt.Key_Escape);
                    wait(100);
                    equal(scores.page, "scores");
                    if (root.review.width === 420 && root.review.fontSize === 12)
                        check(!scores.hasOverflow(), "Normal Following must expose all three additional games");
                    team.revealEnd();
                    wait(100);
                    capture(team, "team-schedule-end");
                    console.log("DESIGN_PREVIEW_PASS " + root.review.width + "/" + root.review.fontSize);
                } catch (error) {
                    console.error("DESIGN_PREVIEW_FAIL " + String(error));
                }
                Qt.quit();
            }
        }
    }
}

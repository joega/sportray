pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import QtQuick.Controls as Controls
import qs.Commons as Commons
import "../../model/UiContrast.js" as Contrast

// A separate, fixture-only visual prototype. Never acquires SportrayService.
Rectangle {
    id: root
    property var sample: ({
            games: [],
            standings: {
                rows: []
            }
        })
    property var logos: ({})
    property string page: "scores"
    property string section: "scores"
    property string gameId: "nhl:demo-bos-tor"
    property var selectedGame: null
    property string gameFilter: "All"
    property string leagueFilter: "Following"
    property var history: []
    property bool alertsOn: false
    property real typeScale: Commons.Style.fontBaseSize / 12
    readonly property color ink: Commons.Color.popups.text
    readonly property color canvas: Commons.Color.popups.background
    readonly property color muted: Contrast.foreground(Qt.alpha(ink, 0.66), ink, canvas)
    readonly property color line: Qt.alpha(ink, 0.09)
    readonly property color surface: Qt.tint(canvas, Qt.alpha(ink, 0.035))
    readonly property color accent: Contrast.foreground(Contrast.luminance(canvas) > .5 ? Qt.darker(Commons.Color.accent, 1.15) : Commons.Color.accent, ink, canvas)
    readonly property var featured: sample.games.length ? sample.games[0] : null
    readonly property var currentGame: {
        if (selectedGame)
            return selectedGame;
        for (var i = 0; i < sample.games.length; i++)
            if (sample.games[i].id === gameId)
                return sample.games[i];
        return featured;
    }
    readonly property var remainingGames: sample.games.filter(function (game) {
        if (root.featured && game.id === root.featured.id)
            return false;
        if (root.leagueFilter !== "Following" && game.league.toUpperCase() !== root.leagueFilter)
            return false;
        if (root.gameFilter === "Live" && game.status !== "live")
            return false;
        if (root.gameFilter === "Favorites" && game.league === "mlb")
            return false;
        return true;
    })
    readonly property bool showFeature: featured && (leagueFilter === "Following" || leagueFilter === "NHL")
    readonly property var schedule: [
        {
            day: "MON",
            date: "12",
            name: "New York Rangers",
            code: "nyr",
            place: "Away",
            time: "7:00 PM",
            week: "This week"
        },
        {
            day: "THU",
            date: "15",
            name: "Carolina Hurricanes",
            code: "car",
            place: "Home",
            time: "7:00 PM",
            week: ""
        },
        {
            day: "SAT",
            date: "17",
            name: "Colorado Avalanche",
            code: "col",
            place: "Home",
            time: "1:00 PM",
            week: ""
        },
        {
            day: "TUE",
            date: "20",
            name: "Edmonton Oilers",
            code: "edm",
            place: "Away",
            time: "9:00 PM",
            week: "Next week"
        },
        {
            day: "THU",
            date: "22",
            name: "Vegas Golden Knights",
            code: "vgk",
            place: "Away",
            time: "10:00 PM",
            week: ""
        }
    ]
    readonly property var nextGame: scheduledGame(schedule[0])
    signal pageChangedByUser
    color: canvas
    radius: 18
    border.color: Qt.alpha(ink, 0.12)
    border.width: 1
    clip: true

    function sp(value) {
        return Math.round(value * typeScale);
    }
    function logo(league, code) {
        return logos["https://a.espncdn.com/i/teamlogos/" + league + "/500/" + code + ".png"] || "";
    }
    function shortName(team) {
        if (!team)
            return "";
        return {
            "TOR": "Maple Leafs",
            "BOS": "Bruins",
            "BUF": "Bills",
            "KC": "Chiefs",
            "NYY": "Yankees",
            "LAD": "Dodgers",
            "LAL": "Lakers",
            "DEN": "Nuggets"
        }[team.abbreviation] || team.name;
    }
    function scheduledGame(fixture) {
        var opponent = {
            name: fixture.name,
            abbreviation: fixture.code.toUpperCase(),
            logoUrl: "https://a.espncdn.com/i/teamlogos/nhl/500/" + fixture.code + ".png"
        };
        var boston = {
            name: "Boston Bruins",
            abbreviation: "BOS",
            logoUrl: "https://a.espncdn.com/i/teamlogos/nhl/500/bos.png"
        };
        return {
            id: "preview-oct-" + fixture.date,
            league: "nhl",
            status: "scheduled",
            timeLabel: fixture.time,
            dateLabel: "Oct " + fixture.date,
            venue: fixture.place === "Home" ? "TD Garden" : "Away game",
            awayTeam: fixture.place === "Home" ? opponent : boston,
            homeTeam: fixture.place === "Home" ? boston : opponent
        };
    }
    function openPage(value, id, override) {
        history = history.concat([
            {
                page: page,
                section: section,
                gameId: gameId,
                selectedGame: selectedGame,
                y: scroll.contentY
            }
        ]);
        if (id)
            gameId = id;
        if (value === "detail")
            selectedGame = override || null;
        page = value;
        scroll.contentY = 0;
        pageChangedByUser();
    }
    function goBack() {
        if (!history.length) {
            page = "scores";
            section = "scores";
            return;
        }
        var stack = history.slice(), previous = stack.pop();
        history = stack;
        page = previous.page;
        section = previous.section;
        gameId = previous.gameId;
        selectedGame = previous.selectedGame;
        Qt.callLater(function () {
            scroll.contentY = previous.y;
        });
        pageChangedByUser();
    }
    function selectSection(value) {
        history = [];
        section = value;
        page = value;
        scroll.contentY = 0;
        pageChangedByUser();
    }
    function reset() {
        page = "scores";
        section = "scores";
        history = [];
        gameFilter = "All";
        leagueFilter = "Following";
        gameId = "nhl:demo-bos-tor";
        selectedGame = null;
        alertsOn = false;
        scroll.contentY = 0;
    }
    function revealEnd() {
        scroll.contentY = Math.max(0, scroll.contentHeight - scroll.height);
    }
    function hasOverflow() {
        return scroll.contentHeight > scroll.height;
    }
    Keys.onEscapePressed: root.goBack()
    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_PageDown)
            scroll.contentY = Math.min(scroll.contentHeight - scroll.height, scroll.contentY + scroll.height * .8);
        else if (event.key === Qt.Key_PageUp)
            scroll.contentY = Math.max(0, scroll.contentY - scroll.height * .8);
        else
            return;
        event.accepted = true;
    }

    component Label: Text {
        textFormat: Text.PlainText
        color: root.ink
        font.family: "Adwaita Sans"
        font.pixelSize: root.sp(13)
        renderType: Text.QtRendering
    }
    component Button: Controls.AbstractButton {
        id: control
        property bool emphasized: false
        property bool filled: false
        padding: root.sp(9)
        implicitWidth: contentItem.implicitWidth + padding * 2
        implicitHeight: Math.max(root.sp(30), contentItem.implicitHeight + root.sp(12))
        activeFocusOnTab: true
        contentItem: Label {
            textFormat: Text.PlainText
            text: control.text
            font.pixelSize: root.sp(12)
            font.weight: control.emphasized ? Font.DemiBold : Font.Normal
            color: control.emphasized ? root.accent : root.ink
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 9
            color: control.down ? Qt.alpha(root.ink, .1) : control.hovered || control.filled ? root.surface : "transparent"
            border.width: control.visualFocus ? 2 : 0
            border.color: root.accent
        }
        Accessible.name: text
        Accessible.role: Accessible.Button
        Accessible.onPressAction: control.clicked()
    }
    component Logo: Item {
        id: badge
        property string source: ""
        property string abbreviation: ""
        implicitWidth: root.sp(30)
        implicitHeight: implicitWidth
        // The white plate belongs to the asset, keeping dark team marks readable.
        Rectangle {
            anchors.fill: parent
            radius: width * .24
            color: "#fafafa"
            visible: mark.status === Image.Ready
        }
        Image {
            id: mark
            anchors.fill: parent
            anchors.margins: width * .08
            source: badge.source
            fillMode: Image.PreserveAspectFit
        }
        Label {
            textFormat: Text.PlainText
            anchors.centerIn: parent
            visible: mark.status !== Image.Ready
            text: badge.abbreviation
            font.weight: Font.DemiBold
        }
    }
    component SectionLabel: Item {
        property string title: ""
        property string trailing: ""
        implicitHeight: root.sp(31)
        Label {
            textFormat: Text.PlainText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: parent.title
            font.pixelSize: root.sp(15)
            font.weight: Font.DemiBold
        }
        Label {
            textFormat: Text.PlainText
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: parent.trailing
            font.pixelSize: root.sp(11)
            color: root.muted
        }
    }
    component Hero: Rectangle {
        id: hero
        property var game: root.featured
        property bool upcoming: false
        property bool linkVisible: false
        implicitHeight: heroColumn.implicitHeight + root.sp(30)
        color: Qt.tint(root.canvas, Qt.alpha(Commons.Color.accent, .055))
        radius: 15
        border.width: 1
        border.color: Qt.alpha(root.ink, .055)
        Column {
            id: heroColumn
            x: root.sp(16)
            y: root.sp(15)
            width: parent.width - x * 2
            spacing: root.sp(13)
            Item {
                width: parent.width
                height: root.sp(17)
                Label {
                    textFormat: Text.PlainText
                    text: hero.game ? hero.game.league.toUpperCase() + (hero.game.venue ? " · " + hero.game.venue : "") : ""
                    color: root.muted
                    font.pixelSize: root.sp(11)
                    width: parent.width * .8
                    elide: Text.ElideRight
                }
                Row {
                    anchors.right: parent.right
                    spacing: root.sp(5)
                    Rectangle {
                        width: root.sp(5)
                        height: width
                        radius: width / 2
                        color: root.accent
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !hero.upcoming && hero.game && hero.game.status === "live"
                    }
                    Label {
                        textFormat: Text.PlainText
                        text: hero.upcoming || (hero.game && hero.game.status === "scheduled") ? "Next up" : "Live"
                        color: root.accent
                        font.pixelSize: root.sp(11)
                        font.weight: Font.DemiBold
                    }
                }
            }
            Item {
                width: parent.width
                height: Math.max(awayIdentity.height, homeIdentity.height, scoreBlock.height)
                Column {
                    id: awayIdentity
                    width: parent.width * .29
                    spacing: root.sp(6)
                    Logo {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: root.sp(48)
                        height: width
                        source: hero.game ? root.logos[hero.game.awayTeam.logoUrl] || "" : ""
                        abbreviation: hero.game ? hero.game.awayTeam.abbreviation : ""
                    }
                    Label {
                        textFormat: Text.PlainText
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: hero.game ? root.shortName(hero.game.awayTeam) : ""
                        font.pixelSize: root.sp(13)
                        font.weight: Font.DemiBold
                    }
                }
                Column {
                    id: scoreBlock
                    width: parent.width * .42
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.sp(5)
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: root.sp(9)
                        visible: !hero.upcoming && hero.game && hero.game.status !== "scheduled"
                        Label {
                            textFormat: Text.PlainText
                            text: hero.game && hero.game.awayScore !== undefined ? String(hero.game.awayScore) : ""
                            font.pixelSize: Math.min(root.sp(40), heroColumn.width * .13)
                            font.weight: Font.DemiBold
                            font.features: {
                                "tnum": 1
                            }
                        }
                        Label {
                            textFormat: Text.PlainText
                            text: "–"
                            font.pixelSize: root.sp(24)
                            color: root.muted
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Label {
                            textFormat: Text.PlainText
                            text: hero.game && hero.game.homeScore !== undefined ? String(hero.game.homeScore) : ""
                            font.pixelSize: Math.min(root.sp(40), heroColumn.width * .13)
                            font.weight: Font.DemiBold
                            font.features: {
                                "tnum": 1
                            }
                        }
                    }
                    Label {
                        textFormat: Text.PlainText
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: hero.upcoming || (hero.game && hero.game.status === "scheduled")
                        text: hero.game && hero.game.timeLabel ? hero.game.timeLabel : "8:30 PM"
                        font.pixelSize: Math.min(root.sp(22), heroColumn.width * .085)
                        font.weight: Font.DemiBold
                    }
                    Label {
                        textFormat: Text.PlainText
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: hero.upcoming ? "Tomorrow" : hero.game && hero.game.status === "scheduled" ? hero.game.dateLabel || "Tonight" : hero.game && hero.game.league === "nhl" ? "2nd · 8:42" : hero.game && hero.game.league === "nfl" ? "4th · 2:16" : "Top 7th"
                        font.pixelSize: root.sp(11)
                        color: root.muted
                    }
                }
                Column {
                    id: homeIdentity
                    width: parent.width * .29
                    anchors.right: parent.right
                    spacing: root.sp(6)
                    Logo {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: root.sp(48)
                        height: width
                        source: hero.game ? root.logos[hero.game.homeTeam.logoUrl] || "" : ""
                        abbreviation: hero.game ? hero.game.homeTeam.abbreviation : ""
                    }
                    Label {
                        textFormat: Text.PlainText
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: hero.game ? root.shortName(hero.game.homeTeam) : ""
                        font.pixelSize: root.sp(13)
                        font.weight: Font.DemiBold
                    }
                }
            }
            Rectangle {
                width: parent.width
                height: 1
                color: root.line
                visible: hero.linkVisible
            }
            Button {
                objectName: hero.upcoming ? "nextFixtureDetails" : "featuredDetails"
                width: parent.width
                height: root.sp(25)
                padding: 0
                visible: hero.linkVisible
                text: "Game details  →"
                emphasized: true
                onClicked: root.openPage("detail", hero.game.id, hero.upcoming ? hero.game : null)
            }
        }
    }
    component GameRow: Controls.AbstractButton {
        id: gameRow
        required property var game
        implicitHeight: root.sp(79)
        activeFocusOnTab: true
        onClicked: root.openPage("detail", game.id)
        background: Rectangle {
            radius: 10
            color: gameRow.hovered ? Qt.alpha(root.ink, .045) : "transparent"
            border.width: gameRow.visualFocus ? 2 : 0
            border.color: root.accent
        }
        contentItem: Item {
            Column {
                x: root.sp(12)
                y: root.sp(11)
                width: parent.width * .69
                spacing: root.sp(7)
                Repeater {
                    model: [gameRow.game.awayTeam, gameRow.game.homeTeam]
                    Row {
                        required property var modelData
                        width: parent.width
                        spacing: root.sp(9)
                        Logo {
                            width: root.sp(22)
                            height: width
                            source: root.logos[modelData.logoUrl] || ""
                            abbreviation: modelData.abbreviation
                        }
                        Label {
                            textFormat: Text.PlainText
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.shortName(modelData)
                            font.pixelSize: root.sp(13)
                            font.weight: Font.Medium
                        }
                    }
                }
            }
            Column {
                anchors.right: parent.right
                anchors.rightMargin: root.sp(12)
                y: root.sp(12)
                spacing: root.sp(9)
                Label {
                    textFormat: Text.PlainText
                    anchors.right: parent.right
                    text: gameRow.game.status === "scheduled" ? "8:30 PM" : gameRow.game.awayScore
                    font.pixelSize: root.sp(gameRow.game.status === "scheduled" ? 12 : 16)
                    font.weight: Font.DemiBold
                    font.features: {
                        "tnum": 1
                    }
                }
                Label {
                    textFormat: Text.PlainText
                    anchors.right: parent.right
                    text: gameRow.game.status === "scheduled" ? "Tonight" : gameRow.game.homeScore
                    font.pixelSize: root.sp(gameRow.game.status === "scheduled" ? 11 : 16)
                    color: gameRow.game.status === "scheduled" ? root.muted : root.ink
                    font.weight: Font.DemiBold
                    font.features: {
                        "tnum": 1
                    }
                }
            }
            Label {
                textFormat: Text.PlainText
                anchors.left: parent.left
                anchors.leftMargin: root.sp(12)
                anchors.bottom: parent.bottom
                anchors.bottomMargin: root.sp(5)
                text: gameRow.game.league.toUpperCase() + (gameRow.game.status === "scheduled" ? "" : gameRow.game.league === "nfl" ? " · 4th · 2:16" : " · Top 7th")
                font.pixelSize: root.sp(9)
                color: root.muted
            }
        }
        Accessible.name: game.awayTeam.name + " at " + game.homeTeam.name + ". Open game details"
        Accessible.role: Accessible.Button
    }

    Column {
        id: main
        anchors.fill: parent
        anchors.margins: root.sp(20)
        spacing: root.sp(12)
        Item {
            id: heading
            width: parent.width
            height: Math.max(root.sp(47), titleColumn.implicitHeight)
            Column {
                id: titleColumn
                anchors.left: parent.left
                anchors.right: utility.left
                anchors.rightMargin: root.sp(6)
                spacing: root.sp(3)
                Label {
                    textFormat: Text.PlainText
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: root.page === "team" ? "Boston Bruins" : root.page === "detail" ? "Game details" : root.page === "calendar" ? "Calendar" : root.page === "standings" ? "Standings" : "Today"
                    font.pixelSize: Math.min(root.sp(24), root.width * .08)
                    font.weight: Font.Bold
                }
                Label {
                    textFormat: Text.PlainText
                    text: root.page === "team" ? "NHL · Team schedule" : root.page === "detail" ? root.currentGame && root.currentGame.status === "scheduled" ? "Upcoming matchup" : "Sunday, October 11" : root.page === "calendar" ? "October 2026" : root.page === "standings" ? "NHL · Eastern Conference" : "Sunday, October 11"
                    color: root.muted
                    font.pixelSize: root.sp(11)
                }
            }
            Button {
                id: utility
                objectName: "backButton"
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.page === "detail" || root.page === "team" ? root.width < 360 ? "←" : "← Back" : "•••"
                emphasized: true
                Accessible.name: root.page === "detail" || root.page === "team" ? "Back" : "Preview options"
                onClicked: root.page === "detail" || root.page === "team" ? root.goBack() : options.open()
            }
            Controls.Menu {
                id: options
                x: parent.width - width
                y: utility.y + utility.height
                Controls.MenuItem {
                    text: "Reset preview"
                    onTriggered: root.reset()
                }
                Controls.MenuItem {
                    text: "Close preview"
                    onTriggered: root.Window.window.close()
                }
            }
        }
        Row {
            id: navigation
            width: parent.width
            height: visible ? root.sp(37) : 0
            visible: root.page !== "detail" && root.page !== "team"
            Repeater {
                model: [
                    {
                        id: "scores",
                        label: "Scores"
                    },
                    {
                        id: "calendar",
                        label: "Calendar"
                    },
                    {
                        id: "standings",
                        label: "Standings"
                    }
                ]
                Button {
                    required property var modelData
                    width: navigation.width / 3
                    height: navigation.height
                    objectName: "nav-" + modelData.id
                    text: modelData.label
                    emphasized: root.section === modelData.id
                    onClicked: root.selectSection(modelData.id)
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 2
                        width: parent.width * .58
                        radius: 1
                        color: root.section === parent.modelData.id ? root.accent : "transparent"
                    }
                }
            }
        }
        Item {
            id: scope
            width: parent.width
            height: visible ? root.sp(26) : 0
            visible: root.page === "scores"
            Button {
                anchors.left: parent.left
                height: parent.height
                padding: 0
                text: root.leagueFilter + "  ⌄"
                emphasized: true
                onClicked: leagues.open()
            }
            Button {
                anchors.right: parent.right
                height: parent.height
                padding: 0
                text: root.gameFilter + "  ⌄"
                onClicked: filters.open()
            }
            Controls.Menu {
                id: leagues
                y: scope.height
                Repeater {
                    model: ["Following", "NHL", "NFL", "MLB", "NBA"]
                    Controls.MenuItem {
                        required property string modelData
                        text: modelData
                        onTriggered: root.leagueFilter = modelData
                    }
                }
            }
            Controls.Menu {
                id: filters
                x: scope.width - width
                y: scope.height
                Repeater {
                    model: ["All", "Live", "Favorites"]
                    Controls.MenuItem {
                        required property string modelData
                        text: modelData
                        onTriggered: root.gameFilter = modelData
                    }
                }
            }
        }
        Flickable {
            id: scroll
            width: parent.width
            height: Math.max(0, main.height - heading.height - (navigation.visible ? navigation.height : 0) - (scope.visible ? scope.height : 0) - footnote.height - main.spacing * 4)
            contentWidth: width
            contentHeight: pages.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Controls.ScrollBar.vertical: Controls.ScrollBar {
                policy: Controls.ScrollBar.AsNeeded
            }
            Column {
                id: pages
                width: parent.width
                spacing: root.sp(14)
                Column {
                    width: parent.width
                    visible: root.page === "scores"
                    spacing: root.sp(12)
                    Hero {
                        width: parent.width
                        visible: root.showFeature
                        linkVisible: true
                    }
                    SectionLabel {
                        width: parent.width
                        title: "More games"
                        trailing: root.remainingGames.length + " games"
                    }
                    Rectangle {
                        width: parent.width
                        height: gamesColumn.implicitHeight
                        radius: 13
                        color: root.surface
                        Column {
                            id: gamesColumn
                            width: parent.width
                            Repeater {
                                model: root.remainingGames
                                Column {
                                    required property var modelData
                                    required property int index
                                    width: gamesColumn.width
                                    GameRow {
                                        width: parent.width
                                        game: modelData
                                    }
                                    Rectangle {
                                        x: root.sp(12)
                                        width: parent.width - x * 2
                                        height: index < root.remainingGames.length - 1 ? 1 : 0
                                        color: root.line
                                    }
                                }
                            }
                            Label {
                                textFormat: Text.PlainText
                                visible: !root.remainingGames.length
                                width: parent.width
                                padding: root.sp(14)
                                text: "No other games in this view."
                                color: root.muted
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
                Column {
                    width: parent.width
                    visible: root.page === "detail"
                    spacing: root.sp(15)
                    Hero {
                        width: parent.width
                        game: root.currentGame
                    }
                    Flow {
                        id: detailActions
                        width: parent.width
                        spacing: root.sp(8)
                        Button {
                            objectName: "teamScheduleButton"
                            width: root.width < 360 && root.typeScale > 1.1 ? parent.width : (parent.width - parent.spacing) / 2
                            text: "Bruins schedule  →"
                            filled: true
                            emphasized: true
                            visible: root.currentGame && root.currentGame.league === "nhl"
                            onClicked: root.openPage("team")
                        }
                        Button {
                            width: root.width < 360 && root.typeScale > 1.1 ? parent.width : (parent.width - parent.spacing) / 2
                            text: root.alertsOn ? "✓  Alerts on" : "♡  Game alerts"
                            filled: true
                            onClicked: root.alertsOn = !root.alertsOn
                        }
                    }
                    Column {
                        width: parent.width
                        spacing: root.sp(6)
                        visible: root.currentGame && root.currentGame.league === "nhl" && root.currentGame.status !== "scheduled"
                        SectionLabel {
                            width: parent.width
                            title: "Scoring"
                            trailing: root.currentGame ? root.currentGame.league.toUpperCase() : ""
                        }
                        Rectangle {
                            width: parent.width
                            height: root.sp(108)
                            radius: 13
                            color: root.surface
                            Column {
                                x: root.sp(14)
                                y: root.sp(12)
                                width: parent.width - x * 2
                                spacing: root.sp(10)
                                Repeater {
                                    model: [["", "1", "2", "3", "T"], ["TOR", "1", "2", "–", "3"], ["BOS", "1", "1", "–", "2"]]
                                    Row {
                                        required property var modelData
                                        required property int index
                                        width: parent.width
                                        Repeater {
                                            model: modelData
                                            Label {
                                                textFormat: Text.PlainText
                                                required property string modelData
                                                required property int index
                                                width: index === 0 ? parent.width * .34 : parent.width * .165
                                                text: modelData
                                                horizontalAlignment: index ? Text.AlignRight : Text.AlignLeft
                                                color: parent.index === 0 ? root.muted : root.ink
                                                font.pixelSize: root.sp(12)
                                                font.weight: index === 4 ? Font.DemiBold : Font.Normal
                                                font.features: {
                                                    "tnum": 1
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Column {
                        width: parent.width
                        visible: root.currentGame && root.currentGame.league === "nhl" && root.currentGame.status !== "scheduled"
                        spacing: root.sp(6)
                        SectionLabel {
                            width: parent.width
                            title: "Team stats"
                            trailing: "TOR       BOS"
                        }
                        Rectangle {
                            width: parent.width
                            height: statsColumn.implicitHeight + root.sp(22)
                            radius: 13
                            color: root.surface
                            Column {
                                id: statsColumn
                                x: root.sp(14)
                                y: root.sp(11)
                                width: parent.width - x * 2
                                spacing: root.sp(15)
                                Repeater {
                                    model: [
                                        {
                                            label: "Shots on goal",
                                            away: "24",
                                            home: "28",
                                            ratio: 24 / 52
                                        },
                                        {
                                            label: "Power play",
                                            away: "0/2",
                                            home: "1/3",
                                            ratio: null
                                        },
                                        {
                                            label: "Penalty minutes",
                                            away: "4",
                                            home: "6",
                                            ratio: .4
                                        }
                                    ]
                                    Column {
                                        required property var modelData
                                        width: statsColumn.width
                                        spacing: root.sp(7)
                                        Item {
                                            width: parent.width
                                            height: root.sp(17)
                                            Label {
                                                textFormat: Text.PlainText
                                                text: parent.parent.modelData.away
                                                font.weight: Font.DemiBold
                                            }
                                            Label {
                                                textFormat: Text.PlainText
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: parent.parent.modelData.label
                                                color: root.muted
                                                font.pixelSize: root.sp(11)
                                            }
                                            Label {
                                                textFormat: Text.PlainText
                                                anchors.right: parent.right
                                                text: parent.parent.modelData.home
                                                font.weight: Font.DemiBold
                                            }
                                        }
                                        Row {
                                            visible: parent.modelData.ratio !== null
                                            width: parent.width
                                            spacing: root.sp(4)
                                            Rectangle {
                                                width: (parent.width - parent.spacing) * (parent.parent.modelData.ratio || 0)
                                                height: root.sp(3)
                                                radius: 2
                                                color: Qt.alpha(root.ink, .22)
                                            }
                                            Rectangle {
                                                width: (parent.width - parent.spacing) * (1 - parent.parent.modelData.ratio)
                                                height: root.sp(3)
                                                radius: 2
                                                color: Qt.alpha(root.accent, .65)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Column {
                    width: parent.width
                    visible: root.page === "team"
                    spacing: root.sp(10)
                    Hero {
                        width: parent.width
                        game: root.nextGame
                        upcoming: true
                        linkVisible: true
                    }
                    Repeater {
                        model: root.schedule.slice(1)
                        Column {
                            required property var modelData
                            width: pages.width
                            SectionLabel {
                                width: parent.width
                                visible: modelData.week !== "" || modelData.date === "15"
                                title: modelData.date === "15" ? "This week" : modelData.week
                                trailing: modelData.date === "15" ? "October 12–18" : "October 19–25"
                            }
                            Controls.AbstractButton {
                                id: fixture
                                width: parent.width
                                height: root.sp(68)
                                activeFocusOnTab: true
                                onClicked: root.openPage("detail", "preview-oct-" + fixture.parent.modelData.date, root.scheduledGame(fixture.parent.modelData))
                                background: Rectangle {
                                    radius: 10
                                    color: fixture.hovered ? root.surface : "transparent"
                                    border.width: fixture.visualFocus ? 2 : 0
                                    border.color: root.accent
                                }
                                contentItem: Item {
                                    Column {
                                        x: 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: root.sp(35)
                                        spacing: 1
                                        Label {
                                            textFormat: Text.PlainText
                                            text: fixture.parent.modelData.day
                                            color: root.muted
                                            font.pixelSize: root.sp(9)
                                            font.weight: Font.Medium
                                        }
                                        Label {
                                            textFormat: Text.PlainText
                                            text: fixture.parent.modelData.date
                                            font.pixelSize: root.sp(20)
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                    Logo {
                                        x: root.sp(47)
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: root.sp(30)
                                        height: width
                                        source: root.logo("nhl", fixture.parent.modelData.code)
                                    }
                                    Column {
                                        x: root.sp(88)
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - x - (root.width < 360 ? 0 : root.sp(73))
                                        spacing: root.sp(4)
                                        Label {
                                            textFormat: Text.PlainText
                                            width: parent.width
                                            wrapMode: Text.WordWrap
                                            text: fixture.parent.modelData.name
                                            font.pixelSize: root.sp(12)
                                            font.weight: Font.Medium
                                        }
                                        Label {
                                            textFormat: Text.PlainText
                                            width: parent.width
                                            wrapMode: Text.WordWrap
                                            text: fixture.parent.modelData.place + (root.width < 360 ? " · " + fixture.parent.modelData.time : "")
                                            color: root.muted
                                            font.pixelSize: root.sp(11)
                                        }
                                    }
                                    Label {
                                        textFormat: Text.PlainText
                                        visible: root.width >= 360
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: fixture.parent.modelData.time
                                        font.pixelSize: root.sp(11)
                                        font.weight: Font.Medium
                                    }
                                }
                                Accessible.name: fixture.parent.modelData.name + ", " + fixture.parent.modelData.time
                            }
                            Rectangle {
                                width: parent.width
                                height: 1
                                color: root.line
                            }
                        }
                    }
                }
                Column {
                    width: parent.width
                    visible: root.page === "calendar"
                    spacing: root.sp(10)
                    SectionLabel {
                        width: parent.width
                        title: "All followed leagues"
                        trailing: "October"
                    }
                    Grid {
                        width: parent.width
                        columns: 7
                        spacing: 0
                        Repeater {
                            model: ["M", "T", "W", "T", "F", "S", "S"]
                            Label {
                                textFormat: Text.PlainText
                                required property string modelData
                                width: pages.width / 7
                                height: root.sp(25)
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData
                                color: root.muted
                                font.pixelSize: root.sp(11)
                            }
                        }
                        Repeater {
                            model: 35
                            Button {
                                required property int index
                                width: pages.width / 7
                                height: root.sp(39)
                                text: index >= 3 && index < 34 ? String(index - 2) : ""
                                enabled: text !== ""
                                emphasized: index - 2 === calendarDay.day
                                filled: index - 2 === calendarDay.day
                                onClicked: calendarDay.day = index - 2
                            }
                        }
                    }
                    SectionLabel {
                        id: calendarDay
                        property int day: 11
                        width: parent.width
                        title: "October " + day
                        trailing: "Your teams"
                    }
                    Hero {
                        width: parent.width
                        visible: calendarDay.day === 11
                        linkVisible: true
                    }
                    Label {
                        textFormat: Text.PlainText
                        width: parent.width
                        visible: calendarDay.day !== 11
                        text: "No illustrative games on this date."
                        wrapMode: Text.WordWrap
                        color: root.muted
                    }
                }
                Column {
                    width: parent.width
                    visible: root.page === "standings"
                    spacing: root.sp(8)
                    SectionLabel {
                        width: parent.width
                        title: "Eastern Conference"
                        trailing: "GP     PTS"
                    }
                    Repeater {
                        model: root.sample.standings.rows.slice(0, 4)
                        Button {
                            required property var modelData
                            width: pages.width
                            height: root.sp(50)
                            text: modelData.rank + "    " + modelData.team.name + "    " + modelData.played + "    " + modelData.points
                            filled: modelData.team.abbreviation === "BOS"
                            onClicked: root.openPage("team")
                        }
                    }
                }
            }
        }
        Label {
            textFormat: Text.PlainText
            id: footnote
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "Design preview · Illustrative games"
            color: root.muted
            font.pixelSize: root.sp(10)
        }
    }
}

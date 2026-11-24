import QtQuick
import qs.Commons as Commons
import qs.Ui
import "../model/UiTypography.js" as Typography
import "../model/StandingsPresentation.js" as Presentation

Item {
  id: root
  required property var standing
  property bool favorite: false
  property var settings: null
  property var imageStore: null
  property bool selected: false
  readonly property string teamLogoSource: root.imageStore && root.standing.team && root.standing.team.logoUrl
    ? root.imageStore.sourceFor(root.standing.team.logoUrl) : ""
  readonly property var columns: Presentation.columnsForLeague(root.standing.league)
  readonly property var geometry: Presentation.layout(width, Commons.Style.spaceReal(1), root.standing.league)
  readonly property bool childActionPressed: favoriteButton.pointerPressed || teamLink.pointerPressed
  signal teamScheduleRequested(string teamId)
  width: parent ? parent.width : implicitWidth
  implicitHeight: Math.max(Commons.Style.space(42), favoriteButton.implicitHeight + Commons.Style.spacing.xs * 2)
  height: implicitHeight

  function valueOrDash(value) { return value === null || value === undefined || value === "" ? "—" : String(value) }
  function teamLabel() {
    var team = root.standing && root.standing.team ? root.standing.team : {}
    return team.name || team.shortName || team.abbreviation || "Unnamed team"
  }
  function toggleFavorite() {
    if (root.settings && root.standing && root.standing.team
        && typeof root.settings.toggleFavoriteTeam === "function")
      root.settings.toggleFavoriteTeam(root.standing.team.id, root.teamLabel())
  }
  function activatePrimaryAction() {
    if (root.standing && root.standing.team && root.standing.team.id)
      root.teamScheduleRequested(root.standing.team.id)
  }
  function focusTeam() {
    if (!teamLink.available) return false
    teamLink.forceActiveFocus()
    return true
  }
  Accessible.name: root.teamLabel() + ", " + (root.standing.rankKind === "seed" ? "seed " : "rank ")
    + root.valueOrDash(root.standing.rank) + ". " + root.columns.map(function(column) {
      return column.label + " " + Presentation.metricValue(root.standing, column.key)
    }).join(", ") + (root.favorite ? ". Favorite team." : "")
  Accessible.role: root.standing && root.standing.team && root.standing.team.id ? Accessible.Button : Accessible.StaticText
  Accessible.onPressAction: root.activatePrimaryAction()

  BorderSurface {
    anchors.fill: parent
    color: root.favorite ? Qt.alpha(Commons.Color.accent, 0.05) : "transparent"
    borderSpec: root.selected ? Commons.Border.controlSpec("focus", Commons.Color.popups.text, Commons.Color.accent) : Commons.Border.none()
    radius: Commons.Style.cornerRadius
  }
  Row {
    width: parent.width - root.geometry.padding * 2
    height: parent.height
    x: root.geometry.padding
    spacing: root.geometry.gap
    Text {
      width: root.geometry.rankWidth
      anchors.verticalCenter: parent.verticalCenter
      text: root.valueOrDash(root.standing.rank)
      textFormat: Text.PlainText
      color: Qt.alpha(Commons.Color.popups.text, 0.85)
      font.family: Typography.family
      font.pixelSize: Commons.Style.font.bodySmall
      font.features: ({"tnum": 1})
      horizontalAlignment: Text.AlignHCenter
    }
    Item {
      width: root.geometry.teamWidth
      height: parent.height
      Rectangle {
        anchors.fill: logo
        anchors.margins: -Commons.Style.space(2)
        radius: Commons.Style.space(4)
        color: "#f5f5f5"
        visible: logo.visible
      }
      Image {
        id: logo
        width: Commons.Style.space(22)
        height: width
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        source: root.teamLogoSource
        sourceSize: Qt.size(width * 2, height * 2)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        visible: status === Image.Ready
      }
      Text {
        width: Commons.Style.space(22)
        anchors.verticalCenter: parent.verticalCenter
        text: root.standing.team && root.standing.team.abbreviation ? root.standing.team.abbreviation : "?"
        textFormat: Text.PlainText
        visible: !logo.visible
        color: Qt.alpha(Commons.Color.popups.text, 0.85)
        font.family: Typography.family
        font.pixelSize: Commons.Style.font.caption
        elide: Text.ElideRight
      }
      TeamScheduleLink {
        id: teamLink
        anchors.left: logo.right
        anchors.leftMargin: Commons.Style.spacing.xs
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.geometry.teamWidth < Commons.Style.space(140) && root.standing.team && root.standing.team.abbreviation
          ? root.standing.team.abbreviation : root.teamLabel()
        foreground: Commons.Color.popups.text
        fontSize: Commons.Style.font.body
        bold: root.favorite
        height: parent.height
        team: root.standing.team
        onRequested: function(teamId) { root.teamScheduleRequested(teamId) }
      }
    }
    Row {
      width: root.geometry.metricsWidth
      anchors.verticalCenter: parent.verticalCenter
      Repeater {
        model: root.columns
        Text {
          required property var modelData
          width: root.geometry.metricsWidth / root.columns.length
          text: Presentation.metricValue(root.standing, modelData.key)
          textFormat: Text.PlainText
          color: Commons.Color.popups.text
          font.family: Typography.family
          font.pixelSize: Commons.Style.font.bodySmall
          font.features: ({"tnum": 1})
          horizontalAlignment: Text.AlignRight
        }
      }
    }
    SemanticActionButton {
      id: favoriteButton
      width: root.geometry.favoriteWidth
      anchors.verticalCenter: parent.verticalCenter
      iconName: root.favorite ? "star" : "starOutline"
      size: Commons.Style.space(28)
      fontSize: Commons.Style.font.body
      foreground: root.favorite ? Commons.Color.accent : Qt.alpha(Commons.Color.popups.text, 0.85)
      tooltipText: (root.favorite ? "Remove " : "Add ") + root.teamLabel() + (root.favorite ? " from favorites" : " to favorites")
      focusable: true
      onClicked: root.toggleFavorite()
      Accessible.name: tooltipText
      Accessible.role: Accessible.CheckBox
      Accessible.checkable: true
      Accessible.checked: root.favorite
      Accessible.onToggleAction: root.toggleFavorite()
    }
  }
  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 1
    color: Commons.Color.popups.text
    opacity: 0.08
  }
}

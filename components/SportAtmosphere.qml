import QtQuick
import QtQuick.Shapes
import qs.Commons
import "../model/Iconography.js" as Iconography

// Quiet, provider-neutral sport geometry for the clipped upper panel. Shapes
// are deliberately generic and theme-tinted so the atmosphere supports the
// destination label without competing with score text or team logos.
Item {
  id: root

  property string leagueId: "following"
  // Kept as an explicit contract for future transitions. U3.4 is static, so
  // reduced motion has no animation to suppress.
  property bool reducedMotion: false

  readonly property string sport: Iconography.sportKind(root.leagueId)
  readonly property color tint: Util.alpha(Color.accent, 0.19)
  readonly property color softTint: Util.alpha(Color.accent, 0.11)
  readonly property color faintTint: Util.alpha(Color.foreground, 0.09)

  clip: true
  opacity: 0.86

  Rectangle {
    anchors.fill: parent
    color: Util.alpha(Color.popups.background, 0.30)
  }

  // Following uses a neutral overlapping-ring mark rather than borrowing a
  // sport's field grammar.
  Rectangle {
    visible: root.sport === "neutral"
    width: Math.max(Style.space(92), parent.height * 1.18)
    height: width
    x: parent.width - width * 0.57
    y: -height * 0.48
    radius: width / 2
    color: "transparent"
    border.width: Math.max(1, Style.space(2))
    border.color: root.softTint
  }

  Rectangle {
    visible: root.sport === "neutral"
    width: Math.max(Style.space(46), parent.height * 0.52)
    height: width
    x: parent.width - width * 1.35
    y: parent.height * 0.37
    radius: width / 2
    color: "transparent"
    border.width: Math.max(1, Style.space(1))
    border.color: root.faintTint
  }

  // Hockey: a rink boundary, center line, and crease.
  Rectangle {
    id: hockeyRink
    visible: root.sport === "hockey"
    width: Math.min(parent.width * 0.48, Style.space(190))
    height: Math.min(parent.height * 0.62, Style.space(82))
    x: parent.width - width - Style.spacing.lg
    y: parent.height * 0.18
    radius: height / 2
    color: "transparent"
    border.width: Math.max(1, Style.space(2))
    border.color: root.tint

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      x: parent.width * 0.50
      width: Math.max(1, Style.space(2))
      height: parent.height * 0.78
      color: root.softTint
    }

    Rectangle {
      anchors.right: parent.right
      anchors.rightMargin: parent.width * 0.06
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width * 0.19
      height: parent.height * 0.38
      radius: height / 2
      color: "transparent"
      border.width: Math.max(1, Style.space(2))
      border.color: root.tint
    }
  }

  // Baseball: diamond plus a light seam arc.
  Rectangle {
    id: baseballDiamond
    visible: root.sport === "baseball"
    width: Math.min(parent.height * 0.74, Style.space(92))
    height: width
    x: parent.width - width * 1.02
    y: parent.height * 0.20
    rotation: 45
    color: "transparent"
    border.width: Math.max(1, Style.space(2))
    border.color: root.tint
  }

  Shape {
    visible: root.sport === "baseball"
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: "transparent"
      strokeColor: root.softTint
      strokeWidth: Math.max(1, Style.space(2))

      PathMove { x: root.width * 0.79; y: root.height * 0.18 }
      PathArc {
        x: root.width * 0.93
        y: root.height * 0.70
        radiusX: Math.max(Style.space(20), root.width * 0.12)
        radiusY: Math.max(Style.space(20), root.height * 0.40)
        direction: PathArc.Clockwise
      }
    }
  }

  // Football: a field slice with yard lines and a goal line.
  Rectangle {
    id: footballField
    visible: root.sport === "football"
    width: Math.min(parent.width * 0.54, Style.space(210))
    height: Math.min(parent.height * 0.60, Style.space(78))
    x: parent.width - width - Style.spacing.lg
    y: parent.height * 0.20
    color: "transparent"
    border.width: Math.max(1, Style.space(2))
    border.color: root.tint

    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      width: Math.max(1, Style.space(2))
      height: parent.height
      color: root.softTint
    }

    Rectangle {
      anchors.right: parent.right
      anchors.top: parent.top
      width: Math.max(1, Style.space(2))
      height: parent.height
      color: root.softTint
    }

    Row {
      anchors.fill: parent
      anchors.leftMargin: parent.width * 0.18
      anchors.rightMargin: parent.width * 0.18
      spacing: parent.width * 0.12

      Repeater {
        model: 4
        delegate: Rectangle {
          width: Math.max(1, Style.space(2))
          height: parent.height * 0.72
          anchors.verticalCenter: parent.verticalCenter
          color: root.softTint
        }
      }
    }
  }

  // Basketball: key and three-point arc.
  Rectangle {
    id: basketballKey
    visible: root.sport === "basketball"
    width: Math.min(parent.width * 0.32, Style.space(112))
    height: Math.min(parent.height * 0.65, Style.space(86))
    x: parent.width - width - Style.spacing.lg
    y: parent.height * 0.16
    color: "transparent"
    border.width: Math.max(1, Style.space(2))
    border.color: root.tint
  }

  Shape {
    visible: root.sport === "basketball"
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: "transparent"
      strokeColor: root.tint
      strokeWidth: Math.max(1, Style.space(2))

      PathMove { x: root.width * 0.62; y: root.height * 0.10 }
      PathArc {
        x: root.width * 0.98
        y: root.height * 0.90
        radiusX: Math.max(Style.space(28), root.width * 0.27)
        radiusY: Math.max(Style.space(28), root.height * 0.60)
        direction: PathArc.Clockwise
      }
    }
  }

  // Soccer: center circle, halfway line, and a penalty-box cue.
  Rectangle {
    id: soccerField
    visible: root.sport === "soccerField"
    width: Math.min(parent.width * 0.52, Style.space(205))
    height: Math.min(parent.height * 0.60, Style.space(78))
    x: parent.width - width - Style.spacing.lg
    y: parent.height * 0.20
    color: "transparent"
    border.width: Math.max(1, Style.space(2))
    border.color: root.tint

    Rectangle {
      anchors.centerIn: parent
      width: Math.min(parent.height * 0.44, Style.space(42))
      height: width
      radius: width / 2
      color: "transparent"
      border.width: Math.max(1, Style.space(2))
      border.color: root.softTint
    }

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      x: parent.width * 0.50
      width: Math.max(1, Style.space(1))
      height: parent.height
      color: root.softTint
    }

    Rectangle {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width * 0.18
      height: parent.height * 0.48
      color: "transparent"
      border.width: Math.max(1, Style.space(2))
      border.color: root.softTint
    }
  }

  SemanticIcon {
    anchors.right: parent.right
    anchors.rightMargin: Style.spacing.lg
    anchors.verticalCenter: parent.verticalCenter
    iconName: Iconography.iconNameForLeague(root.leagueId)
    fontSize: Style.font.display
    color: root.tint
    opacity: 0.72
    decorative: true
  }
}

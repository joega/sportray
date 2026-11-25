import QtQuick
import qs.Commons as Commons
import "../model/UiContrast.js" as Contrast

// Shared presentation values follow the active shell palette and text scale.
QtObject {
  readonly property color ink: Commons.Color.popups.text
  readonly property color canvas: Commons.Color.popups.background
  readonly property color muted: Contrast.foreground(Qt.alpha(ink, 0.68), ink, canvas)
  readonly property color surface: Qt.tint(canvas, Qt.alpha(ink, 0.035))
  readonly property color feature: Qt.tint(canvas, Qt.alpha(Commons.Color.accent, 0.055))
  readonly property color line: Qt.alpha(ink, 0.09)
  readonly property color accent: Contrast.foreground(Contrast.luminance(canvas) > 0.5
    ? Qt.darker(Commons.Color.accent, 1.15) : Commons.Color.accent, ink, canvas)
  readonly property int radius: Commons.Style.cornerRadius > 0 ? Commons.Style.space(13) : 0
  readonly property int featureRadius: Commons.Style.cornerRadius > 0 ? Commons.Style.space(15) : 0
  readonly property int title: Commons.Style.fontPx(2.0)
  readonly property int section: Commons.Style.fontPx(1.25)
  readonly property int body: Commons.Style.fontPx(1.083)
}

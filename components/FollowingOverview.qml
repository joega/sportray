import QtQuick
import qs.Commons as Commons
import qs.Ui
import "../model/UiTypography.js" as Typography

Item {
  id: root
  property var projection: ({counts: {}, summary: "Your followed games", filterId: "all"})
  readonly property bool popupOpen: picker.popupOpen
  signal filterSelected(string filterId)
  implicitHeight: picker.implicitHeight
  Dropdown {
    id: picker
    width: parent.width
    label: "Filter games"
    showLabel: false
    fontFamily: Typography.family
    value: root.projection.filterId || "all"
    options: [{value: "all", label: "All " + Number(root.projection.counts.all || 0)},
      {value: "live", label: "Live " + Number(root.projection.counts.live || 0)},
      {value: "favorites", label: "Favorites " + Number(root.projection.counts.favorites || 0)}]
    onChanged: function(value) { root.filterSelected(value) }
    Accessible.name: "Filter Following games. " + root.projection.summary + ". F cycles filters."
    Accessible.role: Accessible.ComboBox
  }
}

import QtQuick
import Logos.Theme

// Reusable ring widget — Rectangle + ArcGauge + content overlay.
//
// Usage:
//   ArcWidget {
//       fraction:  0.65
//       fillColor: Theme.palette.success
//
//       ColumnLayout { anchors.centerIn: parent; ... }
//   }
//
// Children are placed inside an overlay Item that fills the widget,
// so anchors such as `anchors.centerIn: parent` work as expected.
Rectangle {
    id: root

    width: 140
    height: 140
    radius: 14
    color: Theme.palette.backgroundSecondary
    border.color: Theme.palette.borderSecondary
    border.width: 1

    // ── Arc properties ────────────────────────────────────────────────────────
    property real  fraction:   0.0
    property color fillColor:  Theme.palette.text
    property color trackColor: Theme.palette.textMuted

    // ── Content slot ──────────────────────────────────────────────────────────
    // Children declared inside ArcWidget { … } land here, on top of the arc.
    default property alias content: overlay.data

    ArcGauge {
        anchors.fill: parent
        fraction:   root.fraction
        trackColor: root.trackColor
        fillColor:  root.fillColor
    }

    Item {
        id: overlay
        anchors.fill: parent
    }
}

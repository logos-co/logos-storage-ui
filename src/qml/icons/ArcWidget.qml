import QtQuick
import Logos.Theme

// Reusable ring widget — Rectangle + arc canvas + content overlay.
// Usage:
//   ArcWidget {
//       fraction:  0.65
//       fillColor: Theme.palette.success
//       ColumnLayout { anchors.centerIn: parent; ... }
//   }
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

    property real fraction: 0.0
    property color fillColor: Theme.palette.text
    property color trackColor: Theme.palette.textMuted
    property real arcRadius: 46
    property real arcWidth: 8

    onFractionChanged: arc.requestPaint()
    onFillColorChanged: arc.requestPaint()
    onTrackColorChanged: arc.requestPaint()

    default property alias content: overlay.data

    Canvas {
        id: arc
        anchors.fill: parent

        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var cx = width / 2
            var cy = height / 2
            var startRad = 130 * Math.PI / 180
            var totalRad = 280 * Math.PI / 180

            // Track (full arc, muted)
            ctx.beginPath()
            ctx.arc(cx, cy, root.arcRadius, startRad, startRad + totalRad)
            ctx.strokeStyle = root.trackColor.toString()
            ctx.lineWidth = root.arcWidth
            ctx.lineCap = "round"
            ctx.stroke()

            // Fill (proportional)
            var f = Math.min(Math.max(root.fraction, 0.0), 1.0)
            if (f > 0) {
                ctx.beginPath()
                ctx.arc(cx, cy, root.arcRadius, startRad,
                        startRad + totalRad * f)
                ctx.strokeStyle = root.fillColor.toString()
                ctx.lineWidth = root.arcWidth
                ctx.lineCap = "round"
                ctx.stroke()
            }
        }
    }

    Item {
        id: overlay
        anchors.fill: parent
    }
}

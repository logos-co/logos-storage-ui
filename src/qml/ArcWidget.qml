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

    implicitWidth: 120
    implicitHeight: 120
    color: Theme.palette.backgroundSecondary

    property real fraction: 0.0
    property color fillColor: Theme.palette.text
    property color trackColor: Theme.palette.textMuted
    // arcRadius scales with the widget so enlarging the container also enlarges the arc
    property real arcScale: 1.0
    // arcOffsetY: shifts the arc center downward (px, in Rectangle space).
    // Useful when arcScale > 1 — the canvas overflows upward, this offset re-centers it visually.
    property real arcOffsetY: 0
    // arcRadius and arcWidth are based on the Canvas dimensions (not the Rectangle),
    // so arcScale enlarges them without affecting the layout footprint.
    property real arcRadius: Math.min(arc.width, arc.height) * 0.43
    property real arcWidth: 8

    onFractionChanged: arc.requestPaint()
    onFillColorChanged: arc.requestPaint()
    onTrackColorChanged: arc.requestPaint()
    onWidthChanged: arc.requestPaint()
    onHeightChanged: arc.requestPaint()
    onArcOffsetYChanged: arc.requestPaint()

    default property alias content: overlay.data

    Canvas {
        id: arc
        width: parent.width * root.arcScale
        height: parent.height * root.arcScale
        anchors.centerIn: parent

        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var cx = width / 2
            // arcOffsetY is in Rectangle px — same scale as Canvas, just an offset
            var cy = height / 2 + root.arcOffsetY
            var totalDeg = 180
            var startDeg = 270 - totalDeg / 2   // centered around the top (270°)
            var numSeg = 5
            var gapDeg = 4
            var segDeg = (totalDeg - gapDeg * (numSeg - 1)) / numSeg

            // Stroke widths: biggest at the base (index 0), smallest at tip — scale with arcWidth
            var s = root.arcWidth / 8
            var widths = [22 * s, 15 * s, 10 * s, 6 * s, 3 * s]
            // Segments fade toward the tip — depth cue from the design
            var alphas = [1.0, 0.9, 0.7, 0.6, 0.4]

            var f = Math.min(Math.max(root.fraction, 0.0), 1.0)

            for (var i = 0; i < numSeg; i++) {
                var sDeg = startDeg + i * (segDeg + gapDeg)
                // Fraction of this segment filled — the fill boundary lands mid-segment
                var localFill = Math.min(Math.max(f * numSeg - i, 0.0), 1.0)
                var midDeg = sDeg + localFill * segDeg

                ctx.lineWidth = widths[i]
                ctx.lineCap = "butt"
                ctx.globalAlpha = alphas[i]

                if (localFill > 0) {
                    ctx.beginPath()
                    ctx.arc(cx, cy, root.arcRadius, sDeg * Math.PI / 180,
                            midDeg * Math.PI / 180)
                    ctx.strokeStyle = root.fillColor.toString()
                    ctx.stroke()
                }
                if (localFill < 1) {
                    ctx.beginPath()
                    ctx.arc(cx, cy, root.arcRadius, midDeg * Math.PI / 180,
                            (sDeg + segDeg) * Math.PI / 180)
                    ctx.strokeStyle = root.trackColor.toString()
                    ctx.stroke()
                }
            }
            ctx.globalAlpha = 1
        }
    }

    Item {
        id: overlay
        anchors.fill: parent
    }
}

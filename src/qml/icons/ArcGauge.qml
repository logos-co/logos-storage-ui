import QtQuick
import Logos.Theme

// Reusable arc gauge — same visual style as the Nothing OS ring widgets.
//
// Usage:
//   ArcGauge {
//       anchors.fill: parent
//       fraction:   0.65
//       fillColor:  Theme.palette.success
//   }
Canvas {
    id: root

    // 0.0 – 1.0  (clamped internally)
    property real  fraction:   0.0
    property color trackColor: Theme.palette.textMuted
    property color fillColor:  Theme.palette.text
    property real  arcRadius:  46
    property real  arcWidth:   8

    onFractionChanged:   requestPaint()
    onTrackColorChanged: requestPaint()
    onFillColorChanged:  requestPaint()

    Component.onCompleted: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()

        var cx         = width  / 2
        var cy         = height / 2
        var startDeg   = 130
        var totalDeg   = 280
        var numSeg     = 4
        var gapDeg     = 4
        var segDeg     = (totalDeg - gapDeg * (numSeg - 1)) / numSeg  // 67°

        // Stroke widths: biggest at the base (index 0), smallest at tip
        var widths     = [13, 9, 6, 4]

        var f          = Math.min(Math.max(root.fraction, 0.0), 1.0)
        var litCount   = Math.min(Math.round(f * numSeg), numSeg)

        for (var i = 0; i < numSeg; i++) {
            var sDeg = startDeg + i * (segDeg + gapDeg)
            var sRad = sDeg * Math.PI / 180
            var eRad = (sDeg + segDeg) * Math.PI / 180

            ctx.beginPath()
            ctx.arc(cx, cy, root.arcRadius, sRad, eRad)
            ctx.strokeStyle = (i < litCount)
                              ? root.fillColor.toString()
                              : root.trackColor.toString()
            ctx.lineWidth   = widths[i]
            ctx.lineCap     = "butt"
            ctx.stroke()
        }
    }
}

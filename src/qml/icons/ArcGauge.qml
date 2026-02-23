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

        var cx       = width  / 2
        var cy       = height / 2
        var startRad = 130 * Math.PI / 180
        var totalRad = 280 * Math.PI / 180

        // ── Track (full arc, muted) ───────────────────────────────────────────
        ctx.beginPath()
        ctx.arc(cx, cy, root.arcRadius, startRad, startRad + totalRad)
        ctx.strokeStyle = root.trackColor.toString()
        ctx.lineWidth   = root.arcWidth
        ctx.lineCap     = "round"
        ctx.stroke()

        // ── Fill (proportional) ───────────────────────────────────────────────
        var f = Math.min(Math.max(root.fraction, 0.0), 1.0)
        if (f > 0) {
            ctx.beginPath()
            ctx.arc(cx, cy, root.arcRadius, startRad, startRad + totalRad * f)
            ctx.strokeStyle = root.fillColor.toString()
            ctx.lineWidth   = root.arcWidth
            ctx.lineCap     = "round"
            ctx.stroke()
        }
    }
}

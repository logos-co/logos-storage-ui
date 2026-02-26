import QtQuick
import Logos.Theme

// ECG-style I/O activity monitor.
// Feed it with addActivity(bytes) from upload/download events.
// The line spikes proportionally to I/O throughput and decays back to baseline.
Item {
    id: root

    implicitWidth: 200
    implicitHeight: 80

    // ── Public properties ─────────────────────────────────────────────────────
    property color lineColor: Theme.palette.primary

    // Number of time-buckets visible on screen (1 bucket = 500 ms)
    property int maxHistory: 80

    // ── Public API ────────────────────────────────────────────────────────────
    // Call this whenever bytes are transferred (download or upload)
    function addActivity(bytes) {
        _activityAccum += bytes
    }

    // ── Internal state ────────────────────────────────────────────────────────
    property real _activityAccum: 0
    property var  _history:       []
    // Auto-scaling ceiling (grows instantly, decays slowly); never below 1 KB
    property real _maxObserved:   1024

    // ── Sample timer ──────────────────────────────────────────────────────────
    Timer {
        interval: 500
        running:  true
        repeat:   true

        onTriggered: {
            var val = root._activityAccum
            root._activityAccum = 0

            // Auto-scale: instant growth, slow exponential decay
            if (val > root._maxObserved) {
                root._maxObserved = val
            } else {
                root._maxObserved = Math.max(1024, root._maxObserved * 0.995)
            }

            var normalized = root._maxObserved > 0 ? val / root._maxObserved : 0

            var h = root._history.slice()
            h.push(normalized)
            if (h.length > root.maxHistory) h.shift()
            root._history = h

            canvas.requestPaint()
        }
    }

    // ── Canvas ────────────────────────────────────────────────────────────────
    Canvas {
        id: canvas
        anchors.fill: parent

        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx     = getContext("2d")
            ctx.reset()

            var w        = width
            var h        = height
            var history  = root._history
            var n        = history.length
            var dx       = w / (root.maxHistory - 1)
            var baseY    = h - 2          // bottom baseline (2 px margin)
            var amplitude = h - 8         // total vertical travel

            // ── Subtle horizontal grid ────────────────────────────────────────
            ctx.setLineDash([2, 5])
            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.07).toString()
            ctx.lineWidth = 1
            for (var g = 1; g <= 3; g++) {
                ctx.beginPath()
                ctx.moveTo(0,  h * g / 4)
                ctx.lineTo(w,  h * g / 4)
                ctx.stroke()
            }
            ctx.setLineDash([])

            if (n < 2) return

            var lc       = root.lineColor
            var startIdx = root.maxHistory - n   // left-align history tail

            // ── Glow passes (widest/faintest → narrowest/brightest) ───────────
            var glows = [
                { lw: 9, a: 0.05 },
                { lw: 5, a: 0.12 },
                { lw: 2, a: 0.24 }
            ]
            for (var p = 0; p < glows.length; p++) {
                ctx.beginPath()
                ctx.lineWidth   = glows[p].lw
                ctx.strokeStyle = Qt.rgba(lc.r, lc.g, lc.b, glows[p].a).toString()
                ctx.lineJoin    = "round"
                ctx.lineCap     = "round"
                for (var i = 0; i < n; i++) {
                    var xi = (startIdx + i) * dx
                    var yi = baseY - history[i] * amplitude
                    i === 0 ? ctx.moveTo(xi, yi) : ctx.lineTo(xi, yi)
                }
                ctx.stroke()
            }

            // ── Main crisp line ───────────────────────────────────────────────
            ctx.beginPath()
            ctx.lineWidth   = 1.5
            ctx.strokeStyle = lc.toString()
            ctx.lineJoin    = "round"
            ctx.lineCap     = "round"
            for (var j = 0; j < n; j++) {
                var xj = (startIdx + j) * dx
                var yj = baseY - history[j] * amplitude
                j === 0 ? ctx.moveTo(xj, yj) : ctx.lineTo(xj, yj)
            }
            ctx.stroke()

            // ── Tip dot (live cursor) ─────────────────────────────────────────
            var tx = (root.maxHistory - 1) * dx
            var ty = baseY - history[n - 1] * amplitude

            // Outer halo
            ctx.beginPath()
            ctx.arc(tx, ty, 5.5, 0, Math.PI * 2)
            ctx.fillStyle = Qt.rgba(lc.r, lc.g, lc.b, 0.22).toString()
            ctx.fill()

            // Solid dot
            ctx.beginPath()
            ctx.arc(tx, ty, 2.5, 0, Math.PI * 2)
            ctx.fillStyle = lc.toString()
            ctx.fill()
        }
    }
}

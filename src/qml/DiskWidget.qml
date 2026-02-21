import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

Rectangle {
    id: root

    width: 140; height: 140
    radius: 14
    color: Theme.palette.backgroundSecondary
    border.color: Theme.palette.borderSecondary
    border.width: 1

    property real total: 0
    property real used: 0

    function formatBytes(bytes) {
        if (bytes <= 0) return "0 B"
        if (bytes < 1024) return bytes + " B"
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB"
        if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + " MB"
        return (bytes / (1024 * 1024 * 1024)).toFixed(2) + " GB"
    }

    onTotalChanged: arc.requestPaint()
    onUsedChanged:  arc.requestPaint()

    Canvas {
        id: arc
        anchors.fill: parent

        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var cx = width  / 2
            var cy = height / 2
            var r  = 46
            var lw = 8
            var startRad = 130 * Math.PI / 180
            var totalRad = 280 * Math.PI / 180

            // ── Background track (available / grey) ───────────────────────────
            ctx.beginPath()
            ctx.arc(cx, cy, r, startRad, startRad + totalRad)
            ctx.strokeStyle = Theme.palette.textMuted.toString()
            ctx.lineWidth   = lw
            ctx.lineCap     = "round"
            ctx.stroke()

            // ── Fill (used / white) ───────────────────────────────────────────
            if (root.total > 0) {
                var fraction = Math.min(root.used / root.total, 1.0)
                if (fraction > 0) {
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, startRad, startRad + totalRad * fraction)
                    ctx.strokeStyle = Theme.palette.text.toString()
                    ctx.lineWidth   = lw
                    ctx.lineCap     = "round"
                    ctx.stroke()
                }
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 2

        LogosText {
            text: root.total > 0 ? root.formatBytes(root.used) : "—"
            font.pixelSize: 15
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        LogosText {
            text: "STORAGE"
            font.pixelSize: 9
            color: Theme.palette.textTertiary
            font.letterSpacing: 1.3
            Layout.alignment: Qt.AlignHCenter
        }
    }
}

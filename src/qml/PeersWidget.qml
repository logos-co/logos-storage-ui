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

    property int peerCount: 0
    // Soft ceiling: arc is full at maxPeers connected peers
    property int maxPeers: 20

    onPeerCountChanged: arc.requestPaint()

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

            // ── Background track ──────────────────────────────────────────────
            ctx.beginPath()
            ctx.arc(cx, cy, r, startRad, startRad + totalRad)
            ctx.strokeStyle = Theme.palette.textMuted.toString()
            ctx.lineWidth   = lw
            ctx.lineCap     = "round"
            ctx.stroke()

            // ── Fill (peers / white) ───────────────────────────────────────────
            var fraction = root.maxPeers > 0
                ? Math.min(root.peerCount / root.maxPeers, 1.0) : 0
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

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 2

        LogosText {
            text: root.peerCount
            font.pixelSize: 22
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        LogosText {
            text: "PEERS"
            font.pixelSize: 9
            color: Theme.palette.textTertiary
            font.letterSpacing: 1.3
            Layout.alignment: Qt.AlignHCenter
        }
    }
}

import QtQuick
import Logos.Theme
import Logos.Controls

// Privacy-safe peer view: your node at the center, peers scattered around it.
// Each peer's angle and distance come from a hash of its peerId — stable and
// deterministic, but carrying no geographic meaning. Connected peers are lit,
// glow, and link to the center; known peers are dim and unlinked. A subtle
// mouse parallax and a drifting starfield give it an outer-space feel.
Item {
    id: root

    // [{ peerId: string, seen: bool }]
    property var peers: []

    // Laid-out points from the last paint, for hover hit-testing and the
    // table highlight: [{ x, y, seen, peerId }]. Same order as `peers`, so the
    // index maps 1:1 onto the table row index.
    property var layoutPoints: []
    property int hoveredIndex: -1

    // Emitted when a peer dot is clicked; index maps onto the table row.
    signal peerClicked(int index)

    property color nodeColor: Theme.palette.primary
    property color connectedColor: Theme.palette.primary
    property color knownColor: Theme.palette.textMuted
    property color starColor: Theme.palette.text

    // Looping phase for the pulsing glow / twinkle.
    property real phase: 0
    // Cursor offset from center, normalized to [-1, 1], drives the parallax.
    property real mx: 0
    property real my: 0
    // Shooting-star progress: < 0 idle, else 0..1.
    property real shootT: -1
    property real shootY0: 0

    onPeersChanged: canvas.requestPaint()
    onHoveredIndexChanged: canvas.requestPaint()
    onPhaseChanged: canvas.requestPaint()
    onMxChanged: canvas.requestPaint()
    onMyChanged: canvas.requestPaint()
    onShootTChanged: canvas.requestPaint()

    // Spring follow: reactive to fast moves, still smooth. Higher spring =
    // snappier, higher damping = less overshoot.
    Behavior on mx { SpringAnimation { spring: 3.0; damping: 0.32; epsilon: 0.001 } }
    Behavior on my { SpringAnimation { spring: 3.0; damping: 0.32; epsilon: 0.001 } }

    function hashCode(s) {
        var h = 5381
        for (var i = 0; i < s.length; i++)
            h = ((h << 5) + h + s.charCodeAt(i)) | 0
        return Math.abs(h)
    }

    // Deterministic [0,1) noise so the starfield stays put across repaints.
    function pseudo(seed) {
        var x = Math.sin(seed) * 43758.5453
        return x - Math.floor(x)
    }

    // Continuous pulse, only while the page is on screen.
    NumberAnimation on phase {
        from: 0
        to: 2 * Math.PI
        duration: 3200
        loops: Animation.Infinite
        running: root.visible
    }

    // Occasional shooting star.
    Timer {
        interval: 6500
        running: root.visible
        repeat: true
        onTriggered: {
            root.shootY0 = Math.random() * root.height * 0.55
            shootAnim.restart()
        }
    }
    NumberAnimation {
        id: shootAnim
        target: root
        property: "shootT"
        from: 0
        to: 1
        duration: 850
        easing.type: Easing.InQuad
        onFinished: root.shootT = -1
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var W = width
            var H = height
            var cx = W / 2
            var cy = H / 2

            // Per-layer parallax (px): far = small shift, near = larger. Layers
            // track the cursor (move with it); near layers shift most.
            var starDX = root.mx * 7, starDY = root.my * 5
            var peerDX = root.mx * 20, peerDY = root.my * 15
            var coreDX = root.mx * 28, coreDY = root.my * 20

            // ── Starfield (spawned slightly past the edges so parallax leaves
            //    no gap), with a gentle per-star twinkle.
            var starCount = Math.round(W * H / 2200)
            ctx.fillStyle = root.starColor.toString()
            for (var s = 0; s < starCount; s++) {
                var stx = root.pseudo(s * 1.13 + 0.7) * (W + 16) - 8 + starDX
                var sty = root.pseudo(s * 2.71 + 3.3) * (H + 16) - 8 + starDY
                var str = 0.6 + root.pseudo(s * 0.37 + 1.9) * 1.1
                var tw = 0.6 + 0.4 * Math.sin(root.phase * 1.3 + s)
                ctx.globalAlpha = (0.1 + root.pseudo(s * 4.17 + 5.5) * 0.35) * tw
                ctx.beginPath()
                ctx.arc(stx, sty, str, 0, 2 * Math.PI)
                ctx.fill()
            }
            ctx.globalAlpha = 1

            // ── Shooting star
            if (root.shootT >= 0) {
                var sLen = W * 0.95
                var dirx = 0.866, diry = 0.5
                var sx0 = -W * 0.1 + coreDX
                var sy0 = root.shootY0 + coreDY
                var hx = sx0 + root.shootT * sLen * dirx
                var hy = sy0 + root.shootT * sLen * diry
                var tailLen = 100
                var tx = hx - tailLen * dirx
                var ty = hy - tailLen * diry
                var grad = ctx.createLinearGradient(tx, ty, hx, hy)
                grad.addColorStop(0, "transparent")
                grad.addColorStop(1, root.starColor.toString())
                var fade = root.shootT < 0.15 ? root.shootT / 0.15
                         : (root.shootT > 0.85 ? (1 - root.shootT) / 0.15 : 1)
                ctx.globalAlpha = fade
                ctx.strokeStyle = grad
                ctx.lineWidth = 2
                ctx.beginPath()
                ctx.moveTo(tx, ty)
                ctx.lineTo(hx, hy)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(hx, hy, 1.6, 0, 2 * Math.PI)
                ctx.fillStyle = root.starColor.toString()
                ctx.fill()
                ctx.globalAlpha = 1
            }

            // ── Peer layout (elliptical spread, fills a wide short panel)
            var maxRx = W / 2 - 24
            var maxRy = H / 2 - 16
            var minF = 0.28
            var pts = []
            for (var i = 0; i < root.peers.length; i++) {
                var p = root.peers[i]
                var h = root.hashCode(p.peerId || ("peer" + i))
                var ang = (h % 3600) / 3600 * 2 * Math.PI
                var f = minF + (1 - minF) * ((Math.floor(h / 3600) % 1000) / 1000)
                var ph = (h % 100) / 100 * 2 * Math.PI
                // Gentle seamless drift: integer multiples of the looping phase
                // (a tiny Lissajous orbit, phase-offset per node) so it never
                // jumps when the phase wraps.
                var driftX = 3.0 * Math.cos(root.phase + ph)
                var driftY = 2.2 * Math.sin(root.phase * 2 + ph)
                pts.push({
                    "x": cx + f * maxRx * Math.cos(ang) + peerDX + driftX,
                    "y": cy + f * maxRy * Math.sin(ang) + peerDY + driftY,
                    "seen": p.seen === true,
                    "peerId": p.peerId || "",
                    "ph": ph
                })
            }
            root.layoutPoints = pts

            var ccx = cx + coreDX
            var ccy = cy + coreDY

            // ── Dynamic glow around connected nodes (pulsing, out of phase)
            for (i = 0; i < pts.length; i++) {
                if (!pts[i].seen)
                    continue
                var pulse = 0.5 + 0.5 * Math.sin(root.phase + pts[i].ph)
                var gR = 9 + pulse * 11
                var g = ctx.createRadialGradient(pts[i].x, pts[i].y, 0,
                                                 pts[i].x, pts[i].y, gR)
                g.addColorStop(0, root.connectedColor.toString())
                g.addColorStop(1, "transparent")
                ctx.globalAlpha = 0.18 + pulse * 0.32
                ctx.fillStyle = g
                ctx.beginPath()
                ctx.arc(pts[i].x, pts[i].y, gR, 0, 2 * Math.PI)
                ctx.fill()
            }
            ctx.globalAlpha = 1

            // ── Links to connected peers
            ctx.lineWidth = 1
            ctx.strokeStyle = root.connectedColor.toString()
            for (i = 0; i < pts.length; i++) {
                if (!pts[i].seen)
                    continue
                ctx.globalAlpha = 0.22
                ctx.beginPath()
                ctx.moveTo(ccx, ccy)
                ctx.lineTo(pts[i].x, pts[i].y)
                ctx.stroke()
            }
            ctx.globalAlpha = 1

            // ── Peer dots
            for (i = 0; i < pts.length; i++) {
                ctx.beginPath()
                ctx.arc(pts[i].x, pts[i].y, pts[i].seen ? 4 : 3, 0, 2 * Math.PI)
                ctx.fillStyle = (pts[i].seen ? root.connectedColor : root.knownColor).toString()
                ctx.globalAlpha = pts[i].seen ? 1.0 : 0.45
                ctx.fill()
            }
            ctx.globalAlpha = 1

            // ── Hover highlight ring
            if (root.hoveredIndex >= 0 && root.hoveredIndex < pts.length) {
                var hp = pts[root.hoveredIndex]
                ctx.strokeStyle = root.starColor.toString()
                ctx.globalAlpha = 0.9
                ctx.lineWidth = 1.5
                ctx.beginPath()
                ctx.arc(hp.x, hp.y, 8.5, 0, 2 * Math.PI)
                ctx.stroke()
                ctx.globalAlpha = 1
            }

            // ── Center = your node (halo breathes with the phase)
            var cpulse = 0.5 + 0.5 * Math.sin(root.phase)
            ctx.beginPath()
            ctx.arc(ccx, ccy, 14 + cpulse * 3, 0, 2 * Math.PI)
            ctx.strokeStyle = root.nodeColor.toString()
            ctx.globalAlpha = 0.3
            ctx.lineWidth = 2
            ctx.stroke()
            ctx.globalAlpha = 1
            ctx.beginPath()
            ctx.arc(ccx, ccy, 7, 0, 2 * Math.PI)
            ctx.fillStyle = root.nodeColor.toString()
            ctx.fill()
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: root.hoveredIndex >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: {
            if (root.hoveredIndex >= 0)
                root.peerClicked(root.hoveredIndex)
        }

        onPositionChanged: {
            root.mx = Math.max(-1, Math.min(1, (mouseX - width / 2) / (width / 2)))
            root.my = Math.max(-1, Math.min(1, (mouseY - height / 2) / (height / 2)))

            var best = -1
            var bestD = 144 // within a ~12px radius
            for (var i = 0; i < root.layoutPoints.length; i++) {
                var dx = mouseX - root.layoutPoints[i].x
                var dy = mouseY - root.layoutPoints[i].y
                var d = dx * dx + dy * dy
                if (d < bestD) {
                    bestD = d
                    best = i
                }
            }
            root.hoveredIndex = best
        }
        onExited: {
            root.hoveredIndex = -1
            root.mx = 0
            root.my = 0
        }
    }

    Rectangle {
        id: tip
        readonly property var pt: (root.hoveredIndex >= 0
                                   && root.hoveredIndex < root.layoutPoints.length)
                                  ? root.layoutPoints[root.hoveredIndex] : null
        visible: tip.pt !== null
        z: 10
        color: Theme.palette.backgroundBlack
        border.width: 1
        border.color: Theme.palette.border
        radius: Theme.spacing.radiusSmall
        implicitWidth: tipText.width + Theme.spacing.small * 2
        implicitHeight: tipText.implicitHeight + Theme.spacing.tiny * 2
        x: tip.pt ? Math.min(Math.max(tip.pt.x + 10, 0), root.width - width) : 0
        y: tip.pt ? Math.max(tip.pt.y - height - 8, 0) : 0

        LogosText {
            id: tipText
            anchors.centerIn: parent
            width: Math.min(implicitWidth, 300)
            text: tip.pt ? tip.pt.peerId : ""
            elide: Text.ElideMiddle
            font.pixelSize: Theme.typography.secondaryText
            font.family: "monospace"
            color: Theme.palette.text
        }
    }
}

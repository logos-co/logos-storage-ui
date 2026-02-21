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

    property int    uploadProgress: 0       // 0‒100
    property string uploadCid: ""
    property bool   running: false

    // States
    readonly property bool isUploading: uploadProgress > 0 && uploadProgress < 100
    readonly property bool isDone:      uploadCid.length > 0

    signal uploadRequested

    onUploadProgressChanged: arc.requestPaint()
    onUploadCidChanged:      arc.requestPaint()

    // ── Arc ───────────────────────────────────────────────────────────────────
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

            // Background track
            ctx.beginPath()
            ctx.arc(cx, cy, r, startRad, startRad + totalRad)
            ctx.strokeStyle = Theme.palette.textMuted.toString()
            ctx.lineWidth   = lw
            ctx.lineCap     = "round"
            ctx.stroke()

            // Fill
            var fraction = root.isDone ? 1.0 : root.uploadProgress / 100.0
            if (fraction > 0) {
                ctx.beginPath()
                ctx.arc(cx, cy, r, startRad, startRad + totalRad * fraction)
                ctx.strokeStyle = root.isDone
                    ? Theme.palette.success.toString()
                    : Theme.palette.text.toString()
                ctx.lineWidth   = lw
                ctx.lineCap     = "round"
                ctx.stroke()
            }
        }
    }

    // ── Center content ────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 2

        // Idle: dot upload icon
        UploadIcon {
            dotColor: Theme.palette.textSecondary
            dotSize: 4; dotSpacing: 3
            activeOpacity: 0.5
            visible: !root.isUploading && !root.isDone
            Layout.alignment: Qt.AlignHCenter
        }

        // Uploading: percentage
        LogosText {
            text: root.uploadProgress + "%"
            font.pixelSize: 22
            font.bold: true
            visible: root.isUploading
            Layout.alignment: Qt.AlignHCenter
        }

        // Done: abbreviated CID
        LogosText {
            text: root.uploadCid.length > 10
                  ? root.uploadCid.substring(0, 6) + "…" + root.uploadCid.slice(-4)
                  : root.uploadCid
            font.pixelSize: 11
            font.family: "monospace"
            visible: root.isDone && !root.isUploading
            Layout.alignment: Qt.AlignHCenter
        }

        LogosText {
            text: root.isDone ? "TAP TO COPY" : "UPLOAD"
            font.pixelSize: 9
            color: Theme.palette.textTertiary
            font.letterSpacing: 1.2
            Layout.alignment: Qt.AlignHCenter
        }
    }

    // ── "Copied!" toast ───────────────────────────────────────────────────────
    Rectangle {
        id: copiedToast
        anchors.centerIn: parent
        width: 80; height: 26
        radius: 6
        color: Theme.palette.backgroundElevated
        border.color: Theme.palette.success
        border.width: 1
        visible: false

        LogosText {
            anchors.centerIn: parent
            text: "Copied ✓"
            font.pixelSize: 11
            color: Theme.palette.success
        }
    }

    SequentialAnimation {
        id: copiedAnim
        ScriptAction  { script: copiedToast.visible = true  }
        PauseAnimation{ duration: 1400 }
        ScriptAction  { script: copiedToast.visible = false }
    }

    // ── Click handler ─────────────────────────────────────────────────────────
    HoverHandler { id: widgetHover }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: widgetHover.hovered ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: (root.running || root.isDone) ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (root.isDone) {
                Qt.copyToClipboard(root.uploadCid)
                copiedAnim.restart()
            } else if (root.running) {
                root.uploadRequested()
            }
        }
    }
}

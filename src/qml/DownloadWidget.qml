import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls
import "Utils.js" as Utils

// qmllint disable unqualified
LogosFrame {
    id: root
    objectName: "downloadWidget"

    backgroundColor: Theme.palette.backgroundSecondary
    borderColor: "transparent"
    radius: Theme.spacing.radiusLarge

    implicitWidth: 300
    implicitHeight: 180

    property var backend: MockBackend
    property string downloadFilename: ""
    property string downloadCid: ""
    property real totalBytes: 0
    property real downloadedBytes: 0
    property bool downloadInProgress: false

    function startLooking() {
        root.downloadInProgress = true
    }

    readonly property real progress: totalBytes > 0 ? Math.min(
                                                          downloadedBytes / totalBytes,
                                                          1.0) : 0.0
    readonly property bool isDownloading: progress > 0 && progress < 1.0
    readonly property bool isDone: progress >= 1.0

    // ── Grid config ───────────────────────────────────────────────────────────
    readonly property int gridRows: 6
    readonly property int maxCols: 30
    readonly property real blockSize: 12
    readonly property int blockGap: 4

    // Fixed block size; fit as many columns as the width allows, fewer when narrow.
    readonly property int gridCols: Math.max(6, Math.min(maxCols, Math.floor(
        (gridItem.width + blockGap) / (blockSize + blockGap))))
    readonly property int totalBlocks: gridCols * gridRows

    property var filledBlocks: []

    function reset() {
        root.downloadCid = ""
        root.downloadFilename = ""
        root.totalBytes = 0
        root.downloadedBytes = 0
        root.downloadInProgress = false
        root.initBlocks()
    }

    function initBlocks() {
        var arr = []
        for (var i = 0; i < totalBlocks; i++)
            arr.push(false)
        root.filledBlocks = arr
    }

    function applyProgress(p) {
        var target = Math.round(Math.min(Math.max(p, 0.0), 1.0) * totalBlocks)
        var blocks = root.filledBlocks.slice()
        var current = 0
        for (var i = 0; i < blocks.length; i++) {
            if (blocks[i])
                current++
        }
        if (target <= current)
            return
        var empty = []
        for (var j = 0; j < totalBlocks; j++) {
            if (!blocks[j])
                empty.push(j)
        }
        var needed = target - current
        for (var k = 0; k < needed && empty.length > 0; k++) {
            var idx = Math.floor(Math.random() * empty.length)
            blocks[empty[idx]] = true
            empty.splice(idx, 1)
        }
        root.filledBlocks = blocks
    }

    onProgressChanged: applyProgress(progress)
    onTotalBlocksChanged: {
        initBlocks()
        applyProgress(progress)
    }
    Component.onCompleted: initBlocks()

    Connections {
        target: root.backend

        function onDownloadStarted(cid, filename, total) {
            root.downloadCid = cid
            root.downloadFilename = filename
            root.totalBytes = total
            root.downloadedBytes = 0
            root.initBlocks()
        }

        function onDownloadChunk(len) {
            root.downloadedBytes += len
        }

        function onDownloadCompleted(cid) {
            root.downloadedBytes = root.totalBytes
            root.downloadInProgress = false
        }

        function onError(message) {
            root.reset()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            visible: root.isDownloading || root.isDone

            LogosText {
                text: root.downloadFilename
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.textMuted
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Image {
                source: "assets/close-circle.png"
                visible: root.isDone

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.reset()
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        // ── Grid ──────────────────────────────────────────────────────────────
        Item {
            id: gridItem
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter

            readonly property real gridWidth: root.gridCols * root.blockSize + (root.gridCols - 1) * root.blockGap
            readonly property real xOffset: (width - gridWidth) / 2
            implicitHeight: root.gridRows * root.blockSize + (root.gridRows - 1) * root.blockGap

            Repeater {
                model: root.totalBlocks
                Rectangle {
                    x: gridItem.xOffset + (index % root.gridCols) * (root.blockSize + root.blockGap)
                    y: Math.floor(
                           index / root.gridCols) * (root.blockSize + root.blockGap)
                    width: root.blockSize
                    height: root.blockSize
                    radius: Theme.spacing.radiusSmall
                    color: root.filledBlocks[index] ? Theme.palette.primary : Theme.palette.borderInteractive
                    Behavior on color {
                        ColorAnimation {
                            duration: 300
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        // ── Footer: label + progress % ────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            visible: root.isDownloading || root.isDone

            LogosText {
                text: root.isDone ? "Complete" : "Downloading..."
                font.pixelSize: Theme.typography.panelTitleText
                color: Theme.palette.text
            }
            Item {
                Layout.fillWidth: true
            }
            LogosText {
                text: Math.round(root.progress * 100) + "%"
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.textMuted
            }
        }

        // ── BottomTitle — visible when idle ───────────────────────────────────
        BottomTitle {
            Layout.fillWidth: true
            title: root.downloadInProgress ? "Looking for peers..." : "No download in progress"
            visible: !root.isDownloading && !root.isDone
            color: Theme.palette.textSecondary
            hasSeparator: false
        }
    }

    // ── Progress bar — thin, flush with the card's bottom edge ───────────────
    LogosProgressBar {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: -Theme.spacing.medium
        anchors.rightMargin: -Theme.spacing.medium
        anchors.bottomMargin: -Theme.spacing.medium
        height: 2
        value: root.progress
    }
}

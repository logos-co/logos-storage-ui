import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls
import "Utils.js" as Utils

// qmllint disable unqualified
Card {
    id: root

    implicitWidth: 300
    implicitHeight: 180
    padding: 0

    property var backend: MockBackend
    property string downloadFilename: ""
    property string downloadCid: ""
    property real totalBytes: 0
    property real downloadedBytes: 0

    readonly property real progress: totalBytes > 0 ? Math.min(
                                                          downloadedBytes / totalBytes,
                                                          1.0) : 0.0
    readonly property bool isDownloading: progress > 0 && progress < 1.0
    readonly property bool isDone: progress >= 1.0

    // ── Grid config ───────────────────────────────────────────────────────────
    readonly property int gridCols: 20
    readonly property int gridRows: 5
    readonly property int totalBlocks: gridCols * gridRows
    readonly property int blockGap: 2

    property var filledBlocks: []

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

        function onDownloadChunk(bytes) {
            root.downloadedBytes += bytes
        }

        function onDownloadCompleted(cid) {
            root.downloadedBytes = root.totalBytes
        }
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacing.medium
            Layout.leftMargin: Theme.spacing.medium
            Layout.rightMargin: Theme.spacing.medium
            spacing: Theme.spacing.small

            LogosText {
                text: Math.round(root.progress * 100) + "%"
                font.pixelSize: Theme.typography.secondaryText
                color: root.isDone ? Theme.palette.success : Theme.palette.textMuted
                visible: root.isDownloading || root.isDone
            }
        }
        Item {
            Layout.fillHeight: true
        }

        Item {
            id: gridItem
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacing.medium
            Layout.rightMargin: Theme.spacing.medium

            readonly property real blockSize: width > 0 ? (width - (root.gridCols - 1)
                                                           * root.blockGap) / root.gridCols : 8
            implicitHeight: root.gridRows * blockSize + (root.gridRows - 1) * root.blockGap

            Repeater {
                model: root.totalBlocks

                Rectangle {
                    x: (index % root.gridCols) * (gridItem.blockSize + root.blockGap)
                    y: Math.floor(
                           index / root.gridCols) * (gridItem.blockSize + root.blockGap)
                    width: gridItem.blockSize
                    height: gridItem.blockSize
                    radius: 2
                    color: root.filledBlocks[index] ? Theme.palette.primary : Theme.palette.backgroundElevated

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

        // Footer row
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacing.medium
            Layout.rightMargin: Theme.spacing.medium
            Layout.bottomMargin: Theme.spacing.small

            LogosText {
                text: root.isDone ? "Complete" : root.isDownloading ? "Downloading..." : "Download"
                font.pixelSize: Theme.typography.titleText * 0.8
                color: Theme.palette.text
            }

            Item {
                Layout.fillWidth: true
            }

            LogosText {
                text: Utils.formatBytes(
                          root.downloadedBytes) + " / " + Utils.formatBytes(
                          root.totalBytes)
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.textMuted
                visible: root.isDownloading || root.isDone
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.palette.borderSecondary
        }

        // Progress bar — flush to card bottom, clipped by card radius
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            color: Theme.palette.backgroundElevated

            Rectangle {
                width: parent.width * root.progress
                height: parent.height
                color: root.isDone ? Theme.palette.success : Theme.palette.primary

                Behavior on width {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: 400
                    }
                }
            }
        }
    }
}

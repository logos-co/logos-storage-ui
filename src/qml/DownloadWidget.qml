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
    readonly property int gridCols: 28
    readonly property int gridRows: 6
    readonly property int totalBlocks: gridCols * gridRows
    readonly property int blockGap: 2

    property var filledBlocks: []

    function reset() {
        root.downloadCid = ""
        root.downloadFilename = ""
        root.totalBytes = 0
        root.downloadedBytes = 0
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
        }
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Header : filename + close (visible quand actif) ───────────────────
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

        // ── Grid centré ───────────────────────────────────────────────────────
        Item {
            id: gridItem
            Layout.alignment: Qt.AlignHCenter

            readonly property real blockSize: 12
            implicitWidth: root.gridCols * blockSize + (root.gridCols - 1) * root.blockGap
            implicitHeight: root.gridRows * blockSize + (root.gridRows - 1) * root.blockGap

            Repeater {
                model: root.totalBlocks
                Rectangle {
                    x: (index % root.gridCols) * (gridItem.blockSize + root.blockGap)
                    y: Math.floor(
                           index / root.gridCols) * (gridItem.blockSize + root.blockGap)
                    width: gridItem.blockSize
                    height: gridItem.blockSize
                    radius: Theme.spacing.radiusSmall
                    // TODO: Logos Design System
                    color: root.filledBlocks[index] ? Theme.palette.primary : "#444444"
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

        // ── Footer : label + % pendant le téléchargement ─────────────────────
        RowLayout {
            Layout.fillWidth: true
            visible: root.isDownloading || root.isDone

            LogosText {
                text: root.isDone ? "Complete" : "Downloading..."
                font.pixelSize: Theme.typography.titleText * 0.8
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

        // ── BottomTitle — visible uniquement au repos ─────────────────────────
        BottomTitle {
            Layout.fillWidth: true
            title: "No download in progress"
            visible: !root.isDownloading && !root.isDone
        }

        // ── Progress bar — flush aux bords de la card ─────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: -Theme.spacing.medium
            Layout.rightMargin: -Theme.spacing.medium
            Layout.bottomMargin: -Theme.spacing.medium - 4
            Layout.preferredHeight: 6
            color: Theme.palette.backgroundSecondary

            Rectangle {
                width: parent.width * root.progress
                height: parent.height
                color: Theme.palette.primary
                Behavior on width {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}

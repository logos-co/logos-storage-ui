import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

// qmllint disable unqualified
LogosFrame {
    id: root
    objectName: "downloadWidget"

    backgroundColor: Theme.palette.backgroundSecondary
    borderColor: "transparent"
    radius: Theme.spacing.radiusLarge

    implicitWidth: 300
    // Idle mirrors the CID cards around it; the grid and progress footer need more.
    implicitHeight: 120

    property var backend: MockBackend
    property bool running: false
    property string downloadFolderPath: ""

    property string downloadFilename: ""
    property string downloadCid: ""
    property real totalBytes: 0
    property real downloadedBytes: 0
    property bool downloadInProgress: false

    function startLooking() {
        root.downloadInProgress = true;
    }

    readonly property real progress: totalBytes > 0 ? Math.min(downloadedBytes / totalBytes, 1.0) : 0.0
    readonly property bool isDownloading: progress > 0 && progress < 1.0
    readonly property bool isDone: progress >= 1.0
    readonly property bool idle: !downloadInProgress && !isDownloading && !isDone

    // ── Grid config ───────────────────────────────────────────────────────────
    readonly property int gridRows: 4
    readonly property real blockSize: 12
    readonly property int blockGap: 4
    // Space kept clear on the right of the grid, so the close icon does not
    // overlap the dots.
    readonly property real gridRightReserve: Theme.spacing.xxlarge + Theme.spacing.small

    // Fit as many columns as the reserved width allows. Width comes from
    // contentCol (the full padded content width) minus the reserved right zone;
    // gridItem's own width can be 0 with absolutely-positioned children.
    readonly property int gridCols: Math.max(6, Math.floor((contentCol.width - gridRightReserve + blockGap) / (blockSize + blockGap)))
    readonly property int totalBlocks: gridCols * gridRows

    property var filledBlocks: []

    function reset() {
        root.downloadCid = "";
        root.downloadFilename = "";
        root.totalBytes = 0;
        root.downloadedBytes = 0;
        root.downloadInProgress = false;
        root.initBlocks();
    }

    function initBlocks() {
        var arr = [];
        for (var i = 0; i < totalBlocks; i++)
            arr.push(false);
        root.filledBlocks = arr;
    }

    function applyProgress(p) {
        var target = Math.round(Math.min(Math.max(p, 0.0), 1.0) * totalBlocks);
        var blocks = root.filledBlocks.slice();
        var current = 0;
        for (var i = 0; i < blocks.length; i++) {
            if (blocks[i])
                current++;
        }
        if (target <= current)
            return;
        var empty = [];
        for (var j = 0; j < totalBlocks; j++) {
            if (!blocks[j])
                empty.push(j);
        }
        var needed = target - current;
        for (var k = 0; k < needed && empty.length > 0; k++) {
            var idx = Math.floor(Math.random() * empty.length);
            blocks[empty[idx]] = true;
            empty.splice(idx, 1);
        }
        root.filledBlocks = blocks;
    }

    onProgressChanged: applyProgress(progress)
    onTotalBlocksChanged: {
        initBlocks();
        applyProgress(progress);
    }
    Component.onCompleted: initBlocks()

    Connections {
        target: root.backend

        // The manifest we asked for landed: it carries the filename and the size
        // downloadFile needs, so the download starts here rather than on click.
        // downloadCid is cleared right away — manifestsUpdated is re-emitted on
        // every manifest fetch and removal, and must not restart this download.
        function onManifestsUpdated(manifests) {
            if (root.downloadCid === "")
                return;
            for (var i = 0; i < manifests.length; i++) {
                if (manifests[i].cid !== root.downloadCid)
                    continue;
                const cid = root.downloadCid;
                const name = manifests[i].filename || cid;
                const dest = root.downloadFolderPath.replace(/\/$/, "") + "/" + name;

                root.downloadCid = "";
                root.backend.downloadFile(cid, dest, parseInt(manifests[i].datasetSize) || 0);

                return;
            }
        }

        function onManifestFetchFailed(cid, error) {
            if (cid === root.downloadCid)
                root.reset();
        }

        function onDownloadStarted(cid, filename, total) {
            root.downloadFilename = filename;
            root.totalBytes = total;
            root.downloadedBytes = 0;
            root.initBlocks();
        }

        function onDownloadChunk(len) {
            root.downloadedBytes += len;
        }

        function onDownloadCompleted(cid) {
            root.downloadedBytes = root.totalBytes;
            root.downloadInProgress = false;
        }

        function onError(message) {
            root.reset();
        }
    }

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        spacing: 0

        // ── Idle: fetch the manifest for a CID, then download it ──────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: Theme.spacing.medium
            visible: root.idle

            Item {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                implicitHeight: cidInput.implicitHeight

                LogosTextField {
                    id: cidInput
                    anchors.fill: parent
                    leftPadding: Theme.spacing.medium * 2 + Theme.spacing.xlarge
                    rightPadding: Theme.spacing.medium * 2 + Theme.spacing.xlarge
                    placeholderText: "CID"
                    background: CardFieldBackground {
                        radius: Theme.spacing.radiusLarge
                    }
                }

                LogosIcon {
                    source: Qt.resolvedUrl("assets/file-download-line.svg")
                    color: cidInput.text.length > 0 ? Theme.palette.text : cidInput.placeholderTextColor
                    width: Theme.spacing.xlarge
                    height: Theme.spacing.xlarge
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacing.medium
                    anchors.verticalCenter: parent.verticalCenter
                }

                LogosIcon {
                    source: Qt.resolvedUrl("assets/info-custom-fill.svg")
                    color: cidInput.placeholderTextColor
                    width: Theme.spacing.xlarge
                    height: Theme.spacing.xlarge
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacing.medium
                    anchors.verticalCenter: parent.verticalCenter

                    HoverHandler {
                        id: cidHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    LogosToolTip {
                        text: "Paste the CID shared with you."
                        placement: LogosToolTip.Top
                        visible: cidHover.hovered
                    }
                }
            }

            LogosButton {
                radius: Theme.spacing.radiusLarge
                text: "Download"
                implicitWidth: 100
                implicitHeight: cidInput.implicitHeight
                variant: LogosButton.Variant.Secondary
                background: CardButtonBackground {}
                Layout.alignment: Qt.AlignTop
                enabled: cidInput.text.length > 0 && root.running
                onClicked: {
                    root.downloadCid = cidInput.text;
                    root.downloadInProgress = true;
                    root.backend.downloadManifest(cidInput.text);
                    cidInput.text = "";
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        // ── Grid ──────────────────────────────────────────────────────────────
        Item {
            id: gridItem
            visible: !root.idle
            Layout.fillWidth: true
            Layout.preferredWidth: contentCol.width
            Layout.preferredHeight: root.gridRows * root.blockSize + (root.gridRows - 1) * root.blockGap

            // Columns fill the width minus a reserved zone on the right (so the
            // close icon has clean space and does not overlap the dots).
            readonly property real gridWidth: contentCol.width - root.gridRightReserve
            readonly property real colStep: root.gridCols > 1
                ? (gridWidth - root.blockSize) / (root.gridCols - 1)
                : 0

            Repeater {
                model: root.totalBlocks

                Rectangle {
                    x: (index % root.gridCols) * gridItem.colStep
                    y: Math.floor(index / root.gridCols) * (root.blockSize + root.blockGap)
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
                font.pixelSize: Theme.typography.subtitleText
                color: root.isDone ? Theme.palette.primary : Theme.palette.text
            }
            Item {
                Layout.fillWidth: true
            }
            LogosText {
                text: Math.round(root.progress * 100) + "%"
                font.pixelSize: Theme.typography.subtitleText
                color: root.isDone ? Theme.palette.primary : Theme.palette.textMuted
            }
        }

        // ── BottomTitle — visible when idle ───────────────────────────────────
        BottomTitle {
            Layout.fillWidth: true
            title: root.downloadInProgress ? "Looking for peers..." : "Download"
            helpText: root.idle ? "Paste a CID to fetch its manifest and download the file." : ""
            visible: !root.isDownloading && !root.isDone
            color: Theme.palette.textSecondary
            hasSeparator: false
        }
    }

    // ── Close — overlays the grid's top-right corner when done ───────────────
    LogosIcon {
        source: Qt.resolvedUrl("assets/close-circle-line.svg")
        color: Theme.palette.textTertiary
        visible: root.isDone
        width: Theme.spacing.xlarge
        height: Theme.spacing.xlarge
        anchors.top: parent.top
        anchors.right: parent.right

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.reset()
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

import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Logos.Theme
import Logos.Controls
import "Utils.js" as Utils

LogosFrame {
    id: root

    backgroundColor: Theme.palette.backgroundSecondary
    borderColor: "transparent"
    radius: Theme.spacing.radiusLarge

    implicitWidth: 500
    implicitHeight: 500

    property var backend: MockBackend
    property double total: 0
    property double used: 0
    property double prevUsed: -1 // tracks last known used to detect upload deltas

    property string downloadFolderPath: ""

    readonly property real fraction: root.total > 0 ? Math.min(
                                                          root.used / root.total,
                                                          1.0) : 0

    // Type breakdown is derived from downloaded files: manifests whose file is
    // present in the download folder, bucketed by mimetype. The node's own
    // per-mimetype usage API is not available yet.
    property var manifests: []
    property var downloadedNames: ({})

    // Bytes per category [Documents, Images, Videos, Archives].
    property var typeBytes: [0, 0, 0, 0]
    property int usageCount: 0

    // Map a mimetype to a category index matching StorageUsageByType.types.
    // Images and videos are explicit; recognised document types are Documents;
    // everything else falls into Archives.
    function categoryIndex(mimetype) {
        if (!mimetype)
            return 3 // Archives (unknown)
        var m = mimetype.toLowerCase()
        if (m.indexOf("image/") === 0)
            return 1
        if (m.indexOf("video/") === 0)
            return 2
        if (m.indexOf("text/") === 0 || m === "application/pdf"
                || m.indexOf("word") >= 0 || m.indexOf("document") >= 0
                || m.indexOf("spreadsheet") >= 0 || m.indexOf("excel") >= 0
                || m.indexOf("presentation") >= 0 || m.indexOf("powerpoint") >= 0
                || m.indexOf("rtf") >= 0 || m.indexOf("csv") >= 0
                || m.indexOf("json") >= 0 || m.indexOf("xml") >= 0)
            return 0 // Documents
        return 3 // Archives
    }

    // Files sitting in the download folder, by name (mirrors ManifestTable).
    FolderListModel {
        id: downloadFolder
        folder: root.downloadFolderPath
        showDirs: false
        showHidden: false
        nameFilters: ["*"]
        onCountChanged: root.rebuildDownloaded()
        onFolderChanged: root.rebuildDownloaded()
    }

    function rebuildDownloaded() {
        var names = {}
        for (var i = 0; i < downloadFolder.count; i++)
            names[downloadFolder.get(i, "fileName")] = true
        root.downloadedNames = names
    }

    // Sum downloaded files by category. A manifest counts only when a file with
    // its name exists in the download folder.
    function recomputeUsage() {
        var b = [0, 0, 0, 0]
        var count = 0
        for (var i = 0; i < root.manifests.length; i++) {
            var m = root.manifests[i]
            if (!m || !m.filename || !root.downloadedNames[m.filename])
                continue
            b[root.categoryIndex(m.mimetype)] += parseInt(m.datasetSize) || 0
            count++
        }
        root.typeBytes = b
        root.usageCount = count
    }

    onManifestsChanged: root.recomputeUsage()
    onDownloadedNamesChanged: root.recomputeUsage()

    function refreshSpace() {
        let space = root.backend.space()
        root.total = space.total
        root.used = space.used
    }

    Connections {
        target: root.backend

        function onSpaceUpdated(total, used) {
            // Detect upload activity from growing used-space
            if (root.prevUsed >= 0) {
                var delta = used - root.prevUsed
                if (delta > 0)
                    activityGraph.addActivity(delta)
            }
            root.prevUsed = used
            root.total = total
            root.used = used
        }

        function onManifestsUpdated(manifests) {
            root.manifests = manifests
        }

        function onDownloadChunk(len) {
            activityGraph.addActivity(len)
        }

        function onUploadChunk(len) {
            activityGraph.addActivity(len)
        }
    }

    ColumnLayout {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomTitle.top
        spacing: Theme.spacing.medium

        RowLayout {
            Layout.alignment: Qt.AlignTop

            ColumnLayout {
                Layout.alignment: Qt.AlignTop

                LogosText {
                    text: "Logos Storage"
                    font.pixelSize: Theme.typography.panelTitleText
                    color: Theme.palette.textMuted
                }

                VaultText {}
            }

            Item {
                Layout.fillWidth: true
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignTop

                RowLayout {
                    Layout.alignment: Qt.AlignTop
                    spacing: Theme.spacing.small

                    LogosText {
                        text: Utils.formatBytes(root.used)
                        font.pixelSize: Theme.typography.panelTitleText
                        color: Theme.palette.text
                    }

                    LogosText {
                        text: " / " + Utils.formatBytes(root.total)
                        font.pixelSize: Theme.typography.panelTitleText
                        color: Theme.palette.textMuted
                    }

                    Image {
                        source: "assets/hard-drive.png"
                    }
                }

                LogosText {
                    text: "Total space available"
                    font.pixelSize: Theme.typography.secondaryText
                    color: Theme.palette.textSecondary
                    font.family: "monospace"
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.palette.borderSecondary
        }

        StorageUsageByType {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            capacity: root.total
            used: root.used
            bytes: root.typeBytes
            placeholder: root.usageCount === 0
        }

        // Legend
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.alignment: Qt.AlignTop
            spacing: Theme.spacing.medium

            // Utilized
            RowLayout {
                spacing: Theme.spacing.tiny
                visible: false

                Rectangle {
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 8
                    radius: Theme.spacing.radiusSmall
                    color: Theme.palette.accentOrange
                    Layout.alignment: Qt.AlignVCenter
                }
                LogosText {
                    text: Utils.formatBytes(root.used) + " Utilized"
                    font.pixelSize: Theme.typography.secondaryText
                    font.family: "monospace"
                    color: Theme.palette.textSecondary
                }
            }

            // Free
            RowLayout {
                spacing: Theme.spacing.tiny
                visible: false
                Rectangle {
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 8
                    radius: Theme.spacing.radiusSmall
                    color: Theme.palette.backgroundSecondary
                    Layout.alignment: Qt.AlignVCenter
                }
                LogosText {
                    text: Utils.formatBytes(root.total - root.used) + " Free"
                    font.pixelSize: Theme.typography.secondaryText
                    font.family: "monospace"
                    color: Theme.palette.textMuted
                }
            }
        }

        // ── Disk activity graph (ECG-style) ──────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 90
            color: Theme.palette.backgroundBlack
            radius: Theme.spacing.radiusSmall

            DiskActivityGraph {
                id: activityGraph
                anchors.fill: parent
                anchors.margins: Theme.spacing.small
                lineColor: Theme.palette.primary
            }

            LogosText {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.bottomMargin: Theme.spacing.small
                anchors.leftMargin: Theme.spacing.small
                text: "Disk Utilization Rate"
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.textSecondary
                font.family: "monospace"
            }
        }
    }

    BottomTitle {
        id: bottomTitle
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        title: "Storage"
    }
}

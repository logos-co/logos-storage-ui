import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore
import Logos.Theme
import Logos.Controls
import Logos.StorageBackend 1.0

// qmllint disable unqualified
LogosStorageLayout {
    id: root

    property var backend: MockBackend

    readonly property bool running: backend && backend.status === StorageBackend.Running

    // Fixed height of a top dashboard block, in every column count.
    readonly property int topBlockHeight: 465

    // Responsive breakpoints for the top blocks:
    // - wide:   Disk 40% | Upload/Download group 30% | Node/Peers group 30%
    // - medium: Disk full width on top, the two groups 50/50 below it
    // - narrow: every block stacked in a single column
    readonly property real topContentWidth: dashboardScroll.availableWidth
    readonly property string topMode: topContentWidth > 1250 ? "wide"
                                      : topContentWidth > 600 ? "medium" : "narrow"

    readonly property real diskBlockWidth:
        topMode === "wide" ? 0.4 * (topContentWidth - 2 * Theme.spacing.medium)
                           : topContentWidth
    readonly property real sideBlockWidth:
        topMode === "wide" ? 0.3 * (topContentWidth - 2 * Theme.spacing.medium)
        : topMode === "medium" ? (topContentWidth - Theme.spacing.medium) / 2
        : topContentWidth

    Settings {
        id: settings
        category: "Storage"
        property string downloadFolderPath: {
            const p = StandardPaths.standardLocations(StandardPaths.HomeLocation)[0].toString()
            return p.startsWith("file://") ? p : "file://" + p
        }
    }

    function isRunning() {
        return backend && backend.status === StorageBackend.Running
    }

    Component.onCompleted: function () {
        if (isRunning()) {
            root.backend.fetchWidgetsData()
        } else {
            root.backend.start()
        }
    }

    FileDialog {
        id: uploadDialog
        objectName: "uploadDialog"
        modality: Qt.NonModal
        onAccepted: root.backend.uploadFile(selectedFile)
        currentFolder: StandardPaths.standardLocations(
                           StandardPaths.HomeLocation)[0]
    }

    HealthIndicator {
        id: health
        backend: root.backend
    }

    LogosScrollView {
        id: dashboardScroll
        anchors.fill: parent
        anchors.margins: Theme.spacing.medium
        contentWidth: availableWidth

        ColumnLayout {
            width: dashboardScroll.availableWidth
            spacing: Theme.spacing.medium

            GridLayout {
                id: topGrid
                Layout.fillWidth: true
                columnSpacing: Theme.spacing.medium
                rowSpacing: Theme.spacing.medium
                columns: root.topMode === "wide" ? 3 : root.topMode === "medium" ? 2 : 1

                DiskWidget {
                    Layout.fillWidth: true
                    Layout.preferredWidth: root.diskBlockWidth
                    Layout.columnSpan: root.topMode === "medium" ? 2 : 1
                    Layout.preferredHeight: root.topBlockHeight
                    backend: root.backend
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: root.sideBlockWidth
                    Layout.preferredHeight: root.topBlockHeight
                    spacing: Theme.spacing.medium

                    DownloadWidget {
                        id: downloadWidget
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        backend: root.backend
                    }

                    UploadWidget {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        backend: root.backend
                        running: root.running
                        onUploadRequested: uploadDialog.open()
                    }

                    ManifestWidget {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        backend: root.backend
                        running: root.running
                    }
                }

                ColumnLayout {
                    id: thirdCol
                    Layout.fillWidth: true
                    Layout.preferredWidth: root.sideBlockWidth
                    Layout.preferredHeight: root.topBlockHeight
                    spacing: Theme.spacing.medium

                    NodeWidget {
                        Layout.fillWidth: true
                        Layout.preferredHeight: (thirdCol.height - thirdCol.spacing) / 3
                        backend: root.backend
                        nodeIsUp: health.nodeIsUp
                        blinkOn: health.blinkOn
                        downloadFolderPath: settings.downloadFolderPath
                        onFolderPathChanged: function(path) { settings.downloadFolderPath = path }
                    }

                    PeersWidget {
                        Layout.fillWidth: true
                        Layout.preferredHeight: (thirdCol.height - thirdCol.spacing) * 2 / 3
                        backend: root.backend
                        running: root.running
                    }
                }
            }

            ManifestTable {
                id: manifestTable
                Layout.fillWidth: true
                // Fill the remaining viewport when there's room, scroll otherwise.
                Layout.preferredHeight: Math.max(
                    400, dashboardScroll.availableHeight - topGrid.height - Theme.spacing.medium)
                backend: root.backend
                running: root.running
                downloadFolderPath: settings.downloadFolderPath
                onDownloadRequested: downloadWidget.startLooking()
            }
        }
    }
}

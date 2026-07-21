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

    property string currentPage: "dashboard"

    readonly property bool running: backend && backend.status === StorageBackend.Running

    // Fixed height of a top dashboard block, in every column count.
    readonly property int topBlockHeight: 425

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

    Sidebar {
        id: sidebar
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: implicitWidth
        currentPage: root.currentPage
        onPageSelected: function (page) {
            root.currentPage = page
        }
    }

    ScrollView {
        id: dashboardScroll
        visible: root.currentPage === "dashboard"
        anchors.fill: parent
        anchors.margins: Theme.spacing.medium
        anchors.leftMargin: sidebar.width + Theme.spacing.medium
        clip: true
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: dashboardScroll.availableWidth
            spacing: Theme.spacing.medium

            // Top blocks — 3 columns when wide, stacked into 1 when narrow.
            GridLayout {
                id: topGrid
                Layout.fillWidth: true
                columnSpacing: Theme.spacing.medium
                rowSpacing: Theme.spacing.medium
                columns: dashboardScroll.availableWidth > 950 ? 3 : 1

                DiskWidget {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.preferredHeight: root.topBlockHeight
                    backend: root.backend
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.preferredHeight: root.topBlockHeight
                    spacing: Theme.spacing.medium

                    UploadWidget {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        backend: root.backend
                        running: root.running
                        onUploadRequested: uploadDialog.open()
                    }

                    DownloadWidget {
                        id: downloadWidget
                        Layout.fillWidth: true
                        backend: root.backend
                        running: root.running
                        downloadFolderPath: settings.downloadFolderPath
                    }

                    ManifestWidget {
                        Layout.fillWidth: true
                        backend: root.backend
                        running: root.running
                    }
                }

                ColumnLayout {
                    id: thirdCol
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
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

    // Pages other than the dashboard are not built yet
    Item {
        visible: root.currentPage !== "dashboard"
        anchors.fill: parent
        anchors.leftMargin: sidebar.width

        LogosText {
            anchors.centerIn: parent
            text: root.currentPage.charAt(0).toUpperCase() + root.currentPage.slice(1)
            font.pixelSize: Theme.typography.titleText
            color: Theme.palette.textMuted
        }
    }
}

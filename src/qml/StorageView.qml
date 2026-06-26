import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore
import Logos.Theme
import Logos.StorageBackend 1.0

// qmllint disable unqualified
LogosStorageLayout {
    id: root

    property var backend: MockBackend

    readonly property bool running: backend && backend.status === StorageBackend.Running
    readonly property bool busy: backend && backend.busy

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
        onAccepted: {
            if (!root.busy)
                root.backend.uploadFile(selectedFile)
        }
        currentFolder: StandardPaths.standardLocations(
                           StandardPaths.HomeLocation)[0]
    }

    HealthIndicator {
        id: health
        backend: root.backend
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.medium
        spacing: Theme.spacing.medium

        // Partie haute — hauteur strictement fixe (min = max = preferred)
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 465
            Layout.minimumHeight: 465
            Layout.maximumHeight: 465

            RowLayout {
                anchors.fill: parent
                spacing: Theme.spacing.medium

                DiskWidget {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 0
                    backend: root.backend
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 0
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
                        busy: root.busy
                        onUploadRequested: uploadDialog.open()
                    }

                    ManifestWidget {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        backend: root.backend
                        running: root.running
                        busy: root.busy
                    }
                }

                ColumnLayout {
                    id: thirdCol
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 0
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
        }

        ManifestTable {
            id: manifestTable
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            backend: root.backend
            running: root.running
            busy: root.busy
            downloadFolderPath: settings.downloadFolderPath
        }
    }
}

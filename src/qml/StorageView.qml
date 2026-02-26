import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Logos.Theme

// qmllint disable unqualified
LogosStorageLayout {
    id: root

    property var backend: MockBackend

    function isRunning() {
        return backend.status === 2 // StorageBackend.Running
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
        onAccepted: root.backend.uploadFile(selectedFile)
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
                        running: root.isRunning()
                        onUploadRequested: uploadDialog.open()
                    }

                    ManifestWidget {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        backend: root.backend
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
                    }

                    PeersWidget {
                        Layout.fillWidth: true
                        Layout.preferredHeight: (thirdCol.height - thirdCol.spacing) * 2 / 3
                        backend: root.backend
                    }
                }
            }
        }

        // Table — prend tout l'espace restant
        ManifestTable {
            id: manifestTable
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            backend: root.backend
            running: root.isRunning()
        }
    }
}

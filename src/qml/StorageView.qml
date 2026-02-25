import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Logos.Theme

// qmllint disable unqualified
LogosStorageLayout {
    id: root

    property var backend: MockBackend
    property bool showDebug: false

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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.medium
        spacing: Theme.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 370
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

        ManifestTable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            backend: root.backend
            running: root.isRunning()
        }

        HealthIndicator {
            id: health
            backend: root.backend
        }

        Shortcut {
            sequence: "Ctrl+D"
            onActivated: root.showDebug = !root.showDebug
        }

        // ScrollView {
        //     id: mainScroll
        //     anchors.fill: parent
        //     anchors.bottomMargin: root.showDebug ? debugPanel.height : 0
        //     contentWidth: availableWidth
        //     clip: true

        //     ColumnLayout {
        //         width: mainScroll.availableWidth
        //         spacing: 0

        //         NodeHeader {
        //             Layout.fillWidth: true
        //             Layout.leftMargin: 24
        //             Layout.rightMargin: 24
        //             Layout.topMargin: 24
        //             Layout.bottomMargin: 20
        //             backend: root.backend
        //             nodeIsUp: health.nodeIsUp
        //             blinkOn: health.blinkOn
        //             onSettingsRequested: settingsPopup.open()
        //         }

        //         Rectangle {
        //             Layout.fillWidth: true
        //             Layout.leftMargin: 24
        //             Layout.rightMargin: 24
        //             Layout.preferredHeight: 1
        //             color: Theme.palette.borderSecondary
        //         }

        //         Widgets {
        //             Layout.fillWidth: true
        //             Layout.leftMargin: 24
        //             Layout.rightMargin: 24
        //             Layout.topMargin: 20
        //             backend: root.backend
        //             running: root.isRunning()
        //         }

        //         Rectangle {
        //             Layout.fillWidth: true
        //             Layout.leftMargin: 24
        //             Layout.rightMargin: 24
        //             Layout.preferredHeight: 1
        //             color: Theme.palette.borderSecondary
        //         }

        //         ManifestTable {
        //             Layout.fillWidth: true
        //             Layout.leftMargin: 24
        //             Layout.rightMargin: 24
        //             Layout.topMargin: 20
        //             Layout.bottomMargin: 20
        //             backend: root.backend
        //             running: root.isRunning()
        //         }

        //         Item {
        //             Layout.preferredHeight: 20
        //         }
        //     }
        // }
        DebugPanel {
            id: debugPanel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 220
            visible: root.showDebug
            backend: root.backend
            running: root.isRunning()
        }
    }
}

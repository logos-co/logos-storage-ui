import QtQuick
import QtQuick.Controls
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

    HealthIndicator {
        id: health
        backend: root.backend
    }

    Shortcut {
        sequence: "Ctrl+D"
        onActivated: root.showDebug = !root.showDebug
    }

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

    ScrollView {
        id: mainScroll
        anchors.fill: parent
        anchors.margins: Theme.spacing.medium
        anchors.bottomMargin: root.showDebug ? debugPanel.height
                                               + Theme.spacing.medium : Theme.spacing.medium
        contentWidth: availableWidth
        clip: true

        Column {
            id: mainContent
            width: mainScroll.availableWidth
            spacing: Theme.spacing.medium

            Item {
                width: parent.width
                height: 465

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

            ManifestTable {
                width: parent.width
                backend: root.backend
                running: root.isRunning()
            }
        }
    }
}

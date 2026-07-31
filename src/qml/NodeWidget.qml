import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls
import Logos.StorageBackend 1.0

// qmllint disable unqualified
LogosFrame {
    id: root

    backgroundColor: Theme.palette.backgroundSecondary
    borderColor: "transparent"
    radius: Theme.spacing.radiusLarge

    implicitWidth: 320
    implicitHeight: 150

    property var backend: MockBackend
    property string reachability: "Unknown"
    property bool blinkOn: false
    readonly property int effectiveStatus: root.backend ? root.backend.status : StorageBackend.Destroyed

    readonly property color statusColor: {
        if (root.effectiveStatus === StorageBackend.Starting) {
            return Theme.palette.warning
        }

        if (root.effectiveStatus !== StorageBackend.Running) {
            return Theme.palette.textMuted
        }

        if (root.reachability === "Reachable") {
            return Theme.palette.success
        }

        if (root.reachability === "NotReachable") {
            return Theme.palette.warning
        }

        return Theme.palette.textMuted
    }

    property string downloadFolderPath: ""

    signal folderPathChanged(string path)

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacing.medium

        RowLayout {
            Layout.alignment: Qt.AlignTop

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacing.medium

                RowLayout {
                    Layout.alignment: Qt.AlignTop
                    spacing: Theme.spacing.medium

                    Image {
                        Layout.alignment: Qt.AlignTop
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        // The asset already ships in Theme.palette.primary, so it
                        // is drawn as-is: colorizing it would only dull it.
                        source: Qt.resolvedUrl("assets/node-tree.svg")
                        sourceSize: Qt.size(64, 64)
                        fillMode: Image.PreserveAspectFit
                    }

                    LogosText {
                        Layout.alignment: Qt.AlignTop
                        text: "Node"
                        font.pixelSize: Theme.typography.panelTitleText
                        color: Theme.palette.text
                    }
                }

                Rectangle {
                    color: Theme.palette.backgroundBlack
                    Layout.preferredHeight: 32
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    Layout.rightMargin: Theme.spacing.small

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacing.small

                        LogosText {
                            Layout.alignment: Qt.AlignVCenter
                            text: "Manage node"
                            font.pixelSize: Theme.typography.primaryText
                            color: Theme.palette.textMuted
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        LogosIcon {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.rightMargin: Theme.spacing.small
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            source: Qt.resolvedUrl("assets/settings-5-line.svg")
                            color: Theme.palette.textTertiary

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: settingsPopup.open()
                            }
                        }
                    }
                }
            }

            StorageIcon {
                animated: root.effectiveStatus === StorageBackend.Starting
                          || root.effectiveStatus === StorageBackend.Stopping
                dotColor: root.statusColor
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.palette.textTertiary
            opacity: 0.2
        }

        RowLayout {
            id: actionRow

            RowLayout {
                spacing: Theme.spacing.medium

                Rectangle {
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 8
                    radius: Theme.spacing.radiusSmall
                    Layout.alignment: Qt.AlignVCenter
                    color: root.statusColor
                    opacity: root.effectiveStatus
                             === StorageBackend.Running ? (root.blinkOn ? 1.0 : 0.15) : 1.0
                }

                LogosText {
                    text: {
                        switch (root.effectiveStatus) {
                        case StorageBackend.Stopped:
                            return "Stopped"
                        case StorageBackend.Starting:
                            return "Starting…"
                        case StorageBackend.Running:
                            return "Running"
                        case StorageBackend.Stopping:
                            return "Stopping…"
                        case StorageBackend.Destroyed:
                            return "Stopped"
                        default:
                            return "Unknown"
                        }
                    }
                    font.pixelSize: Theme.typography.primaryText
                    color: Theme.palette.textSecondary
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            Item {
                Layout.fillWidth: true
            }

            LogosSwitch {
                id: mixSwitch
                text: "Mix"
                // Mix is always configured; private queries default on when the
                // node runs. The toggle only flips them live, no reconfigure.
                property bool privateQueriesEnabled: true
                checked: mixSwitch.privateQueriesEnabled
                enabled: root.effectiveStatus === StorageBackend.Running
                Layout.alignment: Qt.AlignVCenter
                onToggled: {
                    mixSwitch.privateQueriesEnabled = checked
                    root.backend.togglePrivateQueries(checked)
                }
            }

            Connections {
                target: root.backend
                function onStartCompleted() {
                    // The node re-enables private queries on every (re)start. If
                    // the user turned them off, re-apply that choice once it's up.
                    if (root.backend.mixRunning && !mixSwitch.privateQueriesEnabled)
                        root.backend.togglePrivateQueries(false)
                }
            }

            LogosButton {
                radius: Theme.spacing.radiusLarge
                text: root.effectiveStatus === StorageBackend.Running ? "Stop" : "Start"
                implicitHeight: 32
                implicitWidth: 65
                // The DS button floors at 44 with 12px vertical padding; at 32
                // that padding pushes the label off-center.
                topPadding: 0
                bottomPadding: 0
                Layout.alignment: Qt.AlignVCenter
                background: CardButtonBackground {}
                enabled: root.backend && (root.effectiveStatus === StorageBackend.Running
                                          || root.effectiveStatus === StorageBackend.Destroyed)
                onClicked: {
                    if (!root.backend)
                        return
                    root.backend.status === StorageBackend.Running ? root.backend.stop(
                                                                       ) : root.backend.start()
                }
            }
        }

        SettingsPopup {
            id: settingsPopup
            backend: root.backend
            downloadFolderPath: root.downloadFolderPath
            onFolderPathChanged: function(path) { root.folderPathChanged(path) }
        }

        // Rectangle {
        //     Layout.preferredWidth: 44
        //     Layout.preferredHeight: 44
        //     radius: 8
        //     color: settingsHover.hovered ? Theme.palette.backgroundElevated : "transparent"
        //     border.color: Theme.palette.borderSecondary
        //     border.width: 1

        //     SettingsIcon {
        //         anchors.centerIn: parent
        //         dotColor: Theme.palette.text
        //         dotSize: 5
        //         dotSpacing: 2
        //     }

        //     HoverHandler {
        //         id: settingsHover
        //     }
        //     MouseArea {
        //         anchors.fill: parent
        //         cursorShape: Qt.PointingHandCursor
        //         onClicked: root.settingsRequested()
        //     }
        // }

        // Rectangle {
        //     Layout.preferredWidth: 44
        //     Layout.preferredHeight: 44
        //     radius: 8
        //     color: startStopHover.hovered ? Theme.palette.backgroundElevated : "transparent"
        //     border.color: Theme.palette.borderSecondary
        //     border.width: 1
        //     opacity: (root.backend.status === StorageBackend.Running
        //               || root.backend.status === StorageBackend.Stopped) ? 1.0 : 0.4

        //     PlayIcon {
        //         anchors.centerIn: parent
        //         dotColor: Theme.palette.text
        //         dotSize: 5
        //         dotSpacing: 2
        //         visible: root.backend.status !== StorageBackend.Running
        //     }
        //     StopIcon {
        //         anchors.centerIn: parent
        //         dotColor: Theme.palette.text
        //         dotSize: 5
        //         dotSpacing: 2
        //         visible: root.backend.status === StorageBackend.Running
        //     }

        //     HoverHandler {
        //         id: startStopHover
        //     }
        //     MouseArea {
        //         anchors.fill: parent
        //         enabled: root.backend.status === StorageBackend.Running
        //                  || root.backend.status === StorageBackend.Stopped
        //         cursorShape: Qt.PointingHandCursor
        //         onClicked: root.backend.status === StorageBackend.Running ? root.backend.stop(
        //                                                               ) : root.backend.start()
        //     }
        // }
    }
}

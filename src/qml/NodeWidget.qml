import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
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

    // The dot next to "Running" reports how the node is seen from outside:
    // green once AutoNAT confirms it is reachable, orange when it is not,
    // muted while there is no verdict.
    readonly property color reachabilityColor: {
        if (root.reachability === "Reachable")
            return Theme.palette.success
        if (root.reachability === "NotReachable")
            return Theme.palette.warning
        return Theme.palette.textMuted
    }

    signal infoRequested()

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                Layout.alignment: Qt.AlignTop
                spacing: Theme.spacing.medium

                Image {
                    Layout.alignment: Qt.AlignTop
                    source: "assets/node-tree.png"
                }

                LogosText {
                    Layout.alignment: Qt.AlignTop
                    text: "Node"
                    font.pixelSize: Theme.typography.panelTitleText
                    color: Theme.palette.text
                }
            }

            Item { Layout.fillWidth: true }

            NodeActivityIcon {
                Layout.alignment: Qt.AlignTop
                backend: root.backend
                running: root.effectiveStatus === StorageBackend.Running
                lifecycleBusy: root.effectiveStatus === StorageBackend.Starting
                               || root.effectiveStatus === StorageBackend.Stopping
                idleColor: {
                    if (root.effectiveStatus === StorageBackend.Starting) {
                        return Theme.palette.warning
                    }

                    if (root.effectiveStatus !== StorageBackend.Running) {
                        return Theme.palette.textMuted
                    }

                    return Theme.palette.success
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.palette.borderSecondary
        }

        RowLayout {
            id: actionRow
            Layout.fillWidth: true

            RowLayout {
                spacing: Theme.spacing.medium

                Rectangle {
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 8
                    radius: Theme.spacing.radiusSmall
                    Layout.alignment: Qt.AlignVCenter
                    color: {
                        if (root.effectiveStatus === StorageBackend.Starting) {
                            return Theme.palette.warning
                        }

                        if (root.effectiveStatus !== StorageBackend.Running) {
                            return Theme.palette.textMuted
                        }

                        return root.reachabilityColor
                    }
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

                Item {
                    implicitWidth: 16
                    implicitHeight: 16
                    Layout.alignment: Qt.AlignVCenter

                    Image {
                        id: infoIcon
                        anchors.fill: parent
                        source: "assets/question-line.svg"
                        sourceSize: Qt.size(width * 2, height * 2)
                        fillMode: Image.PreserveAspectFit
                        visible: false
                    }

                    MultiEffect {
                        anchors.fill: infoIcon
                        source: infoIcon
                        colorization: 1.0
                        colorizationColor: infoMouse.containsMouse ? Theme.palette.primary
                                                                   : Theme.palette.textTertiary
                    }

                    MouseArea {
                        id: infoMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.infoRequested()
                    }
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

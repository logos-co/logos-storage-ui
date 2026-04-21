import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls
import Logos.StorageBackend 1.0

// qmllint disable unqualified
Card {
    id: root

    implicitWidth: 320
    implicitHeight: 150

    property var backend: MockBackend
    property bool nodeIsUp: false
    property bool blinkOn: false
    readonly property int effectiveStatus: root.backend ? root.backend.status : StorageBackend.Destroyed

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
                        source: "assets/node-tree.png"
                    }

                    LogosText {
                        Layout.alignment: Qt.AlignTop
                        text: "Node"
                        font.pixelSize: Theme.typography.titleText * 0.7
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

                        Image {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.rightMargin: Theme.spacing.small
                            source: "assets/settings.png"

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
                dotColor: {
                    if (root.effectiveStatus === StorageBackend.Starting) {
                        return Theme.palette.warning
                    }

                    if (root.effectiveStatus !== StorageBackend.Running) {
                        return Theme.palette.textMuted
                    }

                    return root.nodeIsUp ? Theme.palette.success : Theme.palette.error
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.palette.borderSecondary
        }

        RowLayout {

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

                        return root.nodeIsUp ? Theme.palette.success : Theme.palette.error
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
                            return "Not initialised"
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

            LogosStorageButton {
                text: root.effectiveStatus === StorageBackend.Running ? "Stop" : "Start"
                variant: "secondary"
                implicitHeight: 32
                implicitWidth: 65
                enabled: root.backend
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

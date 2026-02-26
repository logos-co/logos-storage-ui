import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

// qmllint disable unqualified
Card {
    id: root

    implicitWidth: 320
    implicitHeight: 150

    property var backend: MockBackend
    property bool nodeIsUp: false
    property bool blinkOn: false

    readonly property int stopped: 0
    readonly property int starting: 1
    readonly property int running: 2
    readonly property int stopping: 3
    readonly property int destroyed: 4

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
                animated: root.backend.status === root.starting
                          || root.backend.status === root.stopping
                dotColor: {
                    if (root.backend.status === root.starting) {
                        return Theme.palette.warning
                    }

                    if (root.backend.status !== root.running) {
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
                        if (root.backend.status === root.starting) {
                            return Theme.palette.warning
                        }

                        if (root.backend.status !== root.running) {
                            return Theme.palette.textMuted
                        }

                        return root.nodeIsUp ? Theme.palette.success : Theme.palette.error
                    }
                    opacity: root.backend.status
                             === root.running ? (root.blinkOn ? 1.0 : 0.15) : 1.0
                }

                LogosText {
                    text: {
                        switch (root.backend.status) {
                        case root.stopped:
                            return "Stopped"
                        case root.starting:
                            return "Starting…"
                        case root.running:
                            return "Running"
                        case root.stopping:
                            return "Stopping…"
                        case root.destroyed:
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
                text: root.backend.status === root.running ? "Stop" : "Start"
                variant: "secondary"
                implicitHeight: 32
                implicitWidth: 65
                onClicked: root.backend.status === root.running ? root.backend.stop(
                                                                      ) : root.backend.start()
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
        //     opacity: (root.backend.status === root.running
        //               || root.backend.status === root.stopped) ? 1.0 : 0.4

        //     PlayIcon {
        //         anchors.centerIn: parent
        //         dotColor: Theme.palette.text
        //         dotSize: 5
        //         dotSpacing: 2
        //         visible: root.backend.status !== root.running
        //     }
        //     StopIcon {
        //         anchors.centerIn: parent
        //         dotColor: Theme.palette.text
        //         dotSize: 5
        //         dotSpacing: 2
        //         visible: root.backend.status === root.running
        //     }

        //     HoverHandler {
        //         id: startStopHover
        //     }
        //     MouseArea {
        //         anchors.fill: parent
        //         enabled: root.backend.status === root.running
        //                  || root.backend.status === root.stopped
        //         cursorShape: Qt.PointingHandCursor
        //         onClicked: root.backend.status === root.running ? root.backend.stop(
        //                                                               ) : root.backend.start()
        //     }
        // }
    }
}

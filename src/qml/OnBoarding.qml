import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

LogosStorageLayout {
    id: root

    property var backend: mockBackend

    signal back
    signal completed(bool upnpEnabled)

    property int selectedMode: -1 // 0 = upnp, 1 = port forwarding

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Theme.spacing.medium
        width: 430

        LogosText {
            text: "Network Configuration"
            font.pixelSize: Theme.typography.titleText
            Layout.alignment: Qt.AlignHCenter
        }

        LogosText {
            text: "How is your network configured?"
            font.pixelSize: Theme.typography.primaryText
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Item {
            height: Theme.spacing.medium
        }

        Row {
            spacing: Theme.spacing.medium
            Layout.alignment: Qt.AlignHCenter

            // ── UPnP card ────────────────────────────────────────────────
            Rectangle {
                width: 190
                height: 230
                radius: 14
                color: root.selectedMode === 0 ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                border.color: root.selectedMode === 0 ? "white" : Qt.rgba(1, 1, 1, 0.2)
                border.width: root.selectedMode === 0 ? 2 : 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 14

                    // Nothing OS dot icon — diamond/network
                    Grid {
                        columns: 5
                        spacing: 4
                        Layout.alignment: Qt.AlignHCenter

                        Repeater {
                            model: [
                                0, 0, 1, 0, 0,
                                0, 1, 0, 1, 0,
                                1, 0, 1, 0, 1,
                                0, 1, 0, 1, 0,
                                0, 0, 1, 0, 0
                            ]
                            Rectangle {
                                width: 6
                                height: 6
                                radius: 2
                                color: "white"
                                opacity: modelData ? 0.9 : 0.1
                            }
                        }
                    }

                    Text {
                        text: "UPnP"
                        color: "white"
                        font.pixelSize: 16
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Automatic port\nforwarding via\nUPnP router."
                        color: Qt.rgba(1, 1, 1, 0.55)
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 150
                        wrapMode: Text.WordWrap
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selectedMode = 0
                }
            }

            // ── Port Forwarding card ─────────────────────────────────────
            Rectangle {
                width: 190
                height: 230
                radius: 14
                color: root.selectedMode === 1 ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                border.color: root.selectedMode === 1 ? "white" : Qt.rgba(1, 1, 1, 0.2)
                border.width: root.selectedMode === 1 ? 2 : 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 14

                    // Nothing OS dot icon — right arrow
                    Grid {
                        columns: 5
                        spacing: 4
                        Layout.alignment: Qt.AlignHCenter

                        Repeater {
                            model: [
                                0, 0, 1, 0, 0,
                                0, 0, 0, 1, 0,
                                1, 1, 1, 1, 1,
                                0, 0, 0, 1, 0,
                                0, 0, 1, 0, 0
                            ]
                            Rectangle {
                                width: 6
                                height: 6
                                radius: 2
                                color: "white"
                                opacity: modelData ? 0.9 : 0.1
                            }
                        }
                    }

                    Text {
                        text: "Port Forwarding"
                        color: "white"
                        font.pixelSize: 16
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Manual TCP port\nconfiguration on\nyour router."
                        color: Qt.rgba(1, 1, 1, 0.55)
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 150
                        wrapMode: Text.WordWrap
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selectedMode = 1
                }
            }
        }

        Item {
            height: Theme.spacing.small
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spacing.medium

            LogosStorageButton {
                text: "Back"
                onClicked: root.back()
            }

            LogosStorageButton {
                text: "Continue"
                enabled: root.selectedMode !== -1
                onClicked: {
                    if (root.selectedMode === 0) {
                        root.backend.enableUpnpConfig()
                    }
                    root.completed(root.selectedMode === 0)
                }
            }
        }
    }

    QtObject {
        id: mockBackend

        function enableUpnpConfig() {}
    }
}

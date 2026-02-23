import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

LogosStorageLayout {
    id: root

    property var backend: MockBackend

    signal back
    signal completed(bool upnpEnabled)

    property int selectedMode: -1

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
            Layout.preferredHeight: Theme.spacing.medium
        }

        Row {
            spacing: Theme.spacing.medium
            Layout.alignment: Qt.AlignHCenter

            Rectangle {
                width: 190
                height: 230
                radius: 14
                color: root.selectedMode === 0 ? Theme.palette.overlayLight : "transparent"
                border.color: root.selectedMode
                              === 0 ? Theme.palette.text : Theme.palette.borderTertiaryMuted
                border.width: root.selectedMode === 0 ? 2 : 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 14

                    UpnpIcon {
                        dotColor: Theme.palette.text
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "UPnP"
                        color: Theme.palette.text
                        font.pixelSize: 16
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Automatic port\nforwarding via\nUPnP router."
                        color: Theme.palette.textSecondary
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

            Rectangle {
                width: 190
                height: 230
                radius: 14
                color: root.selectedMode === 1 ? Theme.palette.overlayLight : "transparent"
                border.color: root.selectedMode
                              === 1 ? Theme.palette.text : Theme.palette.borderTertiaryMuted
                border.width: root.selectedMode === 1 ? 2 : 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 14

                    PortIcon {
                        dotColor: Theme.palette.text
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Port Forwarding"
                        color: Theme.palette.text
                        font.pixelSize: 16
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Manual TCP port\nconfiguration on\nyour router."
                        color: Theme.palette.textSecondary
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
            Layout.preferredHeight: Theme.spacing.small
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

}

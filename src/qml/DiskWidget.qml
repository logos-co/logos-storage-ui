import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls
import "Utils.js" as Utils

Card {
    id: root

    implicitWidth: 500
    implicitHeight: 300

    property var backend: MockBackend
    property double total: 20000
    property double used: 5000

    readonly property real fraction: root.total > 0 ? Math.min(
                                                          root.used / root.total,
                                                          1.0) : 0

    function refreshSpace() {
        let space = root.backend.space()
        root.total = space.total
        root.used = space.used
    }

    Connections {
        target: root.backend

        function onSpaceUpdated(total, used) {
            root.total = total
            root.used = used
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacing.medium

        RowLayout {
            Layout.alignment: Qt.AlignTop

            ColumnLayout {
                Layout.alignment: Qt.AlignTop

                LogosText {
                    text: "Logos Storage"
                    font.pixelSize: Theme.typography.titleText * 0.8
                    color: Theme.palette.textMuted
                }

                VaultText {}
            }

            Item {
                Layout.fillWidth: true
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignTop

                RowLayout {
                    Layout.alignment: Qt.AlignTop
                    spacing: Theme.spacing.small

                    LogosText {
                        text: Utils.formatBytes(root.used)
                        font.pixelSize: Theme.typography.titleText * 0.8
                        color: Theme.palette.text
                    }

                    LogosText {
                        text: " / " + Utils.formatBytes(root.total)
                        font.pixelSize: Theme.typography.titleText * 0.8
                        color: Theme.palette.textMuted
                    }

                    Image {
                        source: "assets/hard-drive.png"
                    }
                }

                LogosText {
                    text: "Total space available"
                    font.pixelSize: Theme.typography.secondaryText
                    color: Theme.palette.textSecondary
                    font.family: "monospace"
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.palette.borderSecondary
        }

        Item {
            Layout.fillHeight: true
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: Theme.palette.colors.black

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 40
                // TODO Logos Design System
                color: "#313131"

                // Fill
                Rectangle {
                    width: parent.width * root.fraction
                    height: parent.height
                    radius: parent.radius
                    color: Theme.palette.accentOrange

                    Behavior on width {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        // Legend
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.alignment: Qt.AlignTop
            spacing: Theme.spacing.medium

            // Utilized
            RowLayout {
                spacing: Theme.spacing.tiny
                Rectangle {
                    width: 8
                    height: 8
                    radius: Theme.spacing.radiusLarge
                    color: Theme.palette.accentOrange
                    Layout.alignment: Qt.AlignVCenter
                }
                LogosText {
                    text: Utils.formatBytes(root.used) + " Utilized"
                    font.pixelSize: Theme.typography.secondaryText
                    font.family: "monospace"
                    color: Theme.palette.textSecondary
                }
            }

            // Free
            RowLayout {
                spacing: Theme.spacing.tiny
                Rectangle {
                    width: 8
                    height: 8
                    radius: Theme.spacing.radiusLarge
                    color: Theme.typography.backgroundSecondary
                    Layout.alignment: Qt.AlignVCenter
                }
                LogosText {
                    text: Utils.formatBytes(root.total - root.used) + " Free"
                    font.pixelSize: Theme.typography.secondaryText
                    font.family: "monospace"
                    color: Theme.palette.textMuted
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.palette.borderSecondary
        }

        LogosText {
            text: "Space"
            font.pixelSize: Theme.typography.titleText * 0.8
            color: Theme.palette.text
        }
    }
}

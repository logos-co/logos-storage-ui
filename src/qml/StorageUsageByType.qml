import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls
import "Utils.js" as Utils

ColumnLayout {
    id: root

    // Placeholder data — no live backend wiring yet
    readonly property double totalUsed: 192 * 1e9
    readonly property double capacity: 250 * 1e9
    readonly property var segments: [
        {
            "name": "Documents",
            "bytes": 98 * 1e9,
            "color": Theme.palette.accentOrange
        },
        {
            "name": "Images",
            "bytes": 34 * 1e9,
            "color": Theme.palette.accentOrangeMid
        },
        {
            "name": "Videos",
            "bytes": 18 * 1e9,
            "color": Theme.palette.accentOrangeDeep
        },
        {
            "name": "Archives",
            "bytes": 42 * 1e9,
            "color": Theme.palette.accentBurntOrange
        }
    ]
    property bool placeholder: true

    spacing: Theme.spacing.small

    // Header + legend
    RowLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop

        ColumnLayout {
            spacing: 0
            Layout.alignment: Qt.AlignTop

            LogosText {
                text: "Storage"
                color: Theme.palette.text
            }
            LogosText {
                text: "Usage by Type"
                color: Theme.palette.text
            }
        }

        Item {
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: Theme.spacing.medium

            Repeater {
                model: root.segments

                RowLayout {
                    spacing: Theme.spacing.tiny

                    Rectangle {
                        Layout.preferredWidth: 6
                        Layout.preferredHeight: 6
                        radius: 3
                        color: modelData.color
                        Layout.alignment: Qt.AlignVCenter
                    }
                    LogosText {
                        text: modelData.name
                        font.pixelSize: Theme.typography.secondaryText
                        font.family: "monospace"
                        color: Theme.palette.textSecondary
                    }
                }
            }
        }
    }

    // Segmented bar
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 150
        color: Theme.palette.backgroundBlack

        Rectangle {
            id: track
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 40
            radius: Theme.spacing.radiusSmall
            color: Theme.palette.surface
            clip: true

            Row {
                anchors.fill: parent

                Repeater {
                    model: root.segments

                    Rectangle {
                        width: track.width * (modelData.bytes / root.capacity)
                        height: track.height
                        color: modelData.color
                    }
                }
            }
        }

        // Per-type chips under the bar
        Row {
            anchors.left: track.left
            anchors.top: track.bottom
            anchors.topMargin: Theme.spacing.small
            spacing: Theme.spacing.medium

            Repeater {
                model: root.segments

                Rectangle {
                    width: chipCol.implicitWidth + Theme.spacing.small
                    height: chipCol.implicitHeight + Theme.spacing.tiny
                    radius: Theme.spacing.radiusSmall
                    color: Theme.palette.backgroundSecondary

                    ColumnLayout {
                        id: chipCol
                        anchors.centerIn: parent
                        spacing: 0

                        LogosText {
                            text: modelData.name
                            font.pixelSize: Theme.typography.secondaryText
                            font.family: "monospace"
                            color: Theme.palette.textSecondary
                        }
                        LogosText {
                            text: Utils.formatBytes(modelData.bytes) + " / " + Utils.formatBytes(root.totalUsed)
                            font.pixelSize: Theme.typography.secondaryText
                            font.family: "monospace"
                            color: Theme.palette.textMuted
                        }
                    }
                }
            }
        }

        // Placeholder callout: shown until live data is wired
        Rectangle {
            visible: root.placeholder
            anchors.left: track.left
            anchors.verticalCenter: track.top
            width: Math.min(340, track.width * 0.6)
            height: overlayCol.implicitHeight + Theme.spacing.medium * 2
            radius: Theme.spacing.radiusSmall
            color: Theme.palette.glassStrong

            ColumnLayout {
                id: overlayCol
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacing.medium
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing.tiny

                LogosText {
                    text: "Disk not utilized"
                    color: Theme.palette.text
                }
                LogosText {
                    text: "Download Files to see live component."
                    font.pixelSize: Theme.typography.secondaryText
                    font.family: "monospace"
                    color: Theme.palette.textSecondary
                }
            }
        }
    }
}

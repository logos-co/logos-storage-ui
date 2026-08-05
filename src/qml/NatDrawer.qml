import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

LogosDrawer {
    id: root

    property color stateColor: Theme.palette.textMuted
    property string stateLabel: "Unknown"

    edge: Qt.RightEdge
    width: 420
    height: parent ? parent.height : 0

    contentItem: ColumnLayout {
        spacing: Theme.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacing.large
            Layout.leftMargin: Theme.spacing.large
            Layout.rightMargin: Theme.spacing.large

            LogosText {
                text: "Network reachability"
                font.pixelSize: Theme.typography.panelTitleText
                color: Theme.palette.text
                Layout.fillWidth: true
            }

            LogosIcon {
                Layout.preferredWidth: 23
                Layout.preferredHeight: 23
                source: Qt.resolvedUrl("assets/close-circle-line.svg")
                color: Theme.palette.textTertiary

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }
        }

        RowLayout {
            Layout.leftMargin: Theme.spacing.large
            Layout.rightMargin: Theme.spacing.large
            spacing: Theme.spacing.medium

            Rectangle {
                Layout.preferredWidth: 8
                Layout.preferredHeight: 8
                radius: Theme.spacing.radiusSmall
                Layout.alignment: Qt.AlignVCenter
                color: root.stateColor
            }

            LogosText {
                text: root.stateLabel
                font.pixelSize: Theme.typography.subtitleText
                color: Theme.palette.text
                Layout.alignment: Qt.AlignVCenter
            }
        }

        LogosText {
            text: "Your node reachability is refreshed periodically."
            font.pixelSize: Theme.typography.primaryText
            color: Theme.palette.textSecondary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacing.large
            Layout.rightMargin: Theme.spacing.large
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.leftMargin: Theme.spacing.large
            Layout.rightMargin: Theme.spacing.large
            color: Theme.palette.textTertiary
            opacity: 0.2
        }

        Repeater {
            model: [{
                    "color": Theme.palette.success,
                    "label": "Reachable",
                    "body": "Others can connect to you directly. Transfers run at full speed, nothing to do."
                }, {
                    "color": Theme.palette.warning,
                    "label": "Not reachable",
                    "body": "Your router turns incoming connections away, so others reach you through a relay: another node that takes their connection and forwards it to you. You can still share everything, it is just slower. To get direct connections, enable automatic port forwarding in your router settings."
                }, {
                    "color": Theme.palette.textMuted,
                    "label": "Unknown",
                    "body": "Your node is still testing whether the outside world can reach it. This usually takes a moment after it starts."
                }]

            ColumnLayout {
                id: entry

                required property var modelData

                Layout.fillWidth: true
                Layout.leftMargin: Theme.spacing.large
                Layout.rightMargin: Theme.spacing.large
                spacing: Theme.spacing.tiny

                RowLayout {
                    spacing: Theme.spacing.medium

                    Rectangle {
                        Layout.preferredWidth: 8
                        Layout.preferredHeight: 8
                        radius: Theme.spacing.radiusSmall
                        Layout.alignment: Qt.AlignVCenter
                        color: entry.modelData.color
                    }

                    LogosText {
                        text: entry.modelData.label
                        font.pixelSize: Theme.typography.subtitleText
                        font.weight: Theme.typography.weightBold
                        color: Theme.palette.text
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                LogosText {
                    text: entry.modelData.body
                    font.pixelSize: Theme.typography.primaryText
                    color: Theme.palette.textSecondary
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}

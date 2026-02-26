import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls
import "Utils.js" as Utils

Card {
    id: root

    implicitWidth: 500
    implicitHeight: 500

    property var backend: MockBackend
    property double total: 0
    property double used: 0
    property double prevUsed: -1 // tracks last known used to detect upload deltas

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
            // Detect upload activity from growing used-space
            if (root._prevUsed >= 0) {
                var delta = used - root._prevUsed
                if (delta > 0)
                    activityGraph.addActivity(delta)
            }
            root.prevUsed = used
            root.total = total
            root.used = used
        }

        function onDownloadChunk(len) {
            activityGraph.addActivity(len)
        }

        function onUploadChunk(len) {
            activityGraph.addActivity(len)
        }
    }

    ColumnLayout {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomTitle.top
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

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            color: Theme.palette.colors.black

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 40
                // TODO Logos Design System
                color: "#313131"

                Rectangle {
                    width: parent.width * root.fraction + 10
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
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 8
                    radius: Theme.spacing.radiusSmall
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
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 8
                    radius: Theme.spacing.radiusSmall
                    color: Theme.palette.backgroundSecondary
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

        // ── Disk activity graph (ECG-style) ──────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 90
            color: Theme.palette.colors.black
            radius: Theme.spacing.radiusSmall

            DiskActivityGraph {
                id: activityGraph
                anchors.fill: parent
                anchors.margins: Theme.spacing.small
                lineColor: Theme.palette.primary
            }

            LogosText {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.bottomMargin: Theme.spacing.small
                anchors.leftMargin: Theme.spacing.small
                text: "Disk Utilization Rate"
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.textSecondary
                font.family: "monospace"
            }
        }
    }

    BottomTitle {
        id: bottomTitle
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        title: "Storage"
    }
}

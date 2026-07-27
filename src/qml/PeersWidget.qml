import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

LogosFrame {
    id: root

    backgroundColor: Theme.palette.backgroundSecondary
    borderColor: "transparent"
    radius: Theme.spacing.radiusLarge

    implicitWidth: 320
    implicitHeight: 300

    property var backend: MockBackend
    property bool running: false
    property int peers: 0
    property int maxPeers: 20

    signal detailsRequested()

    onRunningChanged: {
        if (!running) root.peers = 0
    }

    ColumnLayout {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomTitle.top
        spacing: Theme.spacing.medium

        Image {
            source: "assets/global.png"
        }

        ArcWidget {
            Layout.alignment: Qt.AlignHCenter
            arcScale: 1.9
            arcOffsetY: 35
            fraction: root.maxPeers > 0 ? Math.min(root.peers / root.maxPeers,
                                                   1.0) : 0
            fillColor: Theme.palette.primary
            trackColor: Theme.palette.border

            ColumnLayout {
                anchors.centerIn: parent

                LogosText {
                    text: root.peers
                    font.pixelSize: Theme.typography.panelTitleText
                    font.weight: Theme.typography.weightBold
                    Layout.alignment: Qt.AlignHCenter
                }

                LogosText {
                    text: "PEERS"
                    font.pixelSize: Theme.typography.primaryText
                    color: Theme.palette.textTertiary
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            Connections {
                target: root.backend

                function onPeersUpdated(peers) {
                    root.peers = peers
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Theme.spacing.medium * 1.25

            Image {
                Layout.alignment: Qt.AlignVCenter
                source: root.peers > 0 ? "assets/success.png" : "assets/error.png"
            }

            LogosText {
                text: root.peers > 0 ? "Verified peers in the routing table."
                                     : "No verified peers yet."
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.textMuted
                font.family: "monospace"
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    BottomTitle {
        id: bottomTitle
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        title: "Peers"
        actionText: "Details"
        onActionClicked: root.detailsRequested()
    }
}

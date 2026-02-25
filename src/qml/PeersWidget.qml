import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

Card {
    id: root

    implicitWidth: 320
    implicitHeight: 300

    property var backend: MockBackend
    property int peers: 0
    property int maxPeers: 20

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacing.medium

        Image {
            source: "assets/global.png"
        }

        ArcWidget {
            Layout.alignment: Qt.AlignHCenter
            fraction: root.maxPeers > 0 ? Math.min(root.peers / root.maxPeers,
                                                   1.0) : 0
            fillColor: Theme.palette.primary

            ColumnLayout {
                anchors.centerIn: parent

                LogosText {
                    text: root.peers
                    font.pixelSize: Theme.typography.primaryText * 1.5
                    font.bold: true
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

            Image {
                Layout.alignment: Qt.AlignVCenter
                source: root.peers > 0 ? "assets/success.png" : "assets/error.png"
            }

            LogosText {
                text: "Peer connections are in good standing."
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.textMuted
                font.family: "monospace"
                Layout.alignment: Qt.AlignVCenter
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.palette.borderSecondary
        }

        LogosText {
            text: "Peers"
            font.pixelSize: Theme.typography.titleText * 0.8
            color: Theme.palette.text
        }
    }
}

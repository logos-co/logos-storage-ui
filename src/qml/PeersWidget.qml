import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

ArcWidget {
    id: root

    property var backend
    property int peers: 0
    property int maxPeers: 20

    fraction: root.maxPeers > 0 ? Math.min(root.peers / root.maxPeers, 1.0) : 0

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 2

        LogosText {
            text: root.peers
            font.pixelSize: 22
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        LogosText {
            text: "PEERS"
            font.pixelSize: 9
            color: Theme.palette.textTertiary
            font.letterSpacing: 1.3
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

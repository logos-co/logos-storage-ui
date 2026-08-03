import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls
import Logos.Icons

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
            Layout.preferredWidth: 28
            Layout.preferredHeight: 26
            source: Qt.resolvedUrl("assets/global-line.svg")
            sourceSize: Qt.size(64, 58)
            fillMode: Image.PreserveAspectFit
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

            LogosIcon {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                source: root.peers > 0 ? LogosIcons.check : LogosIcons.warning
                color: root.peers > 0 ? Theme.palette.success : Theme.palette.error
                // The DS glyphs are dark; colorization preserves luminance, so
                // they need normalizing before they take the tint.
                brightness: 1.0
            }

            LogosText {
                text: root.peers > 0 ? "Detected peers are in good standing."
                                     : "No active peer detected."
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.textMuted
                font.family: Theme.typography.mono
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
    }
}

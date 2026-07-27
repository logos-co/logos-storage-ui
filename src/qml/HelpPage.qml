import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

// qmllint disable unqualified
LogosFrame {
    id: root

    backgroundColor: Theme.palette.backgroundSecondary
    borderColor: "transparent"
    radius: Theme.spacing.radiusLarge

    property int openIndex: 0

    readonly property var faqs: [
        {
            "q": "What is Logos Storage?",
            "a": "Logos Storage is a peer-to-peer file sharing client. Files you upload are split into blocks and shared directly with other peers on the network, without a central server."
        },
        {
            "q": "Where are my files stored?",
            "a": "Blocks are kept locally in the data directory (see Settings). The node also announces the content it holds to the network so other peers can fetch it from you."
        },
        {
            "q": "How do I share a file?",
            "a": "Upload a file from the dashboard. Once processed you get a CID (content identifier). Share that CID with anyone: they can fetch the file by entering the CID in their own node."
        },
        {
            "q": "How do I download a file?",
            "a": "Enter the CID in the download widget. The node looks up peers that hold the content, fetches its manifest, then downloads the blocks into your chosen download folder."
        },
        {
            "q": "What is Mix / private queries?",
            "a": "Mix routes DHT provider lookups through relay nodes so the proxy cannot link a lookup to your identity. Private queries toggle this on the running node. It requires the node to run with Mix enabled."
        },
        {
            "q": "Which settings need a restart?",
            "a": "Settings tagged \"Restart required\" (ports, NAT, network, storage quota, bootstrap nodes, ...) only take effect after the node restarts. Log level and private queries apply without a restart."
        },
        {
            "q": "Why does my node have no peers?",
            "a": "Discovery is usually blocked, most often because another process already uses the discovery (UDP) port, or the port isn't reachable. Check that the discovery and listen ports in Settings are free and reachable, and that your NAT/router allows the connections. Changing ports requires a restart."
        },
        {
            "q": "I can download files, but others can't download from me. Why?",
            "a": "Outgoing connections pass through your router normally, but incoming ones are blocked, so your node is unreachable from the internet. Make it reachable by enabling UPnP during setup, or by configuring manual port forwarding on your router."
        },
        {
            "q": "Why is UPnP not working?",
            "a": "Many routers ship with UPnP disabled for security. Enable it on your router, or switch to manual port forwarding."
        },
        {
            "q": "Why doesn't manual port forwarding work?",
            "a": "Make sure your router forwards both the listen port (TCP) and the discovery port (UDP) to your machine's local address. Both rules are required."
        },
        {
            "q": "My node is still unreachable despite correct port forwarding.",
            "a": "Your machine's own firewall may block incoming connections. Allow both the listen (TCP) and discovery (UDP) ports through your system firewall."
        },
        {
            "q": "My node was reachable before and stopped working. Why?",
            "a": "ISPs change public IPs periodically. If you set a fixed external IP (extip) in Settings, update it to your current public IP and restart. Using UPnP avoids this by discovering the address automatically."
        },
        {
            "q": "Why do downloads time out from other machines?",
            "a": "The node publishing the content isn't reachable from the internet, usually because NAT is blocking incoming connections. It needs to be reachable via UPnP or manual port forwarding."
        }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.large
        spacing: Theme.spacing.tiny

        LogosText {
            text: "Help"
            font.pixelSize: Theme.typography.titleText
            font.weight: Theme.typography.weightBold
            color: Theme.palette.text
        }

        LogosText {
            text: "Frequently asked questions"
            font.pixelSize: Theme.typography.primaryText
            color: Theme.palette.textSecondary
            Layout.bottomMargin: Theme.spacing.medium
        }

        ScrollView {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: scroll.availableWidth
                spacing: Theme.spacing.small

                Repeater {
                    model: root.faqs

                    delegate: Rectangle {
                        id: card

                        required property var modelData
                        required property int index

                        readonly property bool open: root.openIndex === index

                        Layout.fillWidth: true
                        implicitHeight: cardCol.implicitHeight + Theme.spacing.medium * 2
                        color: Theme.palette.backgroundInset
                        radius: Theme.spacing.radiusMedium
                        border.width: 1
                        border.color: card.open ? Theme.palette.borderSubtle : "transparent"

                        ColumnLayout {
                            id: cardCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Theme.spacing.medium
                            spacing: Theme.spacing.small

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacing.small

                                LogosText {
                                    text: card.modelData.q
                                    font.pixelSize: Theme.typography.primaryText
                                    font.weight: Theme.typography.weightMedium
                                    color: Theme.palette.text
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }

                                LogosText {
                                    text: card.open ? "−" : "+"
                                    font.pixelSize: Theme.typography.subtitleText
                                    color: Theme.palette.textTertiary
                                }
                            }

                            LogosText {
                                visible: card.open
                                text: card.modelData.a
                                font.pixelSize: Theme.typography.secondaryText
                                color: Theme.palette.textSecondary
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            z: -1
                            onClicked: root.openIndex = card.open ? -1 : card.index
                        }
                    }
                }
            }
        }
    }
}

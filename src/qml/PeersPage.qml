import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

// qmllint disable unqualified
LogosFrame {
    id: root

    property var backend: MockBackend
    property bool running: false

    backgroundColor: Theme.palette.backgroundSecondary
    borderColor: "transparent"
    radius: Theme.spacing.radiusLarge

    // Rows come from the node debug info (table.nodes):
    // {peerId, address, seen, direct}.
    ListModel { id: peersModel }

    // Plain-array copy for the constellation canvas.
    property var peerList: []

    function setPeers(list) {
        peersModel.clear()
        for (var i = 0; i < list.length; i++) {
            peersModel.append({
                "peerId": list[i].peerId || "",
                "address": list[i].address || "",
                "seen": list[i].seen === true,
                "direct": list[i].direct === true
            })
        }
        root.peerList = list
    }

    function refresh() {
        if (root.backend && (root.backend.isMock || root.running))
            root.backend.refreshNodeStatus()
    }

    onVisibleChanged: if (visible) root.refresh()

    Connections {
        target: root.backend
        function onPeersTableUpdated(peers) {
            root.setPeers(peers)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.large
        spacing: Theme.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.small

            LogosText {
                text: "Peers"
                font.pixelSize: Theme.typography.titleText
                font.weight: Theme.typography.weightBold
                color: Theme.palette.text
            }

            LogosBadge {
                text: peersModel.count + " in routing table"
                color: Theme.palette.primary
            }

            Item { Layout.fillWidth: true }

            LogosButton {
                text: "Refresh"
                radius: Theme.spacing.radiusLarge
                variant: LogosButton.Variant.Primary
                onClicked: root.refresh()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 300
            color: Theme.palette.backgroundInset
            radius: Theme.spacing.radiusLarge

            PeerConstellation {
                id: constellation
                anchors.fill: parent
                anchors.margins: Theme.spacing.medium
                peers: root.peerList
                onPeerClicked: function (index) {
                    if (peersTable.view)
                        peersTable.view.positionViewAtIndex(index, ListView.Center)
                }
            }

            // Legend
            RowLayout {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: Theme.spacing.medium
                spacing: Theme.spacing.medium

                Row {
                    spacing: Theme.spacing.tiny
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: Theme.palette.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    LogosText {
                        text: "Verified"
                        font.pixelSize: Theme.typography.secondaryText
                        color: Theme.palette.textSecondary
                    }
                }
                Row {
                    spacing: Theme.spacing.tiny
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: Theme.palette.textMuted
                        opacity: 0.45
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    LogosText {
                        text: "Unverified"
                        font.pixelSize: Theme.typography.secondaryText
                        color: Theme.palette.textSecondary
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            // Row highlight kept in sync with the constellation hover (same
            // order, so the hovered index is the row index).
            Rectangle {
                readonly property int idx: constellation.hoveredIndex
                visible: idx >= 0
                anchors.left: parent.left
                anchors.right: parent.right
                height: peersTable.rowHeight
                y: peersTable.headerHeight + idx * peersTable.rowHeight
                   - (peersTable.view ? peersTable.view.contentY : 0)
                color: Theme.palette.primary
                opacity: 0.1
                z: 3
            }

            LogosTable {
            id: peersTable
            anchors.fill: parent
            model: peersModel
            rowHeight: 48
            emptyText: "No peers in the routing table yet"

            columns: [
                LogosTableColumn {
                    title: "Peer ID"
                    role: "peerId"
                    minWidth: 240
                    fillWidth: true
                    cellDelegate: Component {
                        Item {
                            LogosText {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: rowItem ? rowItem.peerId : ""
                                color: Theme.palette.text
                                font.family: "monospace"
                                font.pixelSize: Theme.typography.secondaryText
                                elide: Text.ElideMiddle
                            }
                        }
                    }
                },
                LogosTableColumn {
                    title: "Address"
                    role: "address"
                    minWidth: 160
                    preferredWidth: 220
                },
                LogosTableColumn {
                    title: "Status"
                    role: "seen"
                    minWidth: 120
                    preferredWidth: 120
                    headerCellDelegate: Component {
                        RowLayout {
                            spacing: Theme.spacing.tiny

                            LogosText {
                                text: columnDef.title
                                color: Theme.palette.textSecondary
                                font.pixelSize: Theme.typography.secondaryText
                                font.weight: Theme.typography.weightMedium
                                verticalAlignment: Text.AlignVCenter
                            }
                            LogosIcon {
                                source: Qt.resolvedUrl("assets/question-line.svg")
                                color: statusHelp.hovered ? Theme.palette.text : Theme.palette.textTertiary
                                width: 16
                                height: 16
                                Layout.alignment: Qt.AlignVCenter

                                HoverHandler {
                                    id: statusHelp
                                    cursorShape: Qt.PointingHandCursor
                                }
                                LogosToolTip {
                                    text: "Verified — node answered, tracked as reliable (DHT).\nUnverified — known but not confirmed."
                                    placement: LogosToolTip.Top
                                    visible: statusHelp.hovered
                                }
                            }
                            Item { Layout.fillWidth: true }
                        }
                    }
                    cellDelegate: Component {
                        Item {
                            LogosBadge {
                                anchors.verticalCenter: parent.verticalCenter
                                text: rowItem && rowItem.seen ? "Verified" : "Unverified"
                                color: rowItem && rowItem.seen ? Theme.palette.success
                                                              : Theme.palette.textTertiary
                            }
                        }
                    }
                },
                LogosTableColumn {
                    title: "Connection"
                    role: "direct"
                    minWidth: 130
                    preferredWidth: 130
                    headerCellDelegate: Component {
                        RowLayout {
                            spacing: Theme.spacing.tiny

                            LogosText {
                                text: columnDef.title
                                color: Theme.palette.textSecondary
                                font.pixelSize: Theme.typography.secondaryText
                                font.weight: Theme.typography.weightMedium
                                verticalAlignment: Text.AlignVCenter
                            }
                            LogosIcon {
                                source: Qt.resolvedUrl("assets/question-line.svg")
                                color: connectionHelp.hovered ? Theme.palette.text : Theme.palette.textTertiary
                                width: 16
                                height: 16
                                Layout.alignment: Qt.AlignVCenter

                                HoverHandler {
                                    id: connectionHelp
                                    cursorShape: Qt.PointingHandCursor
                                }
                                LogosToolTip {
                                    text: "Connection with the peer"
                                    placement: LogosToolTip.Top
                                    visible: connectionHelp.hovered
                                }
                            }
                            Item { Layout.fillWidth: true }
                        }
                    }
                    cellDelegate: Component {
                        Item {
                            LogosText {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: rowItem && rowItem.direct ? "Connected" : "—"
                                color: rowItem && rowItem.direct ? Theme.palette.text
                                                                 : Theme.palette.textMuted
                                font.pixelSize: Theme.typography.secondaryText
                            }
                        }
                    }
                }
            ]
            }
        }
    }
}

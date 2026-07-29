import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

// qmllint disable unqualified
// Everything the node reports in its debug info, one field per row.
LogosFrame {
    id: page

    property var backend: MockBackend
    property bool running: false

    backgroundColor: Theme.palette.backgroundSecondary
    borderColor: "transparent"
    radius: Theme.spacing.radiusLarge

    // One row per displayed field: kind is "text", "mono" or "tag", tone only
    // colours a tag, copyable adds the copy button.
    ListModel { id: rowsModel }

    function toneColor(tone) {
        if (tone === "success")
            return Theme.palette.success
        if (tone === "warning")
            return Theme.palette.warning
        return Theme.palette.textTertiary
    }

    // Debug values are strings most of the time, but the module also sends
    // structured ones (keys, records): render those as compact JSON.
    function asText(value) {
        if (value === undefined || value === null)
            return ""
        if (typeof value === "string")
            return value
        if (typeof value === "boolean")
            return value ? "Yes" : "No"
        return JSON.stringify(value)
    }

    function addRow(label, value, kind, tone, copyable) {
        rowsModel.append({
            "label": label,
            "value": value,
            "kind": kind || "text",
            "tone": tone || "neutral",
            "copyable": copyable === true
        })
    }

    // One row per value, so a node announcing three addresses shows three rows.
    function addAll(label, values) {
        var list = values || []
        for (var i = 0; i < list.length; i++) {
            var text = page.asText(list[i])
            if (text !== "")
                page.addRow(label, text, "mono")
        }
    }

    function countBy(list, key) {
        var count = 0
        for (var i = 0; i < list.length; i++) {
            if (list[i][key])
                count++
        }
        return count
    }

    function setInfo(info) {
        rowsModel.clear()

        var nat = info.nat || {}
        var storage = info.storage || {}
        var nodes = (info.table && info.table.nodes) || []
        var connections = info.connections || []

        var reachability = nat.reachability || "Unknown"
        var portMapping = nat.portMapping || "none"

        page.addRow("Peer ID", page.asText(info.id), "mono", "neutral", true)
        page.addRow("Reachability", reachability, "tag",
                    reachability === "Reachable" ? "success"
                                                 : reachability === "NotReachable" ? "warning"
                                                                                   : "neutral")
        page.addRow("Port mapping", portMapping, "tag",
                    portMapping === "none" ? "neutral" : "success")
        page.addRow("Relay running", page.asText(nat.relayRunning), "tag")
        page.addRow("DHT client mode", page.asText(nat.clientMode), "tag")
        page.addRow("Routing table",
                    page.countBy(nodes, "seen") + " verified / " + nodes.length + " known")
        page.addRow("Connections",
                    connections.length + " open / " + page.countBy(connections, "direct") + " direct")
        page.addRow("Storage version", page.asText(storage.version))
        page.addRow("Storage revision", page.asText(storage.revision), "mono")

        page.addAll("Listen address", info.addrs)
        page.addAll("Provider address", info.providerAddresses)
        page.addAll("Discovery address", info.discoveryAddresses)

        // Absent from the payload when the node has no such record or no mix.
        var identifiers = [["SPR", info.spr], ["Provider record", info.providerRecord],
                           ["libp2p public key", info.libp2pPubKey],
                           ["Mix public key", info.mixPubKey]]
        for (var i = 0; i < identifiers.length; i++) {
            var text = page.asText(identifiers[i][1])
            if (text !== "")
                page.addRow(identifiers[i][0], text, "mono", "neutral", true)
        }
    }

    function refresh() {
        if (page.backend && (page.backend.isMock || page.running))
            page.backend.refreshNodeStatus()
    }

    onVisibleChanged: if (visible) page.refresh()

    Connections {
        target: page.backend
        function onDebugInfoUpdated(info) {
            page.setInfo(info)
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
                text: "Debug"
                font.pixelSize: Theme.typography.titleText
                font.weight: Theme.typography.weightBold
                color: Theme.palette.text
            }

            Item { Layout.fillWidth: true }

            LogosButton {
                text: "Refresh"
                radius: Theme.spacing.radiusLarge
                variant: LogosButton.Variant.Primary
                onClicked: page.refresh()
            }
        }

        LogosTable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: rowsModel
            rowHeight: 44
            emptyText: page.running ? "No debug info yet" : "Start the node to read its debug info"

            columns: [
                LogosTableColumn {
                    title: "Field"
                    role: "label"
                    minWidth: 160
                    preferredWidth: 200
                },
                LogosTableColumn {
                    title: "Value"
                    role: "value"
                    minWidth: 240
                    fillWidth: true
                    cellDelegate: Component {
                        Item {
                            LogosBadge {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: rowItem && rowItem.kind === "tag"
                                text: rowItem ? rowItem.value : ""
                                color: page.toneColor(rowItem ? rowItem.tone : "neutral")
                            }

                            RowLayout {
                                anchors.fill: parent
                                spacing: Theme.spacing.small
                                visible: !rowItem || rowItem.kind !== "tag"

                                LogosText {
                                    Layout.fillWidth: true
                                    verticalAlignment: Text.AlignVCenter
                                    text: rowItem ? rowItem.value : ""
                                    color: Theme.palette.text
                                    font.family: rowItem && rowItem.kind === "mono"
                                                 ? "monospace" : Theme.typography.publicSans
                                    font.pixelSize: Theme.typography.secondaryText
                                    elide: Text.ElideMiddle
                                }

                                LogosIconButton {
                                    id: copyBtn
                                    visible: rowItem && rowItem.copyable
                                    size: 28
                                    iconSize: 16
                                    Layout.alignment: Qt.AlignVCenter

                                    property bool copied: false

                                    iconSource: copied ? Qt.resolvedUrl("assets/success.png")
                                                       : Qt.resolvedUrl("assets/file-copy-line.svg")
                                    iconColor: copied ? Theme.palette.success : Theme.palette.textTertiary

                                    background: Rectangle {
                                        color: Theme.palette.backgroundInset
                                        radius: Theme.spacing.radiusPill
                                        border.width: 1
                                        border.color: copyBtn.isActive ? Theme.palette.overlayOrange
                                                                       : Theme.palette.borderSubtle
                                    }

                                    Timer {
                                        id: resetCopyTimer
                                        interval: 1500
                                        onTriggered: copyBtn.copied = false
                                    }

                                    onClicked: {
                                        clipboardHelper.text = rowItem ? rowItem.value : ""
                                        clipboardHelper.selectAll()
                                        clipboardHelper.copy()
                                        copyBtn.copied = true
                                        resetCopyTimer.restart()
                                    }
                                }
                            }

                            TextEdit {
                                id: clipboardHelper
                                visible: false
                            }
                        }
                    }
                }
            ]
        }
    }
}

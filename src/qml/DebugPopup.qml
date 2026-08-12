import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

// qmllint disable unqualified
// Everything the node reports in its debug info, one field per row.
Popup {
    id: root

    objectName: "debugPopup"

    property var backend: MockBackend
    property bool running: false

    // One row per displayed field: kind is "text", "mono" or "tag", tone only
    // colours a tag, copyable adds the copy button.
    ListModel {
        id: rowsModel
    }

    modal: true
    padding: 0
    closePolicy: Popup.CloseOnEscape
    anchors.centerIn: Overlay.overlay
    width: Math.min(920, Overlay.overlay ? Overlay.overlay.width - 48 : 920)
    height: Math.min(680, Overlay.overlay ? Overlay.overlay.height - 48 : 680)

    onOpened: root.refresh()

    background: Rectangle {
        color: Theme.palette.background
        border.color: Theme.palette.borderSecondary
        border.width: 1
        radius: Theme.spacing.radiusXlarge
    }

    Connections {
        target: root.backend
        ignoreUnknownSignals: true

        function onDebugInfoUpdated(info) {
            root.setInfo(info)
        }
    }

    function refresh() {
        if (root.backend && (root.backend.isMock || root.running))
            root.backend.logDebugInfo()
    }

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
        const list = values || []
        for (let i = 0; i < list.length; i++) {
            const text = root.asText(list[i])
            if (text !== "")
                root.addRow(label, text, "mono")
        }
    }

    function countBy(list, key) {
        let count = 0
        for (let i = 0; i < list.length; i++) {
            if (list[i][key])
                count++
        }
        return count
    }

    function setInfo(info) {
        rowsModel.clear()

        const nat = info.nat || {}
        const storage = info.storage || {}
        const nodes = (info.table && info.table.nodes) || []
        const connections = info.connections || []

        const reachability = nat.reachability || "Unknown"
        const portMapping = nat.portMapping || "none"

        root.addRow("Peer ID", root.asText(info.id), "mono", "neutral", true)
        root.addRow("Reachability", reachability, "tag",
                    reachability === "Reachable" ? "success"
                                                 : reachability === "NotReachable" ? "warning" : "neutral")
        root.addRow("Port mapping", portMapping, "tag",
                    portMapping === "none" ? "neutral" : "success")
        root.addRow("Relay running", root.asText(nat.relayRunning), "tag")
        root.addRow("DHT client mode", root.asText(nat.clientMode), "tag")
        root.addRow("Routing table",
                    root.countBy(nodes, "seen") + " verified / " + nodes.length + " known")
        root.addRow("Connections",
                    connections.length + " open / " + root.countBy(connections, "direct") + " direct")
        root.addRow("Storage version", "2.1.1")

        root.addAll("Listen address", info.addrs)
        root.addAll("Provider address", info.providerAddresses)
        root.addAll("Discovery address", info.discoveryAddresses)

        // Absent from the payload when the node has no such record or no mix.
        const identifiers = [["SPR", info.spr], ["Provider record", info.providerRecord],
                             ["libp2p public key", info.libp2pPubKey],
                             ["Mix public key", info.mixPubKey]]
        for (let i = 0; i < identifiers.length; i++) {
            const text = root.asText(identifiers[i][1])
            if (text !== "")
                root.addRow(identifiers[i][0], text, "mono", "neutral", true)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.spacing.large
            spacing: Theme.spacing.medium

            ColumnLayout {
                Layout.fillWidth: false
                spacing: 2

                LogosText {
                    text: "Debug"
                    font.pixelSize: Theme.typography.titleText
                    color: Theme.palette.text
                }

                LogosText {
                    text: "What the node reports about itself."
                    font.pixelSize: Theme.typography.secondaryText
                    color: Theme.palette.textSecondary
                }
            }

            Item {
                Layout.fillWidth: true
            }

            LogosIcon {
                Layout.alignment: Qt.AlignVCenter
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

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.palette.borderSecondary
        }

        ScrollView {
            id: scroll

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Item {
                width: scroll.availableWidth
                implicitHeight: card.implicitHeight + 2 * Theme.spacing.large

                Rectangle {
                    id: card
                    x: Theme.spacing.large
                    y: Theme.spacing.large
                    width: parent.width - 2 * Theme.spacing.large
                    implicitHeight: Math.max(rows.implicitHeight + 2 * Theme.spacing.large, 80)
                    color: Theme.palette.backgroundSecondary
                    border.color: Theme.palette.borderSecondary
                    border.width: 1
                    radius: Theme.spacing.radiusLarge

                    LogosText {
                        anchors.centerIn: parent
                        visible: rowsModel.count === 0
                        text: root.running ? "No debug info yet"
                                           : "Start the node to read its debug info"
                        color: Theme.palette.textSecondary
                    }

                    ColumnLayout {
                        id: rows
                        anchors.fill: parent
                        anchors.margins: Theme.spacing.large
                        spacing: 0

                        Repeater {
                            model: rowsModel

                            RowLayout {
                                id: row

                                required property int index
                                required property string label
                                required property string value
                                required property string kind
                                required property string tone
                                required property bool copyable

                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                spacing: Theme.spacing.large

                                LogosText {
                                    Layout.preferredWidth: 180
                                    Layout.minimumWidth: 120
                                    text: row.label
                                    font.pixelSize: Theme.typography.secondaryText
                                    color: Theme.palette.textSecondary
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    visible: row.kind === "tag"
                                    implicitWidth: tagText.implicitWidth + 2 * Theme.spacing.small
                                    implicitHeight: 22
                                    radius: height / 2
                                    color: "transparent"
                                    border.width: 1
                                    border.color: root.toneColor(row.tone)

                                    LogosText {
                                        id: tagText
                                        anchors.centerIn: parent
                                        text: row.value
                                        font.pixelSize: Theme.typography.secondaryText
                                        color: root.toneColor(row.tone)
                                    }
                                }

                                LogosText {
                                    Layout.fillWidth: true
                                    visible: row.kind !== "tag"
                                    text: row.value
                                    font.family: row.kind === "mono" ? "monospace"
                                                                     : Theme.typography.publicSans
                                    font.pixelSize: Theme.typography.secondaryText
                                    color: Theme.palette.text
                                    elide: Text.ElideMiddle
                                }

                                Item {
                                    Layout.fillWidth: row.kind === "tag"
                                }

                                LogosCopyButton {
                                    visible: row.copyable
                                    Layout.alignment: Qt.AlignVCenter
                                    value: row.value
                                    size: 32
                                    iconSize: 16
                                    background: IconButtonBackground {}
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.palette.borderSecondary
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.spacing.large
            spacing: Theme.spacing.medium

            LogosText {
                Layout.fillWidth: true
                visible: !root.running
                text: "The node is stopped: these values are from its last run."
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.textSecondary
                elide: Text.ElideRight
            }

            Item {
                Layout.fillWidth: true
            }

            LogosButton {
                objectName: "restartOnboardingButton"
                radius: Theme.spacing.radiusLarge
                text: "Restart onboarding"
                implicitHeight: 40
                implicitWidth: 180
                onClicked: {
                    root.close()
                    root.backend.restartOnboarding()
                }
            }

            LogosButton {
                radius: Theme.spacing.radiusLarge
                text: "Refresh"
                variant: LogosButton.Variant.Primary
                implicitHeight: 40
                implicitWidth: 130
                enabled: root.running
                onClicked: root.refresh()
            }
        }
    }
}

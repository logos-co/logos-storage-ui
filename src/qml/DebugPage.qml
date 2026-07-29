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

    // Rows come from the backend: {label, value, kind, tone, copyable}.
    ListModel { id: rowsModel }

    function toneColor(tone) {
        if (tone === "success")
            return Theme.palette.success
        if (tone === "warning")
            return Theme.palette.warning
        return Theme.palette.textTertiary
    }

    function setRows(rows) {
        rowsModel.clear()
        for (var i = 0; i < rows.length; i++) {
            rowsModel.append({
                "label": rows[i].label || "",
                "value": rows[i].value || "",
                "kind": rows[i].kind || "text",
                "tone": rows[i].tone || "neutral",
                "copyable": rows[i].copyable === true
            })
        }
    }

    function refresh() {
        if (page.backend && (page.backend.isMock || page.running))
            page.backend.refreshNodeStatus()
    }

    onVisibleChanged: if (visible) page.refresh()

    Connections {
        target: page.backend
        function onDebugInfoUpdated(rows) {
            page.setRows(rows)
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

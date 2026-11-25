import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

// qmllint disable unqualified
// The names this node publishes: each one with its name key and the dataset it points to.
Item {
    id: root

    property var backend: MockBackend
    property bool running: false
    // { label: { cid, nameKey } }, kept by the table.
    property var publishedNames: ({})
    property var manifests: []
    // Names whose publish runs in the node: { label: cid }.
    property var publishingLabels: ({})

    signal changeRequested(string label, string cid)

    // Three 40px icon buttons, the gaps between them and the pill's own padding.
    readonly property int actionsColumnWidth: 40 * 3 + Theme.spacing.medium * 4

    // The manifest of the cid in this node, or null.
    function manifestOf(cid) {
        for (var i = 0; i < root.manifests.length; i++) {
            if (root.manifests[i].cid === cid)
                return root.manifests[i]
        }
        return null
    }

    ListModel {
        id: namesModel
    }

    // A new name shows up as soon as its publish starts, without a name key yet.
    function rebuild() {
        namesModel.clear()
        var all = Object.assign({}, root.publishingLabels, root.publishedNames)
        var labels = Object.keys(all).sort()
        for (var i = 0; i < labels.length; i++) {
            var entry = root.publishedNames[labels[i]]
            var cid = entry ? entry.cid : root.publishingLabels[labels[i]]
            var manifest = root.manifestOf(cid)
            namesModel.append({
                                  "label": labels[i],
                                  "cid": cid,
                                  "nameKey": entry ? entry.nameKey : "",
                                  "inNode": !!manifest,
                                  "filename": manifest ? (manifest.filename || "Untitled") : "",
                                  "publishing": !!root.publishingLabels[labels[i]]
                              })
        }
    }

    onPublishedNamesChanged: root.rebuild()
    onManifestsChanged: root.rebuild()
    onPublishingLabelsChanged: root.rebuild()
    Component.onCompleted: root.rebuild()

    LogosTable {
        objectName: "namesTable"
        anchors.fill: parent
        model: namesModel
        rowHeight: 72
        emptyText: "No names yet"

        emptyDelegate: Component {
            LogosText {
                text: "No names yet. Use New name to give a dataset a name."
                color: Theme.palette.textMuted
                font.pixelSize: Theme.typography.secondaryText
            }
        }

        columns: [
            LogosTableColumn {
                title: "Name"
                role: "label"
                minWidth: 140
                preferredWidth: 160
                cellDelegate: Component {
                    Item {
                        LogosText {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: rowItem ? rowItem.label : ""
                            color: Theme.palette.accentOrange
                            font.pixelSize: Theme.typography.primaryText
                            font.weight: Theme.typography.weightBold
                            elide: Text.ElideRight
                        }
                    }
                }
            },
            LogosTableColumn {
                title: "Name key"
                role: "nameKey"
                minWidth: 200
                fillWidth: true
                cellDelegate: Component {
                    Item {
                        LogosText {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: rowItem ? rowItem.nameKey : ""
                            color: Theme.palette.textSecondary
                            font.pixelSize: Theme.typography.secondaryText
                            font.family: Theme.typography.mono
                            elide: Text.ElideMiddle

                            HoverHandler {
                                id: keyHover
                            }

                            LogosToolTip {
                                text: rowItem ? rowItem.nameKey : ""
                                visible: keyHover.hovered
                            }
                        }
                    }
                }
            },
            LogosTableColumn {
                title: "Points to"
                role: "filename"
                minWidth: 200
                fillWidth: true
                cellDelegate: Component {
                    Item {
                        HoverHandler {
                            id: targetHover
                        }

                        // Set once the node confirms the name: a test waits for this text.
                        LogosToolTip {
                            text: rowItem && !rowItem.publishing
                                  ? rowItem.label + " points to " + (rowItem.filename || rowItem.cid) : ""
                            visible: targetHover.hovered && text.length > 0
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            LogosText {
                                width: parent.width
                                text: !rowItem ? "" : rowItem.publishing ? "Publishing..."
                                                                         : rowItem.inNode ? rowItem.filename : "Not in this node"
                                color: rowItem && !rowItem.publishing && rowItem.inNode ? Theme.palette.text
                                                                                        : Theme.palette.textSecondary
                                font.pixelSize: Theme.typography.primaryText
                                elide: Text.ElideRight
                            }

                            LogosText {
                                width: parent.width
                                text: rowItem ? rowItem.cid : ""
                                color: Theme.palette.textSecondary
                                font.pixelSize: Theme.typography.secondaryText
                                elide: Text.ElideMiddle
                            }
                        }
                    }
                }
            },
            LogosTableColumn {
                title: "Actions"
                minWidth: root.actionsColumnWidth
                preferredWidth: root.actionsColumnWidth
                cellPadding: 0
                alignment: Qt.AlignHCenter | Qt.AlignVCenter
                cellDelegate: Component {
                    Item {
                        Rectangle {
                            anchors.centerIn: parent
                            color: Theme.palette.backgroundInset
                            radius: Theme.spacing.radiusLarge
                            implicitWidth: root.actionsColumnWidth
                            implicitHeight: namesActions.implicitHeight + Theme.spacing.small * 2

                            Row {
                                id: namesActions
                                anchors.centerIn: parent
                                spacing: Theme.spacing.medium

                                LogosCopyButton {
                                    enabled: rowItem && rowItem.nameKey.length > 0
                                    value: rowItem ? rowItem.nameKey : ""
                                    size: 40
                                    iconSize: 20
                                    background: IconButtonBackground {}
                                }

                                LogosIconButton {
                                    // One per row, so a test can pick the row by its label.
                                    objectName: "changeDatasetButton_" + (rowItem ? rowItem.label : "")
                                    iconSource: Qt.resolvedUrl("assets/arrow-left-right-line.svg")
                                    background: IconButtonBackground {}
                                    enabled: root.running && rowItem && !rowItem.publishing

                                    LogosToolTip {
                                        text: "Change dataset"
                                        visible: parent.hovered
                                    }

                                    onClicked: root.changeRequested(rowItem.label, rowItem.cid)
                                }

                                LogosIconButton {
                                    objectName: "unpublishButton_" + (rowItem ? rowItem.label : "")
                                    iconSource: Qt.resolvedUrl("assets/close-circle-line.svg")
                                    background: IconButtonBackground {}
                                    enabled: root.running && rowItem && !rowItem.publishing

                                    LogosToolTip {
                                        text: "Unpublish"
                                        visible: parent.hovered
                                    }

                                    onClicked: root.backend.unpublishName(rowItem.label)
                                }
                            }
                        }
                    }
                }
            }
        ]
    }
}

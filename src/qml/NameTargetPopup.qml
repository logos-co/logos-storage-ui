import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

// qmllint disable unqualified
// Pick the dataset a name points to: a new name, or an existing one moved to another dataset.
Popup {
    id: root

    objectName: "nameTargetPopup"

    property var backend: MockBackend
    property bool running: false
    property var manifests: []
    // { label: { cid, nameKey } }, kept by the table.
    property var publishedNames: ({})
    // Names whose publish runs in the node: { label: cid }.
    property var publishingLabels: ({})

    property string selectedCid: ""

    readonly property string label: labelInput.text
    // The dataset the label points to now, or "" for a new name.
    readonly property string currentCid: root.publishedNames[root.label] ? root.publishedNames[root.label].cid : ""
    // The label is already a name on another dataset: publishing moves it to the picked one.
    readonly property bool isMove: root.currentCid.length > 0 && root.selectedCid !== root.currentCid
    // A running publish can't be cancelled: the label waits until it ends.
    readonly property bool labelPublishing: !!root.publishingLabels[root.label]

    // The same popup for an existing name, with its label and its dataset already picked.
    function openForChange(label, cid) {
        labelInput.text = label
        root.selectedCid = cid
        root.open()
    }

    // cid: the dataset to start with, or "" to let the user pick it.
    function openForNew(cid) {
        labelInput.text = ""
        root.selectedCid = cid
        root.open()
    }

    // The other name of the dataset, or "": a dataset has one name at most.
    // A name still publishing counts too.
    function otherNameOf(cid) {
        for (var l in root.publishedNames) {
            if (root.publishedNames[l].cid === cid && l !== root.label)
                return l
        }
        for (var p in root.publishingLabels) {
            if (root.publishingLabels[p] === cid && p !== root.label)
                return p
        }
        return ""
    }

    // Called by the confirm button, and by a test: it can't fire a typed signal.
    function confirm() {
        root.backend.publishName(root.label, root.selectedCid)
        root.close()
    }

    modal: true
    // Takes the keyboard on open: Escape closes it.
    focus: true
    padding: 0
    closePolicy: Popup.CloseOnEscape
    anchors.centerIn: Overlay.overlay
    width: Math.min(560, Overlay.overlay ? Overlay.overlay.width - 48 : 560)

    background: Rectangle {
        color: Theme.palette.background
        border.color: Theme.palette.borderSecondary
        border.width: 1
        radius: Theme.spacing.radiusXlarge
    }

    contentItem: ColumnLayout {
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.spacing.large
            spacing: Theme.spacing.medium

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                LogosText {
                    text: "Publish under a name"
                    font.pixelSize: Theme.typography.titleText
                    color: Theme.palette.text
                }

                LogosText {
                    Layout.fillWidth: true
                    text: "Share this file under a name. You get a name key to share. It looks like a CID. You can link this name key to another file later: pick the file in the list below. You don't need to share the key again."
                    font.pixelSize: Theme.typography.secondaryText
                    color: Theme.palette.textSecondary
                    wrapMode: Text.WordWrap
                }
            }

            LogosIcon {
                Layout.alignment: Qt.AlignTop
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

        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.spacing.large
            spacing: Theme.spacing.medium

            LogosTextField {
                id: labelInput
                objectName: "nameLabelInput"
                Layout.fillWidth: true
                placeholderText: "Label"
            }

            // Picking one of the node's names moves it to the dataset.
            ColumnLayout {
                Layout.fillWidth: true
                visible: Object.keys(root.publishedNames).length > 0
                spacing: Theme.spacing.small

                LogosText {
                    text: "Or use one of your names:"
                    font.pixelSize: Theme.typography.secondaryText
                    color: Theme.palette.textSecondary
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Theme.spacing.small

                    Repeater {
                        model: Object.keys(root.publishedNames).sort()

                        LogosButton {
                            required property string modelData
                            objectName: "existingNameButton_" + modelData
                            radius: Theme.spacing.radiusLarge
                            text: modelData
                            compact: true
                            // The name in the label field shows as picked.
                            variant: modelData === root.label ? LogosButton.Variant.Primary
                                                              : LogosButton.Variant.Secondary
                            onClicked: labelInput.text = modelData
                        }
                    }
                }
            }

            LogosText {
                Layout.fillWidth: true
                visible: root.labelPublishing
                text: "The name " + root.label + " is being published. Wait until it ends."
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.warning
                wrapMode: Text.WordWrap
            }

            LogosText {
                Layout.fillWidth: true
                visible: root.isMove && !root.labelPublishing
                text: "The name " + root.label + " points to another dataset. Move points it to the dataset you pick. The name key stays the same."
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.warning
                wrapMode: Text.WordWrap
            }

            LogosText {
                Layout.fillWidth: true
                visible: datasetList.count === 0
                text: "No datasets yet. Upload a file first."
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.textMuted
            }

            ListView {
                id: datasetList
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 280)
                visible: count > 0
                clip: true
                spacing: 2
                model: root.manifests
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: datasetRow
                    required property var modelData
                    readonly property string otherName: root.otherNameOf(modelData.cid)
                    readonly property bool selectable: otherName.length === 0
                    readonly property bool selected: root.selectedCid === modelData.cid

                    width: ListView.view.width
                    height: 52
                    radius: Theme.spacing.radiusLarge
                    color: selected ? Theme.palette.backgroundInset
                                    : rowHover.hovered && selectable ? Theme.palette.backgroundSecondary : "transparent"
                    border.width: selected ? 1 : 0
                    border.color: Theme.palette.accentOrange

                    HoverHandler {
                        id: rowHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: datasetRow.selectable
                        cursorShape: datasetRow.selectable ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.selectedCid = datasetRow.modelData.cid
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacing.medium
                        anchors.rightMargin: Theme.spacing.medium
                        spacing: Theme.spacing.medium

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            LogosText {
                                Layout.fillWidth: true
                                text: datasetRow.modelData.filename || "Untitled"
                                color: datasetRow.selectable ? Theme.palette.text : Theme.palette.textMuted
                                font.pixelSize: Theme.typography.primaryText
                                elide: Text.ElideRight
                            }

                            LogosText {
                                Layout.fillWidth: true
                                text: datasetRow.modelData.cid
                                color: Theme.palette.textSecondary
                                font.pixelSize: Theme.typography.secondaryText
                                elide: Text.ElideMiddle
                            }
                        }

                        LogosText {
                            visible: !datasetRow.selectable
                            text: "named " + datasetRow.otherName
                            color: Theme.palette.textMuted
                            font.pixelSize: Theme.typography.secondaryText
                        }

                        LogosText {
                            visible: datasetRow.modelData.cid === root.currentCid
                            text: "now"
                            color: Theme.palette.accentOrange
                            font.pixelSize: Theme.typography.secondaryText
                        }
                    }
                }
            }

            LogosButton {
                objectName: "nameTargetConfirmButton"
                Layout.alignment: Qt.AlignRight
                radius: Theme.spacing.radiusLarge
                text: root.isMove ? "Move" : "Publish"
                implicitWidth: 120
                implicitHeight: 42
                enabled: root.running && root.label.length > 0 && !root.labelPublishing && root.selectedCid.length > 0
                         && root.selectedCid !== root.currentCid && root.otherNameOf(root.selectedCid).length === 0
                onClicked: root.confirm()
            }
        }
    }
}

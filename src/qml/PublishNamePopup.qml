import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

// qmllint disable unqualified
// Share a dataset under a name, or stop sharing it.
Popup {
    id: root

    objectName: "publishNamePopup"

    property var backend: MockBackend
    property bool running: false

    // The dataset of the row the popup was opened from.
    property string cid: ""
    property string filename: ""
    // The name the dataset is published under, empty when it has none.
    property string label: ""
    property string nameKey: ""

    // Every name the node publishes, by label: { label: { cid, nameKey } }.
    property var publishedNames: ({})

    // Cids whose publish runs in the node: kept by the table, so it survives
    // closing the popup.
    property var publishingCids: ({})
    // Set on click, until the backend confirms the publish started or ended.
    property bool requested: false
    readonly property bool publishing: root.requested || !!root.publishingCids[root.cid]
    property string error: ""

    // A dataset has one name at most: unpublish it to change it.
    readonly property bool hasName: root.label.length > 0
    // The label already names another dataset: publishing moves the name here.
    readonly property bool nameTaken: {
        var entry = root.publishedNames[labelInput.text]
        return !!entry && entry.cid !== root.cid
    }

    // A publish in flight gets no event once the node stops.
    onRunningChanged: {
        if (!root.running)
            root.requested = false
    }

    function openFor(cid, filename, published) {
        root.cid = cid
        root.filename = filename
        root.label = published ? published.label : ""
        root.nameKey = published ? published.nameKey : ""
        root.requested = false
        root.error = ""
        labelInput.text = root.label
        root.open()
    }

    modal: true
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

    Connections {
        target: root.backend
        ignoreUnknownSignals: true

        function onNamePublishStarted(label, cid) {
            if (cid === root.cid)
                root.requested = false
        }

        function onNamePublished(label, cid, nameKey) {
            if (cid !== root.cid)
                return
            root.requested = false
            root.label = label
            root.nameKey = nameKey
        }

        function onNamePublishFailed(label, cid, error) {
            if (cid !== root.cid)
                return
            root.requested = false
            root.error = error
        }

        function onNameUnpublished(label) {
            if (label !== root.label)
                return
            root.label = ""
            root.nameKey = ""
        }
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
                    text: root.filename || root.cid
                    font.pixelSize: Theme.typography.secondaryText
                    color: Theme.palette.textSecondary
                    elide: Text.ElideMiddle
                }
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

        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.spacing.large
            spacing: Theme.spacing.medium

            LogosText {
                Layout.fillWidth: true
                text: "Others fetch this dataset with the name key. A dataset has one name, and a name points to one dataset."
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.textSecondary
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacing.medium

                LogosTextField {
                    id: labelInput
                    objectName: "nameLabelInput"
                    Layout.fillWidth: true
                    placeholderText: "Label"
                    enabled: root.running && !root.publishing
                }

                LogosButton {
                    objectName: "publishNameConfirmButton"
                    radius: Theme.spacing.radiusLarge
                    text: root.publishing ? "Publishing..." : root.nameTaken ? "Move" : "Publish"
                    implicitWidth: 120
                    implicitHeight: 42
                    enabled: root.running && !root.publishing && labelInput.text.length > 0
                             && !root.hasName
                    onClicked: {
                        root.error = ""
                        root.requested = true
                        root.backend.publishName(labelInput.text, root.cid)
                    }
                }
            }

            LogosText {
                Layout.fillWidth: true
                visible: root.hasName && labelInput.text !== root.label
                text: "This dataset is already published as " + root.label + ". Unpublish it first to use another label."
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.warning
                wrapMode: Text.WordWrap
            }

            LogosText {
                Layout.fillWidth: true
                visible: root.nameTaken && !root.hasName
                text: "The name " + labelInput.text + " points to another dataset. Move points it to this dataset. The name key stays the same."
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.warning
                wrapMode: Text.WordWrap
            }

            LogosText {
                Layout.fillWidth: true
                visible: root.error.length > 0
                text: root.error
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.error
                wrapMode: Text.WordWrap
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: root.nameKey.length > 0
                spacing: Theme.spacing.small

                LogosText {
                    text: "Published as " + root.label + ". Share this name key:"
                    font.pixelSize: Theme.typography.secondaryText
                    color: Theme.palette.text
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing.medium

                    LogosText {
                        objectName: "nameKeyText"
                        Layout.fillWidth: true
                        text: root.nameKey
                        font.pixelSize: Theme.typography.secondaryText
                        color: Theme.palette.textSecondary
                        elide: Text.ElideMiddle
                    }

                    LogosCopyButton {
                        value: root.nameKey
                        size: 40
                        iconSize: 20
                        background: IconButtonBackground {}
                    }

                    LogosButton {
                        objectName: "unpublishNameButton"
                        radius: Theme.spacing.radiusLarge
                        text: "Unpublish"
                        implicitWidth: 120
                        implicitHeight: 42
                        variant: LogosButton.Variant.Secondary
                        enabled: root.running && !root.publishing
                        onClicked: root.backend.unpublishName(root.label)
                    }
                }
            }
        }
    }
}

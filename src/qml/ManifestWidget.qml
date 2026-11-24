import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

LogosFrame {
    id: root

    backgroundColor: Theme.palette.backgroundSecondary
    borderColor: "transparent"
    radius: Theme.spacing.radiusLarge

    implicitWidth: 300
    implicitHeight: 120

    property var backend: MockBackend
    property bool running: false
    property bool enabled: true
    property bool isPrivate: false
    // Name keys the node is resolving in the DHT.
    property var resolving: ({})

    function setResolving(nameKey, on) {
        var r = Object.assign({}, root.resolving)
        if (on) {
            r[nameKey] = true
        } else {
            delete r[nameKey]
        }
        root.resolving = r
    }

    Connections {
        target: root.backend
        ignoreUnknownSignals: true

        function onNameResolveStarted(nameKey) {
            root.setResolving(nameKey, true)
        }

        function onNameResolved(nameKey, cid) {
            root.setResolving(nameKey, false)
        }

        function onNameResolveFailed(nameKey, error) {
            root.setResolving(nameKey, false)
        }
    }

    RowLayout {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomTitle.top
        anchors.bottomMargin: Theme.spacing.small
        spacing: Theme.spacing.medium

        LogosTextField {
            id: cidInput
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            placeholderText: "CID or name key"
            enabled: root.running
            background: CardFieldBackground {}
        }

        LogosButton {
            radius: Theme.spacing.radiusLarge
            text: "Fetch"
            implicitWidth: 100
            implicitHeight: 42
            variant: LogosButton.Variant.Secondary
            background: CardButtonBackground {}
            Layout.alignment: Qt.AlignTop
            // The table shows the name keys being resolved: only the same key waits.
            enabled: cidInput.text.length > 0 && root.running && root.enabled
                     && !root.resolving[cidInput.text.trim()]
            onClicked: {
                root.backend.fetchManifestOrName(cidInput.text, root.isPrivate && root.backend.mixRunning)
                cidInput.text = ""
            }
        }
    }

    BottomTitle {
        id: bottomTitle
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        title: "Fetch Manifest"
        color: Theme.palette.textSecondary
        hasSeparator: false
    }

    LogosSwitch {
        objectName: "fetchPrivateSwitch"
        anchors.right: parent.right
        y: bottomTitle.y + bottomTitle.labelCenterY - height / 2
        text: "Private"
        // Mix carries private transfers.
        enabled: root.backend.mixRunning
        checked: root.isPrivate && root.backend.mixRunning
        onToggled: root.isPrivate = checked
    }
}

import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

Card {
    id: root

    implicitWidth: 300
    implicitHeight: 120

    property var backend: MockBackend
    property bool running: false
    property bool enabled: true

    RowLayout {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomTitle.top
        anchors.bottomMargin: Theme.spacing.small
        spacing: Theme.spacing.medium
        opacity: root.running ? 1.0 : 0.4

        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        LogosStorageTextField {
            id: cidInput
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            placeholderText: "CID"
            isValid: true
            enabled: root.running
        }

        LogosStorageButton {
            text: "Fetch"
            implicitWidth: 100
            implicitHeight: 42
            variant: "secondary"
            Layout.alignment: Qt.AlignTop
            enabled: cidInput.text.length > 0 && root.running && root.enabled
            onClicked: {
                root.enabled = false
                root.backend.downloadManifest(cidInput.text)
                root.enabled = true
                cidInput.clear()
            }
        }
    }

    BottomTitle {
        id: bottomTitle
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        title: "Fetch Manifest"
    }
}

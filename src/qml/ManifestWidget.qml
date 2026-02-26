import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

Card {
    id: root

    implicitWidth: 300
    implicitHeight: 120

    property var backend: MockBackend

    RowLayout {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomTitle.top
        anchors.bottomMargin: Theme.spacing.small
        spacing: Theme.spacing.medium

        LogosStorageTextField {
            id: cidInput
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            placeholderText: "CID"
            isValid: true
        }

        LogosStorageButton {
            text: "Fetch"
            implicitWidth: 100
            implicitHeight: 42
            variant: "secondary"
            Layout.alignment: Qt.AlignTop
            enabled: cidInput.text.length > 0
            onClicked: {
                root.backend.downloadManifest(cidInput.text)
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

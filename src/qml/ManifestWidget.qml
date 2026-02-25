import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

Card {
    id: root

    implicitWidth: 300
    implicitHeight: 120

    property var backend: MockBackend

    LogosText {
        id: footerLabel
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        text: "Fetch Manifest"
        font.pixelSize: Theme.typography.titleText * 0.8
        color: Theme.palette.text
    }

    Rectangle {
        id: footerSeparator
        anchors.bottom: footerLabel.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: Theme.spacing.medium + 2
        height: 1
        color: Theme.palette.borderSecondary
    }

    RowLayout {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: footerSeparator.top
        anchors.bottomMargin: Theme.spacing.small
        spacing: Theme.spacing.medium

        LogosTextField {
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
}

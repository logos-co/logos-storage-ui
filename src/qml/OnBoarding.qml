import QtQuick
import QtQuick.Dialogs
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

LogosStorageLayout {
    id: root

    property var backend: mockBackend

    signal completed(bool enabled)

    ColumnLayout {
        spacing: Theme.spacing.medium
        Layout.fillWidth: true
        anchors.centerIn: parent

        LogosText {
            id: titleText
            font.pixelSize: Theme.typography.titleText
            text: "Welcome to Logos Storage"
            Layout.alignment: Qt.AlignCenter
        }

        LogosText {
            id: questionText
            font.pixelSize: Theme.typography.titleText
            text: "Is UPnP enabled on your router ?"
            Layout.alignment: Qt.AlignCenter
        }

        LogosText {
            id: questionDescriptionText
            font.pixelSize: Theme.typography.primaryText
            text: "UPnP simplifies configuration by handling port forwarding automatically."
            Layout.alignment: Qt.AlignCenter
        }

        RowLayout {
            spacing: Theme.spacing.medium
            Layout.alignment: Qt.AlignCenter

            LogosStorageButton {
                text: "No / I don't know"
                onClicked: root.completed(false)
            }

            LogosStorageButton {
                text: "Yes, I use UPnP"
                onClicked: function () {
                    console.info("enableUpnpConfig")
                    root.backend.enableUpnpConfig()
                    root.completed(true)
                }
            }
        }
    }

    QtObject {
        id: mockBackend

        function enableUpnpConfig() {}
    }
}

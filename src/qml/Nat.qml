import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

LogosStorageLayout {
    id: root

    signal completed(bool enabled)

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Theme.spacing.medium
        width: 400

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
                onClicked: root.completed(true)
            }
        }
    }
}

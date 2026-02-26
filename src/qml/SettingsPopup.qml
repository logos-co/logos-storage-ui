import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

Popup {
    id: root

    property var backend: MockBackend

    modal: true
    width: 520
    height: 400
    anchors.centerIn: Overlay.overlay
    padding: 24
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    // Reload the live config every time the popup opens
    onOpened: jsonEditor.load(root.backend.configJson() || "{}")

    background: Rectangle {
        color: Theme.palette.backgroundSecondary
        border.color: Theme.palette.borderSecondary
        border.width: 1
        radius: 14
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacing.small

        LogosText {
            text: "Configuration"
            font.pixelSize: Theme.typography.titleText
            Layout.alignment: Qt.AlignHCenter
        }

        LogosText {
            text: "Edit the JSON configuration below, then click Save."
            font.pixelSize: Theme.typography.primaryText
            color: Theme.palette.textSecondary
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        JsonEditor {
            id: jsonEditor
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spacing.medium

            LogosStorageButton {
                text: "Cancel"
                onClicked: root.close()
            }

            LogosStorageButton {
                text: "Save"
                variant: "primary"
                enabled: jsonEditor.isValid
                onClicked: {
                    root.backend.saveUserConfig(jsonEditor.text)
                    root.close()
                }
            }
        }
    }
}

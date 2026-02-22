import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

LogosStorageLayout {
    id: root

    property var backend: null

    signal back
    signal completed

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40
        spacing: Theme.spacing.medium

        LogosText {
            text: "Advanced Configuration"
            font.pixelSize: Theme.typography.titleText
            Layout.alignment: Qt.AlignHCenter
        }

        LogosText {
            text: "Edit the JSON configuration below, then click Validate."
            font.pixelSize: Theme.typography.primaryText
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        JsonEditor {
            id: jsonEditor
            Layout.fillWidth: true
            Layout.fillHeight: true
            Component.onCompleted: load(root.backend.configJson() || "{}")
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spacing.medium

            LogosStorageButton {
                text: "Back"
                onClicked: root.back()
            }

            LogosStorageButton {
                text: "Validate"
                variant: "success"
                enabled: jsonEditor.isValid
                onClicked: {
                    root.backend.saveUserConfig(jsonEditor.text)
                    root.completed()
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

OnBoardingLayout {
    id: root

    property var backend: MockBackend

    signal back
    signal completed

    OnBoardingContainer {
        spacing: Theme.spacing.medium

        Column {
            Layout.fillHeight: false

            LogosText {
                text: "Advanced Configuration"
                font.pixelSize: Theme.typography.titleText
                font.weight: Font.Bold
            }

            LogosText {
                text: "Edit the JSON configuration below, than click Validate. "
                font.pixelSize: Theme.typography.primaryText * 1.8
            }
        }

        JsonEditor {
            id: jsonEditor
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: 250
            Component.onCompleted: load(root.backend.configJson() || "{}")
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.medium

            LogosStorageButton {
                text: "Back"
                onClicked: root.back()
                iconSource: "assets/arrow-left.png"
                iconPosition: "left"
            }

            Item {
                Layout.fillWidth: true
            }

            LogosStorageButton {
                text: "Validate"
                variant: "primary"
                enabled: jsonEditor.isValid
                iconSource: "assets/arrow-right.png"
                iconPosition: "right"
                onClicked: {
                    root.backend.saveUserConfig(jsonEditor.text)
                    root.completed()
                }
            }
        }
    }
}

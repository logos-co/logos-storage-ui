import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls
import Logos.Icons

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
                font.pixelSize: Theme.typography.panelTitleText
            }
        }

        JsonEditor {
            id: jsonEditor
            objectName: "configEditor"
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: 250
            Component.onCompleted: jsonEditor.load(root.backend.defaultConfigJson || "{}")
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.medium

            LogosButton {
                radius: Theme.spacing.radiusLarge
                text: "Back"
                onClicked: root.back()
                leadingIcon.source: LogosIcons.arrowLeft
                leadingIcon.color: Theme.palette.text
                leadingIcon.brightness: 1.0
            }

            Item {
                Layout.fillWidth: true
            }

            LogosButton {
                radius: Theme.spacing.radiusLarge
                text: "Validate"
                variant: LogosButton.Variant.Primary
                enabled: jsonEditor.isValid
                trailingIcon.source: LogosIcons.arrowRight
                trailingIcon.color: Theme.palette.text
                trailingIcon.brightness: 1.0
                                onClicked: {
                    root.backend.saveUserConfig(jsonEditor.text)
                    root.completed()
                }
            }
        }
    }
}

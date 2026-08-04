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
        backend: root.backend
        spacing: Theme.spacing.medium

        Column {
            Layout.fillHeight: false

            LogosText {
                text: "Advanced Configuration"
                font.pixelSize: Theme.typography.titleText
                font.weight: Font.Bold
            }

            LogosText {
                text: "Review the node configuration below, then click Validate."
                font.pixelSize: Theme.typography.panelTitleText
            }
        }

        SettingsForm {
            id: form
            objectName: "configEditor"

            Layout.fillWidth: true
            // Bounded like the editor it replaces: the container is centred and
            // has no height of its own, so filling would push past the frame.
            Layout.fillHeight: false
            Layout.preferredHeight: 350

            backend: root.backend
            onboarding: true

            Component.onCompleted: form.load()
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
                enabled: form.valid
                trailingIcon.source: LogosIcons.arrowRight
                trailingIcon.color: Theme.palette.text
                trailingIcon.brightness: 1.0
                onClicked: {
                    form.save()
                    root.completed()
                }
            }
        }
    }
}

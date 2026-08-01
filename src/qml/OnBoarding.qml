import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls
import Logos.Icons

OnBoardingLayout {
    id: root

    property var backend: MockBackend

    signal back
    signal completed(bool upnpEnabled)

    property int selectedMode: -1

    OnBoardingContainer {

        OnBoardingProgress {
            Layout.fillWidth: true
            currentStep: 0
            Layout.topMargin: Theme.spacing.small
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacing.small

            RowLayout {
                Layout.fillWidth: true

                LogosText {
                    text: "Network Configuration"
                    font.pixelSize: Theme.typography.titleText
                    font.weight: Font.Bold
                }

                Item {
                    Layout.fillWidth: true
                }

                LogosText {
                    text: "1 / 5"
                    font.pixelSize: Theme.typography.primaryText
                    color: Theme.palette.primary
                    font.family: Theme.typography.mono
                }
            }

            LogosText {
                text: "How would you like to set up your node?"
                font.pixelSize: Theme.typography.panelTitleText
            }
        }

        Item {
            Layout.preferredHeight: Theme.spacing.medium
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.medium

            OnBoardingCard {
                objectName: "upnpCard"
                Layout.fillWidth: true
                title: "UPnP"
                description: "Atuomatic port forwarding via UPnP Router."
                icon: UpnpIcon {}
                selected: root.selectedMode == 0
                onCardSelected: root.selectedMode = 0
            }

            OnBoardingCard {
                objectName: "portForwardingCard"
                Layout.fillWidth: true
                title: "Port Fowarding"
                description: "Atuomatic port Manual TCP port configuration on your Router. via UPnP Router."
                icon: PortIcon {}
                selected: root.selectedMode == 1
                onCardSelected: root.selectedMode = 1
            }
        }

        Item {
            Layout.preferredHeight: Theme.spacing.small
        }

        RowLayout {
            spacing: Theme.spacing.medium

            LogosButton {
                radius: Theme.spacing.radiusLarge
                text: "Back"
                leadingIcon.source: LogosIcons.arrowLeft
                leadingIcon.color: Theme.palette.text
                leadingIcon.brightness: 1.0
                                onClicked: root.back()
            }

            Item {
                Layout.fillWidth: true
            }

            LogosButton {
                radius: Theme.spacing.radiusLarge
                text: "Continue"
                variant: LogosButton.Variant.Primary
                trailingIcon.source: LogosIcons.arrowRight
                trailingIcon.color: Theme.palette.text
                trailingIcon.brightness: 1.0
                                enabled: root.selectedMode !== -1
                onClicked: {
                    if (root.selectedMode === 0) {
                        root.backend.enableUpnpConfig()
                    }
                    root.completed(root.selectedMode === 0)
                }
            }
        }
    }
}

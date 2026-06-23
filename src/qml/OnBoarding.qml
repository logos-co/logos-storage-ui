import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

OnBoardingLayout {
    id: root

    property var backend: MockBackend

    signal back
    signal completed(bool upnpEnabled, bool mixEnabled)

    property int selectedMode: -1
    property bool mixEnabled: false

    OnBoardingContainer {

        OnBoardingProgress {
            Layout.fillWidth: true
            currentStep: 0
            Layout.topMargin: Theme.spacing.small
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 10

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
                    font.family: "monospace"
                }
            }

            LogosText {
                text: "How would you like to set up your node?"
                font.pixelSize: Theme.typography.primaryText * 1.8
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

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.tiny

            LogosStorageSwitch {
                text: "Enable Mix"
                checked: root.mixEnabled
                onToggled: root.mixEnabled = checked
            }

            LogosText {
                text: "Use the Mix privacy network for DHT queries. You can change this later in the app."
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.textSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        Item {
            Layout.preferredHeight: Theme.spacing.small
        }

        RowLayout {
            spacing: Theme.spacing.medium

            LogosStorageButton {
                text: "Back"
                iconSource: "assets/arrow-left.png"
                iconPosition: "left"
                onClicked: root.back()
            }

            Item {
                Layout.fillWidth: true
            }

            LogosStorageButton {
                text: "Continue"
                variant: "primary"
                iconSource: "assets/arrow-right.png"
                iconPosition: "right"
                enabled: root.selectedMode !== -1
                onClicked: {
                    if (root.selectedMode === 0) {
                        root.backend.enableUpnpConfig()
                    }
                    root.completed(root.selectedMode === 0, root.mixEnabled)
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

OnBoardingLayout {
    id: root

    signal completed(bool isGuide, bool mixEnabled)

    property int selectedMode: 0
    property bool mixEnabled: false

    OnBoardingContainer {

        Column {
            LogosText {
                text: "Network Configuration"
                font.pixelSize: Theme.typography.titleText
                font.weight: Font.Bold
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
                objectName: "guidedCard"
                Layout.fillWidth: true
                title: "Guided"
                description: "Step-by-step guided wizard to setup your node with the appropriate settings."
                icon: GuideIcon {}
                selected: root.selectedMode == 0
                onCardSelected: root.selectedMode = 0
            }

            OnBoardingCard {
                objectName: "advancedCard"
                Layout.fillWidth: true
                title: "Advanced"
                description: "Manual JSON configuration for experienced users."
                icon: AdvancedIcon {}
                selected: root.selectedMode == 1
                onCardSelected: root.selectedMode = 1
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacing.small
            spacing: Theme.spacing.tiny

            LogosStorageSwitch {
                text: "Enable Mix"
                checked: root.mixEnabled
                onToggled: root.mixEnabled = checked
            }

            LogosText {
                text: "Routes DHT queries through the Mix privacy network. You can also enable it later in Settings."
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.textMuted
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true

                LogosText {
                    text: "Logos Storage is a decentralised data storage protocol, created so the world community can preserve its most important knowledge without risk of censorship."
                    font.pixelSize: Theme.typography.secondaryText
                    font.family: "monospace"
                    color: Theme.palette.textMuted
                    Layout.preferredWidth: 400
                    wrapMode: Text.WordWrap
                }

                Item {
                    Layout.fillWidth: true
                }

                LogosText {
                    text: "Legal Disclaimer"
                    font.pixelSize: Theme.typography.secondaryText
                    color: Theme.palette.primary
                    font.family: "monospace"
                }
            }

            LogosStorageButton {
                text: "Continue"
                variant: "primary"
                iconSource: "assets/arrow-right.png"
                iconPosition: "right"
                onClicked: root.completed(root.selectedMode === 0, root.mixEnabled)
            }
        }
    }
}

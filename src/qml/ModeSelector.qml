import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls
import Logos.Icons

OnBoardingLayout {
    id: root

    signal completed(bool isGuide)

    property var backend: MockBackend
    property int selectedMode: 0

    // The guided path writes defaultConfigJson, which stays empty until the
    // replica has synced.
    readonly property bool backendReady: !!(root.backend && root.backend.defaultConfigJson)

    OnBoardingContainer {
        backend: root.backend

        Column {
            LogosText {
                text: "Network Configuration"
                font.pixelSize: Theme.typography.titleText
                font.weight: Font.Bold
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

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true

                LogosText {
                    text: "Logos Storage is a decentralised data storage protocol, created so the world community can preserve its most important knowledge without risk of censorship."
                    font.pixelSize: Theme.typography.secondaryText
                    font.family: Theme.typography.mono
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
                    font.family: Theme.typography.mono
                }
            }

            LogosButton {
                radius: Theme.spacing.radiusLarge
                enabled: root.backendReady
                text: "Continue"
                variant: LogosButton.Variant.Primary
                trailingIcon.source: LogosIcons.arrowRight
                trailingIcon.color: Theme.palette.text
                trailingIcon.brightness: 1.0
                onClicked: root.completed(root.selectedMode === 0)
            }
        }
    }
}

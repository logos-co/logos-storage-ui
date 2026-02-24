import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

OnBoardingLayout {
    id: root
    color: "#999999"

    signal completed(bool isGuide)

    property int selectedMode: 0

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Theme.spacing.medium
        width: 830

        //anchors.fill: parent
        OnBoardingHeader {
            Layout.fillWidth: true
            step: 1
        }

        Column {
            LogosText {
                text: "Network Configuration"
                font.pixelSize: Theme.typography.titleText
                font.weight: Font.Bold
            }

            LogosText {
                text: "How would you like to set up your node?"
                font.pixelSize: Theme.typography.primaryText
            }
        }

        Item {
            Layout.preferredHeight: Theme.spacing.medium
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.medium

            OnBoardingCard {
                Layout.fillWidth: true
                title: "Guided"
                description: "Step-by-step guided wizard to setup your node with the appropriate settings."
                icon: GuideIcon {
                    dotColor: Theme.palette.text
                }
                selected: root.selectedMode == 0
                onCardSelected: root.selectedMode = 0
            }

            OnBoardingCard {
                Layout.fillWidth: true
                title: "Advanced"
                description: "Manual JSON configuration for experienced users."
                icon: AdvancedIcon {
                    dotColor: Theme.palette.text
                }
                selected: root.selectedMode == 1
                onCardSelected: root.selectedMode = 1
            }
        }

        LogosStorageButton {
            text: "Continue"
            enabled: root.selectedMode !== -1
            onClicked: root.completed(root.selectedMode === 0)
            Layout.alignment: Qt.AlignHCenter
        }
    }
}

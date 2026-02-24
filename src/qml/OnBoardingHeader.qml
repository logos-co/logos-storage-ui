import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

ColumnLayout {
    id: root

    property int step: 1

    Layout.fillWidth: true
    spacing: Theme.spacing.small

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: false
        Layout.preferredHeight: 10
        spacing: Theme.spacing.small

        LogosText {
            text: "Logos Storage"
            font.pixelSize: Theme.typography.primaryText * 1.2
            Layout.alignment: Qt.AlignTop
        }

        Item {
            Layout.fillWidth: true
        }

        Column {
            Layout.alignment: Qt.AlignTop
            spacing: Theme.spacing.tiny

            Image {
                source: "assets/alpha.png"
            }

            LogosText {
                text: "V. 0.1.3"
                font.pixelSize: Theme.typography.secondaryText
                font.family: "monospace"
                color: Theme.palette.textMuted
            }
        }
    }

    RowLayout {
        Layout.fillHeight: false
        spacing: Theme.spacing.small

        LogosText {
            text: "Vault."
            font.pixelSize: Theme.typography.titleText
            color: Theme.palette.primary
            font.weight: Font.Bold
        }

        Image {
            source: "assets/badge_alpha.png"
        }
    }

    OnBoardingProgress {
        Layout.fillWidth: true
        currentStep: root.step
        Layout.topMargin: Theme.spacing.small
    }
}

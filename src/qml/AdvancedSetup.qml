import QtQuick
import QtQuick.Layouts
import QtCore
import Logos.Theme
import Logos.Controls

OnBoardingLayout {
    id: root

    property var backend: MockBackend

    signal back
    signal completed

    Settings {
        id: settings
        category: "Storage"

        property string downloadFolderPath: {
            const p = StandardPaths.standardLocations(StandardPaths.HomeLocation)[0].toString()
            return p.startsWith("file://") ? p : "file://" + p
        }
    }

    OnBoardingContainer {
        spacing: Theme.spacing.medium

        OnBoardingProgress {
            Layout.fillWidth: true
            currentStep: 1
            Layout.topMargin: Theme.spacing.small
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacing.small

            RowLayout {
                Layout.fillWidth: true

                LogosText {
                    text: "Advanced Configuration"
                    font.pixelSize: Theme.typography.titleText
                    font.weight: Font.Bold
                }

                Item {
                    Layout.fillWidth: true
                }

                LogosText {
                    text: "2 / 2"
                    font.pixelSize: Theme.typography.primaryText
                    color: Theme.palette.primary
                    font.family: "monospace"
                }
            }

            LogosText {
                text: "Review the node settings, then click Continue."
                font.pixelSize: Theme.typography.panelTitleText
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 380
            radius: Theme.spacing.radiusLarge
            color: Theme.palette.backgroundSecondary
            border.color: Theme.palette.borderInteractive
            border.width: 1

            SettingsForm {
                id: form
                objectName: "onboardingSettings"
                anchors.fill: parent
                anchors.margins: Theme.spacing.medium
                backend: root.backend
                showRestartOnboarding: false
                downloadFolderPath: settings.downloadFolderPath
                onFolderPathChanged: function (path) {
                    settings.downloadFolderPath = path
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.medium

            LogosButton {
                radius: Theme.spacing.radiusLarge
                text: "Back"
                onClicked: root.back()
                leadingIcon.source: Qt.resolvedUrl("assets/arrow-left-line.svg")
            }

            Item {
                Layout.fillWidth: true
            }

            LogosButton {
                radius: Theme.spacing.radiusLarge
                text: "Continue"
                variant: LogosButton.Variant.Primary
                trailingIcon.source: Qt.resolvedUrl("assets/arrow-right-line.svg")
                onClicked: {
                    form.save()
                    root.completed()
                }
            }
        }
    }
}

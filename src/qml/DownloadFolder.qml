import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Window
import Logos.Theme
import Logos.Controls
import Logos.Icons
import QtCore

OnBoardingLayout {
    id: root

    property var backend: MockBackend
    property url downloadFolder: {
        const p = StandardPaths.standardLocations(
                    StandardPaths.HomeLocation)[0].toString()
        return p.startsWith("file://") ? p : "file://" + p
    }
    readonly property string downloadFolderPath: downloadFolder.toString(
                                                     ).replace(/^file:\/{2,2}/,
                                                               "")
    signal back
    signal next

    Settings {
        id: settings
        category: "Storage"

        property string downloadFolderPath: root.downloadFolder.toString()
    }

    OnBoardingContainer {
        backend: root.backend
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
                    text: "Select Drives"
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
                    font.family: Theme.typography.mono
                }
            }

            LogosText {
                text: "Decide which drive you wish to use alongside your storage node."
                font.pixelSize: Theme.typography.panelTitleText
            }
        }

        Rectangle {
            property bool selected: false
            property Component icon

            Layout.fillWidth: true
            Layout.preferredHeight: 230
            radius: Theme.spacing.radiusLarge
            color: Theme.palette.backgroundSecondary
            border.color: selected ? Theme.palette.primary : Theme.palette.borderInteractive
            border.width: 1

            ColumnLayout {
                anchors.fill: parent

                DownloadIcon {
                    Layout.topMargin: Theme.spacing.large
                    Layout.leftMargin: Theme.spacing.medium
                }

                Item {
                    Layout.fillHeight: true
                }

                LogosText {
                    text: "Downloads folder"
                    font.pixelSize: Theme.typography.subtitleText
                    Layout.leftMargin: Theme.spacing.medium
                    Layout.bottomMargin: Theme.spacing.tiny
                }

                FolderDialog {
                    id: uploadDialog
                    onAccepted: root.downloadFolder = selectedFolder
                    currentFolder: root.downloadFolder
                }

                LogosTextField {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.spacing.medium
                    Layout.rightMargin: Theme.spacing.medium
                    Layout.bottomMargin: Theme.spacing.large
                    readOnly: true
                    text: root.downloadFolderPath
                    background: CardFieldBackground {}

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: uploadDialog.open()
                    }
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spacing.small

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
                text: "Continue"
                objectName: "downloadFolderContinue"
                trailingIcon.source: LogosIcons.arrowRight
                trailingIcon.color: Theme.palette.text
                trailingIcon.brightness: 1.0
                variant: LogosButton.Variant.Primary
                onClicked: {
                    settings.downloadFolderPath = root.downloadFolder.toString()
                    root.next()
                }
            }
        }
    }
}

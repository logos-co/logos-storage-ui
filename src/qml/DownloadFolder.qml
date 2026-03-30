import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Window
import Logos.Theme
import Logos.Controls
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
        spacing: Theme.spacing.medium

        OnBoardingProgress {
            Layout.fillWidth: true
            currentStep: 3
            Layout.topMargin: Theme.spacing.small
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 10

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
                    text: "4 / 5"
                    font.pixelSize: Theme.typography.primaryText
                    color: Theme.palette.primary
                    font.family: "monospace"
                }
            }

            LogosText {
                text: "Decide which drive you wish to use alongside your storage node."
                font.pixelSize: Theme.typography.primaryText * 1.8
            }
        }

        Rectangle {
            property bool selected: false
            property Component icon

            Layout.fillWidth: true
            Layout.preferredHeight: 230
            radius: Theme.spacing.radiusLarge
            color: Theme.palette.backgroundSecondary
            border.color: selected ? Theme.palette.primary : Theme.palette.textMuted
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
                    font.pixelSize: Theme.typography.primaryText * 1.2
                    Layout.leftMargin: Theme.spacing.medium
                    Layout.bottomMargin: Theme.spacing.tiny
                }

                FolderDialog {
                    id: uploadDialog
                    onAccepted: root.downloadFolder = selectedFolder
                    currentFolder: root.downloadFolder
                }

                LogosStorageTextField {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.spacing.medium
                    Layout.rightMargin: Theme.spacing.medium
                    Layout.bottomMargin: Theme.spacing.large
                    readOnly: true
                    text: root.downloadFolderPath

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

            LogosStorageButton {
                text: "Back"
                onClicked: root.back()
                iconSource: "assets/arrow-left.png"
                iconPosition: "left"
            }

            Item {
                Layout.fillWidth: true
            }

            LogosStorageButton {
                text: "Continue"
                iconSource: "assets/arrow-right.png"
                iconPosition: "right"
                variant: "primary"
                onClicked: {
                    settings.downloadFolderPath = root.downloadFolder.toString()
                    root.next()
                }
            }
        }
    }
}

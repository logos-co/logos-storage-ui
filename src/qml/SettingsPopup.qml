import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtCore
import Logos.Theme
import Logos.Controls

Popup {
    id: root

    property var backend: MockBackend
    property string downloadFolderPath: ""

    signal folderPathChanged(string path)

    readonly property string displayFolderPath: downloadFolderPath.replace(
                                                    /^file:\/{2,2}/, "")

    FolderDialog {
        id: folderDialog
        currentFolder: root.downloadFolderPath
        onAccepted: {
            root.downloadFolderPath = selectedFolder.toString()
            root.folderPathChanged(root.downloadFolderPath)
        }
    }

    modal: true
    width: 520
    height: 480
    anchors.centerIn: Overlay.overlay
    padding: 24
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    // Reload the live config every time the popup opens
    onOpened: jsonEditor.load(root.backend.getUserConfig() || "{}")

    background: Rectangle {
        color: Theme.palette.backgroundSecondary
        border.color: Theme.palette.borderSecondary
        border.width: 1
        radius: 14
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacing.small

        LogosText {
            text: "Configuration"
            font.pixelSize: Theme.typography.titleText
            Layout.alignment: Qt.AlignHCenter
        }

        LogosText {
            text: "Edit the JSON configuration below, then click Save."
            font.pixelSize: Theme.typography.primaryText
            color: Theme.palette.textSecondary
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        JsonEditor {
            id: jsonEditor
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.tiny

            LogosText {
                text: "Download folder"
                font.pixelSize: Theme.typography.primaryText
                color: Theme.palette.textSecondary
            }

            LogosStorageTextField {
                Layout.fillWidth: true
                Layout.bottomMargin: Theme.spacing.large
                readOnly: true
                text: root.displayFolderPath
                rightPadding: Theme.spacing.large + 20

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: folderDialog.open()
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spacing.medium

            LogosStorageButton {
                text: "Cancel"
                onClicked: root.close()
            }

            LogosStorageButton {
                text: "Save"
                variant: "primary"
                enabled: jsonEditor.isValid
                onClicked: {
                    root.backend.saveUserConfig(jsonEditor.text)
                    root.close()
                }
            }
        }
    }
}

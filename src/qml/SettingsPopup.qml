import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtCore
import Logos.Theme
import Logos.Controls

LogosDialog {
    id: root

    property var backend: MockBackend
    property string downloadFolderPath: ""

    signal folderPathChanged(string path)

    readonly property string displayFolderPath: downloadFolderPath.replace(
                                                    /^file:\/{2,2}/, "")

    title: "Configuration"
    modal: true
    width: 520
    height: 480
    anchors.centerIn: Overlay.overlay
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    FolderDialog {
        id: folderDialog
        currentFolder: root.downloadFolderPath
        onAccepted: {
            root.downloadFolderPath = selectedFolder.toString()
            root.folderPathChanged(root.downloadFolderPath)
        }
    }

    // Reload the live config every time the popup opens
    onOpened: {
        if (root.backend.isMock) {
            jsonEditor.load(root.backend.getUserConfig() || "{}")
        } else if (typeof logos !== "undefined" && logos) {
            logos.watch(root.backend.getUserConfig(), function (text) {
                jsonEditor.load(text || "{}")
            }, function (err) {
                console.warn("getUserConfig:", err)
            })
        } else {
            jsonEditor.load("{}")
        }
    }

    contentItem: ColumnLayout {
        spacing: Theme.spacing.small

        LogosText {
            text: "Edit the JSON configuration below, then click Save."
            font.pixelSize: Theme.typography.primaryText
            color: Theme.palette.textSecondary
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

            LogosTextField {
                Layout.fillWidth: true
                readOnly: true
                text: root.displayFolderPath
                rightPadding: Theme.spacing.large + 20
                background: CardFieldBackground {}

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: folderDialog.open()
                }
            }
        }
    }

    rightActions: [
        LogosButton {
            radius: Theme.spacing.radiusLarge
            text: "Cancel"
            onClicked: root.close()
        },
        LogosButton {
            radius: Theme.spacing.radiusLarge
            text: "Save"
            variant: LogosButton.Variant.Primary
            enabled: jsonEditor.isValid
            onClicked: {
                root.backend.saveUserConfig(jsonEditor.text)
                root.close()
            }
        }
    ]
}

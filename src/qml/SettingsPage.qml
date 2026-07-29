import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

// qmllint disable unqualified
LogosFrame {
    id: root

    property var backend: MockBackend
    property string downloadFolderPath: ""

    signal folderPathChanged(string path)

    backgroundColor: Theme.palette.backgroundSecondary
    borderColor: "transparent"
    radius: Theme.spacing.radiusLarge

    property bool savedNote: false

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.large
        spacing: Theme.spacing.medium

        LogosText {
            text: "Settings"
            font.pixelSize: Theme.typography.titleText
            font.weight: Theme.typography.weightBold
            color: Theme.palette.text
        }

        SettingsForm {
            id: form
            Layout.fillWidth: true
            Layout.fillHeight: true
            backend: root.backend
            downloadFolderPath: root.downloadFolderPath
            onFolderPathChanged: function (path) {
                root.downloadFolderPath = path
                root.folderPathChanged(path)
            }
            onSaved: root.savedNote = true
        }

        // ---------- Footer actions ----------
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.medium

            LogosText {
                visible: root.savedNote
                text: "Saved. Restart the node to apply changes."
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.success
            }

            Item { Layout.fillWidth: true }

            LogosButton {
                text: "Reset"
                radius: Theme.spacing.radiusLarge
                enabled: form.dirty
                onClicked: {
                    root.savedNote = false
                    form.load()
                }
            }

            LogosButton {
                text: "Save changes"
                radius: Theme.spacing.radiusLarge
                variant: LogosButton.Variant.Primary
                enabled: form.dirty
                onClicked: form.save()
            }
        }
    }
}

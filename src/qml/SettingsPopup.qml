import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls
import Logos.StorageBackend 1.0

// qmllint disable unqualified
// Chrome around SettingsForm: title, close, and the save bar that stays put
// while the form scrolls.
Popup {
    id: root

    objectName: "settingsPopup"

    property var backend: MockBackend
    property string downloadFolderPath: ""
    property bool privateQueries: true

    signal folderPathChanged(string path)
    signal privateQueriesToggled(bool enabled)

    // Saved, waiting for the restart that makes the node read the new values.
    property bool restartPending: false

    // A stop that fails never emits stopCompleted, so a handler connected for
    // the occasion would outlive it and restart the node on the user's next
    // deliberate stop. A flag the signal reads is what keeps it one-shot.
    property bool restarting: false

    readonly property bool compact: root.width < 640

    readonly property bool nodeIdle: root.backend
                                     && root.backend.status !== StorageBackend.Starting
                                     && root.backend.status !== StorageBackend.Stopping

    modal: true
    padding: 0
    closePolicy: Popup.CloseOnEscape
    anchors.centerIn: Overlay.overlay
    width: Math.min(920, Overlay.overlay ? Overlay.overlay.width - 48 : 920)
    height: Math.min(680, Overlay.overlay ? Overlay.overlay.height - 48 : 680)

    onOpened: form.load()

    background: Rectangle {
        color: Theme.palette.background
        border.color: Theme.palette.borderSecondary
        border.width: 1
        radius: Theme.spacing.radiusXlarge
    }

    Connections {
        target: root.backend
        ignoreUnknownSignals: true

        function onStartCompleted() {
            root.restartPending = false
            root.restarting = false
        }

        function onStopCompleted() {
            if (!root.restarting)
                return
            root.restarting = false
            root.backend.start()
        }

        function onError(message) {
            root.restarting = false
        }
    }

    function restartNode() {
        if (!root.backend || root.restarting)
            return
        if (root.backend.status !== StorageBackend.Running) {
            root.backend.start()
            return
        }
        root.restarting = true
        root.backend.stop()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.spacing.large
            spacing: Theme.spacing.medium

            ColumnLayout {
                Layout.fillWidth: false
                spacing: 2

                LogosText {
                    text: "Settings"
                    font.pixelSize: Theme.typography.titleText
                    color: Theme.palette.text
                }

                LogosText {
                    visible: !root.compact
                    text: "Most changes take effect the next time the node starts."
                    font.pixelSize: Theme.typography.secondaryText
                    color: Theme.palette.textSecondary
                }
            }

            Item {
                Layout.fillWidth: true
            }

            LogosIcon {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 23
                Layout.preferredHeight: 23
                source: Qt.resolvedUrl("assets/close-circle-line.svg")
                color: Theme.palette.textTertiary

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.palette.borderSecondary
        }

        SettingsForm {
            id: form

            Layout.fillWidth: true
            Layout.fillHeight: true

            backend: root.backend
            downloadFolderPath: root.downloadFolderPath
            privateQueries: root.privateQueries

            onFolderPathChanged: function (path) {
                root.folderPathChanged(path)
            }
            onPrivateQueriesToggled: function (enabled) {
                root.privateQueriesToggled(enabled)
            }
            onSaved: function (restartNeeded) {
                if (restartNeeded)
                    root.restartPending = true
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.palette.borderSecondary
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.spacing.large
            spacing: Theme.spacing.medium

            LogosText {
                objectName: "restartPendingNotice"
                Layout.fillWidth: true
                visible: root.restartPending
                text: root.compact ? "Saved. Restart to apply." : "Saved. Restart the node to apply the new settings."
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.warning
                elide: Text.ElideRight
            }

            LogosButton {
                radius: Theme.spacing.radiusLarge
                visible: root.restartPending
                text: "Restart node"
                implicitHeight: 40
                implicitWidth: 140
                enabled: root.nodeIdle
                onClicked: root.restartNode()
            }

            LogosText {
                objectName: "unsavedNotice"
                Layout.fillWidth: true
                visible: form.dirty && !root.restartPending
                text: {
                    if (!form.restartRequired)
                        return "Unsaved changes"
                    return root.compact ? "Unsaved — needs a restart" : "Unsaved changes — the node must restart to apply them."
                }
                font.pixelSize: Theme.typography.secondaryText
                color: form.restartRequired ? Theme.palette.warning : Theme.palette.textSecondary
                elide: Text.ElideRight
            }

            Item {
                Layout.fillWidth: true
            }

            LogosButton {
                radius: Theme.spacing.radiusLarge
                objectName: "saveButton"
                text: "Save"
                variant: LogosButton.Variant.Primary
                implicitHeight: 40
                implicitWidth: root.compact ? 90 : 130
                enabled: form.dirty && form.valid
                onClicked: form.save()
            }
        }
    }
}

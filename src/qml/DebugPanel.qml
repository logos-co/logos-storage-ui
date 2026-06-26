import QtQuick
import QtQuick.Layouts
import QtCore
import Logos.Theme
import Logos.Controls

// qmllint disable unqualified
ColumnLayout {
    id: root

    property var backend: MockBackend
    property bool isOpen: false
    property bool running: false

    Settings {
        id: storageSettings
        category: "Storage"

        property bool onboardingCompleted: false
        property string downloadFolderPath: ""
    }

    onRunningChanged: {
        if (!root.running)
            return
        const cfg = StandardPaths.writableLocation(StandardPaths.GenericConfigLocation)
        console.log("[QML] settings file =",
                    cfg + "/" + Qt.application.organization + "/" + Qt.application.name + ".conf")
        console.log("[QML] Storage/onboardingCompleted =", storageSettings.onboardingCompleted)
        console.log("[QML] Storage/downloadFolderPath =", storageSettings.downloadFolderPath)
    }

    anchors.fill: parent
    visible: root.isOpen
    spacing: Theme.spacing.small

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 50
        color: Theme.palette.backgroundInset
        radius: Theme.spacing.radiusSmall

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacing.medium
            anchors.rightMargin: Theme.spacing.medium
            spacing: Theme.spacing.small

            LogosStorageButton {
                text: "Debug"
                implicitHeight: 32
                implicitWidth: 70
                enabled: root.running
                onClicked: root.backend.logDebugInfo()
            }
            LogosStorageButton {
                text: "Data dir"
                implicitHeight: 32
                implicitWidth: 80
                enabled: root.running
                onClicked: root.backend.logDataDir()
            }
            LogosStorageButton {
                text: "Version"
                implicitHeight: 32
                implicitWidth: 80
                enabled: root.running
                onClicked: root.backend.logVersion()
            }
            LogosStorageButton {
                text: "Restart onboarding"
                implicitHeight: 32
                implicitWidth: 150
                enabled: root.running
                onClicked: root.backend.restartOnboarding()
            }

            Item {
                Layout.fillWidth: true
            }
        }
    }

    Flickable {
        id: logFlick
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        contentWidth: width
        contentHeight: debugLogText.implicitHeight

        TextEdit {
            id: debugLogText
            width: logFlick.width
            text: root.backend ? root.backend.debugLogs : ""
            color: Theme.palette.textSecondary
            font.family: "monospace"
            font.pixelSize: 11
            wrapMode: Text.WrapAnywhere
            readOnly: true
            padding: Theme.spacing.small
            bottomPadding: Theme.spacing.large

            onTextChanged: Qt.callLater(function () {
                logFlick.contentY = Math.max(
                            0, logFlick.contentHeight - logFlick.height)
            })
        }
    }
}

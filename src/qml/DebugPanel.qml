import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

// qmllint disable unqualified
ColumnLayout {
    id: root

    property var backend: MockBackend
    property bool isOpen: false
    property bool running: false

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
                implicitHeight: 24
                implicitWidth: 70
                enabled: root.running
                onClicked: root.backend.logDebugInfo()
            }
            LogosStorageButton {
                text: "Peer ID"
                implicitHeight: 24
                implicitWidth: 80
                enabled: root.running
                onClicked: root.backend.logPeerId()
            }
            LogosStorageButton {
                text: "Data dir"
                implicitHeight: 24
                implicitWidth: 80
                enabled: root.running
                onClicked: root.backend.logDataDir()
            }
            LogosStorageButton {
                text: "SPR"
                implicitHeight: 24
                implicitWidth: 60
                enabled: root.running
                onClicked: root.backend.logSpr()
            }
            LogosStorageButton {
                text: "Version"
                implicitHeight: 24
                implicitWidth: 80
                enabled: root.running
                onClicked: root.backend.logVersion()
            }
            LogosStorageButton {
                text: "List settings"
                implicitHeight: 24
                implicitWidth: 150
                enabled: root.running
                onClicked: root.backend.listSettings()
            }
            LogosStorageButton {
                text: "Restart onboarding"
                implicitHeight: 24
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
            text: root.backend.debugLogs
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

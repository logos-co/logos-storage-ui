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

            LogosButton {
                radius: Theme.spacing.radiusLarge
                text: "Debug"
                implicitHeight: 32
                topPadding: 0
                bottomPadding: 0
                implicitWidth: 70
                enabled: root.running
                onClicked: root.backend.logDebugInfo()
            }
            LogosButton {
                radius: Theme.spacing.radiusLarge
                text: "Data dir"
                implicitHeight: 32
                topPadding: 0
                bottomPadding: 0
                implicitWidth: 80
                enabled: root.running
                onClicked: root.backend.logDataDir()
            }
            LogosButton {
                radius: Theme.spacing.radiusLarge
                text: "Version"
                implicitHeight: 32
                topPadding: 0
                bottomPadding: 0
                implicitWidth: 80
                enabled: root.running
                onClicked: root.backend.logVersion()
            }
            LogosButton {
                radius: Theme.spacing.radiusLarge
                text: "Restart onboarding"
                implicitHeight: 32
                topPadding: 0
                bottomPadding: 0
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
            font.family: Theme.typography.mono
            font.pixelSize: Theme.typography.secondaryText
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

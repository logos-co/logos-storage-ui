import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

// qmllint disable unqualified
Rectangle {
    id: root

    property var backend
    property bool running: false

    color: Theme.palette.backgroundElevated
    border.color: Theme.palette.borderSecondary
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.topMargin: 6
            Layout.bottomMargin: 4
            spacing: 6

            LogosStorageButton {
                text: "Debug"
                enabled: root.running
                onClicked: root.backend.logDebugInfo()
            }
            LogosStorageButton {
                text: "Peer ID"
                enabled: root.running
                onClicked: root.backend.logPeerId()
            }
            LogosStorageButton {
                text: "Data dir"
                enabled: root.running
                onClicked: root.backend.logDataDir()
            }
            LogosStorageButton {
                text: "SPR"
                enabled: root.running
                onClicked: root.backend.logSpr()
            }
            LogosStorageButton {
                text: "Version"
                enabled: root.running
                onClicked: root.backend.logVersion()
            }

            Item {
                Layout.fillWidth: true
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.palette.borderSecondary
        }

        Flickable {
            id: logFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: debugText.implicitHeight

            TextEdit {
                id: debugText
                width: logFlick.width
                text: root.backend.debugLogs
                color: Theme.palette.textSecondary
                font.family: "monospace"
                font.pixelSize: 11
                wrapMode: Text.WrapAnywhere
                readOnly: true
                padding: 8
                bottomPadding: 20

                onTextChanged: Qt.callLater(function () {
                    logFlick.contentY = Math.max(
                                0, logFlick.contentHeight - logFlick.height)
                })
            }
        }
    }
}

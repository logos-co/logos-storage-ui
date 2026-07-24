import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

// qmllint disable unqualified
LogosFrame {
    id: root

    backgroundColor: Theme.palette.backgroundSecondary
    borderColor: "transparent"
    radius: Theme.spacing.radiusLarge

    property var backend: MockBackend

    Flickable {
        id: logFlick
        anchors.fill: parent
        anchors.margins: Theme.spacing.medium
        clip: true
        contentWidth: width
        contentHeight: logText.implicitHeight

        TextEdit {
            id: logText
            width: logFlick.width
            text: root.backend ? root.backend.debugLogs : ""
            color: Theme.palette.textSecondary
            font.family: "monospace"
            font.pixelSize: Theme.typography.secondaryText
            wrapMode: Text.WrapAnywhere
            readOnly: true
            bottomPadding: Theme.spacing.large

            onTextChanged: Qt.callLater(function () {
                logFlick.contentY = Math.max(
                            0, logFlick.contentHeight - logFlick.height)
            })
        }
    }
}

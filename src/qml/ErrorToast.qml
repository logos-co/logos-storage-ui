import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

Rectangle {
    id: root

    property alias title: titleText.text
    property alias message: messageText.text

    function show(t, msg) {
        root.title = t
        root.message = msg
        root.visible = true
        slideAnim.restart()
    }

    function hide() {
        root.visible = false
    }

    visible: false
    opacity: 0
    width: 500
    radius: Theme.spacing.tiny
    color: "#1e1e1e"

    implicitHeight: content.implicitHeight + Theme.spacing.medium * 2

    transform: Translate { id: slideTranslate; y: 20 }

    ParallelAnimation {
        id: slideAnim

        NumberAnimation {
            target: slideTranslate
            property: "y"
            from: 20
            to: 0
            duration: 500
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "opacity"
            from: 0
            to: 1
            duration: 500
            easing.type: Easing.OutCubic
        }
    }

    ColumnLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            margins: Theme.spacing.medium
        }
        spacing: Theme.spacing.tiny

        RowLayout {
            Layout.fillWidth: true

            LogosText {
                id: titleText
                Layout.fillWidth: true
                color: Theme.palette.error
                font.pixelSize: Theme.typography.primaryText
                font.bold: true
            }

            LogosText {
                text: "✕"
                color: Theme.palette.textMuted
                font.pixelSize: Theme.typography.primaryText

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.hide()
                }
            }
        }

        LogosText {
            id: messageText
            Layout.fillWidth: true
            color: Theme.palette.text
            font.pixelSize: Theme.typography.primaryText
            wrapMode: Text.WordWrap
        }
    }
}

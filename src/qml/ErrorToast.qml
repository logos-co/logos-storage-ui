import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

Rectangle {
    id: root

    property alias title: titleText.text
    property alias message: messageText.text

    function show(title, message) {
        root.title = title
        root.message = message
        root.visible = true
        slideAnim.restart()
    }

    function hide() {
        hideAnim.restart()
    }

    visible: false
    opacity: 0
    width: 500
    radius: Theme.spacing.tiny
    color: "#3D2020"

    implicitHeight: content.implicitHeight + Theme.spacing.medium * 2

    transform: Translate {
        id: slideTranslate
        y: 20
    }

    ParallelAnimation {
        id: hideAnim

        NumberAnimation {
            target: slideTranslate
            property: "y"
            from: 0
            to: 20
            duration: 300
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: root
            property: "opacity"
            from: 1
            to: 0
            duration: 300
            easing.type: Easing.InCubic
        }

        onFinished: root.visible = false
    }

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

    // Close button top right
    LogosText {
        text: "x"
        font.pixelSize: Theme.typography.primaryText
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Theme.spacing.small
        z: 1
        color: Theme.palette.text

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.hide()
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

        LogosText {
            id: titleText
            Layout.fillWidth: true
            color: Theme.palette.error
            font.pixelSize: Theme.typography.primaryText
            font.bold: true
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

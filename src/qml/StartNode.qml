import QtQuick
import QtQuick.Layouts
import Logos.Controls
import Logos.Theme

Rectangle {
    id: root
    color: Theme.palette.background
    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitWidth: 600
    implicitHeight: 400

    property var backend
    property string status: ""
    property bool starting: true
    property bool success: false

    signal back
    signal next

    Connections {
        target: root.backend

        function onStartCompleted() {
            console.log("onStartCompleted received")
            root.starting = false
            root.status = "Logos Storage started successfully."
            root.success = true
        }

        function onStartFailed(error) {
            console.log("onStartFailed received")
            root.starting = false
            root.status = "Failed to start: " + error
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Theme.spacing.medium
        width: 400

        LogosText {
            id: titleText
            font.pixelSize: Theme.typography.titleText
            text: "Starting your node...."
            Layout.alignment: Qt.AlignHCenter
        }

        LogosText {
            id: statusText
            font.pixelSize: Theme.typography.primaryText
            text: root.status
            Layout.alignment: Qt.AlignHCenter
        }
    }

    LogosStorageButton {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.bottomMargin: 10
        anchors.leftMargin: 10
        text: "Back"
        onClicked: root.back()
        enabled: root.starting == false
    }

    LogosStorageButton {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 10
        anchors.rightMargin: 10
        text: "Next"
        onClicked: root.next()
        enabled: root.success == true
    }
}

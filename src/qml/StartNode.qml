import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Logos.Controls
import Logos.Theme

Rectangle {
    id: root
    color: Theme.palette.background
    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitWidth: 600
    implicitHeight: 400

    property var backend: mockBackend
    property string status: ""
    property string title: "Starting your node...."
    property bool starting: true
    property bool success: false

    signal back
    signal next

    function onNodeStarted() {
        root.starting = false
        root.status = "Logos Storage started successfully."
        root.title = "Success"
        root.success = true
    }

    QtObject {
        id: mockBackend

        readonly property bool isMock: true
        property string configJson: "{}"

        signal startCompleted
        signal startFailed
        signal nodeStarted
    }

    Timer {
        interval: 2000
        running: root.backend && root.backend.isMock === true
        onTriggered: {
            console.log("timer triggered")
            root.onNodeStarted()
        }
    }

    Connections {
        target: root.backend

        function onStartCompleted() {
            console.log("onStartCompleted")
            root.onNodeStarted()
        }

        function onStartFailed(error) {
            root.starting = false
            root.title = "Error"
            root.status = "Failed to start: " + error
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        anchors.bottomMargin: 60
        spacing: Theme.spacing.medium

        LogosText {
            id: titleText
            font.pixelSize: Theme.typography.titleText
            text: root.title
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

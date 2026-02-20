import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Logos.Controls
import Logos.Theme

LogosStorageLayout {
    id: root

    property var backend: mockBackend
    property string status: ""
    property string title: "Starting your node"
    property string resolution: ""
    property bool starting: true
    property bool success: false

    signal back
    signal next

    function onNodeStarted() {
        root.starting = false
        root.status = "Your node is up and reachable."
        root.title = "Node is ready"
        root.success = true
    }

    Component.onCompleted: root.backend.start()

    Timer {
        id: nodeCheckTimer
        interval: 500
        repeat: false
        onTriggered: root.backend.checkNodeIsUp()
    }

    Connections {
        target: root.backend

        function onStartCompleted() {
            root.title = "Checking connectivity"
            root.status = "Node started, verifying reachability..."
            nodeCheckTimer.start()
        }

        function onStartFailed(error) {
            root.starting = false
            root.title = "Failed to start"
            root.status = "Your node failed to start: " + error
        }

        function onNodeIsUp() {
            root.onNodeStarted()
        }

        function onNodeIsntUp(reason) {
            root.starting = false
            root.title = "Node unreachable"
            root.status = ""
            root.resolution = reason
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: 400
        spacing: Theme.spacing.medium

        LogosText {
            font.pixelSize: Theme.typography.titleText
            text: root.title
            Layout.alignment: Qt.AlignHCenter
        }

        NodeStatusIcon {
            starting: root.starting
            success: root.success
            Layout.alignment: Qt.AlignHCenter
        }

        LogosText {
            font.pixelSize: Theme.typography.primaryText
            text: root.status
            visible: root.status !== ""
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        LogosText {
            font.pixelSize: Theme.typography.primaryText
            text: root.resolution
            visible: root.resolution !== ""
            color: Theme.palette.error
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }
    }

    LogosStorageButton {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.bottomMargin: 10
        anchors.leftMargin: 10
        text: "Back"
        enabled: !root.starting
        onClicked: {
            root.backend.stop()
            root.back()
        }
    }

    LogosStorageButton {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 10
        anchors.rightMargin: 10
        text: "Next"
        enabled: root.success
        onClicked: {
            root.backend.saveCurrentConfig()
            root.next()
        }
    }

    Timer {
        interval: 2000
        running: root.backend && root.backend.isMock === true
        repeat: false
        onTriggered: root.onNodeStarted()
    }

    QtObject {
        id: mockBackend

        readonly property bool isMock: true

        signal startCompleted
        signal startFailed(string error)
        signal nodeIsUp
        signal nodeIsntUp(string reason)

        function checkNodeIsUp() {}
        function stop() {}
        function saveCurrentConfig() {}
        function start() {}
    }
}

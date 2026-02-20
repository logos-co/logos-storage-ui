import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Logos.Controls
import Logos.Theme

LogosStorageLayout {
    id: root

    property var backend: mockBackend
    property string status: ""
    property string title: "Starting your node...."
    property string resolution: ""
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

    Component.onCompleted: root.backend.start()

    // Wait after startCompleted before calling checkNodeIs to
    // make sure the the node is started and ready.
    Timer {
        id: nodeCheckTimer
        interval: 500
        repeat: false
        onTriggered: root.backend.checkNodeIsUp()
    }

    Connections {
        target: root.backend

        function onStartCompleted() {
            console.info("startCompleted")
            root.title = "Checking.."
            root.status = "Your node is started, checking everything is up."
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
            root.title = "Node not reachable"
            root.status = ""
            root.resolution = reason
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: 400
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
            wrapMode: Text.WordWrap
        }

        LogosText {
            id: resolutionText
            font.pixelSize: Theme.typography.primaryText
            text: root.resolution
            visible: root.resolution !== ""
            color: Theme.palette.error
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
        }
    }

    LogosStorageButton {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.bottomMargin: 10
        anchors.leftMargin: 10
        text: "Back"
        onClicked: function () {
            root.backend.stop()
            root.back()
        }

        enabled: root.starting == false
    }

    LogosStorageButton {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 10
        anchors.rightMargin: 10
        text: "Next"
        onClicked: function () {
            root.backend.saveCurrentConfig()
            root.next()
        }
        enabled: root.success == true
    }

    // In preview/mock mode, simulate a successful node start after 2 seconds
    Timer {
        interval: 2000
        running: root.backend && root.backend.isMock === true
        onTriggered: root.onNodeStarted()
        repeat: false
    }

    QtObject {
        id: mockBackend

        readonly property bool isMock: true
        property string configJson: "{}"

        signal startCompleted
        signal startFailed(string error)
        signal nodeIsUp
        signal nodeIsntUp(string reason)

        function guessResolution() {
            return ""
        }

        function checkNodeIsUp() {}

        function stop() {}

        function saveCurrentConfig() {}
    }
}

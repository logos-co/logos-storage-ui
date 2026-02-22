import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

// qmllint disable unqualified
LogosStorageLayout {
    id: root

    property var backend: mockBackend
    property bool showDebug: false

    function isRunning() {
        return backend.status === 2 // StorageBackend.Running
    }

    Component.onCompleted: root.backend.start()

    HealthIndicator {
        id: health
        backend: root.backend
    }

    QtObject {
        id: mockBackend
        property var status: 0
        property var debugLogs: "Hello!"
        property string uploadStatus: ""
        property int uploadProgress: 0
        property var manifests: []
        signal nodeIsUp
        signal nodeIsntUp(string reason)
        signal peersUpdated(int count)
        signal uploadCompleted(string cid)
        signal downloadCompleted(string cid)

        function start() { status = 2 }
        function stop() { status = 0 }
        function checkNodeIsUp() {}
        function tryUploadFile(f) {}
        function downloadManifest(c) {}
        function remove(c) {}
        function tryDownloadFile(c, d) {}
        function tryDebug() {}
        function showPeerId() {}
        function dataDir() {}
        function spr() {}
        function version() {}
        function saveUserConfig(j) {}
        function reloadIfChanged(j) {}
        function configJson() { return "{}" }
    }

    SettingsPopup {
        id: settingsPopup
        backend: root.backend
    }

    Shortcut {
        sequence: "Ctrl+D"
        onActivated: root.showDebug = !root.showDebug
    }

    ScrollView {
        id: mainScroll
        anchors.fill: parent
        anchors.bottomMargin: root.showDebug ? debugPanel.height : 0
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: mainScroll.availableWidth
            spacing: 0

            NodeHeader {
                Layout.fillWidth: true
                Layout.leftMargin: 24
                Layout.rightMargin: 24
                Layout.topMargin: 24
                Layout.bottomMargin: 20
                backend: root.backend
                nodeIsUp: health.nodeIsUp
                blinkOn: health.blinkOn
                onSettingsRequested: settingsPopup.open()
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 24
                Layout.rightMargin: 24
                Layout.preferredHeight: 1
                color: Theme.palette.borderSecondary
            }

            StatusWidgets {
                Layout.fillWidth: true
                Layout.leftMargin: 24
                Layout.rightMargin: 24
                Layout.topMargin: 20
                backend: root.backend
                running: root.isRunning()
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 24
                Layout.rightMargin: 24
                Layout.preferredHeight: 1
                color: Theme.palette.borderSecondary
            }

            ManifestTable {
                Layout.fillWidth: true
                Layout.leftMargin: 24
                Layout.rightMargin: 24
                Layout.topMargin: 20
                Layout.bottomMargin: 20
                backend: root.backend
                running: root.isRunning()
            }

            Item {
                Layout.preferredHeight: 20
            }
        }
    }

    DebugPanel {
        id: debugPanel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 220
        visible: root.showDebug
        backend: root.backend
        running: root.isRunning()
    }
}

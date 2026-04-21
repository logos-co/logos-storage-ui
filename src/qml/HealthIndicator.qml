import QtQuick
import Logos.StorageBackend 1.0

QtObject {
    id: root

    property var backend: MockBackend
    property bool nodeIsUp: false
    property bool blinkOn: true
    readonly property int threeMinutes: 180000

    // 600 ms blink toggle
    property Timer blinkTimer: Timer {
        interval: 600
        repeat: true
        running: true
        onTriggered: root.blinkOn = !root.blinkOn
    }

    // Reachability check every 3 minutes while running
    property Timer checkTimer: Timer {
        interval: root.threeMinutes
        repeat: true
        running: root.backend !== null && root.backend.status === StorageBackend.Running
        triggeredOnStart: true
        onTriggered: function () {
            if (root.backend) {
                root.backend.checkNodeIsUp()
            }
        }
    }

    property Connections connections: Connections {
        target: root.backend

        function onNodeIsUp() {
            root.nodeIsUp = true
        }

        function onNodeIsntUp(r) {
            root.nodeIsUp = false
        }

        function onStatusChanged() {
            if (!root.backend || root.backend.status !== StorageBackend.Running) {
                root.nodeIsUp = false
            }
        }
    }
}

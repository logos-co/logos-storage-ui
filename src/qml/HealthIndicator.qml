import QtQuick
import Logos.StorageBackend 1.0

QtObject {
    id: root

    property var backend: MockBackend
    property bool blinkOn: true
    readonly property int checkIntervalMs: 30000

    // AutoNAT verdict on the running node: "Reachable", "NotReachable" or
    // "Unknown" while it has no answer yet.
    readonly property string reachability: root.backend ? root.backend.natReachability : "Unknown"

    // 600 ms blink toggle
    property Timer blinkTimer: Timer {
        interval: 600
        repeat: true
        running: true
        onTriggered: root.blinkOn = !root.blinkOn
    }

    // Peers and reachability refresh while running
    property Timer checkTimer: Timer {
        interval: root.checkIntervalMs
        repeat: true
        running: root.backend !== null && root.backend.status === StorageBackend.Running
        triggeredOnStart: true
        onTriggered: function () {
            if (root.backend) {
                root.backend.refreshNodeStatus()
            }
        }
    }
}

import QtQuick
import Logos.Theme

Item {
    id: root

    property bool nodeIsUp: false
    property var backend: mockBackend
    readonly property int running: 2

    Timer {
        readonly property int threeMinutes: 180000

        interval: threeMinutes
        repeat: true
        running: root.backend.status == root.running
        triggeredOnStart: true
        onTriggered: root.backend.checkNodeIsUp()
    }

    Connections {
        target: root.backend

        function onNodeIsUp() {
            root.nodeIsUp = true
        }

        function onNodeIsntUp(reason) {
            root.nodeIsUp = false
        }

        function onStatusChanged() {
            if (root.backend.status !== root.running) {
                root.nodeIsUp = false
            }
        }
    }

    property bool blinkOn: true

    Timer {
        interval: 600
        repeat: true
        running: true
        onTriggered: root.blinkOn = !root.blinkOn
    }

    Row {
        id: nodeStatusBadge
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 18
        anchors.rightMargin: 20
        spacing: 7

        Rectangle {
            width: 10
            height: 10
            radius: 5
            anchors.verticalCenter: parent.verticalCenter
            color: root.nodeIsUp ? Theme.palette.success : Theme.palette.error
            opacity: root.blinkOn ? 1.0 : 0.15
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.nodeIsUp ? "Node reachable" : "Node unreachable"
            color: root.nodeIsUp ? Theme.palette.success : Theme.palette.error
            font.pixelSize: 12
        }
    }

    QtObject {
        id: mockBackend

        signal nodeIsUp
        signal nodeIsntUp(string reason)
    }
}

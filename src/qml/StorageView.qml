import QtQuick
import QtQuick.Controls

//import QtQuick.Layouts
Item {
    property var backend: mockBackend
    readonly property int stopped: 0
    readonly property int starting: 1
    readonly property int running: 2
    readonly property int stopping: 3
    readonly property int destroyed: 4

    id: root
    width: 400
    height: 300

    QtObject {
        id: mockBackend

        property var status: root.stopped
        property var statusText: "Destroyed"
        property var startStopText: "Start"
        property var canStartStop: true

        function startStop() {
            if (status == root.running) {
                status = root.stopped
                statusText = "Stopped"
                startStopText = "Start"
            } else {
                status = root.running
                statusText = "Started"
                startStopText = "Stop"
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        anchors.topMargin: 0
        anchors.bottomMargin: 0
        color: "#202428"
    }

    Text {
        objectName: "status"
        text: root.backend.statusText
        color: "white"
        font.pointSize: 20
        anchors.centerIn: parent
        anchors.topMargin: 0
    }

    Button {
        objectName: "startStopButton"
        anchors.leftMargin: 50
        text: root.backend.startStopText
        enabled: root.backend.canStartStop
        onClicked: root.backend.startStop()
    }
}

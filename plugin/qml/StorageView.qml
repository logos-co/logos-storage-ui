import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import StorageBackend

Item {
    id: root

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        anchors.topMargin: 0
        anchors.bottomMargin: 0
        color: "#202428"
    }

    Text {
        text: qsTr("Storage UI")
        color: "black"
        anchors.centerIn: parent
        font.pointSize: 20
    }

    Text {
        objectName: "status"
        text: "..."
        color: "white"
        font.pointSize: 20
        anchors.topMargin: 32
    }

    Button {
        objectName: "startButton"
        anchors.leftMargin: 50
        text: "Stop"
    }
}

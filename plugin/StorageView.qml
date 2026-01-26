import QtQuick
import QtQuick.Controls

Item {
    anchors.fill: parent

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
        anchors.verticalCenterOffset: 214
        anchors.horizontalCenterOffset: -269
        color: "white"
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
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 395
        anchors.horizontalCenterOffset: -270
        text: "Stop"
    }
}

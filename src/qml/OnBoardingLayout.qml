import QtQuick
import QtQuick.Effects

Rectangle {
    implicitWidth: 1200
    implicitHeight: 600

    Image {
        id: bgImage
        anchors.fill: parent
        source: "assets/bg.png"
        opacity: 0.9
    }
}

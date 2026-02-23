import QtQuick
import QtQuick.Controls
import Logos.Theme

// qmllint disable unqualified
TextField {
    id: root

    property bool isValid: acceptableInput && text.length > 0

    placeholderTextColor: Theme.palette.textPlaceholder
    color: isValid ? Theme.palette.text : Theme.palette.error
    selectByMouse: true
    background: Rectangle {

        Rectangle {
            anchors.fill: parent
            color: Theme.palette.backgroundSecondary
        }

        // Border bottom
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: root.isValid ? Theme.palette.textMuted : Theme.palette.error
        }
    }
}

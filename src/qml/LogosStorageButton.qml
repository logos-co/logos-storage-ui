import QtQuick
import QtQuick.Controls
import Logos.Theme

Button {
    id: control
    padding: Theme.spacing.small

    contentItem: Text {
        text: control.text
        font.pixelSize: Theme.typography.primaryText
        color: control.enabled ? Theme.palette.text : Theme.palette.textMuted
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        color: {
            if (!control.enabled)
                return Theme.palette.backgroundElevated
            return Theme.palette.backgroundSecondary
        }
        border.width: 1
        border.color: Theme.palette.border
        radius: Theme.spacing.tiny

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
}

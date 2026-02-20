import QtQuick
import QtQuick.Controls
import Logos.Theme

Button {
    id: control
    padding: Theme.spacing.small

    // "default" | "success"
    property string variant: "default"

    readonly property bool isSuccess: variant === "success"

    contentItem: Text {
        text: control.text
        font.pixelSize: Theme.typography.primaryText
        color: {
            if (!control.enabled)
                return Theme.palette.textMuted
            if (control.isSuccess)
                return Theme.palette.background
            return Theme.palette.text
        }
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        color: {
            if (!control.enabled)
                return Theme.palette.backgroundElevated
            if (control.isSuccess)
                return Theme.palette.success
            return Theme.palette.backgroundSecondary
        }
        border.width: 1
        border.color: {
            if (!control.enabled)
                return Theme.palette.border
            if (control.isSuccess)
                return Theme.palette.success
            return Theme.palette.border
        }
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

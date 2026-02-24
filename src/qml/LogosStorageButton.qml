import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Logos.Theme

// qmllint disable unqualified
Button {
    id: control
    implicitHeight: 48
    implicitWidth: 200
    leftPadding: Theme.spacing.large
    rightPadding: Theme.spacing.large

    // "default" | "primary"
    property string variant: "default"

    // Icon
    property string iconSource: ""
    property string iconPosition: "left" // "left" | "right"

    contentItem: RowLayout {
        width: control.availableWidth
        spacing: Theme.spacing.small

        Image {
            source: control.iconSource
            visible: control.iconSource !== ""
                     && control.iconPosition === "left"
            fillMode: Image.PreserveAspectFit
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
        }

        Text {
            text: control.text
            font.pixelSize: Theme.typography.primaryText
            font.bold: true
            color: control.enabled ? Theme.palette.text : Theme.palette.textMuted
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            Layout.fillWidth: true
        }

        Image {
            source: control.iconSource
            visible: control.iconSource !== ""
                     && control.iconPosition === "right"
            fillMode: Image.PreserveAspectFit
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
        }
    }

    background: Rectangle {
        color: {
            if (!control.enabled)
                return Theme.palette.backgroundElevated
            if (control.variant === "primary")
                return Theme.palette.primary
            return Theme.palette.backgroundSecondary
        }
        border.width: 1
        border.color: control.enabled ? Theme.palette.border : Theme.palette.border
        radius: Theme.spacing.radiusLarge

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

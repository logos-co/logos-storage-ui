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

    // "default" | "primary" | "secondary"
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
            color: {
                if (!control.enabled) {
                    return Theme.palette.textMuted
                }

                if (control.variant === "secondary") {
                    return Theme.palette.textTertiary
                }

                return Theme.palette.text
            }
            horizontalAlignment: Text.AlignHCenter
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
            if (!control.enabled) {
                return Theme.palette.backgroundElevated
            }

            if (control.variant === "primary") {
                return Theme.palette.primary
            }

            if (control.variant == "secondary") {
                return Theme.palette.backgroundButton
            }

            return Theme.palette.backgroundSecondary
        }
        border.width: 1
        border.color: {
            if (!control.enabled) {
                return Theme.palette.borderSecondary
            }

            if (control.variant === "secondary") {
                return Theme.palette.borderInteractive
            }

            return Theme.palette.border
        }
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

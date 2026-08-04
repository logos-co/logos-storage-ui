import QtQuick
import QtQuick.Controls
import Logos.Theme
import Logos.Controls

// Themed ComboBox, styled to match LogosTextField.
ComboBox {
    id: control

    // Emitted only when an item is actually clicked. ComboBox also emits
    // activated() for a currentIndex written from code, and the two cannot be
    // told apart — a form that listens to activated() reports its own updates
    // back to itself.
    signal userPicked(int index)

    implicitHeight: 42
    leftPadding: Theme.spacing.medium
    rightPadding: Theme.spacing.medium + 16

    background: Rectangle {
        color: Theme.palette.backgroundSecondary
        radius: Theme.spacing.radiusSmall
        border.width: 1
        border.color: control.popup.visible ? Theme.palette.focus : Theme.palette.border
    }

    contentItem: LogosText {
        text: control.displayText
        color: control.enabled ? Theme.palette.text : Theme.palette.textMuted
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Canvas {
        x: control.width - width - Theme.spacing.medium
        y: (control.height - height) / 2
        width: 10
        height: 6

        rotation: control.popup.visible ? 180 : 0
        Behavior on rotation {
            NumberAnimation {
                duration: 120
            }
        }

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.beginPath()
            ctx.moveTo(0, 0)
            ctx.lineTo(width, 0)
            ctx.lineTo(width / 2, height)
            ctx.closePath()
            ctx.fillStyle = Theme.palette.textSecondary
            ctx.fill()
        }
    }

    delegate: ItemDelegate {
        id: option

        required property var modelData
        required property int index

        width: control.width
        height: 36
        highlighted: control.highlightedIndex === option.index
        onClicked: control.userPicked(option.index)

        contentItem: LogosText {
            text: option.modelData
            color: Theme.palette.text
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            color: option.highlighted ? Theme.palette.backgroundMuted : "transparent"
        }
    }

    popup: Popup {
        y: control.height + 4
        width: control.width
        implicitHeight: Math.min(contentItem.implicitHeight + 2, 260)
        padding: 1

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator {}
        }

        background: Rectangle {
            color: Theme.palette.backgroundElevated
            border.color: Theme.palette.borderSecondary
            border.width: 1
            radius: Theme.spacing.radiusSmall
        }
    }
}

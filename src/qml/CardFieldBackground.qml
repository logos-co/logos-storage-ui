import QtQuick

import Logos.Theme

// Background override for a LogosTextField sitting on a card. Overriding the
// background means owning the states too: focus and validation error are
// reproduced here from the parent control's textInput.
Rectangle {
    readonly property var ti: parent ? parent.textInput : null

    radius: Theme.spacing.radiusSmall
    color: Theme.palette.backgroundInset
    // Transparent at rest: the mockup has no border on fields, but reserving the
    // width keeps the focus ring from shifting the layout.
    border.width: 1
    border.color: {
        if (ti && ti.validator && ti.text.length > 0 && !ti.acceptableInput)
            return Theme.palette.error
        if (ti && ti.activeFocus)
            return Theme.palette.overlayOrange
        return "transparent"
    }
}

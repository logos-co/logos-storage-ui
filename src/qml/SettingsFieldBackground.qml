import QtQuick

import Logos.Theme

// Background for a LogosTextField in the settings form. The default field
// border reads black next to SettingsComboBox and LogosTextArea, which both
// outline in Theme.palette.border: this aligns the three.
// Overriding the background means owning the states too.
Rectangle {
    readonly property var ti: parent ? parent.textInput : null

    radius: Theme.spacing.radiusSmall
    color: Theme.palette.backgroundSecondary
    border.width: 1
    border.color: {
        if (ti && ti.validator && ti.text.length > 0 && !ti.acceptableInput)
            return Theme.palette.error
        if (ti && ti.activeFocus)
            return Theme.palette.focus
        return Theme.palette.border
    }
}

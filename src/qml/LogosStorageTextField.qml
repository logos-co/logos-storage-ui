import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Logos.Theme

// qmllint disable unqualified
TextField {
    id: root

    property bool isValid: acceptableInput && text.length > 0

    Layout.preferredHeight: 42
    padding: Theme.spacing.medium
    placeholderTextColor: Theme.palette.textPlaceholder
    color: isValid ? Theme.palette.text : Theme.palette.error
    selectByMouse: true
    background: Rectangle {
        color: Theme.palette.backgroundSecondary
        radius: Theme.spacing.radiusSmall
        border.width: 1
        border.color: root.isValid ? Theme.palette.border : Theme.palette.error
    }
}

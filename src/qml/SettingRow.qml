import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

// One setting: a name, a description below it, an optional "restart" tag, and
// the control(s) declared as children (reparented under the description).
ColumnLayout {
    id: root

    property string title: ""
    property string description: ""
    property bool requiresRestart: false
    default property alias content: holder.data

    Layout.fillWidth: true
    spacing: Theme.spacing.tiny

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacing.small

        LogosText {
            text: root.title
            font.pixelSize: Theme.typography.primaryText
            font.weight: Theme.typography.weightMedium
            color: Theme.palette.text
        }

        LogosBadge {
            visible: root.requiresRestart
            text: "Restart required"
            color: Theme.palette.warning
        }

        Item { Layout.fillWidth: true }
    }

    LogosText {
        text: root.description
        visible: root.description.length > 0
        font.pixelSize: Theme.typography.secondaryText
        color: Theme.palette.textSecondary
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    ColumnLayout {
        id: holder
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacing.tiny
        spacing: Theme.spacing.small
    }
}

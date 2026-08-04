import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

// One setting: title and description on the left, the control(s) declared as
// children on the right. Too narrow for both, the control drops below.
GridLayout {
    id: root

    property string title: ""
    property string description: ""
    property int controlWidth: 240

    readonly property bool stacked: root.width > 0 && root.width < 500

    default property alias content: holder.data

    Layout.fillWidth: true
    columns: root.stacked ? 1 : 2
    columnSpacing: Theme.spacing.large
    rowSpacing: Theme.spacing.small

    ColumnLayout {
        Layout.fillWidth: true
        Layout.minimumWidth: root.stacked ? 0 : 200
        Layout.alignment: Qt.AlignVCenter
        spacing: 2

        LogosText {
            Layout.fillWidth: true
            text: root.title
            font.pixelSize: Theme.typography.primaryText
            font.weight: Theme.typography.weightMedium
            color: Theme.palette.text
            wrapMode: Text.WordWrap
        }

        LogosText {
            Layout.fillWidth: true
            visible: root.description.length > 0
            text: root.description
            font.pixelSize: Theme.typography.secondaryText
            color: Theme.palette.textSecondary
            wrapMode: Text.WordWrap
        }
    }

    // A nested layout fills by default: pin it so the label column takes the rest.
    RowLayout {
        id: holder
        Layout.fillWidth: root.stacked
        Layout.preferredWidth: root.stacked ? -1 : root.controlWidth
        Layout.maximumWidth: root.stacked ? Number.POSITIVE_INFINITY : root.controlWidth
        Layout.alignment: Qt.AlignVCenter
        spacing: Theme.spacing.small
    }
}

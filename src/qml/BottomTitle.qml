import QtQuick
import Logos.Theme
import Logos.Controls

Item {
    id: root

    property string title: ""
    property color color: Theme.palette.text
    property bool hasSeparator: true

    // Lets a control placed on the title line center on the label.
    readonly property real labelCenterY: footerLabel.y + footerLabel.height / 2

    implicitHeight: footerLabel.implicitHeight + Theme.spacing.medium * 2

    LogosText {
        id: footerLabel
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        text: root.title
        font.pixelSize: Theme.typography.panelTitleText
        color: root.color
    }

    Rectangle {
        id: footerSeparator
        anchors.bottom: footerLabel.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: Theme.spacing.medium + 2
        height: 1
        color: Theme.palette.textTertiary
        opacity: 0.2
        visible: root.hasSeparator
    }
}

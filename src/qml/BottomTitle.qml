import QtQuick
import Logos.Theme
import Logos.Controls

Item {
    id: root

    property string title: ""

    implicitHeight: footerLabel.implicitHeight + Theme.spacing.medium * 2

    LogosText {
        id: footerLabel
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        text: root.title
        font.pixelSize: Theme.typography.titleText * 0.8
        color: Theme.palette.text
    }

    Rectangle {
        id: footerSeparator
        anchors.bottom: footerLabel.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: Theme.spacing.medium + 2
        height: 1
        color: Theme.palette.borderSecondary
    }
}

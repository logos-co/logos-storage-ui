import QtQuick
import Logos.Theme
import Logos.Controls

Item {
    id: root

    property string title: ""
    property string color: Theme.palette.text
    property string helpText: ""
    property bool hasSeparator: true

    implicitHeight: footerLabel.implicitHeight + Theme.spacing.medium * 2

    LogosText {
        id: footerLabel
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        text: root.title
        font.pixelSize: Theme.typography.panelTitleText
        color: root.color
    }

    LogosIcon {
        id: helpButton
        visible: root.helpText.length > 0
        source: Qt.resolvedUrl("assets/question-line.svg")
        color: helpHover.hovered ? Theme.palette.text : Theme.palette.textTertiary
        width: Theme.spacing.large
        height: Theme.spacing.large
        anchors.right: parent.right
        anchors.verticalCenter: footerLabel.verticalCenter

        HoverHandler {
            id: helpHover
            cursorShape: Qt.PointingHandCursor
        }

        LogosToolTip {
            text: root.helpText
            placement: LogosToolTip.Top
            visible: helpHover.hovered
        }
    }

    Rectangle {
        id: footerSeparator
        anchors.bottom: footerLabel.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: Theme.spacing.medium + 2
        height: 1
        color: Theme.palette.borderSecondary
        visible: root.hasSeparator
    }
}

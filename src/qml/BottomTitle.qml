import QtQuick
import Logos.Theme
import Logos.Controls

Item {
    id: root

    property string title: ""
    property string color: Theme.palette.text
    property string helpText: ""
    property string actionText: ""
    property bool hasSeparator: true

    signal actionClicked()

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

    LogosButton {
        id: actionButton
        visible: root.actionText.length > 0
        text: root.actionText
        variant: LogosButton.Variant.Secondary
        radius: Theme.spacing.radiusLarge
        background: CardButtonBackground {}
        leftPadding: Theme.spacing.medium
        rightPadding: Theme.spacing.medium
        implicitHeight: 32
        implicitWidth: implicitContentWidth + leftPadding + rightPadding
        anchors.right: parent.right
        anchors.verticalCenter: footerLabel.verticalCenter
        onClicked: root.actionClicked()
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

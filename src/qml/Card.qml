import QtQuick
import Logos.Theme

Rectangle {
    id: root

    property int padding: Theme.spacing.medium

    default property alias content: contentArea.data

    color: Theme.palette.backgroundSecondary
    border.color: Theme.palette.borderSecondary
    border.width: 1
    radius: Theme.spacing.radiusLarge
    clip: true

    Item {
        id: contentArea
        anchors.fill: parent
        anchors.margins: root.padding
    }
}

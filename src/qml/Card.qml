import QtQuick
import Logos.Theme

Rectangle {
    id: root

    // Padding appliqué autour du contenu enfant
    property int padding: Theme.spacing.medium

    default property alias content: contentArea.data

    color: Theme.palette.backgroundSecondary
    border.color: Theme.palette.borderSecondary
    border.width: 1
    radius: Theme.spacing.radiusLarge

    Item {
        id: contentArea
        anchors.fill: parent
        anchors.margins: root.padding
    }
}

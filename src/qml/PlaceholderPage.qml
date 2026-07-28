import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Logos.Theme
import Logos.Controls

// Empty-state card for a page that isn't built yet. Centered icon + title +
// short description. Reused per unbuilt page via title / description / icon.
LogosFrame {
    id: root

    backgroundColor: Theme.palette.backgroundSecondary
    borderColor: "transparent"
    radius: Theme.spacing.radiusLarge

    property string title: ""
    property string description: ""
    property url icon: ""

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.spacing.xxlarge * 2, 360)
        spacing: Theme.spacing.medium

        Item {
            implicitWidth: 48
            implicitHeight: 48
            Layout.alignment: Qt.AlignHCenter

            Image {
                id: iconImg
                anchors.fill: parent
                source: root.icon
                sourceSize: Qt.size(width * 2, height * 2)
                fillMode: Image.PreserveAspectFit
                visible: false
            }

            MultiEffect {
                anchors.fill: iconImg
                source: iconImg
                colorization: 1.0
                colorizationColor: Theme.palette.textMuted
            }
        }

        LogosText {
            text: root.title
            font.pixelSize: Theme.typography.titleText
            font.weight: Theme.typography.weightBold
            color: Theme.palette.text
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }

        LogosText {
            text: root.description
            font.pixelSize: Theme.typography.primaryText
            color: Theme.palette.textSecondary
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }

        LogosText {
            text: "Coming soon"
            font.pixelSize: Theme.typography.secondaryText
            font.weight: Theme.typography.weightMedium
            color: Theme.palette.textTertiary
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacing.small
        }
    }
}

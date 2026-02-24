import QtQuick
import QtQuick.Layouts
import Logos.Theme

Rectangle {
    id: root

    property bool selected: false
    property string title: ""
    property string description: ""
    property Component icon

    signal cardSelected

    height: 230
    radius: Theme.spacing.radiusLarge
    color: selected ? Theme.palette.backgroundSecondary : Theme.palette.background
    border.color: selected ? Theme.palette.primary : Theme.palette.textMuted
    border.width: 1

    ColumnLayout {
        anchors.fill: parent

        Loader {
            sourceComponent: root.icon
            Layout.topMargin: Theme.spacing.large
            Layout.leftMargin: Theme.spacing.medium
        }

        Item {
            Layout.fillHeight: true
        }

        ColumnLayout {
            Text {
                text: root.title
                color: Theme.palette.text
                font.pixelSize: Theme.typography.titleText * 0.8
                Layout.leftMargin: Theme.spacing.medium
            }

            Text {
                Layout.preferredWidth: 280
                Layout.leftMargin: Theme.spacing.medium
                Layout.bottomMargin: Theme.spacing.large
                Layout.preferredHeight: 30

                text: root.description
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.textSecondary
                wrapMode: Text.WordWrap
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: function () {
            root.cardSelected()
        }
    }
}

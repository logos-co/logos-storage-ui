import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

LogosFrame {
    id: root

    property bool selected: false
    property string title: ""
    property string description: ""
    property Component icon

    signal cardSelected

    height: 230
    padding: 0
    radius: Theme.spacing.radiusLarge
    backgroundColor: selected ? Theme.palette.backgroundSecondary : Theme.palette.background
    borderColor: selected ? Theme.palette.primary : Theme.palette.borderInteractive

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
            LogosText {
                text: root.title
                color: Theme.palette.text
                font.pixelSize: Theme.typography.panelTitleText
                Layout.leftMargin: Theme.spacing.medium
            }

            LogosText {
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
        objectName: parent.objectName + "MouseArea"
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: function () {
            root.cardSelected()
        }
    }
}

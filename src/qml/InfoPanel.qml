import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

// Non-blocking info drawer sliding in from the right. The caller owns the
// content via title / message / accent. Opened programmatically, closed by the
// user: no auto-dismiss.
LogosDrawer {
    id: root

    property alias title: titleText.text
    property alias message: messageText.text
    property color accent: Theme.palette.primary

    edge: Qt.RightEdge
    modal: false
    dragMargin: 0
    padding: 0
    width: 340

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.large
        spacing: Theme.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.small

            Rectangle {
                Layout.preferredWidth: 8
                Layout.preferredHeight: 8
                radius: Theme.spacing.radiusSmall
                Layout.alignment: Qt.AlignVCenter
                color: root.accent
            }

            LogosText {
                id: titleText
                Layout.fillWidth: true
                font.pixelSize: Theme.typography.panelTitleText
                font.weight: Theme.typography.weightBold
                color: Theme.palette.text
                wrapMode: Text.WordWrap
            }

            LogosText {
                text: "×"
                font.pixelSize: Theme.typography.titleText
                color: closeMouse.containsMouse ? Theme.palette.text
                                                : Theme.palette.textTertiary
                Layout.alignment: Qt.AlignTop

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }
        }

        LogosText {
            id: messageText
            Layout.fillWidth: true
            color: Theme.palette.textSecondary
            font.pixelSize: Theme.typography.primaryText
            wrapMode: Text.WordWrap
        }

        Item { Layout.fillHeight: true }
    }
}

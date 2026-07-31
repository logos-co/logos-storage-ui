import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

ColumnLayout {
    anchors.centerIn: parent
    spacing: Theme.spacing.medium
    width: 830

    ColumnLayout {
        id: root

        Layout.fillWidth: true
        spacing: Theme.spacing.small

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: 10
            spacing: Theme.spacing.small

            LogosText {
                text: "Logos Storage"
                font.pixelSize: Theme.typography.subtitleText
                Layout.alignment: Qt.AlignTop
            }

            Item {
                Layout.fillWidth: true
            }

            Column {
                Layout.alignment: Qt.AlignTop
                spacing: Theme.spacing.tiny

                LogosIcon {
                    source: Qt.resolvedUrl("assets/alpha.png")
                    color: Theme.palette.text
                    width: 71
                    height: 10
                }

                LogosText {
                    text: "V. 0.1.3"
                    font.pixelSize: Theme.typography.secondaryText
                    font.family: Theme.typography.mono
                    color: Theme.palette.textMuted
                }
            }
        }

        VaultText {}
    }
}

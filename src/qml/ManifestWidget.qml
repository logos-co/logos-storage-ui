import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

LogosFrame {
    id: root

    backgroundColor: Theme.palette.backgroundSecondary
    borderColor: "transparent"
    radius: Theme.spacing.radiusLarge

    implicitWidth: 300
    implicitHeight: 120

    property var backend: MockBackend
    property bool running: false
    property bool enabled: true

    RowLayout {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomTitle.top
        anchors.bottomMargin: Theme.spacing.small
        spacing: Theme.spacing.medium

        Item {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            implicitHeight: cidInput.implicitHeight

            LogosTextField {
                id: cidInput
                anchors.fill: parent
                leftPadding: Theme.spacing.medium * 2 + Theme.spacing.xlarge
                rightPadding: Theme.spacing.medium * 2 + Theme.spacing.xlarge
                placeholderText: "CID"
                background: CardFieldBackground { radius: Theme.spacing.radiusLarge }
            }

            LogosIcon {
                source: Qt.resolvedUrl("assets/circle-in 1.svg")
                color: cidInput.text.length > 0 ? Theme.palette.text
                                                : cidInput.placeholderTextColor
                width: Theme.spacing.xlarge
                height: Theme.spacing.xlarge
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacing.medium
                anchors.verticalCenter: parent.verticalCenter
            }

            LogosIcon {
                id: helpIcon
                source: Qt.resolvedUrl("assets/info-custom-fill.svg")
                color: cidInput.placeholderTextColor
                width: Theme.spacing.xlarge
                height: Theme.spacing.xlarge
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacing.medium
                anchors.verticalCenter: parent.verticalCenter

                HoverHandler {
                    id: helpHover
                    cursorShape: Qt.PointingHandCursor
                }

                LogosToolTip {
                    text: "Paste the CID shared with you."
                    placement: LogosToolTip.Top
                    visible: helpHover.hovered
                }
            }
        }

        LogosButton {
            radius: Theme.spacing.radiusLarge
            text: "Fetch"
            implicitWidth: 100
            implicitHeight: cidInput.implicitHeight
            variant: LogosButton.Variant.Secondary
            background: CardButtonBackground {}
            Layout.alignment: Qt.AlignTop
            enabled: cidInput.text.length > 0 && root.running && root.enabled
            onClicked: {
                root.backend.downloadManifest(cidInput.text)
                cidInput.text = ""
            }
        }
    }

    BottomTitle {
        id: bottomTitle
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        title: "Fetch Manifest"
        color: Theme.palette.textSecondary
        helpText: "Fetch a shared file's metadata by its CID."
        hasSeparator: false
    }
}

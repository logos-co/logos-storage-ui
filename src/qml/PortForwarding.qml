import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

LogosStorageLayout {
    id: root

    property var tcpPort: 0
    property bool loading: false
    property var backend: MockBackend

    signal back
    signal completed(int port)

    Connections {
        target: root.backend

        function onNatExtConfigCompleted() {
            root.loading = false
            root.completed(root.tcpPort)
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Theme.spacing.medium
        width: 400

        PortIcon {
            animated: root.loading
            dotColor: Theme.palette.text
            Layout.alignment: Qt.AlignHCenter
        }

        LogosText {
            font.pixelSize: Theme.typography.titleText
            text: "Port Configuration"
            Layout.alignment: Qt.AlignHCenter
        }

        LogosText {
            font.pixelSize: Theme.typography.primaryText
            text: "The TCP port must be open to connect with remote peers."
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        LogosTextField {
            Layout.fillWidth: true
            height: 60
            id: tcpPortTextField
            placeholderText: "Enter the TCP port"
            text: root.tcpPort
            enabled: !root.loading
            isValid: {
                const val = parseInt(text)
                return !isNaN(val) && val >= 0 && val <= 65535
            }
            onTextChanged: {
                const val = parseInt(text)
                if (!isNaN(val) && val >= 0 && val <= 65535) {
                    root.tcpPort = val
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spacing.small

            LogosStorageButton {
                text: "Back"
                enabled: !root.loading
                onClicked: root.back()
            }

            LogosStorageButton {
                text: "Next"
                enabled: !root.loading && tcpPortTextField.isValid
                onClicked: {
                    root.loading = true
                    root.backend.enableNatExtConfig(root.tcpPort)
                }
            }
        }

        LogosText {
            font.pixelSize: Theme.typography.primaryText
            text: "Retrieving your public IP..."
            color: Theme.palette.textTertiary
            visible: root.loading
            Layout.alignment: Qt.AlignHCenter
        }
    }

}

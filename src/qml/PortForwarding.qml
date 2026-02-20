import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

LogosStorageLayout {
    id: root

    property var tcpPort: 0
    property bool loading: false
    property var backend: mockBackend

    signal back
    signal completed(int port)

    Connections {
        target: root.backend

        // The nat ext checking needs a bit of
        // time because the Storage backend retrieves
        // the public IP by making a call to the echo service.
        // When the config is done, just push the startNodeComponent.
        function onNatExtConfigCompleted() {
            root.loading = false
            root.completed(root.tcpPort)
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Theme.spacing.medium
        width: 400
        Layout.fillWidth: true

        LogosText {
            id: questionText
            font.pixelSize: Theme.typography.titleText
            text: "Choose your TCP port"
            Layout.alignment: Qt.AlignCenter
        }

        LogosText {
            id: questionDescriptionText
            font.pixelSize: Theme.typography.primaryText
            text: "The TCP port has to be open to connect with other remote peers."
            Layout.alignment: Qt.AlignCenter
        }

        LogosTextField {
            Layout.fillWidth: true
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

        Row {
            spacing: Theme.spacing.small

            LogosStorageButton {
                text: "Back"
                onClicked: {
                    root.back()
                }
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
    }

    QtObject {
        id: mockBackend

        function enableNatExtConfig(port) {}
    }
}

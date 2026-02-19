import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

LogosStorageLayout {
    id: root

    property var tcpPort: 0

    signal portTcpSelected(int port)

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Theme.spacing.medium
        width: 400

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
            isValid: acceptableInput && text.length > 0
            id: tcpPortTextField
            placeholderText: "Enter the TCP port"
            text: root.tcpPort
            validator: IntValidator {
                bottom: 0
                top: 65536
            }
            onTextChanged: {
                if (isValid) {
                    root.tcpPort = parseInt(text)
                }
            }
        }
    }

    LogosStorageButton {
        text: "Next"
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 10
        anchors.rightMargin: 10
        enabled: tcpPortTextField.isValid
        onClicked: root.portTcpSelected(root.tcpPort)
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

Rectangle {
    id: root
    color: Theme.palette.background
    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitWidth: 600
    implicitHeight: 400

    property int discoveryPort: 8090
    property int tcpPort: 0
    property var backend: mockBackend
    property string dataDir: backend.defaultDataDir()
    signal completed

    QtObject {
        id: mockBackend

        function defaultDataDir() {
            return ".cache/storage"
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Theme.spacing.medium
        width: 400

        LogosText {
            id: titleText
            font.pixelSize: Theme.typography.titleText
            text: "Logos Storage"
            //  anchors.verticalCenter: parent.verticalCenter
        }

        ColumnLayout {
            id: discoveryPortColumn
            spacing: Theme.spacing.tiny
            Layout.fillWidth: true

            LogosText {
                text: "Discovery port"
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.text
            }

            LogosTextField {
                isValid: acceptableInput && text.length > 0
                id: discoveryPortTextField
                placeholderText: "Enter the discovery port"
                text: root.discoveryPort
                validator: IntValidator {
                    bottom: 1
                    top: 65535
                }
                onTextChanged: {
                    if (isValid) {
                        root.discoveryPort = parseInt(text)
                    }
                }
            }
        }

        ColumnLayout {
            id: tcpPortColumn
            spacing: Theme.spacing.tiny
            Layout.fillWidth: true

            LogosText {
                text: "TCP port"
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.text
            }

            LogosTextField {
                isValid: acceptableInput && text.length > 0
                id: tcpPortTextField
                placeholderText: "Enter the TCP port"
                text: root.tcpPort
                validator: IntValidator {
                    bottom: 0
                    top: 65535
                }
                onTextChanged: {
                    if (isValid) {
                        root.tcpPort = parseInt(text)
                    }
                }
            }
        }

        ColumnLayout {
            spacing: Theme.spacing.tiny
            Layout.fillWidth: true

            LogosText {
                text: "Data dir"
            }

            RowLayout {
                spacing: Theme.spacing.tiny

                LogosTextField {
                    isValid: text.trim().length > 0
                    id: dataDirTextField
                    placeholderText: "Enter the data dir"
                    text: root.dataDir
                    Layout.fillWidth: true
                    onTextChanged: {
                        root.dataDir = text
                    }
                }

                LogosStorageButton {
                    text: "Choose"
                    onClicked: folderDialog.open()
                }
            }

            FolderDialog {
                id: folderDialog
                onAccepted: {
                    dataDirTextField.text = selectedFolder
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
        enabled: discoveryPortTextField.acceptableInput
                 && tcpPortTextField.acceptableInput && dataDirTextField.isValid
        onClicked: root.completed()
    }
}

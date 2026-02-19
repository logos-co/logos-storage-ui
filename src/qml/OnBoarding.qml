import QtQuick
import QtQuick.Dialogs
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

LogosStorageLayout {
    id: root

    property int discoveryPort: 8090
    property int tcpPort: 0
    property var backend: mockBackend
    property var local: false
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

        LogosText {
            id: titleText
            font.pixelSize: Theme.typography.titleText
            text: "Logos Storage"
            Layout.alignment: Qt.AlignCenter
        }

        LogosText {
            id: questionText
            font.pixelSize: Theme.typography.titleText
            text: "First, let's choose the storage folder"
            Layout.alignment: Qt.AlignCenter
        }

        // ColumnLayout {
        //     id: discoveryPortColumn
        //     spacing: Theme.spacing.tiny
        //     Layout.fillWidth: true

        //     LogosText {
        //         text: "Discovery port"
        //         font.pixelSize: Theme.typography.secondaryText
        //         color: Theme.palette.text
        //     }

        //     LogosTextField {
        //         isValid: acceptableInput && text.length > 0
        //         id: discoveryPortTextField
        //         placeholderText: "Enter the discovery port"
        //         text: root.discoveryPort
        //         validator: IntValidator {
        //             bottom: 1
        //             top: 65535
        //         }
        //         onTextChanged: {
        //             if (isValid) {
        //                 root.discoveryPort = parseInt(text)
        //             }
        //         }
        //     }
        // }
        ColumnLayout {
            spacing: Theme.spacing.tiny
            Layout.fillWidth: true

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

        // Column {
        //     CheckBox {
        //         text: "Do you want to connect to a local network ?"
        //         checked: false
        //         onCheckedChanged: root.local = checked
        //     }

        //     LogosText {
        //         font.pixelSize: Theme.typography.secondaryText
        //         text: "You will not "
        //         Layout.alignment: Qt.AlignCenter
        //     }
        // }
    }

    LogosStorageButton {
        text: "Next"
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 10
        anchors.rightMargin: 10
        enabled: dataDirTextField.isValid
        // enabled: discoveryPortTextField.acceptableInput
        //          && tcpPortTextField.acceptableInput && dataDirTextField.isValid
        onClicked: function () {
            root.completed()
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Logos.DesignSystem
import Logos.Controls

Rectangle {
    id: root
    width: 600
    height: 400
    color: Theme.palette.background

    property int discoveryPort: 8090
    property string dataDir: ".storage/data-dir"
    property var backend: mockBackend
    signal completed

    QtObject {
        id: mockBackend

        function validateDataDir(path) {
            return path != "error"
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Theme.spacing.medium
        width: 400

        LogosText {
            id: titleText
            font.pixelSize: Theme.typography.headerText
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

            TextField {
                property bool isValid: acceptableInput && text.length > 0

                id: discoveryPortTextField
                placeholderText: "Enter the discovery port"
                placeholderTextColor: Theme.palette.textPlaceholder
                color: acceptableInput ? Theme.palette.text : Theme.palette.error
                selectByMouse: true
                text: root.discoveryPort
                padding: 8
                validator: IntValidator {
                    bottom: 1
                    top: 65535
                }
                onTextChanged: {
                    if (isValid) {
                        root.discoveryPort = parseInt(text)
                    }
                }
                background: Rectangle {
                    Rectangle {
                        anchors.fill: parent
                        color: Theme.palette.backgroundSecondary
                    }

                    // Border bottom
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: discoveryPortTextField.isValid ? Theme.palette.textMuted : Theme.palette.error
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

                TextField {
                    property bool isValid: true

                    id: dataDirTextField
                    padding: 8
                    placeholderText: "Enter the data dir"
                    placeholderTextColor: Theme.palette.textPlaceholder
                    color: isValid ? Theme.palette.text : Theme.palette.error
                    selectByMouse: true
                    text: root.dataDir
                    Layout.fillWidth: true
                    background: Rectangle {
                        Rectangle {
                            anchors.fill: parent
                            color: Theme.palette.backgroundSecondary
                        }

                        // Border bottom
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 1
                            color: dataDirTextField.isValid ? Theme.palette.textMuted : Theme.palette.error
                        }
                    }
                    onTextChanged: {
                        if (text.length > 0) {
                            isValid = root.backend.validateDataDir(text)
                        } else {
                            isValid = false
                        }

                        root.dataDir = text
                    }
                }

                Button {
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

        Button {
            text: "Next"
            enabled: discoveryPortTextField.acceptableInput
                     && dataDirTextField.isValid
            onClicked: root.completed()
        }
    }
}

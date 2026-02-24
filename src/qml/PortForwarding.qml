import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

OnBoardingLayout {
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

    OnBoardingContainer {
        spacing: Theme.spacing.medium

        OnBoardingProgress {
            Layout.fillWidth: true
            currentStep: 1
            Layout.topMargin: Theme.spacing.small
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 10

            RowLayout {
                Layout.fillWidth: true

                LogosText {
                    text: "Port Configuration"
                    font.pixelSize: Theme.typography.titleText
                    font.weight: Font.Bold
                }

                Item {
                    Layout.fillWidth: true
                }

                LogosText {
                    text: "2 / 5"
                    font.pixelSize: Theme.typography.primaryText
                    color: Theme.palette.primary
                    font.family: "monospace"
                }
            }

            LogosText {
                text: "The TCP port must be open to connect with remote peers."
                font.pixelSize: Theme.typography.primaryText * 1.8
            }
        }

        Rectangle {
            property bool selected: false
            property Component icon

            Layout.fillWidth: true
            Layout.preferredHeight: 230
            radius: Theme.spacing.radiusLarge
            color: Theme.palette.backgroundSecondary
            border.color: selected ? Theme.palette.primary : Theme.palette.textMuted
            border.width: 1

            ColumnLayout {
                anchors.fill: parent

                PortIcon {
                    Layout.topMargin: Theme.spacing.large
                    Layout.leftMargin: Theme.spacing.medium
                }

                Item {
                    Layout.fillHeight: true
                }

                LogosText {
                    text: "Port"
                    font.pixelSize: Theme.typography.primaryText * 1.2
                    Layout.leftMargin: Theme.spacing.medium
                    Layout.bottomMargin: Theme.spacing.tiny
                }

                LogosTextField {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.spacing.medium
                    Layout.rightMargin: Theme.spacing.medium
                    Layout.bottomMargin: Theme.spacing.large

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
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spacing.small

            LogosStorageButton {
                text: "Back"
                enabled: !root.loading
                onClicked: root.back()
                iconSource: "assets/arrow-left.png"
                iconPosition: "left"
            }

            Item {
                Layout.fillWidth: true
            }

            LogosStorageButton {
                text: "Continue"
                enabled: !root.loading && tcpPortTextField.isValid
                iconSource: "assets/arrow-right.png"
                iconPosition: "right"
                variant: "primary"
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

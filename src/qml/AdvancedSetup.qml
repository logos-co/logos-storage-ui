import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

LogosStorageLayout {
    id: root

    property var backend: null

    signal back
    signal completed

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40
        spacing: Theme.spacing.medium

        LogosText {
            text: "Advanced Configuration"
            font.pixelSize: Theme.typography.titleText
            Layout.alignment: Qt.AlignHCenter
        }

        LogosText {
            text: "Edit the JSON configuration below, then click Validate."
            font.pixelSize: Theme.typography.primaryText
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // ── JSON editor ──────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#1e1e1e"
            radius: 8
            border.color: jsonArea.isValid ? "#3a3a3a" : "#ff0000"
            border.width: 1

            ScrollView {
                anchors.fill: parent
                anchors.margins: 2

                TextArea {
                    id: jsonArea
                    font.family: "monospace"
                    font.pixelSize: 12
                    color: "#d4d4d4"
                    wrapMode: Text.WrapAnywhere
                    background: Item {}

                    property bool isValid: true

                    Component.onCompleted: {
                        text = (root.backend
                                && root.backend.configJson) ? root.backend.configJson : "{}"
                        validate()
                    }

                    function validate() {
                        try {
                            JSON.parse(text)
                            isValid = true
                        } catch (e) {
                            isValid = false
                        }
                    }

                    onTextChanged: validate()
                }
            }
        }

        // ── Buttons ──────────────────────────────────────────────────────
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spacing.medium

            LogosStorageButton {
                text: "Back"
                onClicked: root.back()
            }

            Rectangle {
                width: 120
                height: 36
                radius: 8
                color: jsonArea.isValid ? "#4CAF50" : "#444444"

                Text {
                    anchors.centerIn: parent
                    text: "Validate"
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: jsonArea.isValid
                    cursorShape: jsonArea.isValid ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: function () {
                        root.backend.saveUserConfig(jsonArea.text)
                        root.backend.reloadIfChanged(jsonArea.text)
                        root.completed()
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

Popup {
    id: root

    property var backend

    modal: true
    width: 520
    height: 400
    anchors.centerIn: Overlay.overlay
    padding: 24
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        color: Theme.palette.backgroundSecondary
        border.color: Theme.palette.borderSecondary
        border.width: 1
        radius: 14
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacing.small

        LogosText {
            text: "Configuration"
            font.pixelSize: Theme.typography.titleText
            Layout.alignment: Qt.AlignHCenter
        }

        LogosText {
            text: "Edit the JSON configuration below, then click Save."
            font.pixelSize: Theme.typography.primaryText
            color: Theme.palette.textSecondary
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // ── JSON editor ───────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.palette.backgroundElevated
            radius: 8
            border.color: jsonArea.isValid
                ? Theme.palette.borderSecondary : Theme.palette.error
            border.width: 1

            ScrollView {
                anchors.fill: parent
                anchors.margins: 2

                TextArea {
                    id: jsonArea
                    font.family: "monospace"
                    font.pixelSize: 12
                    color: Theme.palette.text
                    wrapMode: Text.WrapAnywhere
                    background: Item {}

                    property bool isValid: true

                    function validate() {
                        try { JSON.parse(text); isValid = true }
                        catch (e) { isValid = false }
                    }

                    onTextChanged: validate()

                    Component.onCompleted: {
                        text = (root.backend && root.backend.configJson)
                               ? root.backend.configJson : "{}"
                        validate()
                    }

                    Connections {
                        target: root.backend
                        function onConfigJsonChanged() {
                            jsonArea.text = root.backend.configJson
                        }
                    }
                }
            }
        }

        // ── Buttons ───────────────────────────────────────────────────────────
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spacing.medium

            LogosStorageButton {
                text: "Cancel"
                onClicked: root.close()
            }

            LogosStorageButton {
                text: "Save"
                variant: "success"
                enabled: jsonArea.isValid
                onClicked: {
                    root.backend.saveUserConfig(jsonArea.text)
                    root.backend.reloadIfChanged(jsonArea.text)
                    root.close()
                }
            }
        }
    }
}

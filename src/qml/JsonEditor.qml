import QtQuick
import QtQuick.Controls
import Logos.Theme

// Reusable JSON editor with live validation.
// Usage:
//   JsonEditor {
//       id: editor
//       Layout.fillWidth: true
//       Layout.fillHeight: true
//   }
//   // Load content (e.g. when a popup opens):
//   editor.load(backend.configJson() || "{}")
//   // Read back:
//   editor.text      // current text
//   editor.isValid   // false when JSON.parse would throw
Rectangle {
    id: root

    property alias text: jsonArea.text
    property bool isValid: true

    Component.onCompleted: root.validate()

    color: Theme.palette.backgroundElevated
    radius: 8
    border.color: root.isValid ? Theme.palette.borderSecondary : Theme.palette.error
    border.width: 1

    function load(_text) {
        text = _text
    }

    function validate() {
        try {
            JSON.parse(jsonArea.text)
            isValid = true
        } catch (e) {
            isValid = false
        }
    }

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
            onTextChanged: root.validate()
        }
    }
}

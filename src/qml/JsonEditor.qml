import QtQuick
import QtQuick.Controls
import Logos.Theme
import Logos.Controls

// Reusable JSON editor with live validation.
// Usage:
//   JsonEditor {
//       id: editor
//       Layout.fillWidth: true
//       Layout.fillHeight: true
//   }
//   // Load content (e.g. when a popup opens):
//   editor.load(backend.defaultConfigJson || "{}")
//   // Read back:
//   editor.text      // current text
//   editor.isValid   // false when JSON.parse would throw
LogosFrame {
    id: root

    property alias text: jsonArea.text
    property bool isValid: true

    Component.onCompleted: root.validate()

    backgroundColor: Theme.palette.backgroundElevated
    radius: Theme.spacing.radiusLarge
    borderColor: root.isValid ? Theme.palette.borderSecondary : Theme.palette.error
    // The editor fills the frame; the inner ScrollView keeps its own inset.
    padding: 0

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

    LogosScrollView {
        anchors.fill: parent
        anchors.margins: Theme.spacing.tiny

        LogosTextArea {
            id: jsonArea
            font.family: Theme.typography.mono
            font.pixelSize: Theme.typography.secondaryText
            wrapMode: Text.WrapAnywhere
            background: Item {}
            onTextChanged: root.validate()
        }
    }
}

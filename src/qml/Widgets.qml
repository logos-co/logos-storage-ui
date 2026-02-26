import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

// qmllint disable unqualified
ColumnLayout {
    id: root

    property var backend: MockBackend
    property bool running: false

    spacing: 0

    Connections {
        target: root.backend
        function onDownloadCompleted() {}
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacing.medium

        PeersWidget {
            backend: root.backend
        }
    }
}

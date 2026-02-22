import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

ArcWidget {
    id: root

    property var backend: mockBackend
    property double total: 0
    property double used: 0

    fraction: root.total > 0 ? Math.min(root.used / root.total, 1.0) : 0

    function formatBytes(bytes) {
        if (bytes <= 0) {
            return "0 B"
        }

        if (bytes < 1024) {
            return bytes + " B"
        }

        if (bytes < 1024 * 1024) {
            return (bytes / 1024).toFixed(1) + " KB"
        }

        if (bytes < 1024 * 1024 * 1024) {
            return (bytes / (1024 * 1024)).toFixed(1) + " MB"
        }

        return (bytes / (1024 * 1024 * 1024)).toFixed(2) + " GB"
    }

    function refreshSpace() {
        let space = root.backend.space()
        root.total = space.total
        root.used = space.used
    }

    Connections {
        target: root.backend

        function onSpaceUpdated(total, used) {
            root.total = total
            root.used = used
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 2

        LogosText {
            text: root.total > 0 ? root.formatBytes(root.used) : "—"
            font.pixelSize: 15
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        LogosText {
            text: "STORAGE"
            font.pixelSize: 9
            color: Theme.palette.textTertiary
            font.letterSpacing: 1.3
            Layout.alignment: Qt.AlignHCenter
        }
    }

    QtObject {
        id: mockBackend

        signal spaceUpdated(double total, double used)
        signal uploadCompleted
        signal downloadCompleted

        function space() {
            return {
                "total": 0,
                "used": 0
            }
        }
    }
}

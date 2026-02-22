import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

ArcWidget {
    id: root

    property int uploadProgress: 0 // 0–100
    property bool running: false

    readonly property bool isUploading: uploadProgress > 0
                                        && uploadProgress < 100
    readonly property bool isDone: uploadProgress >= 100

    signal uploadRequested

    fraction: root.uploadProgress / 100.0
    fillColor: root.isDone ? Theme.palette.success : Theme.palette.text

    // ── Center content ────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 2

        // Idle or done: upload icon
        UploadIcon {
            dotColor: Theme.palette.textSecondary
            dotSize: 4
            dotSpacing: 3
            activeOpacity: 0.5
            visible: !root.isUploading
            Layout.alignment: Qt.AlignHCenter
        }

        // Uploading: percentage
        LogosText {
            text: root.uploadProgress + "%"
            font.pixelSize: 22
            font.bold: true
            visible: root.isUploading
            Layout.alignment: Qt.AlignHCenter
        }

        LogosText {
            text: root.isDone ? "DONE" : "UPLOAD"
            font.pixelSize: 9
            color: Theme.palette.textTertiary
            font.letterSpacing: 1.2
            Layout.alignment: Qt.AlignHCenter
        }
    }

    HoverHandler {
        id: widgetHover
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: widgetHover.hovered
               && root.running ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: root.running ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.running) {
                       root.uploadRequested()
                   }
    }
}

import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

// qmllint disable unqualified
RowLayout {
    id: root

    property var backend: MockBackend
    property bool nodeIsUp: false
    property bool blinkOn: false

    readonly property int stopped: 0
    readonly property int starting: 1
    readonly property int running: 2
    readonly property int stopping: 3
    readonly property int destroyed: 4

    signal settingsRequested()

    spacing: Theme.spacing.medium

    StorageIcon {
        animated: root.backend.status === root.starting
                  || root.backend.status === root.stopping
        dotColor: {
            if (root.backend.status === root.starting)
                return Theme.palette.warning
            if (root.backend.status !== root.running)
                return Theme.palette.textMuted
            return root.nodeIsUp ? Theme.palette.success : Theme.palette.error
        }
    }

    ColumnLayout {
        spacing: 6

        LogosText {
            text: "Logos Storage"
            font.pixelSize: Theme.typography.titleText
        }

        RowLayout {
            spacing: 7

            Rectangle {
                Layout.preferredWidth: 7
                Layout.preferredHeight: 7
                radius: 3.5
                Layout.alignment: Qt.AlignVCenter
                color: {
                    if (root.backend.status === root.starting)
                        return Theme.palette.warning
                    if (root.backend.status !== root.running)
                        return Theme.palette.textMuted
                    return root.nodeIsUp ? Theme.palette.success : Theme.palette.error
                }
                opacity: root.backend.status === root.running
                         ? (root.blinkOn ? 1.0 : 0.15) : 1.0
            }

            LogosText {
                text: {
                    switch (root.backend.status) {
                    case root.stopped:    return "Stopped"
                    case root.starting:  return "Starting…"
                    case root.running:   return "Running"
                    case root.stopping:  return "Stopping…"
                    case root.destroyed: return "Not initialised"
                    default:             return ""
                    }
                }
                font.pixelSize: Theme.typography.primaryText
                color: Theme.palette.textSecondary
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    Item {
        Layout.fillWidth: true
    }

    Rectangle {
        Layout.preferredWidth: 44
        Layout.preferredHeight: 44
        radius: 8
        color: settingsHover.hovered ? Theme.palette.backgroundElevated : "transparent"
        border.color: Theme.palette.borderSecondary
        border.width: 1

        SettingsIcon {
            anchors.centerIn: parent
            dotColor: Theme.palette.text
            dotSize: 5
            dotSpacing: 2
        }

        HoverHandler {
            id: settingsHover
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.settingsRequested()
        }
    }

    Rectangle {
        Layout.preferredWidth: 44
        Layout.preferredHeight: 44
        radius: 8
        color: startStopHover.hovered ? Theme.palette.backgroundElevated : "transparent"
        border.color: Theme.palette.borderSecondary
        border.width: 1
        opacity: (root.backend.status === root.running
                  || root.backend.status === root.stopped) ? 1.0 : 0.4

        PlayIcon {
            anchors.centerIn: parent
            dotColor: Theme.palette.text
            dotSize: 5
            dotSpacing: 2
            visible: root.backend.status !== root.running
        }
        StopIcon {
            anchors.centerIn: parent
            dotColor: Theme.palette.text
            dotSize: 5
            dotSpacing: 2
            visible: root.backend.status === root.running
        }

        HoverHandler {
            id: startStopHover
        }
        MouseArea {
            anchors.fill: parent
            enabled: root.backend.status === root.running
                     || root.backend.status === root.stopped
            cursorShape: Qt.PointingHandCursor
            onClicked: root.backend.status === root.running
                       ? root.backend.stop() : root.backend.start()
        }
    }
}

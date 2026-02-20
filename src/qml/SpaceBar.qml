import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

ColumnLayout {
    id: root

    property real total: 0
    property real used: 0
    property real reserved: 0
    readonly property real free: Math.max(0, total - used - reserved)

    spacing: 8

    function formatBytes(bytes) {
        if (bytes <= 0) return "0 B"
        if (bytes < 1024) return bytes + " B"
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB"
        if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + " MB"
        return (bytes / (1024 * 1024 * 1024)).toFixed(2) + " GB"
    }

    // ── Section title ─────────────────────────────────────────────────────────
    LogosText {
        text: "DISK USAGE"
        font.pixelSize: 11
        color: Theme.palette.textTertiary
        font.letterSpacing: 1.5
    }

    // ── No quota message ──────────────────────────────────────────────────────
    LogosText {
        text: "No quota configured"
        color: Theme.palette.textMuted
        font.pixelSize: 12
        visible: root.total <= 0
    }

    // ── Progress track ────────────────────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        height: 10
        radius: 5
        color: Theme.palette.backgroundElevated
        border.color: Theme.palette.borderSecondary
        border.width: 1
        visible: root.total > 0
        clip: true

        // Used (green)
        Rectangle {
            width: Math.min(parent.width * (root.used / root.total), parent.width)
            height: parent.height
            radius: parent.radius
            color: Theme.palette.success
        }

        // Reserved (orange), stacked after used
        Rectangle {
            x: parent.width * (root.used / root.total)
            width: Math.min(
                parent.width * (root.reserved / root.total),
                parent.width - x)
            height: parent.height
            color: Theme.palette.warning
        }
    }

    // ── Legend ────────────────────────────────────────────────────────────────
    Row {
        visible: root.total > 0
        spacing: 18

        Row {
            spacing: 5
            Rectangle { width: 7; height: 7; radius: 2; color: Theme.palette.success; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "Used · " + root.formatBytes(root.used); color: Theme.palette.success; font.pixelSize: 11 }
        }
        Row {
            spacing: 5
            Rectangle { width: 7; height: 7; radius: 2; color: Theme.palette.warning; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "Reserved · " + root.formatBytes(root.reserved); color: Theme.palette.warning; font.pixelSize: 11 }
        }
        Row {
            spacing: 5
            Rectangle { width: 7; height: 7; radius: 2; color: Theme.palette.textSecondary; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "Free · " + root.formatBytes(root.free); color: Theme.palette.textSecondary; font.pixelSize: 11 }
        }
        Row {
            spacing: 5
            Rectangle { width: 7; height: 7; radius: 2; color: Theme.palette.textMuted; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "Total · " + root.formatBytes(root.total); color: Theme.palette.textMuted; font.pixelSize: 11 }
        }
    }
}

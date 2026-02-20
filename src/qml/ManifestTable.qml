import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

ColumnLayout {
    id: root

    property var backend
    property bool running: false

    signal downloadRequested(var manifest)

    spacing: Theme.spacing.small

    function formatBytes(bytes) {
        if (bytes <= 0) return "0 B"
        if (bytes < 1024) return bytes + " B"
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB"
        if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + " MB"
        return (bytes / (1024 * 1024 * 1024)).toFixed(2) + " GB"
    }

    // ── Section title ─────────────────────────────────────────────────────────
    LogosText {
        text: "MANIFESTS"
        font.pixelSize: 11
        color: Theme.palette.textTertiary
        font.letterSpacing: 1.5
    }

    // ── CID input + fetch button ──────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacing.small

        LogosTextField {
            id: cidInput
            Layout.fillWidth: true
            placeholderText: "Enter CID to fetch manifest…"
        }

        LogosStorageButton {
            text: "↓  Fetch"
            enabled: root.running && cidInput.text.length > 0
            onClicked: {
                root.backend.downloadManifest(cidInput.text)
                cidInput.clear()
            }
        }
    }

    // ── Table header ──────────────────────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        height: 30
        color: Theme.palette.backgroundElevated
        radius: 4

        Row {
            anchors.fill: parent
            anchors.leftMargin: 10

            Text { width: 160; text: "CID";      color: Theme.palette.textSecondary; font.pixelSize: 11; font.bold: true; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter }
            Text { width: 130; text: "Filename"; color: Theme.palette.textSecondary; font.pixelSize: 11; font.bold: true; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter }
            Text { width: 90;  text: "MIME";     color: Theme.palette.textSecondary; font.pixelSize: 11; font.bold: true; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter }
            Text { width: 80;  text: "Size";     color: Theme.palette.textSecondary; font.pixelSize: 11; font.bold: true; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter }
        }
    }

    // ── Table body ────────────────────────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        height: 240
        color: Theme.palette.background
        border.color: Theme.palette.borderSecondary
        border.width: 1
        radius: 4
        clip: true

        ListView {
            id: manifestList
            anchors.fill: parent
            model: root.backend ? root.backend.manifests : []
            clip: true

            delegate: Rectangle {
                width: manifestList.width
                height: 36
                color: index % 2 === 0 ? Theme.palette.background : Theme.palette.backgroundSecondary

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8

                    Text {
                        width: 160
                        text: modelData["cid"] ?? ""
                        color: Theme.palette.text
                        font.pixelSize: 11
                        font.family: "monospace"
                        elide: Text.ElideMiddle
                        anchors.verticalCenter: parent.verticalCenter
                        ToolTip.visible: cidHover.hovered
                        ToolTip.text: modelData["cid"] ?? ""
                        HoverHandler { id: cidHover }
                    }
                    Text {
                        width: 130
                        text: modelData["filename"] ?? ""
                        color: Theme.palette.textSecondary
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        width: 90
                        text: modelData["mimetype"] ?? ""
                        color: Theme.palette.textSecondary
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        width: 80
                        text: root.formatBytes(parseInt(modelData["datasetSize"] ?? "0"))
                        color: Theme.palette.textSecondary
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // ── Action buttons ────────────────────────────────────────
                    Row {
                        spacing: 6
                        anchors.verticalCenter: parent.verticalCenter

                        // Download
                        Rectangle {
                            width: 28; height: 28; radius: 4
                            color: dlHover.hovered ? Theme.palette.backgroundElevated : "transparent"
                            border.color: Theme.palette.borderSecondary
                            border.width: 1
                            opacity: root.running ? 1.0 : 0.35

                            Text {
                                anchors.centerIn: parent
                                text: "↓"
                                color: Theme.palette.text
                                font.pixelSize: 14
                            }
                            HoverHandler { id: dlHover }
                            MouseArea {
                                anchors.fill: parent
                                enabled: root.running
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.downloadRequested(modelData)
                            }
                        }

                        // Delete
                        Rectangle {
                            width: 28; height: 28; radius: 4
                            color: rmHover.hovered ? Theme.palette.backgroundElevated : "transparent"
                            border.color: Theme.palette.borderSecondary
                            border.width: 1
                            opacity: root.running ? 1.0 : 0.35

                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                color: Theme.palette.error
                                font.pixelSize: 16
                                font.bold: true
                            }
                            HoverHandler { id: rmHover }
                            MouseArea {
                                anchors.fill: parent
                                enabled: root.running
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.backend.remove(modelData["cid"] ?? "")
                            }
                        }
                    }
                }
            }

            // ── Empty state ───────────────────────────────────────────────────
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10
                visible: manifestList.count === 0

                DotIcon {
                    pattern: [
                        0, 0, 1, 0, 0,
                        0, 1, 0, 1, 0,
                        1, 0, 0, 0, 1,
                        0, 1, 0, 1, 0,
                        0, 0, 1, 0, 0
                    ]
                    dotColor: Theme.palette.textMuted
                    activeOpacity: 0.25
                    Layout.alignment: Qt.AlignHCenter
                }

                LogosText {
                    text: "No manifests yet"
                    color: Theme.palette.textMuted
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}

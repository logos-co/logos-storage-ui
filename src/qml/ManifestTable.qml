import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtCore
import Logos.Theme
import Logos.Controls
import "Utils.js" as Utils

// qmllint disable unqualified
Card {
    id: root

    property var backend: MockBackend
    property bool running: false
    property var manifests: []
    property bool panelOpen: false

    // property var manifests: [{
    //         "cid": "1234",
    //         "filename": "Claude.jpg",
    //         "mimetype": "image/jpg",
    //         "size": 12222
    //     }]
    function mimetypeIcon(mimetype) {
        if (!mimetype)
            return "assets/other.png"
        var m = mimetype.toLowerCase()
        if (m.indexOf("image/") === 0)
            return "assets/image.png"
        if (m.indexOf("video/") === 0)
            return "assets/video.png"
        if (m === "application/pdf")
            return "assets/pdf.png"
        return "assets/other.png"
    }

    implicitWidth: 1200
    implicitHeight: 400

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacing.small

        Connections {
            target: root.backend

            onManifestsUpdated: function (manifests) {
                root.manifests = manifests
            }
        }

        // ── Title row ─────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true

            LogosText {
                text: root.panelOpen ? "Debug" : "Manifests"
                font.pixelSize: Theme.typography.titleText
                color: Theme.palette.text
            }

            Item {
                Layout.fillWidth: true
            }

            // Close button — visible uniquement quand le panel debug est ouvert
            Image {
                source: "assets/close-circle.png"
                visible: root.panelOpen

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.panelOpen = false
                }
            }
        }

        // ── Zone de contenu : liste OU panel ──────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ── Vue liste ────────────────────────────────────────────────────
            ColumnLayout {
                anchors.fill: parent
                spacing: Theme.spacing.small
                visible: !root.panelOpen

                // Header sticky (hors du ListView = ne scrolle pas)
                Rectangle {
                    id: header
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    color: Theme.palette.backgroundInset
                    radius: Theme.spacing.radiusSmall

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacing.medium
                        anchors.rightMargin: Theme.spacing.medium

                        Text {
                            text: "CID"
                            color: Theme.palette.textMuted
                            font.pixelSize: Theme.typography.secondaryText
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "Filename"
                            color: Theme.palette.textSecondary
                            font.pixelSize: Theme.typography.secondaryText
                            Layout.preferredWidth: 140
                        }

                        Text {
                            text: "Mimetype"
                            color: Theme.palette.textSecondary
                            font.pixelSize: Theme.typography.secondaryText
                            Layout.preferredWidth: 100
                        }

                        Text {
                            text: "Size"
                            color: Theme.palette.textSecondary
                            font.pixelSize: Theme.typography.secondaryText
                            Layout.preferredWidth: 80
                        }

                        Text {
                            text: "Actions"
                            color: Theme.palette.textSecondary
                            font.pixelSize: Theme.typography.secondaryText
                            Layout.preferredWidth: 92
                        }
                    }
                }

                ListView {
                    id: manifestList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: root.manifests
                    clip: true  // empêche les items de déborder sur le header sticky

                    delegate: Rectangle {
                        width: manifestList.width
                        height: 72
                        color: Theme.palette.backgroundSecondary

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacing.medium
                            anchors.rightMargin: Theme.spacing.medium

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Image {
                                    id: typeIcon
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: root.mimetypeIcon(modelData.mimetype)
                                    width: 32
                                    height: 32
                                    fillMode: Image.PreserveAspectFit
                                }

                                Text {
                                    anchors.left: typeIcon.right
                                    anchors.leftMargin: Theme.spacing.medium
                                    anchors.right: copyBtn.left
                                    anchors.rightMargin: Theme.spacing.medium
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.cid
                                    color: Theme.palette.text
                                    font.pixelSize: Theme.typography.secondaryText
                                    elide: Text.ElideRight
                                    ToolTip.visible: cidHover.hovered
                                    ToolTip.text: modelData.cid

                                    HoverHandler {
                                        id: cidHover
                                    }
                                }

                                Rectangle {
                                    id: copyBtn
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.rightMargin: Theme.spacing.medium
                                    width: 40
                                    height: 40
                                    radius: Theme.spacing.radiusXlarge * 2
                                    border.color: copyHover.hovered ? Theme.palette.primary : Theme.palette.borderSubtle
                                    border.width: 1

                                    property bool copied: false

                                    color: Theme.palette.backgroundInset

                                    Timer {
                                        id: resetCopyTimer
                                        interval: 1500
                                        onTriggered: copyBtn.copied = false
                                    }

                                    Image {
                                        anchors.centerIn: parent
                                        source: copyBtn.copied ? "assets/success.png" : "assets/file-copy-line.png"
                                        width: 20
                                        height: 20
                                        fillMode: Image.PreserveAspectFit
                                    }
                                    HoverHandler {
                                        id: copyHover
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            clipboardHelper.text = modelData.cid
                                            clipboardHelper.selectAll()
                                            clipboardHelper.copy()
                                            copyBtn.copied = true
                                            resetCopyTimer.restart()
                                        }
                                    }
                                }

                                TextEdit {
                                    id: clipboardHelper
                                    visible: false
                                }
                            }

                            Text {
                                text: modelData.filename
                                color: Theme.palette.text
                                font.pixelSize: Theme.typography.secondaryText
                                elide: Text.ElideRight
                                Layout.preferredWidth: 140
                            }

                            Text {
                                text: modelData.mimetype
                                color: Theme.palette.text
                                font.pixelSize: Theme.typography.secondaryText
                                elide: Text.ElideRight
                                Layout.preferredWidth: 100
                            }

                            Text {
                                text: Utils.formatBytes(parseInt(modelData.datasetSize))
                                color: Theme.palette.text
                                font.pixelSize: Theme.typography.secondaryText
                                Layout.preferredWidth: 80
                            }

                            Rectangle {
                                color: Theme.palette.backgroundInset
                                radius: Theme.spacing.radiusLarge
                                Layout.alignment: Qt.AlignVCenter
                                implicitWidth: actionsRow.implicitWidth + Theme.spacing.medium * 2
                                implicitHeight: actionsRow.implicitHeight + Theme.spacing.small * 2

                                Row {
                                    id: actionsRow
                                    anchors.centerIn: parent
                                    spacing: Theme.spacing.medium

                                    Rectangle {
                                        width: 40
                                        height: 40
                                        radius: Theme.spacing.radiusXlarge * 2
                                        color: Theme.palette.backgroundButton
                                        border.color: dlHover.hovered ? Theme.palette.primary : Theme.palette.borderInteractive
                                        border.width: 1

                                        Image {
                                            anchors.centerIn: parent
                                            source: "assets/download.png"
                                            width: 24
                                            height: 24
                                            fillMode: Image.PreserveAspectFit
                                        }

                                        HoverHandler {
                                            id: dlHover
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: root.running
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                saveDialog.pendingManifest = modelData
                                                saveDialog.currentFile = StandardPaths.writableLocation(
                                                            StandardPaths.HomeLocation)
                                                        + "/" + (modelData.filename
                                                                 || modelData.cid
                                                                 || "download")
                                                saveDialog.open()
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: 40
                                        height: 40
                                        radius: Theme.spacing.radiusXlarge * 2
                                        color: Theme.palette.backgroundButton
                                        border.color: rmHover.hovered ? Theme.palette.primary : Theme.palette.borderInteractive
                                        border.width: 1

                                        Image {
                                            anchors.centerIn: parent
                                            source: "assets/delete.png"
                                            width: 20
                                            height: 20
                                            fillMode: Image.PreserveAspectFit
                                        }

                                        HoverHandler {
                                            id: rmHover
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: root.running
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (modelData.cid.length > 0) {
                                                    root.backend.remove(modelData.cid)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Bottom row separator
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Theme.palette.borderSecondary
                        }
                    }

                    // Empty state — enfant du ListView, pas du delegate
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 10
                        visible: manifestList.count === 0

                        DotIcon {
                            pattern: [0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0]
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

            // ── Vue panel : Debug (même structure visuelle que la vue liste) ──
            ColumnLayout {
                anchors.fill: parent
                visible: root.panelOpen
                spacing: Theme.spacing.small

                // Header sticky — même style que la colonne CID/Filename/…
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    color: Theme.palette.backgroundInset
                    radius: Theme.spacing.radiusSmall

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacing.medium
                        anchors.rightMargin: Theme.spacing.medium
                        spacing: Theme.spacing.small

                        LogosStorageButton {
                            text: "Debug"
                            implicitHeight: 24
                            implicitWidth: 70
                            enabled: root.running
                            onClicked: root.backend.logDebugInfo()
                        }
                        LogosStorageButton {
                            text: "Peer ID"
                            implicitHeight: 24
                            implicitWidth: 80
                            enabled: root.running
                            onClicked: root.backend.logPeerId()
                        }
                        LogosStorageButton {
                            text: "Data dir"
                            implicitHeight: 24
                            implicitWidth: 80
                            enabled: root.running
                            onClicked: root.backend.logDataDir()
                        }
                        LogosStorageButton {
                            text: "SPR"
                            implicitHeight: 24
                            implicitWidth: 60
                            enabled: root.running
                            onClicked: root.backend.logSpr()
                        }
                        LogosStorageButton {
                            text: "Version"
                            implicitHeight: 24
                            implicitWidth: 80
                            enabled: root.running
                            onClicked: root.backend.logVersion()
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }
                }

                // Zone de log scrollable
                Flickable {
                    id: logFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: debugLogText.implicitHeight

                    TextEdit {
                        id: debugLogText
                        width: logFlick.width
                        text: root.backend.debugLogs
                        color: Theme.palette.textSecondary
                        font.family: "monospace"
                        font.pixelSize: 11
                        wrapMode: Text.WrapAnywhere
                        readOnly: true
                        padding: Theme.spacing.small
                        bottomPadding: Theme.spacing.large

                        onTextChanged: Qt.callLater(function () {
                            logFlick.contentY = Math.max(
                                        0, logFlick.contentHeight - logFlick.height)
                        })
                    }
                }
            }
        }

        FileDialog {
            id: saveDialog

            property var pendingManifest: null

            fileMode: FileDialog.SaveFile
            onAccepted: {
                if (pendingManifest) {
                    root.backend.downloadFile(
                                pendingManifest.cid, selectedFile,
                                parseInt(pendingManifest.datasetSize) || 0)
                    pendingManifest = null
                }
            }
            onRejected: pendingManifest = null
        }
    }
}

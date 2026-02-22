import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtCore
import Logos.Theme
import Logos.Controls

// qmllint disable unqualified
LogosStorageLayout {
    id: root

    property var backend: mockBackend
    readonly property int stopped: 0
    readonly property int starting: 1
    readonly property int running: 2
    readonly property int stopping: 3
    readonly property int destroyed: 4
    property int peerCount: 0
    property var pendingDownloadManifest: null
    property bool showDebug: false

    function isRunning() {
        return backend.status === running
    }

    function getStatusLabel() {
        switch (backend.status) {
        case stopped:
            return "Stopped"
        case starting:
            return "Starting…"
        case running:
            return "Running"
        case stopping:
            return "Stopping…"
        case destroyed:
            return "Not initialised"
        default:
            return ""
        }
    }

    Component.onCompleted: root.backend.start()

    HealthIndicator {
        id: health
        backend: root.backend
    }

    Connections {
        target: root.backend
        function onPeersUpdated(count) {
            root._peerCount = count
        }
    }

    // ── Clipboard helper (Qt6 has no Qt.copyToClipboard) ─────────────────────
    TextEdit {
        id: clipHelper
        visible: false
        function copyText(str) {
            clipHelper.text = str
            clipHelper.selectAll()
            clipHelper.copy()
        }
    }

    // ── Mock backend ──────────────────────────────────────────────────────────
    QtObject {
        id: mockBackend
        property var status: root.stopped
        property var debugLogs: "Hello!"
        property var configJson: "{}"
        property string uploadStatus: ""
        property int uploadProgress: 0
        property var manifests: []
        property var quotaMaxBytes: 20 * 1024 * 1024 * 1024
        property var quotaUsedBytes: 0
        property string cid: ""

        signal nodeIsUp
        signal nodeIsntUp(string reason)
        signal peersUpdated(int count)

        function start() {
            status = root.running
        }
        function stop() {
            status = root.stopped
        }
        function checkNodeIsUp() {}
        function tryUploadFile(f) {}
        function downloadManifest(c) {}
        function remove(c) {}
        function tryDownloadFile(c, d) {}
        function space() {}
        function tryDebug() {}
        function showPeerId() {}
        function dataDir() {}
        function spr() {}
        function version() {}
        function saveUserConfig(j) {}
        function reloadIfChanged(j) {}
        function configJson() {
            return "{}"
        }
        function peerCount() {
            return 0
        }
    }

    // ── File dialogs ──────────────────────────────────────────────────────────
    FileDialog {
        id: fileDialog
        onAccepted: root.backend.tryUploadFile(fileDialog.selectedFile)
    }

    FileDialog {
        id: manifestSaveDialog
        fileMode: FileDialog.SaveFile
        onAccepted: {
            if (root.pendingDownloadManifest) {
                root.backend.tryDownloadFile(
                            root.pendingDownloadManifest["cid"],
                            manifestSaveDialog.selectedFile)
                root.pendingDownloadManifest = null
            }
        }
        onRejected: root.pendingDownloadManifest = null
    }

    // ── Settings popup ────────────────────────────────────────────────────────
    SettingsPopup {
        id: settingsPopup
        backend: root.backend
    }

    // ── Ctrl+D toggle ─────────────────────────────────────────────────────────
    Shortcut {
        sequence: "Ctrl+D"
        onActivated: root.showDebug = !root.showDebug
    }

    // ── Main scrollable content ───────────────────────────────────────────────
    ScrollView {
        id: mainScroll
        anchors.fill: parent
        anchors.bottomMargin: root.showDebug ? debugPanel.height : 0
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: mainScroll.availableWidth
            spacing: 0

            // ══════════════════════════════════════════════════════════════════
            // Header — node identity + settings + start/stop
            // ══════════════════════════════════════════════════════════════════
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 24
                Layout.rightMargin: 24
                Layout.topMargin: 24
                Layout.bottomMargin: 20
                spacing: Theme.spacing.medium

                StorageIcon {
                    animated: root.backend.status === root.starting
                              || root.backend.status === root.stopping
                    dotColor: {
                        if (root.backend.status === root.starting)
                            return Theme.palette.warning
                        if (!root.isRunning())
                            return Theme.palette.textMuted
                        return health.nodeIsUp ? Theme.palette.success : Theme.palette.error
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
                                if (!root.isRunning())
                                    return Theme.palette.textMuted
                                return health.nodeIsUp ? Theme.palette.success : Theme.palette.error
                            }
                            opacity: root.isRunning(
                                         ) ? (health.blinkOn ? 1.0 : 0.15) : 1.0
                        }

                        LogosText {
                            text: root.getStatusLabel()
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
                        onClicked: settingsPopup.open()
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
                        onClicked: root.backend.status
                                   === root.running ? root.backend.stop(
                                                          ) : root.backend.start()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 24
                Layout.rightMargin: 24
                Layout.preferredHeight: 1
                color: Theme.palette.borderSecondary
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 24
                Layout.rightMargin: 24
                Layout.topMargin: 20
                Layout.bottomMargin: 10
                spacing: Theme.spacing.medium

                UploadWidget {
                    uploadProgress: root.backend.uploadProgress
                    running: root.isRunning()
                    onUploadRequested: fileDialog.open()
                }

                DiskWidget {
                    total: root.backend.quotaMaxBytes
                    used: root.backend.quotaUsedBytes
                }

                PeersWidget {
                    peerCount: root.peerCount
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.leftMargin: 24
                Layout.rightMargin: 24
                Layout.bottomMargin: 20
                Layout.preferredHeight: 36

                opacity: String(root.backend.cid).length > 0 ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                    }
                }

                Rectangle {
                    id: cidBadge
                    height: 36
                    width: cidBadgeRow.implicitWidth + 28
                    radius: 6
                    color: Theme.palette.backgroundSecondary
                    border.color: Theme.palette.borderSecondary
                    border.width: 1

                    RowLayout {
                        id: cidBadgeRow
                        anchors.centerIn: parent
                        spacing: 8

                        LogosText {
                            text: "CID"
                            font.pixelSize: 10
                            color: Theme.palette.textTertiary
                        }

                        LogosText {
                            text: {
                                var c = String(root.backend.cid)
                                return c.length > 20 ? c.substring(
                                                           0,
                                                           8) + "…" + c.slice(
                                                           -6) : c
                            }
                            font.pixelSize: 11
                            font.family: "monospace"
                            color: Theme.palette.text
                        }

                        LogosText {
                            text: "COPY"
                            font.pixelSize: 9
                            color: Theme.palette.textTertiary
                            font.letterSpacing: 0.8
                        }
                    }

                    // ── Green flash on copy ───────────────────────────────────
                    Rectangle {
                        id: copyFlash
                        anchors.fill: parent
                        radius: parent.radius
                        color: Theme.palette.success
                        opacity: 0

                        SequentialAnimation on opacity {
                            id: copyFlashAnim
                            running: false
                            NumberAnimation {
                                to: 0.18
                                duration: 80
                            }
                            NumberAnimation {
                                to: 0
                                duration: 500
                            }
                        }
                    }

                    HoverHandler {
                        id: cidBadgeHover
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: cidBadgeHover.hovered ? Qt.rgba(
                                                           1, 1, 1,
                                                           0.04) : "transparent"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            clipHelper.copyText(String(root.backend.cid))
                            copyFlashAnim.restart()
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 24
                Layout.rightMargin: 24
                Layout.preferredHeight: 1
                color: Theme.palette.borderSecondary
            }

            ManifestTable {
                Layout.fillWidth: true
                Layout.leftMargin: 24
                Layout.rightMargin: 24
                Layout.topMargin: 20
                Layout.bottomMargin: 20
                backend: root.backend
                running: root.isRunning()
                onDownloadRequested: function (manifest) {
                    root.pendingDownloadManifest = manifest
                    var filename = manifest["filename"] || manifest["cid"]
                            || "download"
                    manifestSaveDialog.currentFile = StandardPaths.writableLocation(
                                StandardPaths.HomeLocation) + "/" + filename
                    manifestSaveDialog.open()
                }
            }

            Item {
                Layout.preferredHeight: 20
            }
        }
    }

    Rectangle {
        id: debugPanel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 220
        color: Theme.palette.backgroundElevated
        border.color: Theme.palette.borderSecondary
        border.width: 1
        visible: root.showDebug

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Dev action buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.topMargin: 6
                Layout.bottomMargin: 4
                spacing: 6

                LogosStorageButton {
                    text: "Space"
                    enabled: root.isRunning()
                    onClicked: root.backend.space()
                }
                LogosStorageButton {
                    text: "Debug"
                    enabled: root.isRunning()
                    onClicked: root.backend.tryDebug()
                }
                LogosStorageButton {
                    text: "Peer ID"
                    enabled: root.isRunning()
                    onClicked: root.backend.showPeerId()
                }
                LogosStorageButton {
                    text: "Data dir"
                    enabled: root.isRunning()
                    onClicked: root.backend.dataDir()
                }
                LogosStorageButton {
                    text: "SPR"
                    enabled: root.isRunning()
                    onClicked: root.backend.spr()
                }
                LogosStorageButton {
                    text: "Version"
                    enabled: root.isRunning()
                    onClicked: root.backend.version()
                }
                Item {
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.palette.borderSecondary
            }

            // Logs
            Flickable {
                id: logFlick
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: debugText.paintedHeight

                TextEdit {
                    id: debugText
                    width: logFlick.width
                    text: root.backend.debugLogs
                    color: Theme.palette.textSecondary
                    font.family: "monospace"
                    font.pixelSize: 11
                    wrapMode: Text.WrapAnywhere
                    readOnly: true
                    padding: 8
                    bottomPadding: 20

                    onTextChanged: Qt.callLater(function () {
                        logFlick.contentY = Math.max(
                                    0, logFlick.contentHeight - logFlick.height)
                    })
                }
            }
        }
    }
}

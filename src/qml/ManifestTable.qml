import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
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
    property bool isDownloading: false
    property string downloadingCid: ""
    property string downloadFolderPath: ""
    property var deleting: ({})

    function markDeleting(cid) {
        var d = Object.assign({}, root.deleting)
        d[cid] = true
        root.deleting = d
    }

    function unmarkDeleting(cid) {
        var d = Object.assign({}, root.deleting)
        delete d[cid]
        root.deleting = d
    }

    function pruneDeleting() {
        var d = {}
        for (var i = 0; i < root.manifests.length; i++) {
            var cid = root.manifests[i].cid
            if (root.deleting[cid]) {
                d[cid] = true
            }
        }
        root.deleting = d
    }

    signal downloadRequested

    // Background manifest fetches in progress / failed. Each entry:
    // { cid, status: "fetching" | "error", error }. Shown as rows above the
    // real manifests until the fetch resolves (success refreshes the list and
    // prunes the row; failure switches it to "error" until dismissed).
    property var pending: []
    property var rows: root.pending.concat(root.manifests)

    function addPending(cid) {
        for (var i = 0; i < root.pending.length; i++)
            if (root.pending[i].cid === cid)
                return
        var p = root.pending.slice()
        p.unshift({
            "cid": cid,
            "status": "fetching",
            "error": ""
        })
        root.pending = p
    }

    function failPending(cid, error) {
        var p = root.pending.slice()
        for (var i = 0; i < p.length; i++) {
            if (p[i].cid === cid) {
                p[i] = {
                    "cid": cid,
                    "status": "error",
                    "error": error
                }
                root.pending = p
                return
            }
        }
    }

    function dismissPending(cid) {
        root.pending = root.pending.filter(function (e) {
            return e.cid !== cid
        })
    }

    function prunePending() {
        var existing = {}
        for (var i = 0; i < root.manifests.length; i++)
            existing[root.manifests[i].cid] = true
        root.pending = root.pending.filter(function (e) {
            return !(e.status === "fetching" && existing[e.cid])
        })
    }

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

    Shortcut {
        sequence: "Ctrl+D"
        onActivated: root.panelOpen = !root.panelOpen
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacing.small

        Connections {
            target: root.backend

            function onManifestsUpdated(manifests) {
                root.manifests = manifests
                root.prunePending()
                root.pruneDeleting()
            }

            function onRemoveStarted(cid) {
                root.markDeleting(cid)
            }

            function onRemoveFailed(cid, error) {
                root.unmarkDeleting(cid)
            }

            function onManifestFetchStarted(cid) {
                root.addPending(cid)
            }

            function onManifestFetchFailed(cid, error) {
                root.failPending(cid, error)
            }

            function onDownloadStarted(cid, filename, total) {
                root.isDownloading = true
                root.downloadingCid = cid
            }

            function onDownloadCompleted(cid) {
                root.isDownloading = false
                root.downloadingCid = ""
            }

            function onError(message) {
                root.isDownloading = false
                root.downloadingCid = ""
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

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ── Vue liste ────────────────────────────────────────────────────
            ColumnLayout {
                anchors.fill: parent
                spacing: Theme.spacing.small
                visible: !root.panelOpen

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
                    model: root.rows
                    clip: true

                    delegate: Rectangle {
                        width: manifestList.width
                        height: 72
                        color: Theme.palette.backgroundSecondary

                        readonly property bool rowDeleting: root.deleting[modelData.cid] === true
                        readonly property bool rowDownloading: root.downloadingCid === modelData.cid

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
                                    visible: !modelData.status
                                    source: root.mimetypeIcon(
                                                modelData.mimetype)
                                    width: 32
                                    height: 32
                                    fillMode: Image.PreserveAspectFit
                                }

                                BusyIndicator {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 32
                                    height: 32
                                    running: visible
                                    visible: modelData.status === "fetching"
                                }

                                Image {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: modelData.status === "error"
                                    source: "assets/error.png"
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
                                    border.color: copyHover.hovered
                                                  && root.running ? Theme.palette.primary : Theme.palette.borderSubtle
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
                                text: modelData.status === "fetching" ? "Fetching..." : (modelData.status === "error" ? (modelData.error || "Failed") : (rowDeleting ? "Deleting..." : (modelData.filename || "")))
                                color: modelData.status === "error" ? Theme.palette.error : Theme.palette.text
                                font.pixelSize: Theme.typography.secondaryText
                                elide: Text.ElideRight
                                ToolTip.visible: modelData.status === "error" && statusHover.hovered
                                ToolTip.text: modelData.error || ""
                                Layout.preferredWidth: 140

                                HoverHandler {
                                    id: statusHover
                                }
                            }

                            Text {
                                text: modelData.status ? "-" : (modelData.mimetype || "")
                                color: Theme.palette.text
                                font.pixelSize: Theme.typography.secondaryText
                                elide: Text.ElideRight
                                Layout.preferredWidth: 100
                            }

                            Text {
                                text: modelData.status ? "-" : Utils.formatBytes(
                                          parseInt(modelData.datasetSize))
                                color: Theme.palette.text
                                font.pixelSize: Theme.typography.secondaryText
                                Layout.preferredWidth: 80
                            }

                            Item {
                                // Actions column — fixed width (the download +
                                // delete pill) so fetching / error rows keep the
                                // same column alignment as normal rows.
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: actionsPill.implicitWidth
                                implicitHeight: actionsPill.implicitHeight

                                Rectangle {
                                    id: actionsPill
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Theme.palette.backgroundInset
                                    radius: Theme.spacing.radiusLarge
                                    visible: !modelData.status
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
                                            border.color: dlHover.hovered
                                                          && root.running && !root.isDownloading && !rowDeleting ? Theme.palette.primary : Theme.palette.borderInteractive
                                            border.width: 1
                                            opacity: root.running && !root.isDownloading && !rowDeleting ? 1.0 : 0.35

                                            Behavior on opacity {
                                                NumberAnimation {
                                                    duration: 200
                                                }
                                            }

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
                                                objectName: "downloadButton"
                                                anchors.fill: parent
                                                enabled: root.running && !root.isDownloading && !rowDeleting
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    const dest = root.downloadFolderPath.replace(/\/$/, "") + "/" + (modelData.filename || modelData.cid || "download")
                                                    root.downloadRequested()
                                                    root.backend.downloadFile(
                                                                modelData.cid,
                                                                dest,
                                                                parseInt(
                                                                    modelData.datasetSize)
                                                                || 0)
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: 40
                                            height: 40
                                            radius: Theme.spacing.radiusXlarge * 2
                                            color: Theme.palette.backgroundButton
                                            border.color: rmHover.hovered
                                                          && root.running && !rowDeleting && !rowDownloading ? Theme.palette.primary : Theme.palette.borderInteractive
                                            border.width: 1
                                            opacity: root.running && !rowDeleting && !rowDownloading ? 1.0 : 0.35

                                            Behavior on opacity {
                                                NumberAnimation {
                                                    duration: 200
                                                }
                                            }

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
                                                objectName: "deleteButton"
                                                anchors.fill: parent
                                                enabled: root.running && !rowDeleting && !rowDownloading
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (modelData.cid.length > 0) {
                                                        root.backend.remove(
                                                                    modelData.cid)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: modelData.status === "fetching"
                                    text: "-"
                                    color: Theme.palette.text
                                    font.pixelSize: Theme.typography.secondaryText
                                }

                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Theme.palette.backgroundInset
                                    radius: Theme.spacing.radiusLarge
                                    visible: modelData.status === "error"
                                    implicitWidth: dismissRow.implicitWidth + Theme.spacing.medium * 2
                                    implicitHeight: dismissRow.implicitHeight + Theme.spacing.small * 2

                                    Row {
                                        id: dismissRow
                                        anchors.centerIn: parent
                                        spacing: Theme.spacing.medium

                                        Rectangle {
                                            width: 40
                                            height: 40
                                            radius: Theme.spacing.radiusXlarge * 2
                                            color: Theme.palette.backgroundButton
                                            border.color: dismissHover.hovered ? Theme.palette.primary : Theme.palette.borderInteractive
                                            border.width: 1

                                            Image {
                                                anchors.centerIn: parent
                                                source: "assets/close-circle.png"
                                                width: 20
                                                height: 20
                                                opacity: 0.6
                                                fillMode: Image.PreserveAspectFit
                                            }

                                            HoverHandler {
                                                id: dismissHover
                                            }

                                            MouseArea {
                                                objectName: "dismissButton"
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.dismissPending(modelData.cid)
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

            DebugPanel {
                backend: root.backend
                running: root.running
                isOpen: panelOpen
            }
        }
    }
}

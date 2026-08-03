import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls
import Logos.Icons
import "Utils.js" as Utils

// qmllint disable unqualified
LogosFrame {
    id: root

    backgroundColor: Theme.palette.backgroundSecondary
    borderColor: "transparent"
    radius: Theme.spacing.radiusLarge

    property var backend: MockBackend
    property bool running: false
    property var manifests: []
    property bool panelOpen: false
    property bool isDownloading: false
    property string downloadingCid: ""
    property string downloadFolderPath: ""
    property var deleting: ({})

    // Two 40px icon buttons, the gap between them and the pill's own padding.
    readonly property int actionsColumnWidth: 40 * 2 + Theme.spacing.medium * 3

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

    // LogosTable reads its row through the delegate's `model`, which a plain JS
    // array does not populate — the rows are mirrored into a ListModel.
    ListModel {
        id: rowsModel
    }

    function rebuildRows() {
        rowsModel.clear()
        for (var i = 0; i < root.rows.length; i++) {
            var r = root.rows[i]
            rowsModel.append({
                                 "cid": r.cid || "",
                                 "filename": r.filename || "",
                                 "mimetype": r.mimetype || "",
                                 "datasetSize": String(r.datasetSize || 0),
                                 "status": r.status || "",
                                 "error": r.error || ""
                             })
        }
    }

    onRowsChanged: root.rebuildRows()
    Component.onCompleted: root.rebuildRows()

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
        var m = (mimetype || "").toLowerCase()
        if (m.indexOf("video/") === 0)
            return "assets/videos.svg"
        if (m.indexOf("image/") === 0)
            return "assets/images.svg"
        return "assets/documents.svg"
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
                font.pixelSize: Theme.typography.panelTitleText
                color: Theme.palette.text
            }

            Item {
                Layout.fillWidth: true
            }

            LogosIcon {
                source: Qt.resolvedUrl("assets/close-circle-line.svg")
                color: Theme.palette.text
                width: 23
                height: 23
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
            LogosTable {
                id: manifestList
                anchors.fill: parent
                visible: !root.panelOpen
                model: rowsModel
                rowHeight: 72
                emptyText: "No manifests yet"

                emptyDelegate: Component {
                    ColumnLayout {
                        spacing: Theme.spacing.small

                        DotIcon {
                            pattern: [0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0]
                            dotColor: Theme.palette.textMuted
                            activeOpacity: 0.25
                            Layout.alignment: Qt.AlignHCenter
                        }

                        LogosText {
                            text: "No manifests yet"
                            color: Theme.palette.textMuted
                            font.pixelSize: Theme.typography.secondaryText
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                columns: [
                    LogosTableColumn {
                        title: "CID"
                        role: "cid"
                        minWidth: 240
                        fillWidth: true
                        cellDelegate: Component {
                            Item {
                                Image {
                                    id: typeIcon
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: rowItem && !rowItem.status
                                    source: rowItem ? root.mimetypeIcon(rowItem.mimetype) : ""
                                    width: 32
                                    height: 32
                                    fillMode: Image.PreserveAspectFit
                                }

                                BusyIndicator {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 32
                                    height: 32
                                    running: rowItem && rowItem.status === "fetching"
                                    visible: running
                                }

                                LogosIcon {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: rowItem && rowItem.status === "error"
                                    source: LogosIcons.warning
                                    color: Theme.palette.error
                                    brightness: 1.0
                                    width: 32
                                    height: 32
                                }

                                LogosText {
                                    anchors.left: typeIcon.right
                                    anchors.leftMargin: Theme.spacing.medium
                                    anchors.right: copyBtn.left
                                    anchors.rightMargin: Theme.spacing.medium
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: rowItem ? rowItem.cid : ""
                                    color: Theme.palette.text
                                    font.pixelSize: Theme.typography.secondaryText
                                    elide: Text.ElideRight

                                    HoverHandler {
                                        id: cidHover
                                    }

                                    LogosToolTip {
                                        text: rowItem ? rowItem.cid : ""
                                        visible: cidHover.hovered
                                    }
                                }

                                LogosCopyButton {
                                    id: copyBtn
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    value: rowItem ? rowItem.cid : ""
                                    // Match the download / delete buttons on the row.
                                    size: 40
                                    iconSize: 20
                                    background: IconButtonBackground {}
                                }
                            }
                        }
                    },
                    LogosTableColumn {
                        title: "Filename"
                        role: "filename"
                        minWidth: 140
                        preferredWidth: 140
                        cellDelegate: Component {
                            Item {
                                id: filenameCell
                                readonly property bool rowDeleting: rowItem && root.deleting[rowItem.cid] === true

                                LogosText {
                                    id: statusLabel
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: {
                                        if (!rowItem)
                                            return ""
                                        if (rowItem.status === "fetching")
                                            return "Fetching..."
                                        if (rowItem.status === "error")
                                            return rowItem.error || "Failed"
                                        return filenameCell.rowDeleting ? "Deleting..." : (rowItem.filename || "")
                                    }
                                    color: rowItem && rowItem.status === "error" ? Theme.palette.error
                                                                                 : Theme.palette.text
                                    font.pixelSize: Theme.typography.secondaryText
                                    elide: Text.ElideRight

                                    HoverHandler {
                                        id: statusHover
                                    }

                                    LogosToolTip {
                                        text: rowItem ? (rowItem.error || "") : ""
                                        visible: rowItem && rowItem.status === "error" && statusHover.hovered
                                    }
                                }
                            }
                        }
                    },
                    LogosTableColumn {
                        title: "Mimetype"
                        role: "mimetype"
                        minWidth: 100
                        preferredWidth: 100
                        cellDelegate: Component {
                            Item {
                                LogosText {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: rowItem ? (rowItem.status ? "-" : (rowItem.mimetype || "")) : ""
                                    color: Theme.palette.text
                                    font.pixelSize: Theme.typography.secondaryText
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    },
                    LogosTableColumn {
                        title: "Size"
                        role: "datasetSize"
                        minWidth: 80
                        preferredWidth: 80
                        cellDelegate: Component {
                            Item {
                                LogosText {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: rowItem ? (rowItem.status ? "-" : Utils.formatBytes(
                                                         parseInt(rowItem.datasetSize))) : ""
                                    color: Theme.palette.text
                                    font.pixelSize: Theme.typography.secondaryText
                                }
                            }
                        }
                    },
                    LogosTableColumn {
                        title: "Actions"
                        minWidth: root.actionsColumnWidth
                        preferredWidth: root.actionsColumnWidth
                        cellPadding: 0
                        alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        cellDelegate: Component {
                            Item {
                                id: actionsCell
                                readonly property bool rowDeleting: rowItem && root.deleting[rowItem.cid] === true
                                readonly property bool rowDownloading: rowItem && root.downloadingCid === rowItem.cid

                                Rectangle {
                                    id: actionsPill
                                    anchors.centerIn: parent
                                    color: Theme.palette.backgroundInset
                                    radius: Theme.spacing.radiusLarge
                                    visible: rowItem && !rowItem.status
                                    implicitWidth: actionsRow.implicitWidth + Theme.spacing.medium * 2
                                    implicitHeight: actionsRow.implicitHeight + Theme.spacing.small * 2

                                    Row {
                                        id: actionsRow
                                        anchors.centerIn: parent
                                        spacing: Theme.spacing.medium

                                        LogosIconButton {
                                            objectName: "downloadButton"
                                            iconSource: Qt.resolvedUrl("assets/download-2-fill.svg")
                                            background: IconButtonBackground {}
                                            enabled: root.running && !root.isDownloading
                                                     && !actionsCell.rowDeleting
                                            onClicked: {
                                                const dest = root.downloadFolderPath.replace(/\/$/, "") + "/" + (rowItem.filename || rowItem.cid || "download")
                                                root.downloadRequested()
                                                root.backend.downloadFile(
                                                            rowItem.cid,
                                                            dest,
                                                            parseInt(
                                                                rowItem.datasetSize)
                                                            || 0)
                                            }
                                        }

                                        LogosIconButton {
                                            objectName: "deleteButton"
                                            iconSource: Qt.resolvedUrl("assets/delete-bin-2-line.svg")
                                            background: IconButtonBackground {}
                                            enabled: root.running && !actionsCell.rowDeleting
                                                     && !actionsCell.rowDownloading
                                            onClicked: {
                                                if (rowItem.cid.length > 0) {
                                                    root.backend.remove(rowItem.cid)
                                                }
                                            }
                                        }
                                    }
                                }

                                LogosText {
                                    anchors.centerIn: parent
                                    visible: rowItem && rowItem.status === "fetching"
                                    text: "-"
                                    color: Theme.palette.text
                                    font.pixelSize: Theme.typography.secondaryText
                                }

                                Rectangle {
                                    anchors.centerIn: parent
                                    color: Theme.palette.backgroundInset
                                    radius: Theme.spacing.radiusLarge
                                    visible: rowItem && rowItem.status === "error"
                                    implicitWidth: dismissRow.implicitWidth + Theme.spacing.medium * 2
                                    implicitHeight: dismissRow.implicitHeight + Theme.spacing.small * 2

                                    Row {
                                        id: dismissRow
                                        anchors.centerIn: parent
                                        spacing: Theme.spacing.medium

                                        LogosIconButton {
                                            objectName: "dismissButton"
                                            iconSource: Qt.resolvedUrl("assets/close-circle-line.svg")
                                            background: IconButtonBackground {}
                                            onClicked: root.dismissPending(rowItem.cid)
                                        }
                                    }
                                }
                            }
                        }
                    }
                ]
            }

            DebugPanel {
                backend: root.backend
                running: root.running
                isOpen: panelOpen
            }
        }
    }
}

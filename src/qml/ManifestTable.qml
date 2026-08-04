import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtCore
import Qt.labs.folderlistmodel
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
    property bool isDownloading: false
    property string downloadingCid: ""
    property string downloadFolderPath: ""
    property var deleting: ({})

    // Two 40px icon buttons, the gap between them and the pill's own padding.
    readonly property int actionsColumnWidth: 40 * 2 + Theme.spacing.medium * 3

    property var addedDates: ({})

    Settings {
        id: addedDatesStore
        category: "ManifestAddedDates"
        property string entries: "{}"
    }

    function loadAddedDates() {
        try {
            root.addedDates = JSON.parse(addedDatesStore.entries)
        } catch (e) {
            root.addedDates = {}
        }
    }

    function recordAdded(cid) {
        if (!cid || root.addedDates[cid])
            return
        var d = Object.assign({}, root.addedDates)
        d[cid] = new Date().toISOString()
        root.addedDates = d
        addedDatesStore.entries = JSON.stringify(d)
    }

    function forgetAdded(cid) {
        if (!cid || !root.addedDates[cid])
            return
        var d = Object.assign({}, root.addedDates)
        delete d[cid]
        root.addedDates = d
        addedDatesStore.entries = JSON.stringify(d)
    }

    function formatAdded(cid) {
        var iso = root.addedDates[cid]
        return iso ? Qt.formatDateTime(new Date(iso), "dd MMM yyyy") : "-"
    }

    // A manifest is "downloaded" when a file with its name sits in the download
    // folder; otherwise it's only "fetched" (manifest present, no local file).
    property var downloadedNames: ({})

    FolderListModel {
        id: downloadFolder
        folder: root.downloadFolderPath
        showDirs: false
        showHidden: false
        nameFilters: ["*"]
        onCountChanged: root.rebuildDownloaded()
        onFolderChanged: root.rebuildDownloaded()
    }

    function rebuildDownloaded() {
        var names = {}
        for (var i = 0; i < downloadFolder.count; i++)
            names[downloadFolder.get(i, "fileName")] = true
        root.downloadedNames = names
    }

    function isDownloaded(item) {
        return !!(item && item.filename && root.downloadedNames[item.filename])
    }

    function openDownloaded(item) {
        Qt.openUrlExternally(root.downloadFolderPath.replace(/\/$/, "")
                             + "/" + encodeURIComponent(item.filename))
    }

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
    // Sorted by the column the user picked, newest first by default. Fetches in
    // progress stay on top: they are what the user is waiting for.
    property string sortRole: "added"
    property int sortOrder: Qt.DescendingOrder

    property var rows: {
        const dir = root.sortOrder === Qt.AscendingOrder ? 1 : -1
        const dates = root.addedDates
        const list = root.manifests.slice().sort(function (a, b) {
            let r
            if (root.sortRole === "datasetSize")
                r = (parseInt(a.datasetSize) || 0) - (parseInt(b.datasetSize) || 0)
            else if (root.sortRole === "added")
                r = (dates[a.cid] || "").localeCompare(dates[b.cid] || "")
            else
                r = (a.filename || "").localeCompare(b.filename || "")
            if (r === 0)
                r = (a.cid || "").localeCompare(b.cid || "")
            return r * dir
        })
        return root.pending.concat(list)
    }

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
                                 "error": r.error || "",
                                 "added": root.formatAdded(r.cid || "")
                             })
        }
    }

    onRowsChanged: root.rebuildRows()

    Component.onCompleted: {
        root.loadAddedDates()
        root.rebuildRows()
    }

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

    // The badged icons claim a type: anything the node does not name as image,
    // video or document gets the plain sheet rather than a wrong badge.
    function mimetypeIcon(mimetype) {
        const m = (mimetype || "").toLowerCase()
        if (m.indexOf("video/") === 0)
            return "assets/videos.svg"
        if (m.indexOf("image/") === 0)
            return "assets/images.svg"
        if (m === "application/pdf" || m.indexOf("text/") === 0
                || m.indexOf("document") >= 0 || m.indexOf("word") >= 0)
            return "assets/documents.svg"
        return "assets/file.svg"
    }

    implicitWidth: 1200
    implicitHeight: 400

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
                root.forgetAdded(cid)
            }

            function onRemoveFailed(cid, error) {
                root.unmarkDeleting(cid)
            }

            function onManifestFetchStarted(cid) {
                root.addPending(cid)
                root.recordAdded(cid)
            }

            function onUploadCompleted(cid) {
                root.recordAdded(cid)
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
        LogosText {
            Layout.fillWidth: true
            text: "Manifests"
            font.pixelSize: Theme.typography.panelTitleText
            color: Theme.palette.text
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ── Vue liste ────────────────────────────────────────────────────
            LogosTable {
                id: manifestList
                anchors.fill: parent
                model: rowsModel
                rowHeight: 72
                emptyText: "No manifests yet"
                sortRole: root.sortRole
                sortOrder: root.sortOrder

                onSortRequested: function (role, order) {
                    root.sortRole = role
                    root.sortOrder = order
                }

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
                        title: "Manifest"
                        role: "filename"
                        sortable: true
                        minWidth: 240
                        fillWidth: true
                        cellDelegate: Component {
                            Item {
                                id: manifestCell
                                readonly property bool rowDeleting: rowItem && root.deleting[rowItem.cid] === true

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

                                Column {
                                    // Anchored to the icon, hidden or not: the
                                    // text starts at the same place on every row.
                                    anchors.left: typeIcon.right
                                    anchors.leftMargin: Theme.spacing.medium
                                    anchors.right: copyBtn.left
                                    anchors.rightMargin: Theme.spacing.medium
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    LogosText {
                                        width: parent.width
                                        text: {
                                            if (!rowItem)
                                                return ""
                                            if (rowItem.status === "fetching")
                                                return "Fetching..."
                                            if (rowItem.status === "error")
                                                return rowItem.error || "Failed"
                                            return manifestCell.rowDeleting ? "Deleting..."
                                                                            : (rowItem.filename || "Untitled")
                                        }
                                        color: rowItem && rowItem.status === "error" ? Theme.palette.error
                                                                                     : Theme.palette.text
                                        font.pixelSize: Theme.typography.primaryText
                                        font.weight: Theme.typography.weightBold
                                        elide: Text.ElideRight

                                        HoverHandler {
                                            id: statusHover
                                        }

                                        LogosToolTip {
                                            text: rowItem ? (rowItem.error || "") : ""
                                            visible: rowItem && rowItem.status === "error" && statusHover.hovered
                                        }
                                    }

                                    LogosText {
                                        width: parent.width
                                        text: rowItem ? rowItem.cid : ""
                                        color: Theme.palette.textSecondary
                                        font.pixelSize: Theme.typography.secondaryText
                                        elide: Text.ElideMiddle

                                        HoverHandler {
                                            id: cidHover
                                        }

                                        LogosToolTip {
                                            text: rowItem ? rowItem.cid : ""
                                            visible: cidHover.hovered
                                        }
                                    }
                                }

                                LogosCopyButton {
                                    id: copyBtn
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: rowItem && !rowItem.status
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
                        sortable: true
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
                        title: "Date added"
                        role: "added"
                        sortable: true
                        minWidth: 120
                        preferredWidth: 120
                        cellDelegate: Component {
                            Item {
                                LogosText {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: rowItem ? (rowItem.status ? "-" : rowItem.added) : ""
                                    color: Theme.palette.text
                                    font.pixelSize: Theme.typography.secondaryText
                                    elide: Text.ElideRight
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

                                        readonly property bool rowDownloaded: root.isDownloaded(rowItem)

                                        LogosIconButton {
                                            objectName: "openButton"
                                            visible: actionsRow.rowDownloaded
                                            iconSource: Qt.resolvedUrl("assets/external-link-line.svg")
                                            background: IconButtonBackground {}
                                            onClicked: root.openDownloaded(rowItem)
                                        }

                                        LogosIconButton {
                                            objectName: "downloadButton"
                                            visible: !actionsRow.rowDownloaded
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
        }
    }
}

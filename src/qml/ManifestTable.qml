import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtCore
import Qt.labs.folderlistmodel
import Logos.Theme
import Logos.Controls
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

    // Active sort column: "manifest" | "size" | "date" | "" (none)
    property string sortColumn: ""
    property bool sortAscending: true

    // Three-state cycle on click: disabled → desc → asc → disabled.
    function toggleSort(col) {
        if (root.sortColumn !== col) {
            root.sortColumn = col
            root.sortAscending = false // desc
        } else if (!root.sortAscending) {
            root.sortAscending = true // asc
        } else {
            root.sortColumn = "" // back to disabled
        }
    }

    // Actions column width, shared by the header and rows so they stay aligned.
    // Two 40px icon buttons + inner spacing + the pill's horizontal padding.
    readonly property int actionsColumnWidth: 40 * 2 + Theme.spacing.medium * 3

    // Fetch dates are not provided by the node API, so we stamp and persist
    // them locally: cid -> ISO date string, recorded only when the user fetches
    // a manifest. Anything already present (uploads, prior files) stays undated
    // and shows "-".
    property var fetchDates: ({})

    Settings {
        id: fetchDatesStore
        category: "ManifestFetchDates"
        // Renamed key: earlier builds stamped every manifest, so the old value
        // is discarded and we start clean.
        property string entries: "{}"
    }

    Component.onCompleted: {
        try {
            root.fetchDates = JSON.parse(fetchDatesStore.entries)
        } catch (e) {
            root.fetchDates = {}
        }
    }

    function recordFetched(cid) {
        if (!cid || root.fetchDates[cid])
            return
        var d = Object.assign({}, root.fetchDates)
        d[cid] = new Date().toISOString()
        root.fetchDates = d
        fetchDatesStore.entries = JSON.stringify(d)
    }

    function formatFetched(cid) {
        var iso = root.fetchDates[cid]
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
    property var rows: {
        // Tab filter: 0 All · 1 Downloaded (file on disk) · 2 Fetched (manifest only)
        var tab = tabBar.currentIndex
        var list = root.manifests
        if (tab === 1)
            list = root.manifests.filter(function (x) { return root.isDownloaded(x) })
        else if (tab === 2)
            list = root.manifests.filter(function (x) { return !root.isDownloaded(x) })

        if (root.sortColumn) {
            var col = root.sortColumn
            var dates = root.fetchDates
            var dir = root.sortAscending ? 1 : -1
            list = list.slice().sort(function (a, b) {
                var r
                if (col === "size")
                    r = (parseInt(a.datasetSize) || 0) - (parseInt(b.datasetSize) || 0)
                else if (col === "date")
                    r = (dates[a.cid] || "").localeCompare(dates[b.cid] || "")
                else
                    r = (a.filename || "").localeCompare(b.filename || "")
                return r * dir
            })
        }

        // In-progress fetches belong to All and Fetched, not Downloaded.
        return (tab === 1 ? [] : root.pending).concat(list)
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
    function mimetypeIcon(mimetype) {
        if (!mimetype)
            return "assets/images.svg"
        var m = mimetype.toLowerCase()
        if (m.indexOf("video/") === 0)
            return "assets/videos.svg"
        if (m.indexOf("image/") === 0)
            return "assets/images.svg"
        if (m === "application/pdf" || m.indexOf("text/") === 0
                || m.indexOf("document") >= 0 || m.indexOf("word") >= 0
                || m.indexOf("pdf") >= 0)
            return "assets/documents.svg"
        return "assets/images.svg"
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
            }

            function onRemoveFailed(cid, error) {
                root.unmarkDeleting(cid)
            }

            function onManifestFetchStarted(cid) {
                root.addPending(cid)
                root.recordFetched(cid)
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
                root.rebuildDownloaded()
            }

            function onError(message) {
                root.isDownloading = false
                root.downloadingCid = ""
            }
        }

        // ── Title row ─────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.large

            LogosText {
                text: "Manifests"
                font.pixelSize: Theme.typography.panelTitleText
                color: Theme.palette.text
            }

            // Tabs on the left, with a gray baseline running across the whole
            // row; the tab bar's colored indicator sits on top of that line.
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: tabBar.implicitHeight
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: Theme.palette.colors.getColor(Theme.palette.textTertiary, 0.2)
                }

                LogosTabBar {
                    id: tabBar
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    spacing: Theme.spacing.medium

                    LogosTabButton {
                        text: "All"
                        // White glyph so the DS tint yields full-strength orange, not a dimmed one
                        iconSource: Qt.resolvedUrl("assets/file-copy-2-fill-white.svg")
                        activeColor: Theme.palette.colors.orange400
                        inactiveColor: Theme.palette.textSecondary
                    }
                    LogosTabButton {
                        text: "Downloaded"
                        inactiveColor: Theme.palette.textSecondary
                    }
                    LogosTabButton {
                        text: "Fetched"
                        inactiveColor: Theme.palette.textSecondary
                    }
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

                Rectangle {
                    id: header
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    color: Theme.palette.colors.getColor(Theme.palette.backgroundInset, 0.6)
                    radius: Theme.spacing.radiusSmall

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacing.medium
                        anchors.rightMargin: Theme.spacing.medium

                        // Manifest — sortable (label + icon clickable)
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleSort("manifest")
                            }

                            RowLayout {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.spacing.tiny

                                Text {
                                    text: "Manifest"
                                    color: Theme.palette.textSecondary
                                    font.pixelSize: Theme.typography.secondaryText
                                }
                                LogosIcon {
                                    source: Qt.resolvedUrl("assets/expand-up-down-fill.svg")
                                    color: root.sortColumn === "manifest" ? Theme.palette.text : Theme.palette.textTertiary
                                    width: 16
                                    height: 16
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }
                        }

                        // Size — sortable
                        Item {
                            Layout.preferredWidth: 100
                            Layout.fillHeight: true

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleSort("size")
                            }

                            RowLayout {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.spacing.tiny

                                Text {
                                    text: "Size"
                                    color: Theme.palette.textSecondary
                                    font.pixelSize: Theme.typography.secondaryText
                                }
                                LogosIcon {
                                    source: Qt.resolvedUrl("assets/expand-up-down-fill.svg")
                                    color: root.sortColumn === "size" ? Theme.palette.text : Theme.palette.textTertiary
                                    width: 16
                                    height: 16
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }
                        }

                        // Date fetched — sortable
                        Item {
                            Layout.preferredWidth: 160
                            Layout.fillHeight: true

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleSort("date")
                            }

                            RowLayout {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.spacing.tiny

                                Text {
                                    text: "Date fetched"
                                    color: Theme.palette.textSecondary
                                    font.pixelSize: Theme.typography.secondaryText
                                }
                                LogosIcon {
                                    source: Qt.resolvedUrl("assets/expand-up-down-fill.svg")
                                    color: root.sortColumn === "date" ? Theme.palette.text : Theme.palette.textTertiary
                                    width: 16
                                    height: 16
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }
                        }

                        Text {
                            text: "Actions"
                            color: Theme.palette.textSecondary
                            font.pixelSize: Theme.typography.secondaryText
                            Layout.preferredWidth: root.actionsColumnWidth
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

                                Column {
                                    anchors.left: typeIcon.right
                                    anchors.leftMargin: Theme.spacing.medium
                                    anchors.right: copyBtn.left
                                    anchors.rightMargin: Theme.spacing.medium
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        width: parent.width
                                        text: modelData.status === "fetching" ? "Fetching..."
                                              : modelData.status === "error" ? (modelData.error || "Failed")
                                              : (rowDeleting ? "Deleting..." : (modelData.filename || "Untitled"))
                                        color: modelData.status === "error" ? Theme.palette.error : Theme.palette.text
                                        font.pixelSize: Theme.typography.primaryText
                                        font.weight: Theme.typography.weightBold
                                        elide: Text.ElideRight
                                        ToolTip.visible: modelData.status === "error" && statusHover.hovered
                                        ToolTip.text: modelData.error || ""

                                        HoverHandler { id: statusHover }
                                    }

                                    Text {
                                        width: parent.width
                                        text: modelData.cid
                                        color: Theme.palette.colors.getColor(Theme.palette.text, 0.8)
                                        font.pixelSize: Theme.typography.secondaryText
                                        elide: Text.ElideMiddle
                                        ToolTip.visible: cidHover.hovered
                                        ToolTip.text: modelData.cid

                                        HoverHandler { id: cidHover }
                                    }
                                }

                                LogosIconButton {
                                    id: copyBtn
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.rightMargin: Theme.spacing.medium
                                    visible: !modelData.status

                                    property bool copied: false

                                    iconSource: copied ? Qt.resolvedUrl("assets/success.png") : Qt.resolvedUrl("assets/file-copy-line.svg")
                                    iconColor: copied ? Theme.palette.success : Theme.palette.textTertiary

                                    background: Rectangle {
                                        color: Theme.palette.backgroundInset
                                        radius: Theme.spacing.radiusPill
                                        border.width: 1
                                        border.color: copyBtn.isActive ? Theme.palette.overlayOrange : Theme.palette.borderSubtle
                                    }

                                    Timer {
                                        id: resetCopyTimer
                                        interval: 1500
                                        onTriggered: copyBtn.copied = false
                                    }

                                    onClicked: {
                                        clipboardHelper.text = modelData.cid
                                        clipboardHelper.selectAll()
                                        clipboardHelper.copy()
                                        copyBtn.copied = true
                                        resetCopyTimer.restart()
                                    }
                                }

                                TextEdit {
                                    id: clipboardHelper
                                    visible: false
                                }
                            }

                            Text {
                                text: modelData.status ? "-" : Utils.formatBytes(
                                          parseInt(modelData.datasetSize))
                                color: Theme.palette.text
                                font.pixelSize: Theme.typography.secondaryText
                                Layout.preferredWidth: 100
                            }

                            Text {
                                text: modelData.status ? "-" : root.formatFetched(modelData.cid)
                                color: Theme.palette.textSecondary
                                font.pixelSize: Theme.typography.secondaryText
                                Layout.preferredWidth: 160
                            }

                            Item {
                                // Actions column — fixed width (the download +
                                // delete pill) so fetching / error rows keep the
                                // same column alignment as normal rows.
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: root.actionsColumnWidth
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

                                        readonly property bool rowDownloaded: root.isDownloaded(modelData)

                                        LogosIconButton {
                                            objectName: "openButton"
                                            visible: actionsRow.rowDownloaded
                                            iconSource: Qt.resolvedUrl("assets/external-link-line.svg")
                                            background: IconButtonBackground {}
                                            onClicked: root.openDownloaded(modelData)
                                        }

                                        LogosIconButton {
                                            objectName: "downloadButton"
                                            visible: !actionsRow.rowDownloaded
                                            iconSource: Qt.resolvedUrl("assets/download-2-fill.svg")
                                            background: IconButtonBackground {}
                                            enabled: root.running && !root.isDownloading && !rowDeleting
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

                                        LogosIconButton {
                                            objectName: "deleteButton"
                                            iconSource: Qt.resolvedUrl("assets/delete-bin-2-line.svg")
                                            enabled: root.running && !rowDeleting && !rowDownloading
                                            background: IconButtonBackground {}
                                            onClicked: {
                                                if (modelData.cid.length > 0) {
                                                    root.backend.remove(
                                                                modelData.cid)
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

                                        LogosIconButton {
                                            objectName: "dismissButton"
                                            iconSource: Qt.resolvedUrl("assets/close-circle.png")
                                            background: IconButtonBackground {}
                                            onClicked: root.dismissPending(modelData.cid)
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
                        spacing: Theme.spacing.small
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
                            font.pixelSize: Theme.typography.secondaryText
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }
    }
}

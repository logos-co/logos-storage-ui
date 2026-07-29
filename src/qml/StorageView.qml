import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore
import Logos.Theme
import Logos.Controls
import Logos.StorageBackend 1.0

// qmllint disable unqualified
LogosStorageLayout {
    id: root

    property var backend: MockBackend

    property string currentPage: "dashboard"

    readonly property bool running: backend && backend.status === StorageBackend.Running

    readonly property int nodeStatus: backend ? backend.status : StorageBackend.Destroyed

    // Status explainer shown in the info panel. Mirrors the dot colour logic
    // in NodeWidget so the panel and the glyph agree.
    readonly property color nodeAccent: {
        if (nodeStatus === StorageBackend.Starting)
            return Theme.palette.warning
        if (nodeStatus !== StorageBackend.Running)
            return Theme.palette.textMuted
        if (health.reachability === "Reachable")
            return Theme.palette.success
        if (health.reachability === "NotReachable")
            return Theme.palette.warning
        return Theme.palette.textMuted
    }
    readonly property string nodeInfoTitle: {
        if (nodeStatus === StorageBackend.Starting)
            return "Node is starting"
        if (nodeStatus !== StorageBackend.Running)
            return "Node is stopped"
        if (health.reachability === "Reachable")
            return "Node is reachable"
        if (health.reachability === "NotReachable")
            return "Node is not reachable"
        return "Checking reachability"
    }
    readonly property string nodeInfoMessage: {
        if (nodeStatus === StorageBackend.Starting)
            return "The node is booting up and connecting to the network. The status icon stays amber until it is ready."
        if (nodeStatus !== StorageBackend.Running)
            return "The node is not running. Start it to join the network and share files."
        if (health.reachability === "Reachable")
            return "The node is running and other peers can reach it from the internet. The dot next to Running is green."
        if (health.reachability === "NotReachable")
            return "The node is running but no peer can open a connection to it, so it only downloads through peers it dialled itself. The dot next to Running is orange. Check the port forwarding or UPnP configuration of your router."
        return "The node is running. AutoNAT has not decided yet whether other peers can reach it, so the dot next to Running stays muted."
    }

    // Below this width the sidebar collapses into a thin rail with a hamburger
    // that opens the full navigation in an overlay drawer.
    readonly property bool compact: width < 820
    readonly property int railWidth: 56
    readonly property int sidebarWidth: 196
    readonly property real navWidth: compact ? railWidth : sidebarWidth

    // Fixed height of a top dashboard block, in every column count.
    readonly property int topBlockHeight: 425

    // Responsive breakpoints for the top blocks:
    // - wide:   Disk 40% | Upload/Download group 30% | Node/Peers group 30%
    // - medium: Disk full width on top, the two groups 50/50 below it
    // - narrow: every block stacked in a single column
    readonly property real topContentWidth: dashboardScroll.availableWidth
    readonly property string topMode: topContentWidth > 1250 ? "wide"
                                      : topContentWidth > 600 ? "medium" : "narrow"

    readonly property real diskBlockWidth:
        topMode === "wide" ? 0.4 * (topContentWidth - 2 * Theme.spacing.medium)
                           : topContentWidth
    readonly property real sideBlockWidth:
        topMode === "wide" ? 0.3 * (topContentWidth - 2 * Theme.spacing.medium)
        : topMode === "medium" ? (topContentWidth - Theme.spacing.medium) / 2
        : topContentWidth

    Settings {
        id: settings
        category: "Storage"
        property string downloadFolderPath: {
            const p = StandardPaths.standardLocations(StandardPaths.HomeLocation)[0].toString()
            return p.startsWith("file://") ? p : "file://" + p
        }

        // Auto-explain the node status the first time the dashboard is opened.
        property bool nodeInfoSeen: false
    }

    function isRunning() {
        return backend && backend.status === StorageBackend.Running
    }

    Component.onCompleted: function () {
        if (isRunning()) {
            root.backend.fetchWidgetsData()
        } else {
            root.backend.start()
        }
        if (!settings.nodeInfoSeen) {
            settings.nodeInfoSeen = true
            infoPanel.open()
        }
    }

    onCompactChanged: if (!root.compact) navDrawer.close()

    FileDialog {
        id: uploadDialog
        objectName: "uploadDialog"
        modality: Qt.NonModal
        onAccepted: root.backend.uploadFile(selectedFile)
        currentFolder: StandardPaths.standardLocations(
                           StandardPaths.HomeLocation)[0]
    }

    HealthIndicator {
        id: health
        backend: root.backend
    }

    Loader {
        id: sidebarLoader
        active: !root.compact
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        sourceComponent: Sidebar {
            width: root.sidebarWidth
            currentPage: root.currentPage
            onPageSelected: function (page) {
                root.currentPage = page
            }
        }
    }

    // Collapsed navigation rail: only a hamburger, opens navDrawer.
    Rectangle {
        id: rail
        visible: root.compact
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.railWidth
        color: Theme.palette.backgroundTertiary

        Rectangle {
            id: hamburger
            width: 24
            height: 18
            color: "transparent"
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: Theme.spacing.large

            Column {
                anchors.fill: parent
                spacing: 5
                Repeater {
                    model: 3
                    Rectangle {
                        width: hamburger.width
                        height: 2
                        radius: 1
                        color: hamburgerMouse.containsMouse ? Theme.palette.primary
                                                            : Theme.palette.textTertiary
                    }
                }
            }

            MouseArea {
                id: hamburgerMouse
                anchors.fill: parent
                anchors.margins: -8
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: navDrawer.open()
            }
        }
    }

    LogosDrawer {
        id: navDrawer
        edge: Qt.LeftEdge
        height: root.height
        width: root.sidebarWidth
        padding: 0

        Sidebar {
            anchors.fill: parent
            currentPage: root.currentPage
            onPageSelected: function (page) {
                root.currentPage = page
                navDrawer.close()
            }
        }
    }

    InfoPanel {
        id: infoPanel
        accent: root.nodeAccent
        title: root.nodeInfoTitle
        message: root.nodeInfoMessage
    }

    ScrollView {
        id: dashboardScroll
        visible: root.currentPage === "dashboard"
        anchors.fill: parent
        anchors.margins: Theme.spacing.medium
        anchors.leftMargin: root.navWidth + Theme.spacing.medium
        clip: true
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: dashboardScroll.availableWidth
            spacing: Theme.spacing.medium

            // Top blocks — responsive: wide 3 columns (40/30/30), medium
            // Disk full-width over two 50/50 groups, narrow single column.
            GridLayout {
                id: topGrid
                Layout.fillWidth: true
                columnSpacing: Theme.spacing.medium
                rowSpacing: Theme.spacing.medium
                columns: root.topMode === "wide" ? 3 : root.topMode === "medium" ? 2 : 1

                DiskWidget {
                    Layout.fillWidth: true
                    Layout.preferredWidth: root.diskBlockWidth
                    Layout.columnSpan: root.topMode === "medium" ? 2 : 1
                    Layout.preferredHeight: root.topBlockHeight
                    backend: root.backend
                    downloadFolderPath: settings.downloadFolderPath
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: root.sideBlockWidth
                    Layout.preferredHeight: root.topBlockHeight
                    spacing: Theme.spacing.medium

                    UploadWidget {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        backend: root.backend
                        running: root.running
                        onUploadRequested: uploadDialog.open()
                    }

                    DownloadWidget {
                        id: downloadWidget
                        Layout.fillWidth: true
                        backend: root.backend
                        running: root.running
                        downloadFolderPath: settings.downloadFolderPath
                    }

                    ManifestWidget {
                        Layout.fillWidth: true
                        backend: root.backend
                        running: root.running
                    }
                }

                ColumnLayout {
                    id: thirdCol
                    Layout.fillWidth: true
                    Layout.preferredWidth: root.sideBlockWidth
                    Layout.preferredHeight: root.topBlockHeight
                    spacing: Theme.spacing.medium

                    NodeWidget {
                        Layout.fillWidth: true
                        Layout.preferredHeight: (thirdCol.height - thirdCol.spacing) / 3
                        backend: root.backend
                        reachability: health.reachability
                        blinkOn: health.blinkOn
                        onInfoRequested: infoPanel.open()
                    }

                    PeersWidget {
                        Layout.fillWidth: true
                        Layout.preferredHeight: (thirdCol.height - thirdCol.spacing) * 2 / 3
                        backend: root.backend
                        running: root.running
                        onDetailsRequested: root.currentPage = "peers"
                    }
                }
            }

            ManifestTable {
                id: manifestTable
                Layout.fillWidth: true
                // Fill the remaining viewport when there's room, scroll otherwise.
                Layout.preferredHeight: Math.max(
                    400, dashboardScroll.availableHeight - topGrid.height - Theme.spacing.medium)
                backend: root.backend
                running: root.running
                downloadFolderPath: settings.downloadFolderPath
                onDownloadRequested: downloadWidget.startLooking()
            }
        }
    }

    LogsPage {
        visible: root.currentPage === "logs"
        anchors.fill: parent
        anchors.margins: Theme.spacing.medium
        anchors.leftMargin: root.navWidth + Theme.spacing.medium
        backend: root.backend
    }

    DebugPage {
        visible: root.currentPage === "debug"
        anchors.fill: parent
        anchors.margins: Theme.spacing.medium
        anchors.leftMargin: root.navWidth + Theme.spacing.medium
        backend: root.backend
        running: root.running
    }

    SettingsPage {
        visible: root.currentPage === "settings"
        anchors.fill: parent
        anchors.margins: Theme.spacing.medium
        anchors.leftMargin: root.navWidth + Theme.spacing.medium
        backend: root.backend
        downloadFolderPath: settings.downloadFolderPath
        onFolderPathChanged: function(path) { settings.downloadFolderPath = path }
    }

    PeersPage {
        visible: root.currentPage === "peers"
        anchors.fill: parent
        anchors.margins: Theme.spacing.medium
        anchors.leftMargin: root.navWidth + Theme.spacing.medium
        backend: root.backend
        running: root.running
    }

    HelpPage {
        visible: root.currentPage === "help"
        anchors.fill: parent
        anchors.margins: Theme.spacing.medium
        anchors.leftMargin: root.navWidth + Theme.spacing.medium
    }

    DisclaimerPage {
        visible: root.currentPage === "disclaimer"
        anchors.fill: parent
        anchors.margins: Theme.spacing.medium
        anchors.leftMargin: root.navWidth + Theme.spacing.medium
    }

    PlaceholderPage {
        visible: root.currentPage === "nodes"
        anchors.fill: parent
        anchors.margins: Theme.spacing.medium
        anchors.leftMargin: root.navWidth + Theme.spacing.medium
        title: "Nodes"
        description: "Run and monitor several storage nodes from one place: add nodes, inspect their status and control them individually."
        icon: "assets/sidebar-nodes.svg"
    }

    PlaceholderPage {
        visible: root.currentPage === "files"
        anchors.fill: parent
        anchors.margins: Theme.spacing.medium
        anchors.leftMargin: root.navWidth + Theme.spacing.medium
        title: "Files"
        description: "Browse the files you have uploaded and downloaded. Search, preview and manage your shared content in one place."
        icon: "assets/sidebar-files.svg"
    }

    PlaceholderPage {
        visible: root.currentPage === "device"
        anchors.fill: parent
        anchors.margins: Theme.spacing.medium
        anchors.leftMargin: root.navWidth + Theme.spacing.medium
        title: "Device"
        description: "See this device's storage, network and resource usage, and tune how much it contributes to the network."
        icon: "assets/sidebar-device.svg"
    }

    // Safety net for any page not wired above.
    Item {
        id: placeholderPage
        readonly property var builtPages: ["dashboard", "nodes", "files", "device", "logs", "debug", "settings", "peers", "help", "disclaimer"]
        visible: placeholderPage.builtPages.indexOf(root.currentPage) === -1
        anchors.fill: parent
        anchors.leftMargin: root.navWidth

        LogosText {
            anchors.centerIn: parent
            text: root.currentPage.charAt(0).toUpperCase() + root.currentPage.slice(1)
            font.pixelSize: Theme.typography.titleText
            color: Theme.palette.textMuted
        }
    }
}

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Logos.Theme
import Logos.Controls

// Left navigation sidebar (Figma "Basecamp - MVP v.1", node 240:9272).
Rectangle {
    id: root

    implicitWidth: 196
    color: Theme.palette.backgroundTertiary

    property string currentPage: "dashboard"

    signal pageSelected(string page)

    // The currently-active item, tracked so the accent bar can slide to it.
    property Item activeItem: null

    // Center y of the accent bar, in root coordinates. Recomputed after layout
    // (mapToItem is not reactive), so we resync via Qt.callLater.
    property real accentY: 0

    // Disabled until the first position is set, so the bar doesn't slide in
    // from the top on startup.
    property bool animateAccent: false

    function syncAccent() {
        if (root.activeItem)
            root.accentY = root.activeItem.mapToItem(
                root, 0, root.activeItem.height / 2).y
    }

    onActiveItemChanged: Qt.callLater(root.syncAccent)
    onHeightChanged: Qt.callLater(root.syncAccent)
    Component.onCompleted: Qt.callLater(function () {
        root.syncAccent()
        root.animateAccent = true
    })

    readonly property var mainPages: [
        { page: "dashboard", label: "Dashboard" },
        { page: "nodes", label: "Nodes" },
        { page: "files", label: "Files" },
        { page: "device", label: "Device" }
    ]

    readonly property var networkPages: [
        { page: "peers", label: "Peers" },
        { page: "logs", label: "Logs" }
    ]

    readonly property var footerPages: [
        { page: "debug", label: "Debug" },
        { page: "settings", label: "Settings" },
        { page: "help", label: "Help" },
        { page: "disclaimer", label: "Disclaimer" }
    ]

    component SidebarItem: Rectangle {
        id: item

        required property var modelData

        readonly property bool active: root.currentPage === modelData.page

        Layout.fillWidth: true
        implicitHeight: 36
        radius: Theme.spacing.radiusLarge
        color: active ? Theme.palette.backgroundSecondary
                      : itemMouse.containsMouse ? Theme.palette.backgroundMuted
                                                : "transparent"

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        onActiveChanged: if (active) root.activeItem = item
        onYChanged: if (active) Qt.callLater(root.syncAccent)
        Component.onCompleted: if (active) root.activeItem = item

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacing.medium
            anchors.rightMargin: Theme.spacing.medium
            spacing: Theme.spacing.small

            Item {
                implicitWidth: 20
                implicitHeight: 20

                Image {
                    id: icon
                    anchors.fill: parent
                    source: "assets/sidebar-" + item.modelData.page + ".svg"
                    sourceSize: Qt.size(width * 2, height * 2)
                    fillMode: Image.PreserveAspectFit
                    visible: false
                }

                MultiEffect {
                    anchors.fill: icon
                    source: icon
                    colorization: 1.0
                    colorizationColor: item.active ? Theme.palette.primary
                                                   : Theme.palette.textTertiary
                }
            }

            LogosText {
                Layout.fillWidth: true
                text: item.modelData.label
                font.weight: Theme.typography.weightMedium
                color: item.active ? Theme.palette.textSecondary
                                   : Theme.palette.textTertiary
            }
        }

        MouseArea {
            id: itemMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.pageSelected(item.modelData.page)
        }
    }

    // Single accent bar pinned to the sidebar's left edge, sliding to the
    // active item.
    Rectangle {
        id: accent
        width: 4
        height: 20
        x: 0
        y: root.accentY - height / 2
        visible: root.activeItem !== null
        topRightRadius: Theme.spacing.radiusSmall
        bottomRightRadius: Theme.spacing.radiusSmall
        color: Theme.palette.primary

        Behavior on y {
            enabled: root.animateAccent
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.large
        spacing: Theme.spacing.xlarge

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.tiny

            Repeater {
                model: root.mainPages
                delegate: SidebarItem {}
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 2
            color: Theme.palette.borderTertiaryMuted
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.tiny

            Repeater {
                model: root.networkPages
                delegate: SidebarItem {}
            }
        }

        Item {
            Layout.fillHeight: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.tiny

            Repeater {
                model: root.footerPages
                delegate: SidebarItem {}
            }
        }
    }
}

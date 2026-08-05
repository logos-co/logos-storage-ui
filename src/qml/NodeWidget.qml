import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls
import Logos.StorageBackend 1.0

// qmllint disable unqualified
LogosFrame {
    id: root

    backgroundColor: Theme.palette.backgroundSecondary
    borderColor: "transparent"
    radius: Theme.spacing.radiusLarge

    implicitWidth: 320
    implicitHeight: 150

    property var backend: MockBackend
    property string reachability: "Unknown"
    property bool blinkOn: false
    readonly property int effectiveStatus: root.backend ? root.backend.status : StorageBackend.Destroyed

    readonly property color nodeStatusColor: {
        switch (root.effectiveStatus) {
        case StorageBackend.Starting:
        case StorageBackend.Stopping:
            return Theme.palette.warning
        case StorageBackend.Running:
            return Theme.palette.success
        default:
            return Theme.palette.error
        }
    }

    readonly property color natColor: {
        if (root.reachability === "Reachable") {
            return Theme.palette.success
        }

        if (root.reachability === "NotReachable") {
            return Theme.palette.warning
        }

        return Theme.palette.textMuted
    }

    readonly property string natLabel: {
        if (root.reachability === "Reachable") {
            return "Reachable"
        }

        if (root.reachability === "NotReachable") {
            return "Not reachable"
        }

        return "Unknown"
    }

    property string downloadFolderPath: ""

    // Mix is always configured; private queries default on when the node runs.
    // The toggle only flips them live, no reconfigure.
    property bool privateQueries: true

    signal folderPathChanged(string path)

    function setPrivateQueries(enabled) {
        root.privateQueries = enabled
        root.backend.togglePrivateQueries(enabled)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacing.medium

        RowLayout {
            Layout.alignment: Qt.AlignTop

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacing.medium

                RowLayout {
                    Layout.alignment: Qt.AlignTop
                    spacing: Theme.spacing.medium

                    Image {
                        Layout.alignment: Qt.AlignTop
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        // The asset already ships in Theme.palette.primary, so it
                        // is drawn as-is: colorizing it would only dull it.
                        source: Qt.resolvedUrl("assets/node-tree.svg")
                        sourceSize: Qt.size(64, 64)
                        fillMode: Image.PreserveAspectFit
                    }

                    LogosText {
                        Layout.alignment: Qt.AlignTop
                        text: "Node"
                        font.pixelSize: Theme.typography.panelTitleText
                        color: Theme.palette.text
                    }
                }

                Rectangle {
                    color: Theme.palette.backgroundBlack
                    Layout.preferredHeight: 32
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    Layout.rightMargin: Theme.spacing.small

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacing.small

                        LogosText {
                            Layout.alignment: Qt.AlignVCenter
                            text: "Manage node"
                            font.pixelSize: Theme.typography.primaryText
                            color: Theme.palette.textMuted
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        LogosIcon {
                            objectName: "debugButton"
                            Layout.alignment: Qt.AlignVCenter
                            Layout.rightMargin: Theme.spacing.small
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            source: Qt.resolvedUrl("assets/debug.svg")
                            color: Theme.palette.textTertiary

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: debugPopup.open()
                            }
                        }

                        LogosIcon {
                            objectName: "settingsButton"
                            Layout.alignment: Qt.AlignVCenter
                            Layout.rightMargin: Theme.spacing.small
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            source: Qt.resolvedUrl("assets/settings-5-line.svg")
                            color: Theme.palette.textTertiary

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: settingsPopup.open()
                            }
                        }
                    }
                }
            }

            StorageIcon {
                id: statusMatrix
                visible: root.effectiveStatus === StorageBackend.Starting
                         || root.effectiveStatus === StorageBackend.Stopping
                         || root.effectiveStatus === StorageBackend.Running
                animated: root.effectiveStatus === StorageBackend.Starting
                          || root.effectiveStatus === StorageBackend.Stopping
                dotColor: root.nodeStatusColor
            }

            DotIcon {
                visible: !statusMatrix.visible
                pattern: [0, 0, 0, 0, 0,
                          0, 0, 0, 0, 0,
                          1, 0, 1, 0, 1,
                          0, 0, 0, 0, 0,
                          0, 0, 0, 0, 0]
                dotSize: 12
                dotSpacing: 4
                dotRadius: 4
                dotColor: Theme.palette.error
                inactiveDotColor: Theme.palette.border
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.palette.textTertiary
            opacity: 0.2
        }

        RowLayout {
            id: actionRow

            RowLayout {
                id: statusRow
                spacing: Theme.spacing.medium

                // While running the node status is already on the matrix above,
                // so this line reports AutoNAT reachability instead.
                readonly property bool showsNat: root.effectiveStatus === StorageBackend.Running

                Rectangle {
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 8
                    radius: Theme.spacing.radiusSmall
                    Layout.alignment: Qt.AlignVCenter
                    color: statusRow.showsNat ? root.natColor : root.nodeStatusColor
                    opacity: statusRow.showsNat ? (root.blinkOn ? 1.0 : 0.15) : 1.0
                }

                LogosText {
                    text: {
                        if (statusRow.showsNat)
                            return root.natLabel

                        switch (root.effectiveStatus) {
                        case StorageBackend.Starting:
                            return "Starting…"
                        case StorageBackend.Stopping:
                            return "Stopping…"
                        default:
                            return "Stopped"
                        }
                    }
                    font.pixelSize: Theme.typography.primaryText
                    color: Theme.palette.textSecondary
                    Layout.alignment: Qt.AlignVCenter
                }

                LogosIcon {
                    visible: statusRow.showsNat
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    source: Qt.resolvedUrl("assets/question-line.svg")
                    color: Theme.palette.textTertiary

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: natDrawer.open()
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            LogosSwitch {
                id: mixSwitch
                text: "Mix"
                checked: root.privateQueries
                enabled: root.effectiveStatus === StorageBackend.Running
                Layout.alignment: Qt.AlignVCenter
                onToggled: root.setPrivateQueries(checked)
            }

            Connections {
                target: root.backend
                function onStartCompleted() {
                    // The node re-enables private queries on every (re)start. If
                    // the user turned them off, re-apply that choice once it's up.
                    if (root.backend.mixRunning && !root.privateQueries)
                        root.backend.togglePrivateQueries(false)
                }
            }

            LogosButton {
                radius: Theme.spacing.radiusLarge
                text: root.effectiveStatus === StorageBackend.Running ? "Stop" : "Start"
                implicitHeight: 32
                implicitWidth: 65
                // The DS button floors at 44 with 12px vertical padding; at 32
                // that padding pushes the label off-center.
                topPadding: 0
                bottomPadding: 0
                Layout.alignment: Qt.AlignVCenter
                background: CardButtonBackground {}
                // Anything but a transition: a failed start leaves the node
                // Stopped, and the user has to be able to try again.
                enabled: root.backend && root.effectiveStatus !== StorageBackend.Starting
                         && root.effectiveStatus !== StorageBackend.Stopping
                onClicked: {
                    if (!root.backend)
                        return
                    root.backend.status === StorageBackend.Running ? root.backend.stop(
                                                                       ) : root.backend.start()
                }
            }
        }

        SettingsPopup {
            id: settingsPopup
            backend: root.backend
            downloadFolderPath: root.downloadFolderPath
            privateQueries: root.privateQueries
            onFolderPathChanged: function(path) { root.folderPathChanged(path) }
            onPrivateQueriesToggled: function(enabled) { root.setPrivateQueries(enabled) }
        }

        DebugPopup {
            id: debugPopup
            backend: root.backend
            running: root.effectiveStatus === StorageBackend.Running
        }

        Shortcut {
            sequence: "Ctrl+D"
            onActivated: debugPopup.open()
        }

        NatDrawer {
            id: natDrawer
            parent: Overlay.overlay
            stateColor: root.natColor
            stateLabel: root.natLabel
        }

        // Rectangle {
        //     Layout.preferredWidth: 44
        //     Layout.preferredHeight: 44
        //     radius: 8
        //     color: settingsHover.hovered ? Theme.palette.backgroundElevated : "transparent"
        //     border.color: Theme.palette.borderSecondary
        //     border.width: 1

        //     SettingsIcon {
        //         anchors.centerIn: parent
        //         dotColor: Theme.palette.text
        //         dotSize: 5
        //         dotSpacing: 2
        //     }

        //     HoverHandler {
        //         id: settingsHover
        //     }
        //     MouseArea {
        //         anchors.fill: parent
        //         cursorShape: Qt.PointingHandCursor
        //         onClicked: root.settingsRequested()
        //     }
        // }

        // Rectangle {
        //     Layout.preferredWidth: 44
        //     Layout.preferredHeight: 44
        //     radius: 8
        //     color: startStopHover.hovered ? Theme.palette.backgroundElevated : "transparent"
        //     border.color: Theme.palette.borderSecondary
        //     border.width: 1
        //     opacity: (root.backend.status === StorageBackend.Running
        //               || root.backend.status === StorageBackend.Stopped) ? 1.0 : 0.4

        //     PlayIcon {
        //         anchors.centerIn: parent
        //         dotColor: Theme.palette.text
        //         dotSize: 5
        //         dotSpacing: 2
        //         visible: root.backend.status !== StorageBackend.Running
        //     }
        //     StopIcon {
        //         anchors.centerIn: parent
        //         dotColor: Theme.palette.text
        //         dotSize: 5
        //         dotSpacing: 2
        //         visible: root.backend.status === StorageBackend.Running
        //     }

        //     HoverHandler {
        //         id: startStopHover
        //     }
        //     MouseArea {
        //         anchors.fill: parent
        //         enabled: root.backend.status === StorageBackend.Running
        //                  || root.backend.status === StorageBackend.Stopped
        //         cursorShape: Qt.PointingHandCursor
        //         onClicked: root.backend.status === StorageBackend.Running ? root.backend.stop(
        //                                                               ) : root.backend.start()
        //     }
        // }
    }
}

import QtQuick
import QtQuick.Layouts
import Logos.Controls
import Logos.Theme

OnBoardingLayout {
    id: root

    property var backend: MockBackend
    property string status: "Starting your node..."
    property string title: "Checking connectivity"
    property string resolution: ""
    property bool starting: true
    property bool success: false
    property bool started: false

    signal back
    signal next

    function onNodeStarted() {
        root.starting = false
        root.status = "Your node is up and reachable."
        root.title = "Node is ready"
        root.success = true
    }

    Component.onCompleted: root.backend.start()

    Timer {
        id: nodeCheckTimer
        interval: 500
        repeat: false
        onTriggered: root.backend.checkNodeIsUp()
    }

    Connections {
        target: root.backend

        function onStartCompleted() {
            root.started = true
            root.title = "Checking connectivity"
            root.status = "Node started, verifying reachability..."
            nodeCheckTimer.start()
        }

        function onStartFailed(error) {
            root.started = false
            root.starting = false
            root.title = "Failed to start"
            root.status = "Your node failed to start: " + error
        }

        function onNodeIsUp() {
            root.onNodeStarted()
        }

        function onNodeIsntUp(reason) {
            root.starting = false
            root.title = "Node unreachable"
            root.status = ""
            root.resolution = reason
        }
    }

    OnBoardingContainer {
        spacing: Theme.spacing.medium

        OnBoardingProgress {
            Layout.fillWidth: true
            currentStep: root.started ? 3 : 2
            Layout.topMargin: Theme.spacing.small
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 10

            RowLayout {
                Layout.fillWidth: true

                LogosText {
                    text: root.title
                    font.pixelSize: Theme.typography.titleText
                    font.weight: Font.Bold
                }

                Item {
                    Layout.fillWidth: true
                }

                LogosText {
                    text: "3 / 5"
                    font.pixelSize: Theme.typography.primaryText
                    color: Theme.palette.primary
                    font.family: "monospace"
                }
            }

            LogosText {
                text: root.status
                font.pixelSize: Theme.typography.primaryText * 1.8
            }
        }

        Rectangle {
            property bool selected: false
            property Component icon

            Layout.fillWidth: true
            Layout.preferredHeight: 230
            radius: Theme.spacing.radiusLarge
            color: Theme.palette.backgroundSecondary
            border.color: selected ? Theme.palette.primary : Theme.palette.textMuted
            border.width: 1

            NodeStatusIcon {
                anchors.centerIn: parent
                starting: root.starting
                success: root.success
            }
        }

        LogosText {
            font.pixelSize: Theme.typography.primaryText
            text: root.resolution
            visible: root.resolution !== ""
            color: Theme.palette.error
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spacing.small

            LogosStorageButton {
                iconSource: "assets/arrow-left.png"
                iconPosition: "left"
                text: "Back"
                enabled: !root.starting
                onClicked: {
                    root.backend.stop()
                    root.back()
                }
            }

            Item {
                Layout.fillWidth: true
            }

            LogosStorageButton {
                iconSource: "assets/arrow-right.png"
                iconPosition: "right"
                text: "Continue"
                enabled: root.success
                onClicked: {
                    root.backend.saveCurrentConfig()
                    root.next()
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: root.backend && root.backend.isMock === true
        repeat: false
        onTriggered: root.onNodeStarted()
    }
}

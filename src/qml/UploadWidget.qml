import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

Card {
    id: root

    implicitWidth: 300
    implicitHeight: 120
    padding: isUploading || isDone ? 0 : Theme.spacing.medium

    property var backend: MockBackend
    property bool running: false
    property real totalBytes: 0
    property real uploadedBytes: 0
    property string uploadedCid: ""
    readonly property bool isUploading: uploadProgress > 0
                                        && uploadProgress < 100
    readonly property bool isDone: uploadProgress >= 100
    readonly property int uploadProgress: {
        if (totalBytes <= 0) {
            return 0
        }
        return Math.min(Math.round(uploadedBytes / totalBytes * 100), 100)
    }

    signal uploadRequested

    function reset() {
        root.totalBytes = 0
        root.uploadedBytes = 0
        root.uploadedCid = ""
    }

    Connections {
        target: root.backend

        function onUploadStarted(totalBytes) {
            root.totalBytes = totalBytes
            root.uploadedBytes = 0
            root.uploadedCid = ""
        }

        function onUploadChunk(len) {
            root.uploadedBytes += len
        }

        function onUploadCompleted(cid) {
            root.uploadedBytes = root.totalBytes
            root.uploadedCid = cid
        }
    }

    // ── Idle ──────────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: uploadBottomTitle.top
        visible: !root.isUploading && !root.isDone

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.spacing.radiusLarge
            color: Theme.palette.backgroundBlack
            border.color: Theme.palette.borderDark
            border.width: 1

            RowLayout {
                anchors.fill: parent

                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.fillHeight: false
                    spacing: Theme.spacing.tiny

                    RowLayout {
                        Layout.topMargin: Theme.spacing.small
                        Layout.leftMargin: Theme.spacing.small
                        Layout.fillHeight: false

                        LogosText {
                            text: "Click to"
                            color: Theme.palette.text
                        }

                        LogosText {
                            text: "browse"
                            color: Theme.palette.primary
                        }
                    }

                    LogosText {
                        Layout.leftMargin: Theme.spacing.small
                        text: "Up to 1 file"
                        color: Theme.palette.textMuted
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Image {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: Theme.spacing.tiny
                    Layout.rightMargin: Theme.spacing.tiny
                    source: "assets/folder-upload.png"
                }
            }
        }
    }

    BottomTitle {
        id: uploadBottomTitle
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        title: "Upload"
        visible: !root.isUploading && !root.isDone
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * (root.uploadProgress / 100.0)
        radius: Theme.spacing.radiusLarge
        clip: true
        opacity: (root.isUploading || root.isDone) ? 1.0 : 0.0
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0.0
                color: Theme.palette.accentOrange
            }
            GradientStop {
                position: 0.70
                color: Theme.palette.accentOrangeMid
            }
            GradientStop {
                position: 1.0
                color: Theme.palette.accentOrangeDeep
            }
        }
        visible: root.isUploading || root.isDone

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0;  color: "#88000000" }
                GradientStop { position: 0.35; color: "#88000000" }
                GradientStop { position: 0.55; color: "#66000000" }
                GradientStop { position: 0.72; color: "#33000000" }
                GradientStop { position: 0.88; color: "#11000000" }
                GradientStop { position: 1.0;  color: "#00000000" }
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.medium
        Layout.alignment: Qt.AlignTop
        visible: root.isUploading || root.isDone

        RowLayout {
            LogosText {
                text: "CID"
                font.pixelSize: Theme.typography.primaryText
                color: Theme.palette.text
                visible: root.uploadedCid != ""
            }

            Item {
                Layout.fillWidth: true
            }

            Image {
                source: "assets/close-circle.png"
                visible: root.isDone

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.reset()
                }
            }
        }

        Rectangle {
            id: cidBox
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            radius: Theme.spacing.radiusSmall
            opacity: 0.8

            property bool copied: false

            color: "#141414"

            Timer {
                id: resetCopyTimer
                interval: 1500
                onTriggered: cidBox.copied = false
            }

            LogosText {
                id: cidText
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacing.small
                anchors.right: copyIcon.left
                anchors.rightMargin: Theme.spacing.small
                text: root.uploadedCid
                font.pixelSize: Theme.typography.primaryText
                color: Theme.palette.text
                horizontalAlignment: Text.AlignHLeft
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            Image {
                id: copyIcon
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacing.small
                source: cidBox.copied ? "assets/success.png" : "assets/file-copy.png"

                Behavior on source {
                    PropertyAnimation {
                        duration: 80
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        clipboardHelper.text = root.uploadedCid
                        clipboardHelper.selectAll()
                        clipboardHelper.copy()
                        cidBox.copied = true
                        resetCopyTimer.restart()
                    }
                }
            }

            TextEdit {
                id: clipboardHelper
                visible: false
            }
        }

        RowLayout {
            LogosText {
                text: root.isUploading ? "Uploading..." : "Complete"
                font.pixelSize: Theme.typography.titleText * 0.6
                color: Theme.palette.text
                visible: root.isUploading || root.isDone
            }

            Item {
                Layout.fillWidth: true
            }

            LogosText {
                text: root.uploadProgress + "%"
                font.pixelSize: Theme.typography.titleText * 0.6
                font.bold: true
                color: Theme.palette.text
                visible: root.isUploading || root.isDone
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: root.running ? Qt.PointingHandCursor : Qt.ArrowCursor
        enabled: !root.isUploading && !root.isDone
        onClicked: root.uploadRequested()
    }
}

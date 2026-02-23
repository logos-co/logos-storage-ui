import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

// qmllint disable unqualified
ColumnLayout {
    id: root

    property var backend: MockBackend
    property bool running: false
    property string _lastUploadedCid: ""

    spacing: 0

    TextEdit {
        id: clipHelper
        visible: false
        function copyText(str) {
            clipHelper.text = str
            clipHelper.selectAll()
            clipHelper.copy()
        }
    }

    FileDialog {
        id: uploadDialog
        onAccepted: root.backend.uploadFile(selectedFile)
    }

    Connections {
        target: root.backend
        function onUploadCompleted(cid) {
            root._lastUploadedCid = cid
        }

        function onDownloadCompleted() {}
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacing.medium

        UploadWidget {
            backend: root.backend
            running: root.running
            onUploadRequested: uploadDialog.open()
        }

        DiskWidget {
            backend: root.backend
        }

        PeersWidget {
            backend: root.backend
        }

        Item {
            Layout.fillWidth: true
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.topMargin: 10
        Layout.bottomMargin: 10
        Layout.preferredHeight: 36

        opacity: root._lastUploadedCid.length > 0 ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        Rectangle {
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
                        var c = root._lastUploadedCid
                        return c.length > 20 ? c.substring(0, 8) + "…" + c.slice(-6) : c
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
                color: cidBadgeHover.hovered ? Qt.rgba(1, 1, 1,
                                                       0.04) : "transparent"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    clipHelper.copyText(root._lastUploadedCid)
                    copyFlashAnim.restart()
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtCore
import Logos.Theme
import Logos.Controls
import "Utils.js" as Utils

// qmllint disable unqualified
Card {
    id: root

    property var backend: MockBackend
    property bool running: false
    property var manifests: [{
            "cid": "1234",
            "filename": "Claude.jpg",
            "mimetype": "image/jpg",
            "size": 12222
        }]

    implicitWidth: 1200
    implicitHeight: 400
    Layout.minimumHeight: 0


    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacing.small

        Connections {
            target: root.backend

            onManifestsUpdated: function (manifests) {
                root.manifests = manifests
            }
        }

        LogosText {
            text: "Manifests"
            font.pixelSize: Theme.typography.titleText
            color: Theme.palette.text
        }

        Rectangle {
            id: header
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            // TODO: Logos Design System
            color: "#141414"
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
            model: root.manifests

            delegate: Rectangle {
                width: manifestList.width
                height: 52
                color: Theme.palette.backgroundSecondary

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacing.medium
                    anchors.rightMargin: Theme.spacing.medium

                    // CID cell with copy button on the far right
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Text {
                            anchors.left: parent.left
                            anchors.right: copyBtn.left
                            anchors.rightMargin: 6
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
                            width: 28
                            height: 28
                            radius: 14
                            color: copyHover.hovered ? Theme.palette.backgroundElevated : "transparent"
                            border.color: Theme.palette.borderSecondary
                            border.width: 1

                            Image {
                                anchors.centerIn: parent
                                source: "assets/file-copy.png"
                                width: 16
                                height: 16
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
                                }
                            }
                        }

                        TextEdit {
                            id: clipboardHelper
                            visible: false
                        }
                    }

                    Text {
                        text: modelData.filename
                        color: Theme.palette.text
                        font.pixelSize: Theme.typography.secondaryText
                        elide: Text.ElideRight
                        Layout.preferredWidth: 140
                    }

                    Text {
                        text: modelData.mimetype
                        color: Theme.palette.text
                        font.pixelSize: Theme.typography.secondaryText
                        elide: Text.ElideRight
                        Layout.preferredWidth: 100
                    }

                    Text {
                        text: Utils.formatBytes(parseInt(modelData.datasetSize))
                        color: Theme.palette.text
                        font.pixelSize: Theme.typography.secondaryText
                        Layout.preferredWidth: 80
                    }

                    Row {
                        spacing: 6
                        Layout.preferredWidth: 92
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            width: 40
                            height: 40
                            radius: 20
                            color: dlHover.hovered ? Theme.palette.backgroundElevated : "transparent"
                            border.color: Theme.palette.borderSecondary
                            border.width: 1
                            opacity: root.running ? 1.0 : 0.35

                            Image {
                                anchors.centerIn: parent
                                source: "assets/download.png"
                                width: 20
                                height: 20
                                fillMode: Image.PreserveAspectFit
                            }
                            HoverHandler {
                                id: dlHover
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: root.running
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    saveDialog.pendingManifest = modelData
                                    saveDialog.currentFile = StandardPaths.writableLocation(
                                                StandardPaths.HomeLocation)
                                            + "/" + (modelData.filename
                                                     || modelData.cid
                                                     || "download")
                                    saveDialog.open()
                                }
                            }
                        }

                        Rectangle {
                            width: 40
                            height: 40
                            radius: 20
                            color: rmHover.hovered ? Theme.palette.backgroundElevated : "transparent"
                            border.color: Theme.palette.borderSecondary
                            border.width: 1
                            opacity: root.running ? 1.0 : 0.35

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
                                anchors.fill: parent
                                enabled: root.running
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.cid.length > 0) {
                                        root.backend.remove(modelData.cid)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Empty state
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

    FileDialog {
        id: saveDialog

        property var pendingManifest: null

        fileMode: FileDialog.SaveFile
        onAccepted: {
            if (pendingManifest) {
                root.backend.downloadFile(pendingManifest.cid, selectedFile,
                                          parseInt(pendingManifest.datasetSize) || 0)
                pendingManifest = null
            }
        }
        onRejected: pendingManifest = null
    }
}

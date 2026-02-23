import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtCore
import Logos.Theme
import Logos.Controls
import "Utils.js" as Utils

// qmllint disable unqualified
ColumnLayout {
    id: root

    property var backend: MockBackend
    property bool running: false
    property var manifests: []

    spacing: Theme.spacing.small

    FileDialog {
        id: saveDialog

        property var pendingManifest: null

        fileMode: FileDialog.SaveFile
        onAccepted: {
            if (pendingManifest) {
                root.backend.downloadFile(pendingManifest.cid, selectedFile)
                pendingManifest = null
            }
        }
        onRejected: pendingManifest = null
    }


    Connections {
        target: root.backend

        onManifestsUpdated: function (manifests) {
            root.manifests = manifests
        }
    }

    LogosText {
        text: "MANIFESTS"
        font.pixelSize: 11
        color: Theme.palette.textTertiary
        font.letterSpacing: 1.5
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacing.small

        LogosTextField {
            id: cidInput
            Layout.fillWidth: true
            height: getManifestBtn.implicitHeight
            placeholderText: "Enter CID to download manifest…"
            isValid: true
        }

        LogosStorageButton {
            id: getManifestBtn
            text: "GET MANIFEST"
            enabled: root.running && cidInput.text.length > 0
            onClicked: {
                root.backend.downloadManifest(cidInput.text)
                cidInput.clear()
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 30
        color: Theme.palette.backgroundElevated
        radius: 4

        Row {
            anchors.fill: parent
            anchors.leftMargin: 10

            Text {
                width: 160
                text: "CID"
                color: Theme.palette.textSecondary
                font.pixelSize: 11
                font.bold: true
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                width: 130
                text: "Filename"
                color: Theme.palette.textSecondary
                font.pixelSize: 11
                font.bold: true
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                width: 90
                text: "MIME"
                color: Theme.palette.textSecondary
                font.pixelSize: 11
                font.bold: true
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                width: 80
                text: "Size"
                color: Theme.palette.textSecondary
                font.pixelSize: 11
                font.bold: true
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 240
        color: Theme.palette.background
        border.color: Theme.palette.borderSecondary
        border.width: 1
        radius: 4
        clip: true

        ListView {
            id: manifestList
            anchors.fill: parent
            model: root.manifests
            clip: true

            delegate: Rectangle {
                id: delegateItem
                width: manifestList.width
                height: 36
                color: index % 2
                       === 0 ? Theme.palette.background : Theme.palette.backgroundSecondary

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8

                    Text {
                        width: 160
                        text: modelData.cid
                        color: Theme.palette.text
                        font.pixelSize: 11
                        font.family: "monospace"
                        elide: Text.ElideMiddle
                        anchors.verticalCenter: parent.verticalCenter
                        ToolTip.visible: cidHover.hovered
                        ToolTip.text: modelData.cid
                        HoverHandler {
                            id: cidHover
                        }
                    }
                    Text {
                        width: 130
                        text: modelData.filename
                        color: Theme.palette.textSecondary
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        width: 90
                        text: modelData.mimetype
                        color: Theme.palette.textSecondary
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        width: 80
                        text: Utils.formatBytes(parseInt(modelData.datasetSize))
                        color: Theme.palette.textSecondary
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Row {
                        spacing: 6
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            width: 28
                            height: 28
                            radius: 4
                            color: dlHover.hovered ? Theme.palette.backgroundElevated : "transparent"
                            border.color: Theme.palette.borderSecondary
                            border.width: 1
                            opacity: root.running ? 1.0 : 0.35

                            DownloadIcon {
                                anchors.centerIn: parent
                                dotColor: Theme.palette.text
                                dotSize: 3
                                dotSpacing: 1
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
                            width: 28
                            height: 28
                            radius: 4
                            color: rmHover.hovered ? Theme.palette.backgroundElevated : "transparent"
                            border.color: Theme.palette.borderSecondary
                            border.width: 1
                            opacity: root.running ? 1.0 : 0.35

                            DeleteIcon {
                                anchors.centerIn: parent
                                dotColor: Theme.palette.error
                                dotSize: 3
                                dotSpacing: 1
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
}

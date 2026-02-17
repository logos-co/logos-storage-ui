import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtCore

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitWidth: 600
    implicitHeight: 600
    color: "#000000"

    property var backend: mockBackend
    readonly property int stopped: 0
    readonly property int starting: 1
    readonly property int running: 2
    readonly property int stopping: 3
    readonly property int destroyed: 4
    property string peerId: ""
    property string downloadDestination: ""
    property url downloadCid: ""
    property string logLevel: ""
    property bool showDebug: false
    property var pendingDownloadManifest: null
    property url uploadCid: root.backend.cid
    property url configJson: root.backend.configJson

    function getStatusLabel() {
        switch (backend.status) {
        case stopped:
            return "Logos Storage stopped."
        case starting:
            return "Logos Storage is starting..."
        case running:
            return "Logos Storage started."
        case stopping:
            return "Logos Storage is stopping..."
        case destroyed:
            return "Logos Storage is not initialised."
        }
    }

    function startStopText() {
        if (backend.status == running) {
            return "Stop"
        }
        return "Start"
    }

    function canStartStop() {
        return backend.status == running || backend.status == stopped
    }

    function isRunning() {
        return backend.status == running
    }

    QtObject {
        id: mockBackend

        property var status: root.stopped
        property var debugLogs: "Hello !"
        property var configJson: "{}"
        property url cid: ""
        property string uploadStatus: ""
        property int uploadProgress: 0

        function start(newConfigJson) {
            status = root.running
        }

        function stop() {
            status = root.stopped
        }

        function tryPeerConnect(peerId) {
            console.log("Attempting peer connection...")
        }

        function tryDebug() {
            console.log("Attempting peer connection...")
        }

        function spr() {}

        function showPeerId() {}

        function version() {}

        function dataDir() {}

        function tryUploadFinalize() {
            console.log("Attempting upload finalize")
        }

        function tryUploadFile(file) {
            console.log("Attempting upload file")
        }

        function tryDownloadFile(cid, file) {
            console.log("Attempting download a file", cid, file)
        }

        function exists(cid) {
            console.log("Attempting exists", cid)
        }

        function fetch(cid) {
            console.log("Attempting fetch", cid)
        }

        function remove(cid) {
            console.log("Attempting remove", cid)
        }

        function downloadManifest(cid) {
            console.log("Attempting downloadManifest", cid)
        }

        function downloadManifests() {
            console.log("Attempting downloadManifests")
        }

        function space() {}

        function updateLogLevel(logLevel) {}

        property var manifests: []
        property var quotaMaxBytes: 20 * 1024 * 1024 * 1024 // 20 GB default
        property var quotaUsedBytes: 0
        property var quotaReservedBytes: 0
    }

    function formatBytes(bytes) {
        if (bytes <= 0)
            return "0 B"
        if (bytes < 1024)
            return bytes + " B"
        if (bytes < 1024 * 1024)
            return (bytes / 1024).toFixed(1) + " KB"
        if (bytes < 1024 * 1024 * 1024)
            return (bytes / (1024 * 1024)).toFixed(1) + " MB"
        return (bytes / (1024 * 1024 * 1024)).toFixed(2) + " GB"
    }

    Text {
        id: statusTextElement
        objectName: "status"
        text: root.getStatusLabel()
        color: "white"
        font.pointSize: 20
        anchors.top: parent.top
        anchors.topMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Button {
        id: startStopButton
        objectName: "startStopButton"
        anchors.leftMargin: 50
        text: root.startStopText()
        enabled: root.canStartStop()
        onClicked: root.backend.status == root.stopped ? root.backend.start(
                                                             jsonEditor.text) : root.backend.stop()
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: statusTextElement.bottom
        anchors.topMargin: 10
    }

    TextEdit {
        id: cidTextEdit
        objectName: "cid"
        color: "white"
        font.pointSize: 14
        readOnly: true
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: startStopButton.bottom
        anchors.topMargin: 10
        text: root.uploadCid
    }

    Button {
        id: openFile
        text: "Open file"
        onClicked: fileDialog.open()
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: cidTextEdit.bottom
        anchors.topMargin: 15
        enabled: root.isRunning
    }

    Column {
        id: uploadProgressColumn
        anchors.top: openFile.bottom
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        width: 300
        spacing: 5
        visible: root.backend.uploadProgress > 0

        ProgressBar {
            width: parent.width
            value: root.backend.uploadProgress / 100.0

            background: Rectangle {
                color: "#333333"
                radius: 3
                implicitWidth: 300
                implicitHeight: 6
            }

            contentItem: Item {
                implicitWidth: 300
                implicitHeight: 6

                Rectangle {
                    width: parent.width * parent.parent.visualPosition
                    height: parent.height
                    radius: 3
                    color: "#4CAF50"
                }
            }
        }

        Text {
            text: root.backend.uploadStatus
            color: "#888888"
            font.pixelSize: 10
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // TextField {
    //     id: peerIdField
    //     placeholderText: "Enter the peer Id"
    //     placeholderTextColor: "#999999"
    //     color: "#000000"
    //     selectByMouse: true
    //     text: root.peerId
    //     onTextChanged: root.peerId = text
    //     anchors.top: uploadProgressColumn.bottom
    //     anchors.topMargin: 50
    //     anchors.horizontalCenter: parent.horizontalCenter
    // }

    // Button {
    //     id: peerConnectButton
    //     objectName: "peerConnectButton"
    //     text: "Peer connect"
    //     onClicked: root.backend.tryPeerConnect(root.peerId)
    //     anchors.top: peerIdField.bottom
    //     anchors.horizontalCenter: parent.horizontalCenter
    //     enabled: root.isRunning
    //     anchors.topMargin: 10
    // }
    Button {
        id: debugButton
        objectName: "debugButton"
        text: "Debug"
        onClicked: root.backend.tryDebug()
        anchors.top: uploadProgressColumn.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        enabled: root.isRunning
        anchors.topMargin: 50
    }

    Button {
        id: peerIdButton
        objectName: "peerIdButton"
        text: "Peer Id"
        onClicked: root.backend.showPeerId()
        anchors.top: uploadProgressColumn.bottom
        anchors.right: debugButton.left
        enabled: root.isRunning
        anchors.topMargin: 50
    }

    Button {
        id: dataDirButton
        objectName: "dataDirButton"
        text: "Data dir"
        onClicked: root.backend.dataDir()
        anchors.top: uploadProgressColumn.bottom
        anchors.right: peerIdButton.left
        enabled: root.isRunning
        anchors.topMargin: 50
    }

    Button {
        id: sprButton
        objectName: "sprButton"
        text: "SPR"
        onClicked: root.backend.spr()
        anchors.top: uploadProgressColumn.bottom
        anchors.left: debugButton.right
        enabled: root.isRunning
        anchors.topMargin: 50
    }

    Button {
        id: versionButton
        objectName: "versionButton"
        text: "Version"
        onClicked: root.backend.version()
        anchors.top: uploadProgressColumn.bottom
        anchors.left: sprButton.right
        enabled: root.isRunning
        anchors.topMargin: 50
    }

    // TextField {
    //     id: cidDownloadField
    //     placeholderTextColor: "#999999"
    //     placeholderText: "Enter the cid to download"
    //     color: "black"
    //     //  text: root.downloadCid
    //     onTextChanged: root.downloadCid = text
    //     anchors.top: debugButton.bottom
    //     anchors.topMargin: 50
    //     anchors.horizontalCenter: parent.horizontalCenter
    // }

    // Button {
    //     id: openFile2
    //     text: "Open file"
    //     onClicked: fileDialog2.open()
    //     anchors.horizontalCenter: parent.horizontalCenter
    //     anchors.top: cidDownloadField.bottom
    //     anchors.topMargin: 15
    //     enabled: root.isRunning
    // }

    // Button {
    //     id: cidDownloadButton
    //     objectName: "cidDownloadButton"
    //     text: "Download"
    //     onClicked: root.backend.tryDownloadFile(root.downloadCid,
    //                                             root.downloadDestination)
    //     anchors.top: openFile2.bottom
    //     anchors.horizontalCenter: parent.horizontalCenter
    //     enabled: root.isRunning
    //     anchors.topMargin: 10
    // }

    // Button {
    //     id: existsButton
    //     objectName: "existsButton"
    //     text: "Exists"
    //     onClicked: root.backend.exists(root.downloadCid)
    //     anchors.top: openFile2.bottom
    //     anchors.left: cidDownloadButton.right
    //     enabled: root.isRunning
    //     anchors.topMargin: 10
    // }

    // Button {
    //     id: fetchButton
    //     objectName: "fetchButton"
    //     text: "Fetch"
    //     onClicked: root.backend.fetch(root.downloadCid)
    //     anchors.top: openFile2.bottom
    //     anchors.left: existsButton.right
    //     enabled: root.isRunning
    //     anchors.topMargin: 10
    // }

    // Button {
    //     id: removeButton
    //     objectName: "removeButton"
    //     text: "Remove"
    //     onClicked: root.backend.remove(root.downloadCid)
    //     anchors.top: openFile2.bottom
    //     anchors.right: cidDownloadButton.left
    //     enabled: root.isRunning
    //     anchors.topMargin: 10
    // }

    // Button {
    //     id: downloadManifestButton
    //     objectName: "downloadManifestButton"
    //     text: "Download manifest"
    //     onClicked: root.backend.downloadManifest(root.downloadCid)
    //     anchors.top: openFile2.bottom
    //     anchors.right: removeButton.left
    //     enabled: root.isRunning
    //     anchors.topMargin: 10
    // }


    /*Button {
        id: downloadManifestsButton
        objectName: "downloadManifestsButton"
        text: "Manifests"
        onClicked: root.backend.downloadManifests()
        anchors.top: cidDownloadButton.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        enabled: root.isRunning
        anchors.topMargin: 10
    }*/

    // ── Manifests section ──────────────────────────────────────────────────
    Text {
        id: manifestsTitle
        text: "Manifests"
        color: "white"
        font.pixelSize: 14
        font.bold: true
        anchors.top: versionButton.bottom
        anchors.topMargin: 30
        anchors.horizontalCenter: parent.horizontalCenter
    }

    // ── Disk space bar ────────────────────────────────────────────────────
    Item {
        id: spaceBarSection
        anchors.top: manifestsTitle.bottom
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 40
        height: root.backend.quotaMaxBytes > 0 ? 36 : 20

        readonly property real total: root.backend.quotaMaxBytes
        readonly property real used: root.backend.quotaUsedBytes
        readonly property real reserved: root.backend.quotaReservedBytes

        // No quota configured
        Text {
            anchors.centerIn: parent
            text: "No quota configured"
            color: "#555555"
            font.pixelSize: 11
            visible: spaceBarSection.total <= 0
        }

        // Background track
        Rectangle {
            id: spaceBarTrack
            visible: spaceBarSection.total > 0
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 14
            radius: 7
            color: "#2a2a2a"
            border.color: "#3a3a3a"
            border.width: 1
            clip: true

            // Used (green)
            Rectangle {
                width: Math.min(
                           parent.width * (spaceBarSection.used / spaceBarSection.total),
                           parent.width)
                height: parent.height
                radius: parent.radius
                color: "#4CAF50"
            }

            // Reserved (orange), stacked after used
            Rectangle {
                x: parent.width * (spaceBarSection.used / spaceBarSection.total)
                width: Math.min(
                           parent.width * (spaceBarSection.reserved / spaceBarSection.total),
                           parent.width - x)
                height: parent.height
                color: "#FF9800"
            }
        }

        // Labels
        Row {
            visible: spaceBarSection.total > 0
            anchors.top: spaceBarTrack.bottom
            anchors.topMargin: 4
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            Text {
                text: "Used: " + root.formatBytes(spaceBarSection.used)
                color: "#4CAF50"
                font.pixelSize: 10
            }
            Text {
                text: "Reserved: " + root.formatBytes(spaceBarSection.reserved)
                color: "#FF9800"
                font.pixelSize: 10
            }
            Text {
                text: "Free: " + root.formatBytes(
                          spaceBarSection.total - spaceBarSection.used - spaceBarSection.reserved)
                color: "#888888"
                font.pixelSize: 10
            }
            Text {
                text: "Total: " + root.formatBytes(spaceBarSection.total)
                color: "#555555"
                font.pixelSize: 10
            }
        }
    }

    Row {
        id: manifestInputRow
        spacing: 8
        anchors.top: spaceBarSection.bottom
        anchors.topMargin: 16
        anchors.horizontalCenter: parent.horizontalCenter

        TextField {
            id: manifestCidField
            width: 380
            placeholderText: "Enter CID to download manifest"
            placeholderTextColor: "#999999"
            color: "#000000"
            selectByMouse: true
        }

        Button {
            id: addManifestButton
            text: "Download Manifest"
            enabled: root.isRunning() && manifestCidField.text.length > 0
            onClicked: {
                root.backend.downloadManifest(manifestCidField.text)
                manifestCidField.clear()
            }
        }
    }

    // Table header
    Rectangle {
        id: manifestTableHeader
        anchors.top: manifestInputRow.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 40
        height: 28
        color: "#222222"
        radius: 2

        Row {
            anchors.fill: parent
            anchors.leftMargin: 6

            Text {
                width: 150
                text: "CID"
                color: "#aaaaaa"
                font.pixelSize: 11
                font.bold: true
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                width: 120
                text: "Filename"
                color: "#aaaaaa"
                font.pixelSize: 11
                font.bold: true
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                width: 85
                text: "MIME type"
                color: "#aaaaaa"
                font.pixelSize: 11
                font.bold: true
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                width: 75
                text: "Size (bytes)"
                color: "#aaaaaa"
                font.pixelSize: 11
                font.bold: true
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                width: 110
                text: ""
                color: "#aaaaaa"
                font.pixelSize: 11
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Rectangle {
        id: manifestTableContainer
        anchors.top: manifestTableHeader.bottom
        anchors.left: manifestTableHeader.left
        anchors.right: manifestTableHeader.right
        height: 280
        color: "#111111"
        border.color: "#333333"
        border.width: 1
        clip: true

        ListView {
            id: manifestListView
            anchors.fill: parent
            model: root.backend.manifests
            clip: true

            delegate: Rectangle {
                width: manifestListView.width
                height: 36
                color: index % 2 === 0 ? "#181818" : "#1e1e1e"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 4
                    spacing: 0

                    Text {
                        width: 150
                        text: modelData["cid"] ?? ""
                        color: "#dddddd"
                        font.pixelSize: 11
                        font.family: "monospace"
                        elide: Text.ElideMiddle
                        anchors.verticalCenter: parent.verticalCenter
                        // ToolTip.visible: hovered
                        ToolTip.text: modelData["cid"] ?? ""
                        HoverHandler {}
                    }
                    Text {
                        width: 120
                        text: modelData["filename"] ?? ""
                        color: "#dddddd"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        width: 85
                        text: modelData["mimetype"] ?? ""
                        color: "#dddddd"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        width: 75
                        text: modelData["datasetSize"] ?? ""
                        color: "#dddddd"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Row {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter

                        Button {
                            width: 50
                            height: 26
                            text: "↓"
                            enabled: root.isRunning()
                            onClicked: {
                                root.pendingDownloadManifest = modelData
                                var filename = modelData["filename"]
                                        || modelData["cid"] || "download"
                                manifestSaveDialog.currentFile = StandardPaths.writableLocation(
                                            StandardPaths.HomeLocation) + "/" + filename
                                manifestSaveDialog.open()
                            }
                        }

                        Button {
                            width: 50
                            height: 26
                            text: "🗑"
                            enabled: root.isRunning()
                            onClicked: root.backend.remove(
                                           modelData["cid"] ?? "")
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: "No manifests yet"
                color: "#555555"
                font.pixelSize: 12
                visible: manifestListView.count === 0
            }
        }
    }

    Button {
        id: spaceButton
        objectName: "spaceButton"
        text: "Space"
        onClicked: root.backend.space()
        anchors.top: manifestTableContainer.bottom
        enabled: root.isRunning
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
    }

    // ── Log level section ──────────────────────────────────────────────────
    // TextField {
    //     id: logLevelField
    //     placeholderTextColor: "#999999"
    //     placeholderText: "Enter the log level to download"
    //     color: "black"
    //     //  text: root.downloadCid
    //     onTextChanged: root.logLevel = text
    //     anchors.top: manifestTableContainer.bottom
    //     anchors.topMargin: 30
    //     anchors.horizontalCenter: parent.horizontalCenter
    // }

    // Button {
    //     id: logLevelButton
    //     objectName: "logLevelButton"
    //     text: "Log level"
    //     onClicked: root.backend.updateLogLevel(root.logLevel)
    //     anchors.top: logLevelField.bottom
    //     anchors.horizontalCenter: parent.horizontalCenter
    //     enabled: root.isRunning
    //     anchors.topMargin: 10
    // }

    // TextEdit {
    //     id: selectableText
    //     anchors.fill: parent
    //     anchors.margins: 10
    //     text: "This text is selectable. You can copy it, but not edit it."
    //     readOnly: true // Makes the text non-editable
    //     selectByMouse: true // Enables selection by mouse drag (often the default for desktop)
    //     // Optional: Change cursor shape to IBeam when hovering
    //     MouseArea {
    //         anchors.fill: parent
    //         cursorShape: Qt.IBeamCursor
    //         acceptedButtons: Qt.NoButton // Allows TextEdit to handle mouse events
    //     }
    // }

    // Button {
    //     anchors.left: parent.left
    //     anchors.bottom: parent.bottom
    //     objectName: "uploadButton"
    //     text: "Upload"
    //     anchors.bottomMargin: 80
    //     onClicked: root.backend.tryUpload()
    // }

    // Button {
    //     anchors.left: parent.left
    //     anchors.bottom: parent.bottom
    //     objectName: "finalizeButton"
    //     text: "Finalize"
    //     onClicked: root.backend.tryUploadFinalize()
    // }
    // Button {
    //     anchors.left: parent.left
    //     anchors.bottom: parent.bottom
    //     objectName: "uploadFileButton"
    //     text: "Upload file"
    //     onClicked: root.backend.tryUploadFile()
    //     anchors.bottomMargin: 30
    // }
    FileDialog {
        id: fileDialog
        onAccepted: root.backend.tryUploadFile(fileDialog.selectedFile)
    }

    FileDialog {
        id: fileDialog2
        fileMode: FileDialog.SaveFile
        onAccepted: {
            root.downloadDestination = fileDialog2.selectedFile
            console.log("Destination selected:",
                        root.backend.downloadDestination)
        }
    }

    FileDialog {
        id: manifestSaveDialog
        fileMode: FileDialog.SaveFile
        onAccepted: {
            if (root.pendingDownloadManifest) {
                root.backend.tryDownloadFile(
                            root.pendingDownloadManifest["cid"],
                            manifestSaveDialog.selectedFile)
                root.pendingDownloadManifest = null
            }
        }
        onRejected: {
            root.pendingDownloadManifest = null
        }
    }

    Rectangle {
        id: debugPanel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 150
        color: "#111111"
        visible: root.showDebug // or: visible: showDebug

        TabBar {
            id: bar
            width: parent.width

            TabButton {
                text: qsTr("Logs")
            }

            TabButton {
                text: qsTr("Config")
            }
        }

        StackLayout {
            id: stackLayout
            currentIndex: bar.currentIndex
            anchors.top: bar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            Item {
                id: homeTab

                Flickable {
                    id: flick
                    anchors.fill: parent
                    clip: true

                    contentWidth: width
                    contentHeight: debugText.paintedHeight

                    TextEdit {
                        id: debugText
                        width: flick.width
                        text: root.backend.debugLogs
                        color: "#dddddd"
                        font.family: "monospace"
                        font.pixelSize: 12
                        wrapMode: Text.WrapAnywhere
                        readOnly: true

                        onTextChanged: Qt.callLater(function () {
                            flick.contentY = Math.max(
                                        0, flick.contentHeight - flick.height)
                        })
                    }
                }
            }
            Rectangle {
                id: discoverTab

                ScrollView {
                    anchors.fill: parent

                    TextArea {
                        id: jsonEditor
                        font.family: "monospace"
                        font.pixelSize: 12
                        color: "#d4d4d4"
                        width: parent.width
                        height: parent.height
                        wrapMode: Text.WrapAnywhere

                        background: Rectangle {
                            color: "#1e1e1e"
                            border.color: jsonEditor.isValid ? "#3a3a3a" : "#ff0000"
                            border.width: 1
                        }

                        property bool isValid: true

                        Connections {
                            target: root.backend

                            function onConfigJsonChanged() {
                                jsonEditor.text = root.backend.configJson
                                try {
                                    const jsonData = JSON.parse(jsonEditor.text)
                                    jsonEditor.isValid = true
                                } catch (e) {
                                    jsonEditor.isValid = false
                                }
                            }
                        }

                        Component.onCompleted: {
                            text = root.backend.configJson

                            try {
                                const jsonData = JSON.parse(text)
                                isValid = true
                            } catch (e) {
                                isValid = false
                            }
                        }

                        onTextChanged: {

                            // try {
                            //     const jsonData = JSON.parse(text)
                            //     isValid = true
                            // } catch (e) {
                            //     isValid = false
                            // }
                        }

                        onEditingFinished: {
                            try {
                                const jsonData = JSON.parse(text)
                                root.backend.saveUserConfig(text)
                                isValid = true
                            } catch (e) {
                                isValid = false
                            }
                        }
                    }
                }
            }
        }
        Shortcut {
            sequence: "Ctrl+D"
            onActivated: root.showDebug = !root.showDebug
        }
    }
}

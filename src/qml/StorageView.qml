import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitWidth: 600
    implicitHeight: 400
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

    TextField {
        id: peerIdField
        placeholderText: "Enter the peer Id"
        placeholderTextColor: "#999999"
        color: "#000000"
        selectByMouse: true
        text: root.peerId
        onTextChanged: root.peerId = text
        anchors.top: uploadProgressColumn.bottom
        anchors.topMargin: 50
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Button {
        id: peerConnectButton
        objectName: "peerConnectButton"
        text: "Peer connect"
        onClicked: root.backend.tryPeerConnect(root.peerId)
        anchors.top: peerIdField.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        enabled: root.isRunning
        anchors.topMargin: 10
    }

    Button {
        id: debugButton
        objectName: "debugButton"
        text: "Debug"
        onClicked: root.backend.tryDebug()
        anchors.top: peerConnectButton.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        enabled: root.isRunning
        anchors.topMargin: 50
    }

    Button {
        id: peerIdButton
        objectName: "peerIdButton"
        text: "Peer Id"
        onClicked: root.backend.showPeerId()
        anchors.top: peerConnectButton.bottom
        anchors.right: debugButton.left
        enabled: root.isRunning
        anchors.topMargin: 50
    }

    Button {
        id: dataDirButton
        objectName: "dataDirButton"
        text: "Data dir"
        onClicked: root.backend.dataDir()
        anchors.top: peerConnectButton.bottom
        anchors.right: peerIdButton.left
        enabled: root.isRunning
        anchors.topMargin: 50
    }

    Button {
        id: sprButton
        objectName: "sprButton"
        text: "SPR"
        onClicked: root.backend.spr()
        anchors.top: peerConnectButton.bottom
        anchors.left: debugButton.right
        enabled: root.isRunning
        anchors.topMargin: 50
    }

    Button {
        id: versionButton
        objectName: "versionButton"
        text: "Version"
        onClicked: root.backend.version()
        anchors.top: peerConnectButton.bottom
        anchors.left: sprButton.right
        enabled: root.isRunning
        anchors.topMargin: 50
    }

    TextField {
        id: cidDownloadField
        placeholderTextColor: "#999999"
        placeholderText: "Enter the cid to download"
        color: "black"
        //  text: root.downloadCid
        onTextChanged: root.downloadCid = text
        anchors.top: debugButton.bottom
        anchors.topMargin: 50
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Button {
        id: openFile2
        text: "Open file"
        onClicked: fileDialog2.open()
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: cidDownloadField.bottom
        anchors.topMargin: 15
        enabled: root.isRunning
    }

    Button {
        id: cidDownloadButton
        objectName: "cidDownloadButton"
        text: "Download"
        onClicked: root.backend.tryDownloadFile(root.downloadCid,
                                                root.downloadDestination)
        anchors.top: openFile2.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        enabled: root.isRunning
        anchors.topMargin: 10
    }

    Button {
        id: existsButton
        objectName: "existsButton"
        text: "Exists"
        onClicked: root.backend.exists(root.downloadCid)
        anchors.top: openFile2.bottom
        anchors.left: cidDownloadButton.right
        enabled: root.isRunning
        anchors.topMargin: 10
    }

    Button {
        id: fetchButton
        objectName: "fetchButton"
        text: "Fetch"
        onClicked: root.backend.fetch(root.downloadCid)
        anchors.top: openFile2.bottom
        anchors.left: existsButton.right
        enabled: root.isRunning
        anchors.topMargin: 10
    }

    Button {
        id: removeButton
        objectName: "removeButton"
        text: "Remove"
        onClicked: root.backend.remove(root.downloadCid)
        anchors.top: openFile2.bottom
        anchors.right: cidDownloadButton.left
        enabled: root.isRunning
        anchors.topMargin: 10
    }

    Button {
        id: downloadManifestButton
        objectName: "downloadManifestButton"
        text: "Download manifest"
        onClicked: root.backend.downloadManifest(root.downloadCid)
        anchors.top: openFile2.bottom
        anchors.right: removeButton.left
        enabled: root.isRunning
        anchors.topMargin: 10
    }

    Button {
        id: downloadManifestsButton
        objectName: "downloadManifestsButton"
        text: "Manifests"
        onClicked: root.backend.downloadManifests()
        anchors.top: cidDownloadButton.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        enabled: root.isRunning
        anchors.topMargin: 10
    }

    Button {
        id: spaceButton
        objectName: "spaceButton"
        text: "Space"
        onClicked: root.backend.space()
        anchors.top: cidDownloadButton.bottom
        anchors.right: downloadManifestsButton.left
        enabled: root.isRunning
        anchors.topMargin: 10
    }

    TextField {
        id: logLevelField
        placeholderTextColor: "#999999"
        placeholderText: "Enter the log level to download"
        color: "black"
        //  text: root.downloadCid
        onTextChanged: root.logLevel = text
        anchors.top: downloadManifestsButton.bottom
        anchors.topMargin: 50
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Button {
        id: logLevelButton
        objectName: "logLevelButton"
        text: "Log level"
        onClicked: root.backend.updateLogLevel(root.logLevel)
        anchors.top: logLevelField.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        enabled: root.isRunning
        anchors.topMargin: 10
    }

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
                            try {
                                const jsonData = JSON.parse(text)
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

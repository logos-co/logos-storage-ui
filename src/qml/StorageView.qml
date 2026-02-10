import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

//import QtQuick.Layouts
Rectangle {
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

    id: root
    width: 400
    height: 700
    color: "#000000"

    QtObject {
        id: mockBackend

        signal test(int code, string msg)

        property var status: root.stopped
        property var statusText: "Destroyed"
        property var startStopText: "Start"
        property var canStartStop: true
        property bool showDebug: false
        property var debugLogs: ""

        function startStop() {
            console.log("Start")
            if (status === root.running) {
                status = root.stopped
                statusText = "Stopped"
                startStopText = "Start"
            } else {
                status = root.running
                statusText = "Started"
                startStopText = "Stop"
            }
        }

        function tryPeerConnect() {
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
        text: root.backend.statusText
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
        text: root.backend.startStopText
        enabled: root.backend.canStartStop
        onClicked: root.backend.startStop()
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: statusTextElement.bottom
        anchors.topMargin: 10
    }

    TextEdit {
        id: cidTextEdit
        objectName: "cid"
        text: root.backend.cidText
        color: "white"
        font.pointSize: 14
        readOnly: true
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: startStopButton.bottom
        anchors.topMargin: 10
    }

    Button {
        id: openFile
        text: "Open file"
        onClicked: fileDialog.open()
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: cidTextEdit.bottom
        anchors.topMargin: 15
        enabled: root.backend.isRunning
    }

    TextField {
        id: peerIdField
        placeholderText: "Enter the peer Id"
        placeholderTextColor: "#999999"
        color: "#000000"
        selectByMouse: true
        text: root.peerId
        onTextChanged: root.peerId = text
        anchors.top: openFile.bottom
        anchors.topMargin: 50
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Button {
        id: peerConnectButton
        objectName: "peerConnectButton"
        text: "Peer connect"
        onClicked: root.backend.tryPeerConnect()
        anchors.top: peerIdField.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        enabled: root.backend.isRunning
        anchors.topMargin: 10
    }

    Button {
        id: debugButton
        objectName: "debugButton"
        text: "Debug"
        onClicked: root.backend.tryDebug()
        anchors.top: peerConnectButton.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        enabled: root.backend.isRunning
        anchors.topMargin: 50
    }

    Button {
        id: peerIdButton
        objectName: "peerIdButton"
        text: "Peer Id"
        onClicked: root.backend.showPeerId()
        anchors.top: peerConnectButton.bottom
        anchors.right: debugButton.left
        enabled: root.backend.isRunning
        anchors.topMargin: 50
    }

    Button {
        id: dataDirButton
        objectName: "dataDirButton"
        text: "Data dir"
        onClicked: root.backend.dataDir()
        anchors.top: peerConnectButton.bottom
        anchors.right: peerIdButton.left
        enabled: root.backend.isRunning
        anchors.topMargin: 50
    }

    Button {
        id: sprButton
        objectName: "sprButton"
        text: "SPR"
        onClicked: root.backend.spr()
        anchors.top: peerConnectButton.bottom
        anchors.left: debugButton.right
        enabled: root.backend.isRunning
        anchors.topMargin: 50
    }

    Button {
        id: versionButton
        objectName: "versionButton"
        text: "Version"
        onClicked: root.backend.version()
        anchors.top: peerConnectButton.bottom
        anchors.left: sprButton.right
        enabled: root.backend.isRunning
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
        enabled: root.backend.isRunning
    }

    Button {
        id: cidDownloadButton
        objectName: "cidDownloadButton"
        text: "Download"
        onClicked: root.backend.tryDownloadFile(root.downloadCid,
                                                root.downloadDestination)
        anchors.top: openFile2.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        enabled: root.backend.isRunning
        anchors.topMargin: 10
    }

    Button {
        id: existsButton
        objectName: "existsButton"
        text: "Exists"
        onClicked: root.backend.exists(root.downloadCid)
        anchors.top: openFile2.bottom
        anchors.left: cidDownloadButton.right
        enabled: root.backend.isRunning
        anchors.topMargin: 10
    }

    Button {
        id: fetchButton
        objectName: "fetchButton"
        text: "Fetch"
        onClicked: root.backend.fetch(root.downloadCid)
        anchors.top: openFile2.bottom
        anchors.left: existsButton.right
        enabled: root.backend.isRunning
        anchors.topMargin: 10
    }

    Button {
        id: removeButton
        objectName: "removeButton"
        text: "Remove"
        onClicked: root.backend.remove(root.downloadCid)
        anchors.top: openFile2.bottom
        anchors.right: cidDownloadButton.left
        enabled: root.backend.isRunning
        anchors.topMargin: 10
    }

    Button {
        id: downloadManifestButton
        objectName: "downloadManifestButton"
        text: "Download manifest"
        onClicked: root.backend.downloadManifest(root.downloadCid)
        anchors.top: openFile2.bottom
        anchors.right: removeButton.left
        enabled: root.backend.isRunning
        anchors.topMargin: 10
    }

    Button {
        id: downloadManifestsButton
        objectName: "downloadManifestsButton"
        text: "Manifests"
        onClicked: root.backend.downloadManifests()
        anchors.top: cidDownloadButton.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        enabled: root.backend.isRunning
        anchors.topMargin: 10
    }

    Button {
        id: spaceButton
        objectName: "spaceButton"
        text: "Space"
        onClicked: root.backend.space()
        anchors.top: cidDownloadButton.bottom
        anchors.right: downloadManifestsButton.left
        enabled: root.backend.isRunning
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
        enabled: root.backend.isRunning
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
        visible: root.backend.showDebug // or: visible: showDebug

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

                // ✅ auto-scroll to bottom on update
                onTextChanged: Qt.callLater(function () {
                    flick.contentY = Math.max(
                                0, flick.contentHeight - flick.height)
                })
            }
        }

        Shortcut {
            sequence: "Ctrl+D"
            onActivated: root.backend.showDebug = !root.backend.showDebug
            // if using local var: onActivated: showDebug = !showDebug
        }
    }
}

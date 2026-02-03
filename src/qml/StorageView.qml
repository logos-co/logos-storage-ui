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

    id: root
    width: 500
    height: 800
    color: "#000000"

    QtObject {
        id: mockBackend

        property var status: root.stopped
        property var isRunning: false
        property var statusText: "Destroyed"
        property var startStopText: "Start"
        property var cidText: "CID"
        property var canStartStop: true

        function startStop() {
            if (status === root.running) {
                status = root.stopped
                statusText = "Stopped"
                startStopText = "Start"
                isRunning = false
            } else {
                status = root.running
                statusText = "Started"
                startStopText = "Stop"
                isRunning = true
            }
        }

        function tryPeerConnect() {
            console.log("Attempting peer connection...")
        }

        function tryUploadFinalize() {
            console.log("Attempting upload finalize")
        }

        function tryUploadFile(file) {
            console.log("Attempting upload file")
        }
    }

    Text {
        id: statusTextElement
        objectName: "status"
        text: root.backend.statusText
        color: "white"
        font.pointSize: 20
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 10
    }

    Button {
        id: startStopButton
        objectName: "startStopButton"
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
        anchors.topMargin: 100
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
        selectByMouse: true
        text: root.backend.peerId
        onTextChanged: root.backend.peerId = text
        anchors.top: openFile.bottom
        anchors.topMargin: 100
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Button {
        objectName: "peerConnectButton"
        text: "Peer connect"
        onClicked: root.backend.tryPeerConnect()
        anchors.top: peerIdField.bottom
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
}

import QtQuick
import QtQuick.Controls
import QtCore
import Logos.Theme
import Logos.Controls

// qmllint disable unqualified
Item {
    id: root
    implicitWidth: 600
    implicitHeight: 400

    property var backend: mockBackend

    // Timer {
    //     readonly property int running: 2

    //     id: timer
    //     interval: 2000
    //     repeat: false
    //     onTriggered: {
    //         console.log("timer triggered")
    //         // root.backend.status = running
    //         // root.backend.startCompleted()
    //         // console.info(root.backend.status)
    //     }
    // }
    QtObject {
        id: mockBackend

        property int status

        signal startCompleted
        signal startFailed
        signal stopCompleted

        function updateBasicConfig(dataDir, discPort) {
            console.log("updateBasicConfig", dataDir, discPort)
        }

        function start() {
            //   timer.start()
            console.log("mock start callde")
        }

        function stop() {
            root.backend.stopCompleted()
        }

        function defaultDataDir() {
            return ".cache/storage"
        }

        function buildConfig() {}

        function reloadIfChanged() {}

        function init() {}
    }

    Settings {
        id: settings
        category: "Storage"

        property int discoveryPort: 8090
        property int tcpPort: 0
        property string dataDir: ""
        property bool onboardingCompleted: false
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: onboarding
    }

    Component {
        id: onboarding

        OnBoarding {
            id: onboardingInstance
            backend: root.backend
            discoveryPort: settings.discoveryPort
            tcpPort: settings.tcpPort
            dataDir: settings.dataDir.length > 0 ? settings.dataDir : root.backend.defaultDataDir()

            onCompleted: {
                settings.discoveryPort = discoveryPort
                settings.dataDir = dataDir
                settings.tcpPort = tcpPort
                settings.onboardingCompleted = true

                let config = root.backend.buildConfig(dataDir,
                                                      discoveryPort, tcpPort)
                root.backend.saveUserConfig(config)
                root.backend.reloadIfChanged(config)
                root.backend.start()

                stackView.push(startNodeView)
            }
        }
    }

    Component {
        id: storageView
        StorageView {
            backend: root.backend
        }
    }

    Component {
        id: startNodeView

        StartNode {
            backend: root.backend

            onBack: {
                root.backend.stop()
            }
            onNext: {
                stackView.push(storageView)
            }
        }
    }

    Connections {
        target: root.backend

        function onStopCompleted() {
            stackView.pop()
        }

        function onInitCompleted() {
            if (settings.onboardingCompleted) {
                root.backend.start()
                stackView.replace(storageView, StackView.Immediate)
            }
        }
    }
}

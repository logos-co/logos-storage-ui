import QtQuick
import QtQuick.Controls
import QtCore

// qmllint disable unqualified
Item {
    id: root
    implicitWidth: 800
    implicitHeight: 800

    property var backend: mockBackend

    QtObject {
        id: mockBackend

        readonly property bool isMock: true
        property int status

        signal startCompleted
        signal startFailed
        signal stopCompleted
        signal initCompleted

        function start() {
            console.log("mock start called")
        }

        function defaultDataDir() {
            return ".cache/storage"
        }

        function buildConfig() {}

        function saveUserConfig() {}

        function reloadIfChanged() {}

        function buildUpnpConfig() {}

        function buildNatExtConfig() {}

        function stop() {}
    }

    Settings {
        id: settings
        category: "Storage"

        property int discoveryPort: 8090
        property int tcpPort: 0
        property string dataDir: ""
        property bool onboardingCompleted: false
        property string natStrategy: "any"
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: onboardingComponent
    }

    Component {
        id: onboardingComponent

        OnBoarding {
            backend: root.backend
            // discoveryPort: settings.discoveryPort
            // tcpPort: settings.tcpPort
            dataDir: settings.dataDir

            onCompleted: {
                // settings.discoveryPort = discoveryPort
                settings.dataDir = dataDir
                // settings.tcpPort = tcpPort
                settings.onboardingCompleted = true

                stackView.push(natComponent)
            }
        }
    }

    Component {
        id: natComponent

        Nat {
            onCompleted: function (enabled) {
                if (enabled) {
                    settings.natStrategy = "upnp"
                    let config = root.backend.buildUpnpConfig(settings.dataDir)
                    root.backend.reloadIfChanged(config)
                    root.backend.start()
                    stackView.push(startNodeComponent)
                } else {
                    stackView.push(portForwardingComponent)
                }
            }
        }
    }

    Component {
        id: storageComponent

        StorageView {
            backend: root.backend
        }
    }

    Component {
        id: startNodeComponent

        StartNode {
            backend: root.backend

            onBack: {
                root.backend.stop()
                stackView.pop()
            }

            onNext: {
                stackView.push(storageComponent)
            }
        }
    }

    Component {
        id: portForwardingComponent

        PortForwarding {
            onPortTcpSelected: function (port) {
                settings.tcpPort = port
                settings.natStrategy = "extip"
                let config = root.backend.buildNatExtConfig(settings.dataDir,
                                                            port)
                root.backend.reloadIfChanged(config)
                root.backend.start()
                stackView.push(startNodeComponent)
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
                stackView.replace(storageComponent, StackView.Immediate)
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtCore
import Logos.Theme

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
        signal ready
        signal error
        signal natExtConfigCompleted

        function start() {
            console.log("mock start called")
        }

        function saveUserConfig() {}

        function loadUserConfig() {}

        function reloadIfChanged() {}

        function enableUpnpConfig() {}

        function enableNatExtConfig() {}

        function saveCurrentConfig() {}

        function stop() {}

        function guessResolution() {}
    }

    Settings {
        id: settings
        category: "Storage"

        property int discoveryPort: 8090
        property int tcpPort: 0
        property string dataDir: ""
        property bool onboardingCompleted: false
        property string natStrategy: "any"

        Component.onCompleted: {
            console.info("Settings completed")
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: onboardingComponent
    }

    ErrorToast {
        id: errorToast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.spacing.medium
    }

    Component {
        id: onboardingComponent

        OnBoarding {
            onCompleted: function (upnpEnabled) {
                console.info("onboarding completed")
                if (upnpEnabled) {
                    root.backend.enableUpnpConfig()
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
                settings.onboardingCompleted = true
                root.backend.saveCurrentConfig()
                stackView.push(storageComponent)
            }
        }
    }

    Component {
        id: portForwardingComponent

        PortForwarding {
            onCompleted: function (port) {
                root.backend.enableNatExtConfig(port)
            }
        }
    }

    Connections {
        target: root.backend

        function onStopCompleted() {
            stackView.pop()
        }

        function onInitCompleted() {}

        function onReady() {
            if (settings.onboardingCompleted) {
                root.backend.loadUserConfig()
                root.backend.start()
                stackView.replace(storageComponent, StackView.Immediate)
            }
        }

        function onError(message) {
            errorToast.show("Error", message)
        }

        function onNatExtConfigCompleted(error) {
            root.backend.start()
            stackView.push(startNodeComponent)
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import Logos.Theme

// qmllint disable unqualified

// Application flow overview:
// On startup, the onboarding screen is shown by default.
// If the storage backend emits a ready event and onboarding is already
// complete, the onboarding screen is immediately replaced by the
// storageComponent.
// Onboarding offers two choices:
//   1. UPnP            : the user proceeds directly to the startNodeComponent.
//   2. Port forwarding : the user selects a TCP port before proceeding
//  to the startNodeComponent.
// The startNodeComponent waits for the node to start and verifies that
// it is reachable. If the node is unreachable, the user is prompted to
// edit the configuration. Once reachable, clicking "Next" marks
// onboarding as complete.
Item {
    id: root
    implicitWidth: 800
    implicitHeight: 800
    Layout.fillWidth: true
    Layout.fillHeight: true

    property var backend: MockBackend

    Connections {
        target: root.backend

        // When the onboarding is completed,
        // the user should have a config save in his
        // home folder.
        // After the config is loaded, the node will be
        // started and the storeComponent will replace
        // the stackView item immediatly.
        function onReady() {
            if (settings.onboardingCompleted) {
                root.backend.loadUserConfig()
                stackView.replace(storageComponent, StackView.Immediate)
            }
        }

        // If there is any error, display it in a toast view
        function onError(message) {
            errorToast.show("Error", message)
        }
    }

    Settings {
        id: settings
        category: "Storage"

        property bool onboardingCompleted: false
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: modeSelectorComponent
    }

    Component {
        id: modeSelectorComponent

        ModeSelector {
            onCompleted: function (isGuide) {
                if (isGuide) {
                    stackView.push(onboardingComponent)
                } else {
                    stackView.push(advancedSetupComponent)
                }
            }
        }
    }

    Component {
        id: onboardingComponent

        OnBoarding {
            backend: root.backend

            onBack: stackView.pop()

            onCompleted: function (upnpEnabled) {
                if (upnpEnabled) {
                    stackView.push(startNodeComponent)
                } else {
                    stackView.push(portForwardingComponent)
                }
            }
        }
    }

    Component {
        id: advancedSetupComponent

        AdvancedSetup {
            backend: root.backend

            onBack: stackView.pop()

            onCompleted: function () {
                settings.onboardingCompleted = true
                stackView.replace(storageComponent, StackView.Immediate)
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
                stackView.pop()
            }

            onNext: {
                settings.onboardingCompleted = true
                stackView.push(storageComponent)
            }
        }
    }

    Component {
        id: portForwardingComponent

        PortForwarding {
            backend: root.backend
            loading: false

            onBack: {
                stackView.pop()
            }

            onCompleted: function () {
                stackView.push(startNodeComponent)
            }
        }
    }

    ErrorToast {
        id: errorToast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.spacing.medium
    }

}

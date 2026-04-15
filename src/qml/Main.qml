import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import Logos.Theme
import Logos.StorageBackend 1.0

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
    implicitHeight: 600
    Layout.fillWidth: true
    Layout.fillHeight: true

    QtObject {
        id: d
        readonly property var backend: typeof logos !== "undefined" && logos ? logos.module(mod) : null
        readonly property string mod: "storage_ui"
    }

    Connections {
        target: d.backend
        ignoreUnknownSignals: true

        // When the onboarding is completed,
        // the user should have a config save in his
        // home folder.
        // After the config is loaded, the node will be
        // started and the storeComponent will replace
        // the stackView item immediatly.
        function onReady() {
            if (settings.onboardingCompleted) {
                d.backend.loadUserConfig()
                stackView.replace(storageComponent, StackView.Immediate)
            }
        }

        // If there is any error, display it in a toast view
        function onError(message) {
            errorToast.show("Error", message)
        }

        function onOnboardingRestarted() {
            d.backend.onStopCompleted.connect(function () {
                stackView.replace(modeSelectorComponent, StackView.Immediate)
            })
            d.backend.stop()
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
            backend: d.backend

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
            backend: d.backend

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
            backend: d.backend
        }
    }

    Component {
        id: startNodeComponent

        StartNode {
            backend: d.backend

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
            backend: d.backend
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

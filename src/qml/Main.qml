import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import Logos.Theme
import Logos.StorageBackend 1.0

// Application flow overview:
// On startup, the onboarding screen is shown by default.
// If the storage replica is valid (logos.viewModuleReadyChanged) and onboarding
// is already complete, the onboarding screen is immediately replaced by the
// storageComponent.
// Onboarding offers two choices, both ending on the download folder step,
// which marks onboarding as complete and hands over to the storageComponent:
//   1. Guided   : the node runs on the default configuration.
//   2. Advanced : the user reviews the node configuration first.
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
        target: typeof logos !== "undefined" && logos ? logos : null
        ignoreUnknownSignals: true

        // When the onboarding is completed,
        // the user should have a config save in his
        // home folder.
        // After the config is loaded, the node will be
        // started and the storeComponent will replace
        // the stackView item immediatly.
        function onViewModuleReadyChanged(moduleName, ready) {
            if (moduleName !== d.mod || !ready)
                return
            if (settings.onboardingCompleted && d.backend) {
                d.backend.loadUserConfig()
                stackView.replace(storageComponent, StackView.Immediate)
            }
        }
    }

    Connections {
        target: d.backend
        ignoreUnknownSignals: true

        // If there is any error, display it in a toast view
        function onError(message) {
            errorToast.show("Error", message)
        }

        function onOnboardingRestarted() {
            function handleStopped() {
                d.backend.onStopCompleted.disconnect(handleStopped)
                stackView.replace(modeSelectorComponent, StackView.Immediate)
            }
            d.backend.onStopCompleted.connect(handleStopped)
            d.backend.stop()
        }
    }

    Settings {
        id: settings
        category: "Storage"

        property bool onboardingCompleted: false
    }

    // Opaque themed backdrop so the bare (white) window is never visible behind
    // the StackView during startup transitions.
    Rectangle {
        anchors.fill: parent
        color: Theme.palette.background
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: loadingComponent

        Component.onCompleted: {
            // Settings is loaded by now, so onboardingCompleted is reliable here
            // (unlike during initialItem evaluation). A returning user stays on
            // the neutral loading screen until the module is ready
            // (see onViewModuleReadyChanged).
            if (!settings.onboardingCompleted) {
                replace(modeSelectorComponent, StackView.Immediate)
            }
        }
    }

    Component {
        id: loadingComponent

        Rectangle {
            color: Theme.palette.background
        }
    }

    Component {
        id: modeSelectorComponent

        ModeSelector {
            backend: d.backend

            onCompleted: function (isGuide) {
                if (isGuide) {
                    // Guided setup: the node runs on the default configuration.
                    d.backend.saveUserConfig(d.backend.defaultConfigJson)
                    stackView.push(downloadFolderComponent)
                } else {
                    stackView.push(advancedSetupComponent)
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
                stackView.push(downloadFolderComponent)
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
        id: downloadFolderComponent

        DownloadFolder {
            backend: d.backend

            onBack: {
                stackView.pop()
            }

            onNext: {
                settings.onboardingCompleted = true
                stackView.replace(storageComponent, StackView.Immediate)
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

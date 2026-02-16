import QtQuick
import QtQuick.Controls
import Logos.DesignSystem
import Logos.Controls
import QtCore

Item {
    id: root
    width: 600
    height: 400

    Settings {
        id: settings
        property int discoveryPort: 0
        property string dataDir: ""
        property bool onboardingCompleted: false
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: settings.onboardingCompleted ? storageView : onboarding
    }

    Component {
        id: onboarding

        OnBoarding {
            id: onboardingInstance

            onCompleted: {
                settings.discoveryPort = discoveryPort
                settings.dataDir = dataDir
                settings.onboardingCompleted = true
                stackView.replace(storageView)
            }
        }
    }

    Component {
        id: storageView
        StorageView {}
    }
}

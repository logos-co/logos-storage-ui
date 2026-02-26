import QtQuick
import QtQuick.Layouts
import Logos.Theme

RowLayout {
    spacing: Theme.spacing.tiny

    property int currentStep: 0
    property int totalSteps: 5

    Repeater {
        model: totalSteps

        Rectangle {
            Layout.fillWidth: true
            height: 4
            color: index <= currentStep ? Theme.palette.primary : Theme.palette.borderTertiaryMuted
        }
    }
}

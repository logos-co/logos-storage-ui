import QtQuick
import Logos.Theme
import Logos.Controls

// Advertise on/off. The caller owns the state: it flips `advertised` on clicked.
LogosIconButton {
    id: root

    property bool advertised: true

    objectName: "advertiseToggle"
    iconSource: Qt.resolvedUrl("assets/advertise.svg")
    iconColor: root.advertised ? Theme.palette.accentOrange : Theme.palette.textTertiary

    background: IconButtonBackground {
        highlighted: root.advertised
    }

    LogosToolTip {
        text: root.advertised ? "Advertised on the network — click to stop" : "Not advertised — click to advertise"
        visible: parent.hovered
    }
}

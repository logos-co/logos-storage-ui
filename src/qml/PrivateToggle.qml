import QtQuick
import Logos.Theme
import Logos.Controls

// Private download on/off. The caller owns the state: it flips `isPrivate` on clicked.
LogosIconButton {
    id: root

    property bool isPrivate: false

    objectName: "privateToggle"
    iconSource: Qt.resolvedUrl("assets/lock-line.svg")
    iconColor: root.isPrivate ? Theme.palette.accentOrange : Theme.palette.textTertiary

    background: IconButtonBackground {
        highlighted: root.isPrivate
    }

    LogosToolTip {
        text: root.isPrivate ? "Private download over Mix, not advertised"
                             : "Direct download — click to download privately over Mix"
        visible: parent.hovered
    }
}

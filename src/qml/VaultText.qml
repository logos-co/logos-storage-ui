import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

RowLayout {
    Layout.fillHeight: false
    spacing: Theme.spacing.small

    LogosText {
        text: "Vault."
        font.pixelSize: Theme.typography.titleText
        color: Theme.palette.primary
        font.weight: Font.Bold
    }

    Image {
        source: "assets/badge-alpha.png"
    }
}

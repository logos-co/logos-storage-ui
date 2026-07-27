import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

// qmllint disable unqualified
LogosFrame {
    id: root

    backgroundColor: Theme.palette.backgroundSecondary
    borderColor: "transparent"
    radius: Theme.spacing.radiusLarge

    readonly property var sections: [
        {
            "h": "Alpha software",
            "b": "Logos Storage is experimental alpha software under active development. It may contain bugs, break between versions, or lose data without notice. Do not rely on it for anything important."
        },
        {
            "h": "No warranty",
            "b": "The software is provided \"as is\", without warranty of any kind, express or implied. The authors and contributors are not liable for any damage, data loss, or other harm arising from its use."
        },
        {
            "h": "Public peer-to-peer network",
            "b": "Content you share is distributed to other peers and is not private by default. A CID can be fetched by anyone who has it. There is no guarantee that shared content stays available, nor that it can be fully deleted once distributed."
        },
        {
            "h": "Privacy features are experimental",
            "b": "Mix and private DHT queries reduce metadata exposure but do not provide anonymity guarantees. Do not depend on them to protect sensitive activity."
        },
        {
            "h": "Your responsibility",
            "b": "You are solely responsible for the content you upload, share, and download, and for complying with the laws that apply to you. Do not use the software to store or distribute unlawful content."
        }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.large
        spacing: Theme.spacing.small

        LogosText {
            text: "Disclaimer"
            font.pixelSize: Theme.typography.titleText
            font.weight: Theme.typography.weightBold
            color: Theme.palette.text
        }

        LogosText {
            text: "Please read before using Logos Storage."
            font.pixelSize: Theme.typography.primaryText
            color: Theme.palette.textSecondary
            Layout.bottomMargin: Theme.spacing.small
        }

        ScrollView {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: scroll.availableWidth
                spacing: Theme.spacing.large

                Repeater {
                    model: root.sections

                    delegate: ColumnLayout {
                        required property var modelData

                        Layout.fillWidth: true
                        spacing: Theme.spacing.tiny

                        LogosText {
                            text: modelData.h
                            font.pixelSize: Theme.typography.subtitleText
                            font.weight: Theme.typography.weightBold
                            color: Theme.palette.text
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        LogosText {
                            text: modelData.b
                            font.pixelSize: Theme.typography.secondaryText
                            color: Theme.palette.textSecondary
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }
}

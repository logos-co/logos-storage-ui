import QtQuick
import QtQuick.Effects
import Logos.Theme
import Logos.Controls

// Storage usage broken down by data type.
//
// Layout:
//   - title (top-left)
//   - legend + per-type data tiles (top-right, one column per type)
//   - two stacked bands:
//       top band    = single orange fill = overall used-space progress
//       bottom band = one textured segment per data type
Rectangle {
    id: root

    // Placeholder data — swap for live values once wired
    readonly property int capacityGb: 250
    readonly property int usedGb: 192
    // Colors and textures taken from the Figma layers (not theme tokens yet)
    readonly property var types: [
        {
            "name": "Documents",
            "gb": 98,
            "color": "#FE4D15",
            "dotColor": "#FE4D15",
            "texture": "vertical"
        },
        {
            "name": "Images",
            "gb": 34,
            "color": "#F04734",
            "dotColor": "#D86153",
            "texture": "hdash"
        },
        {
            "name": "Videos",
            "gb": 18,
            "color": "#F04734",
            "dotColor": "#F04734",
            "texture": "circles"
        },
        {
            "name": "Archives",
            "gb": 42,
            "color": "#F66E5F",
            "dotColor": "#ED7B58",
            "texture": "hdot"
        }
    ]
    property bool placeholder: false

    readonly property real usedFraction: usedGb / capacityGb

    function startFraction(i) {
        var acc = 0
        for (var k = 0; k < i; k++)
            acc += types[k].gb
        return acc / capacityGb
    }

    implicitHeight: 138

    gradient: Gradient {
        GradientStop {
            position: 0.0
            color: Theme.palette.backgroundTertiary
        }
        GradientStop {
            position: 0.35
            color: Theme.palette.backgroundTertiary
        }
        GradientStop {
            position: 1.0
            color: Theme.palette.backgroundBlack
        }
    }

    // Title
    Column {
        id: titleCol
        x: 16
        y: 12
        spacing: 2

        LogosText {
            text: "Storage"
            font.pixelSize: 16
            font.weight: Theme.typography.weightMedium
            color: Theme.palette.text
        }
        LogosText {
            text: "Usage by Type"
            font.pixelSize: 16
            font.weight: Theme.typography.weightMedium
            color: Theme.palette.text
        }
    }

    // Legend + per-type data tiles (top-right)
    Row {
        id: topBlock
        anchors.right: parent.right
        anchors.rightMargin: 8
        y: 10
        spacing: 8

        Repeater {
            model: root.types

            Column {
                spacing: 5

                // Legend: dot + name
                Row {
                    spacing: 4

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: modelData.dotColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    LogosText {
                        text: modelData.name
                        font.pixelSize: 9
                        font.family: "monospace"
                        color: Theme.palette.text
                    }
                }

                // Data tile
                Rectangle {
                    width: 80
                    height: 16
                    color: Theme.palette.backgroundButton

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0

                        LogosText {
                            text: modelData.gb + "GB"
                            font.pixelSize: 9
                            font.family: "monospace"
                            color: Qt.rgba(1, 1, 1, 0.94)
                        }
                        LogosText {
                            text: " / " + root.usedGb + "GB"
                            font.pixelSize: 9
                            font.family: "monospace"
                            color: Qt.rgba(1, 1, 1, 0.58)
                        }
                    }
                }
            }
        }
    }

    // Bar, dimmed while placeholder
    Item {
        id: barGroup
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        height: topBand.height + bottomBand.height
        opacity: root.placeholder ? 0.36 : 1.0

        // Gray out the bar while it holds placeholder data
        layer.enabled: root.placeholder
        layer.effect: MultiEffect {
            saturation: -1.0
        }

        // Top band: overall used-space progress (single orange)
        Rectangle {
            id: topBand
            anchors.left: parent.left
            anchors.right: parent.right
            height: 36
            color: Theme.palette.surface

            Rectangle {
                width: parent.width * root.usedFraction
                height: parent.height
                color: Theme.palette.accentOrange
            }

            // Percent markers at each type boundary
            Repeater {
                model: root.types

                Rectangle {
                    x: topBand.width * root.startFraction(index)
                    anchors.bottom: parent.bottom
                    width: pct.implicitWidth + 8
                    height: pct.implicitHeight + 2
                    color: Qt.rgba(0, 0, 0, 0.13)

                    LogosText {
                        id: pct
                        anchors.centerIn: parent
                        text: Math.round(modelData.gb / root.usedGb * 100) + "%"
                        font.pixelSize: 8
                        font.weight: Theme.typography.weightBold
                        font.family: "monospace"
                        color: Theme.palette.backgroundBlack
                    }
                }
            }
        }

        // Bottom band: one textured segment per data type
        Item {
            id: bottomBand
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: topBand.bottom
            height: 24

            Repeater {
                model: root.types

                Rectangle {
                    x: bottomBand.width * root.startFraction(index)
                    width: bottomBand.width * (modelData.gb / root.capacityGb)
                    height: bottomBand.height
                    color: modelData.color
                    clip: true

                    // Line/dash texture drawn on top of the fill
                    Canvas {
                        anchors.fill: parent
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            ctx.strokeStyle = "black"

                            var w = width
                            var h = height
                            var i

                            if (modelData.texture === "vertical") {
                                ctx.globalAlpha = 0.18
                                ctx.lineWidth = 0.5
                                for (i = 5; i < w; i += 5) {
                                    ctx.beginPath()
                                    ctx.moveTo(i + 0.25, 0)
                                    ctx.lineTo(i + 0.25, h)
                                    ctx.stroke()
                                }
                            } else if (modelData.texture === "hdash") {
                                ctx.globalAlpha = 0.15
                                ctx.lineWidth = 1
                                ctx.setLineDash([2, 4, 6, 8])
                                // Each row starts at a different dash phase (staggered)
                                var rows = [3.5, 9.5, 15.5, 21.5]
                                var offsets = [3, 1, 7, -17]
                                for (var r = 0; r < rows.length && rows[r] < h; r++) {
                                    ctx.lineDashOffset = offsets[r]
                                    ctx.beginPath()
                                    ctx.moveTo(0, rows[r])
                                    ctx.lineTo(w, rows[r])
                                    ctx.stroke()
                                }
                                ctx.lineDashOffset = 0
                            } else if (modelData.texture === "hdot") {
                                ctx.globalAlpha = 0.12
                                ctx.lineWidth = 1
                                ctx.setLineDash([1, 1])
                                for (i = 1.5; i < h; i += 2) {
                                    ctx.beginPath()
                                    ctx.moveTo(0, i)
                                    ctx.lineTo(w, i)
                                    ctx.stroke()
                                }
                            } else if (modelData.texture === "circles") {
                                ctx.globalAlpha = 0.15
                                ctx.fillStyle = "black"
                                var step = 5
                                for (var cy = 3; cy < h; cy += step) {
                                    var shift = (Math.round(cy / step) % 2) * (step / 2)
                                    for (var cx = 3 + shift; cx < w; cx += step) {
                                        ctx.beginPath()
                                        ctx.arc(cx, cy, 1, 0, 2 * Math.PI)
                                        ctx.fill()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Unused remainder
            Rectangle {
                x: bottomBand.width * root.usedFraction
                width: bottomBand.width * (1 - root.usedFraction)
                height: bottomBand.height
                color: Theme.palette.backgroundTertiary
            }
        }
    }

    // Placeholder callout
    Column {
        visible: root.placeholder
        x: 16
        anchors.top: barGroup.top
        anchors.topMargin: 4
        spacing: 2

        LogosText {
            text: "Disk not utilized"
            font.pixelSize: 11
            font.weight: Theme.typography.weightBold
            color: Qt.rgba(1, 1, 1, 0.85)
        }
        LogosText {
            text: "Download Files to see live component."
            font.pixelSize: 10
            color: Qt.rgba(1, 1, 1, 0.54)
        }
    }
}

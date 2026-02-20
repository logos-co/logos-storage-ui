import QtQuick
import Logos.Theme

// 7x7 animated dot grid for the StartNode screen.
// States:
//   starting=true           → white wave expanding from center
//   starting=false, success → all dots green (Theme.palette.success)
//   starting=false, !success → red X pattern (Theme.palette.error)
Item {
    id: root

    property bool starting: true
    property bool success: false
    property int animPhase: 0

    readonly property int columns: 7
    readonly property int dotSize: 8
    readonly property int dotSpacing: 5

    implicitWidth: columns * dotSize + (columns - 1) * dotSpacing
    implicitHeight: columns * dotSize + (columns - 1) * dotSpacing
    width: implicitWidth
    height: implicitHeight

    Timer {
        interval: 120
        repeat: true
        running: root.starting
        onTriggered: root.animPhase = (root.animPhase + 1) % 14
    }

    Grid {
        columns: root.columns
        spacing: root.dotSpacing

        Repeater {
            model: root.columns * root.columns

            Rectangle {
                width: root.dotSize
                height: root.dotSize
                radius: root.dotSize * 0.25

                color: {
                    if (root.success)   return Theme.palette.success
                    if (!root.starting) return Theme.palette.error
                    return Theme.palette.text
                }

                opacity: {
                    const col = index % root.columns
                    const row = Math.floor(index / root.columns)
                    const d = Math.abs(col - 3) + Math.abs(row - 3)

                    if (root.starting) {
                        const wave = root.animPhase % root.columns
                        const diff = Math.abs(d - wave)
                        if (diff === 0) return 0.9
                        if (diff === 1) return 0.35
                        return 0.1
                    }

                    if (root.success) return 0.85

                    // Error — X pattern
                    return (col === row || col + row === 6) ? 0.9 : 0.1
                }
            }
        }
    }
}

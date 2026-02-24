import QtQuick
import Logos.Theme

// qmllint disable unqualified
Item {
    id: root

    // Static pattern — flat array of 0/1, row-major
    property var pattern: []

    // Dimensions
    property int columns: 5
    property int dotSize: 6
    property int dotSpacing: 4

    // Appearance
    property color dotColor: Theme.palette.primary
    property real inactiveOpacity: 0.1
    property real activeOpacity: 0.9

    // Animation
    property bool animated: false
    property int animPhase: 0

    readonly property int rows: Math.max(1, Math.ceil(pattern.length / columns))
    readonly property int count: animated ? columns * columns : pattern.length

    implicitWidth: columns * dotSize + Math.max(0, columns - 1) * dotSpacing
    implicitHeight: rows * dotSize + Math.max(0, rows - 1) * dotSpacing
    width: implicitWidth
    height: implicitHeight

    Timer {
        interval: 140
        repeat: true
        running: root.animated
        onTriggered: root.animPhase = (root.animPhase + 1) % (root.columns * 2)
    }

    Grid {
        columns: root.columns
        spacing: root.dotSpacing

        Repeater {
            model: root.count

            Rectangle {
                width: root.dotSize
                height: root.dotSize
                radius: root.dotSize * 0.3
                color: root.dotColor

                opacity: {
                    if (!root.animated) {
                        return (index < root.pattern.length
                                && root.pattern[index]) ? root.activeOpacity : root.inactiveOpacity
                    }
                    // Wave from center
                    const cx = Math.floor(root.columns / 2)
                    const cy = Math.floor(root.columns / 2)
                    const col = index % root.columns
                    const row = Math.floor(index / root.columns)
                    const d = Math.abs(col - cx) + Math.abs(row - cy)
                    const wave = root.animPhase % root.columns
                    const diff = Math.abs(d - wave)
                    if (diff === 0)
                        return root.activeOpacity
                    if (diff === 1)
                        return 0.35
                    return root.inactiveOpacity
                }
            }
        }
    }
}

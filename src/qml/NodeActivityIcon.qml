import QtQuick
import Logos.Theme

// Node status glyph that morphs on activity: an up arrow while uploading, a
// down arrow while downloading, a loading wave while (re)starting or
// refreshing, otherwise the node hub glyph. Self-contained dot matrix (does not
// extend DotIcon) so it stays independent of the icons/ variants. Status
// semantics are owned by the caller, passed in as lifecycleBusy + idleColor.
// qmllint disable unqualified
Item {
    id: root

    property var backend: MockBackend
    property bool lifecycleBusy: false
    property bool running: false
    property color idleColor: Theme.palette.textMuted

    property bool uploading: false
    property bool downloading: false
    property bool refreshing: false

    // Loading wave: node lifecycle transitions, or a refresh with no transfer
    // in flight (a transfer keeps its arrow instead).
    readonly property bool busy: root.lifecycleBusy
                                 || (root.refreshing && !root.uploading && !root.downloading)

    // Live but idle: gently twinkle the glyph to show the node is up.
    readonly property bool idleRunning: root.running && !root.busy
                                        && !root.uploading && !root.downloading

    property real twinkle: 0
    NumberAnimation on twinkle {
        from: 0
        to: 2 * Math.PI
        duration: 2600
        loops: Animation.Infinite
        running: root.idleRunning
    }

    readonly property int columns: 5
    readonly property int dotSize: 12
    readonly property int dotSpacing: 4
    readonly property int dotRadius: 4

    readonly property color activeColor: (root.uploading || root.downloading)
                                         ? Theme.palette.primary : root.idleColor
    readonly property color inactiveColor: Theme.palette.border

    // 5x5 row-major glyphs.
    readonly property var nodeGlyph: [0, 1, 1, 1, 0,
                                      0, 1, 0, 1, 0,
                                      1, 0, 1, 0, 1,
                                      0, 1, 0, 1, 0,
                                      0, 1, 1, 1, 0]
    readonly property var arrowUp: [0, 0, 1, 0, 0,
                                    0, 1, 1, 1, 0,
                                    1, 1, 1, 1, 1,
                                    0, 0, 1, 0, 0,
                                    0, 0, 1, 0, 0]
    readonly property var arrowDown: [0, 0, 1, 0, 0,
                                      0, 0, 1, 0, 0,
                                      1, 1, 1, 1, 1,
                                      0, 1, 1, 1, 0,
                                      0, 0, 1, 0, 0]

    readonly property var pattern: root.uploading ? root.arrowUp
                                                   : root.downloading ? root.arrowDown : root.nodeGlyph

    property int animPhase: 0

    implicitWidth: columns * dotSize + (columns - 1) * dotSpacing
    implicitHeight: columns * dotSize + (columns - 1) * dotSpacing
    width: implicitWidth
    height: implicitHeight

    Timer {
        interval: 140
        repeat: true
        running: root.busy
        onTriggered: root.animPhase = (root.animPhase + 1) % (root.columns * 2)
    }

    Grid {
        columns: root.columns
        spacing: root.dotSpacing

        Repeater {
            model: root.columns * root.columns

            Rectangle {
                width: root.dotSize
                height: root.dotSize
                radius: root.dotRadius
                color: {
                    if (root.busy)
                        return root.activeColor
                    return root.pattern[index] ? root.activeColor : root.inactiveColor
                }
                opacity: {
                    if (root.busy) {
                        // Wave rippling out from the center.
                        const c = Math.floor(root.columns / 2)
                        const col = index % root.columns
                        const rw = Math.floor(index / root.columns)
                        const d = Math.abs(col - c) + Math.abs(rw - c)
                        const diff = Math.abs(d - (root.animPhase % root.columns))
                        if (diff === 0)
                            return 1.0
                        if (diff === 1)
                            return 0.35
                        return 0.12
                    }
                    // Live-but-idle: active dots breathe in and out, staggered.
                    if (root.idleRunning && root.pattern[index])
                        return 0.2 + 0.8 * (0.5 + 0.5 * Math.sin(root.twinkle + index * 0.7))
                    return 1.0
                }
            }
        }
    }

    // Auto-clear after a lull: every event restarts the timer, so the state
    // clears on completion, on error, and on a stall (no completion at all).
    // The lull also lets quick transfers stay visible briefly.
    Timer { id: upHold; interval: 1500; onTriggered: root.uploading = false }
    Timer { id: downHold; interval: 1500; onTriggered: root.downloading = false }
    Timer { id: refreshHold; interval: 800; onTriggered: root.refreshing = false }

    Connections {
        target: root.backend

        function onUploadStarted(total) { root.uploading = true; upHold.restart() }
        function onUploadChunk(len) { root.uploading = true; upHold.restart() }
        function onUploadCompleted(cid) { upHold.restart() }

        function onDownloadStarted(cid, filename, total) { root.downloading = true; downHold.restart() }
        function onDownloadChunk(len) { root.downloading = true; downHold.restart() }
        function onDownloadCompleted(cid) { downHold.restart() }

        function onManifestsUpdated(manifests) { root.refreshing = true; refreshHold.restart() }

        // Failures don't emit a completed signal; clear any in-flight transfer.
        function onError(message) { upHold.restart(); downHold.restart() }
    }
}

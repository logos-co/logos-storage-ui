import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

// qmllint disable unqualified
// The node log file, tailed line by line and parsed into columns.
LogosFrame {
    id: root

    backgroundColor: Theme.palette.backgroundSecondary
    borderColor: Theme.palette.borderSecondary
    radius: Theme.spacing.radiusLarge

    property var backend: MockBackend
    property int maxLines: 2000

    // Full backing store of every kept raw line; logModel holds the parsed,
    // filtered subset actually shown. Filtering matches the raw line.
    property var allLines: []
    property string filter: ""

    function matches(line) {
        return root.filter.length === 0
                || line.toLowerCase().indexOf(root.filter.toLowerCase()) !== -1
    }

    // Split a chronicles line "LVL YYYY-MM-DD HH:MM:SS.mmm+TZ msg   k=v ..."
    // into its parts. tid is dropped as noise.
    function parse(raw) {
        var m = raw.match(/^([A-Z]{3}) \d{4}-\d{2}-\d{2} (\d{2}:\d{2}:\d{2})\.\d+[+\-]\d{2}:\d{2} (.*)$/)
        if (!m)
            return { "level": "", "time": "", "msg": raw, "attrs": "" }
        var rest = m[3]
        var am = rest.match(/^(.*?)\s+([a-zA-Z]\w*=.*)$/)
        var attrs = am ? am[2].replace(/\s*tid=\S+/, "").trim() : ""
        return { "level": m[1], "time": m[2], "msg": am ? am[1] : rest, "attrs": attrs }
    }

    function levelColor(level) {
        switch (level) {
        case "ERR":
        case "FAT":
            return Theme.palette.error
        case "WRN":
            return Theme.palette.warning
        case "INF":
            return Theme.palette.info
        case "NOT":
            return Theme.palette.success
        default:  // DBG, TRC
            return Theme.palette.textMuted
        }
    }

    function rebuild() {
        logModel.clear()
        for (var i = 0; i < root.allLines.length; i++)
            if (root.matches(root.allLines[i]))
                logModel.append(root.parse(root.allLines[i]))
        Qt.callLater(logList.positionViewAtEnd)
    }

    Connections {
        target: root.backend
        ignoreUnknownSignals: true

        function onLogLines(lines) {
            for (var i = 0; i < lines.length; i++) {
                root.allLines.push(lines[i])
                if (root.matches(lines[i]))
                    logModel.append(root.parse(lines[i]))
            }

            var over = root.allLines.length - root.maxLines
            if (over > 0) {
                var dropped = root.allLines.splice(0, over)
                var remove = 0
                for (var j = 0; j < dropped.length; j++)
                    if (root.matches(dropped[j]))
                        remove++
                if (remove > 0)
                    logModel.remove(0, remove)
            }

            Qt.callLater(logList.positionViewAtEnd)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.medium
        spacing: Theme.spacing.medium

        ListView {
            id: logList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            spacing: Theme.spacing.tiny
            bottomMargin: Theme.spacing.large

            model: ListModel { id: logModel }

            LogosText {
                anchors.centerIn: parent
                visible: logModel.count === 0
                text: root.filter.length > 0 ? "No line matches the search"
                                             : "Start the node to read its logs"
                color: Theme.palette.textSecondary
            }

            ScrollBar.vertical: LogosScrollBar {
                policy: ScrollBar.AsNeeded
            }

            delegate: RowLayout {
                id: row
                required property string time
                required property string level
                required property string msg
                required property string attrs

                width: logList.width - Theme.spacing.medium
                spacing: Theme.spacing.small

                LogosText {
                    Layout.alignment: Qt.AlignTop
                    text: row.time
                    visible: row.time.length > 0
                    color: Theme.palette.textMuted
                    font.family: Theme.typography.mono
                    font.pixelSize: Theme.typography.secondaryText
                }

                LogosText {
                    Layout.alignment: Qt.AlignTop
                    text: row.level
                    visible: row.level.length > 0
                    color: root.levelColor(row.level)
                    font.family: Theme.typography.mono
                    font.weight: Theme.typography.weightBold
                    font.pixelSize: Theme.typography.secondaryText
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    LogosText {
                        Layout.fillWidth: true
                        text: row.msg
                        color: Theme.palette.textSecondary
                        font.pixelSize: Theme.typography.secondaryText
                        wrapMode: Text.WrapAnywhere
                    }

                    LogosText {
                        Layout.fillWidth: true
                        text: row.attrs
                        visible: row.attrs.length > 0
                        color: Theme.palette.textTertiary
                        font.family: Theme.typography.mono
                        font.pixelSize: Theme.typography.secondaryText
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }
        }
    }
}

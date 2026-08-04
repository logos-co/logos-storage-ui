import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

// qmllint disable unqualified
// The node configuration, field by field: reads a config, edits it and writes it
// back. Keys the form does not expose are preserved on save. Shared by the
// settings popup and the advanced onboarding step, which supply the chrome.
ScrollView {
    id: root

    objectName: "settingsForm"

    property var backend: MockBackend
    property string downloadFolderPath: ""
    property bool privateQueries: true

    // Onboarding writes the first config, so it starts from the defaults and
    // hides what its own flow already covers.
    property bool onboarding: false

    signal folderPathChanged(string path)
    signal privateQueriesToggled(bool enabled)
    signal restartOnboardingRequested
    signal saved(bool restartNeeded)

    readonly property string displayFolderPath: downloadFolderPath.replace(
                                                    /^file:\/{2,2}/, "")

    // Config as last loaded or saved, so unknown keys survive a save.
    property var loaded: ({})
    // Not "baseline": Item reserves that name for its anchor line.
    property string baselineJson: ""
    property bool loadedOnce: false

    readonly property bool dirty: root.loadedOnce
                                  && JSON.stringify(root.buildConfig()) !== root.baselineJson

    // A pending edit the node will only pick up on its next start.
    readonly property bool restartRequired: root.loadedOnce
                                            && root.needsRestart(root.loaded, root.buildConfig())

    // Editable values, kept as strings and parsed on save.
    property string vLogLevel: "INFO"
    property string vQuotaGiB: ""
    property string vListenPort: ""
    property string vDiscPort: ""
    property string vNatMode: "auto"
    property string vNatExtIp: ""
    property string vNetwork: ""

    // Read-only values.
    property string vDataDir: ""
    property bool vMixEnabled: false
    property var vMixProxies: []
    property string vMixPool: ""
    property string vConfigVersion: ""

    readonly property var logLevels: ["TRACE", "DEBUG", "INFO", "WARN", "ERROR"]
    readonly property var natModes: ["auto", "extip"]
    readonly property var networks: ["logos.test", "logos.dev"]

    // Keys the node only reads when it starts.
    readonly property var restartKeys: ["storage-quota", "listen-port", "disc-port", "nat", "network"]

    clip: true
    contentWidth: availableWidth
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    FolderDialog {
        id: folderDialog
        currentFolder: root.downloadFolderPath
        onAccepted: {
            root.downloadFolderPath = selectedFolder.toString()
            root.folderPathChanged(root.downloadFolderPath)
        }
    }

    function load() {
        if (!root.backend)
            return
        // Onboarding writes the very first config: there is no user file yet.
        if (root.onboarding) {
            root.applyConfig(root.backend.defaultConfigJson || "{}")
            return
        }
        if (root.backend.isMock) {
            root.applyConfig(root.backend.getUserConfig() || "{}")
        } else if (typeof logos !== "undefined" && logos) {
            logos.watch(root.backend.getUserConfig(), function (text) {
                root.applyConfig(text || "{}")
            }, function (err) {
                console.warn("getUserConfig:", err)
            })
        } else {
            root.applyConfig("{}")
        }
    }

    function applyConfig(text) {
        let cfg
        try {
            cfg = JSON.parse(text || "{}")
        } catch (e) {
            cfg = {}
        }
        root.loaded = cfg

        root.vLogLevel = (cfg["log-level"] || "info").toUpperCase()
        root.vQuotaGiB = root.bytesToGiB(cfg["storage-quota"])
        root.vListenPort = cfg["listen-port"] !== undefined ? String(cfg["listen-port"]) : ""
        root.vDiscPort = cfg["disc-port"] !== undefined ? String(cfg["disc-port"]) : ""
        root.vNetwork = cfg["network"] || ""

        const nat = cfg["nat"] || "auto"
        if (nat.indexOf("extip:") === 0) {
            root.vNatMode = "extip"
            root.vNatExtIp = nat.substring(6)
        } else {
            root.vNatMode = "auto"
            root.vNatExtIp = ""
        }

        root.vDataDir = cfg["data-dir"] || ""
        root.vMixEnabled = !!cfg["mix-enabled"]
        root.vMixProxies = cfg["dht-mix-proxy"] || []
        root.vMixPool = cfg["mix-pool-json"] || ""
        root.vConfigVersion = cfg["config-version"] !== undefined ? String(cfg["config-version"]) : "0"

        // Normalise so an untouched form compares equal to what a save writes.
        root.baselineJson = JSON.stringify(root.buildConfig())
        root.loaded = JSON.parse(root.baselineJson)
        root.loadedOnce = true
    }

    // The node reads "storage-quota" as a plain byte count.
    function bytesToGiB(bytes) {
        const value = Number(bytes)
        if (bytes === undefined || bytes === null || !isFinite(value) || value <= 0)
            return ""
        return String(Math.round(value / (1024 * 1024 * 1024) * 100) / 100)
    }

    function giBToBytes(text) {
        const value = parseFloat(text)
        if (isNaN(value) || value <= 0)
            return ""
        return Math.round(value * 1024 * 1024 * 1024)
    }

    // Merge the edited values onto the loaded config. A field left empty carries
    // no key at all, so the node keeps its own default.
    function buildConfig() {
        const cfg = JSON.parse(JSON.stringify(root.loaded))

        function put(key, value) {
            if (value === "")
                delete cfg[key]
            else
                cfg[key] = value
        }

        function putInt(key, text) {
            const n = parseInt(text)
            put(key, text === "" || isNaN(n) ? "" : n)
        }

        cfg["log-level"] = root.vLogLevel.toLowerCase()

        // "auto" carries no key: the node picks its own strategy, and not every
        // module version accepts an explicit "auto".
        put("nat", root.vNatMode === "extip" && root.vNatExtIp.length > 0
            ? "extip:" + root.vNatExtIp : "")

        put("storage-quota", root.giBToBytes(root.vQuotaGiB))
        put("network", root.vNetwork)
        putInt("listen-port", root.vListenPort)
        putInt("disc-port", root.vDiscPort)

        return cfg
    }

    function needsRestart(before, after) {
        for (let i = 0; i < root.restartKeys.length; i++) {
            const key = root.restartKeys[i]
            if (JSON.stringify(before[key]) !== JSON.stringify(after[key]))
                return true
        }
        return false
    }

    function save() {
        if (!root.backend)
            return
        // Read before the write: saving is what makes the edit the new baseline.
        const restartNeeded = root.restartRequired
        const cfg = root.buildConfig()
        root.backend.saveUserConfig(JSON.stringify(cfg, null, 2))
        root.loaded = cfg
        root.baselineJson = JSON.stringify(cfg)
        root.saved(restartNeeded)
    }


    // preferredWidth 0 keeps the wide implicit width of a text field from
    // pushing the control column past the width SettingRow gives it.
    // An empty field is valid: the node then falls back to its own default.
    component SField: LogosTextField {
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        Layout.minimumWidth: 0
    }

    // `value` flows in, `picked` flows out on a real click only. ComboBox writes
    // currentIndex itself when its model is set, which would kill a plain
    // binding, so the index is re-applied whenever the value changes.
    component SSelect: SettingsComboBox {
        id: select

        property string value: ""
        signal picked(string value)

        Layout.fillWidth: true
        Layout.preferredWidth: 0
        Layout.minimumWidth: 0

        onValueChanged: select.currentIndex = select.model.indexOf(select.value)
        Component.onCompleted: select.currentIndex = select.model.indexOf(select.value)
        onUserPicked: function (index) {
            select.picked(select.model[index])
        }
    }

    component SValue: LogosText {
        Layout.fillWidth: true
        font.pixelSize: Theme.typography.primaryText
        color: Theme.palette.textSecondary
        elide: Text.ElideMiddle
        horizontalAlignment: Text.AlignRight
    }

    component Section: ColumnLayout {
        id: section

        property string title: ""
        default property alias rows: sectionRows.data

        Layout.fillWidth: true
        spacing: Theme.spacing.small

        LogosText {
            text: section.title
            font.pixelSize: Theme.typography.primaryText
            font.weight: Theme.typography.weightBold
            color: Theme.palette.textSecondary
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: sectionRows.implicitHeight + 2 * Theme.spacing.large
            color: Theme.palette.backgroundSecondary
            border.color: Theme.palette.borderSecondary
            border.width: 1
            radius: Theme.spacing.radiusLarge

            ColumnLayout {
                id: sectionRows
                anchors.fill: parent
                anchors.margins: Theme.spacing.large
                spacing: Theme.spacing.large
            }
        }
    }

    // A long read-only value: peer records, relay pool.
    component Blob: ColumnLayout {
        id: blob

        property string title: ""
        property string summary: ""
        property string body: ""
        property bool expanded: false

        Layout.fillWidth: true
        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.large

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 200
                spacing: 2

                LogosText {
                    Layout.fillWidth: true
                    text: blob.title
                    font.pixelSize: Theme.typography.primaryText
                    font.weight: Theme.typography.weightMedium
                    color: Theme.palette.text
                    wrapMode: Text.WordWrap
                }

                LogosText {
                    Layout.fillWidth: true
                    text: blob.summary
                    font.pixelSize: Theme.typography.secondaryText
                    color: Theme.palette.textSecondary
                    wrapMode: Text.WordWrap
                }
            }

            // Explicit width: LogosButton is 200 wide by default and would
            // otherwise squeeze the label column.
            LogosButton {
                Layout.fillWidth: false
                Layout.preferredWidth: 100
                implicitWidth: 100
                implicitHeight: 34
                radius: Theme.spacing.radiusLarge
                text: blob.expanded ? "Hide" : "Show"
                onClicked: blob.expanded = !blob.expanded
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacing.small
            Layout.preferredHeight: 140
            visible: blob.expanded
            clip: true

            TextArea {
                readOnly: true
                text: blob.body
                wrapMode: Text.WrapAnywhere
                font.family: "monospace"
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.textSecondary
                selectByMouse: true
                background: Rectangle {
                    color: Theme.palette.backgroundElevated
                    radius: Theme.spacing.radiusSmall
                }
            }
        }
    }

    Item {
        width: root.availableWidth
        implicitHeight: sections.implicitHeight + 2 * Theme.spacing.large

        ColumnLayout {
            id: sections
            x: Theme.spacing.large
            y: Theme.spacing.large
            width: parent.width - 2 * Theme.spacing.large
            spacing: Theme.spacing.large

            Section {
                title: "General"

                SettingRow {
                    title: "Log level"
                    description: "Verbosity of the node logs."

                    SSelect {
                        objectName: "logLevelSelect"
                        model: root.logLevels
                        value: root.vLogLevel
                        onPicked: function (level) {
                            root.vLogLevel = level
                        }
                    }
                }

                SettingRow {
                    title: "Storage quota"
                    description: "Disk space dedicated to the node, in GiB."

                    SField {
                        objectName: "storageQuotaField"
                        text: root.vQuotaGiB
                        placeholderText: "20"
                        validator: DoubleValidator {
                            bottom: 0
                            decimals: 2
                            // parseFloat only understands a dot separator.
                            locale: "C"
                            notation: DoubleValidator.StandardNotation
                        }
                        onTextChanged: root.vQuotaGiB = text
                    }
                }

                SettingRow {
                    visible: !root.onboarding
                    title: "Download folder"
                    description: "Where downloaded files are saved."

                    SField {
                        readOnly: true
                        text: root.displayFolderPath
                        placeholderText: "Choose a folder"

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: folderDialog.open()
                        }
                    }
                }

                SettingRow {
                    title: "Data directory"
                    description: "Where the node stores its data."

                    SField {
                        objectName: "dataDirField"
                        readOnly: true
                        text: root.vDataDir
                    }
                }
            }

            Section {
                title: "Network"

                SettingRow {
                    title: "Listen port"
                    description: "TCP port for peer connections. 0 picks a random free port."

                    SField {
                        objectName: "listenPortField"
                        text: root.vListenPort
                        placeholderText: "8500"
                        validator: IntValidator {
                            bottom: 0
                            top: 65535
                        }
                        onTextChanged: root.vListenPort = text
                    }
                }

                SettingRow {
                    title: "Discovery port"
                    description: "UDP port used by the discovery layer."

                    SField {
                        objectName: "discPortField"
                        text: root.vDiscPort
                        placeholderText: "9090"
                        validator: IntValidator {
                            bottom: 0
                            top: 65535
                        }
                        onTextChanged: root.vDiscPort = text
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing.small

                    SettingRow {
                        title: "NAT"
                        description: "How the public address is determined."

                        SSelect {
                            objectName: "natSelect"
                            model: root.natModes
                            value: root.vNatMode
                            onPicked: function (mode) {
                                root.vNatMode = mode
                            }
                        }
                    }

                    SField {
                        objectName: "natExtIpField"
                        visible: root.vNatMode === "extip"
                        text: root.vNatExtIp
                        placeholderText: "External IP address"
                        onTextChanged: root.vNatExtIp = text
                    }
                }

                SettingRow {
                    title: "Network"
                    description: "The network preset the node bootstraps from."

                    SSelect {
                        objectName: "networkSelect"
                        model: root.networks
                        value: root.vNetwork === "" ? "logos.test" : root.vNetwork
                        onPicked: function (network) {
                            root.vNetwork = network
                        }
                    }
                }
            }

            Section {
                title: "Privacy"

                SettingRow {
                    title: "Mix enabled"
                    description: "DHT provider lookups are routed through the Mix protocol."

                    Item {
                        Layout.fillWidth: true
                    }

                    LogosSwitch {
                        checked: root.vMixEnabled
                        enabled: false
                    }
                }

                SettingRow {
                    title: "Private DHT queries"
                    description: root.backend && root.backend.mixRunning
                                 ? "Applied immediately, no restart needed."
                                 : "Needs a node running with Mix enabled."

                    Item {
                        Layout.fillWidth: true
                    }

                    LogosSwitch {
                        checked: root.privateQueries
                        enabled: root.backend && root.backend.mixRunning
                        onToggled: root.privateQueriesToggled(checked)
                    }
                }

                Blob {
                    title: "DHT mix proxies"
                    summary: root.vMixProxies.length + " peer records used as proxy destinations."
                    body: root.vMixProxies.join("\n\n")
                }

                Blob {
                    title: "Mix relay pool"
                    summary: "The bundled relay pool the node mixes through."
                    body: root.vMixPool
                }
            }

            Section {
                title: "About"

                SettingRow {
                    title: "Version"
                    description: "Logos Storage UI release."

                    SValue {
                        text: root.backend && root.backend.uiVersion ? root.backend.uiVersion : "unknown"
                    }
                }

                SettingRow {
                    title: "Config version"
                    description: "Schema version of config.json."

                    SValue {
                        text: root.vConfigVersion
                    }
                }
            }

            Section {
                visible: !root.onboarding
                title: "Advanced"

                SettingRow {
                    title: "Restart onboarding"
                    description: "Go back to the initial setup. The node keeps its data."
                    controlWidth: 180

                    LogosButton {
                        Layout.fillWidth: true
                        radius: Theme.spacing.radiusLarge
                        text: "Restart onboarding"
                        implicitHeight: 36
                        onClicked: root.restartOnboardingRequested()
                    }
                }
            }
        }
    }
}

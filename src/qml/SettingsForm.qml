import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls
import Logos.StorageBackend 1.0

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

    // An extip mode with no usable address would silently drop the nat key.
    readonly property bool natExtIpValid: /^((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)$/.test(root.vNatExtIp)
    readonly property bool natIntervalValid: root.vNatInterval.length === 0
                                            || /^\d+(ms|s|m|h)$/.test(root.vNatInterval)
    readonly property bool valid: (root.vNatMode !== "extip" || root.natExtIpValid)
                                 && root.natIntervalValid
                                 && root.isJson(root.vBootstrap)
                                 && root.isJson(root.vMixProxies)
                                 && root.isJson(root.vMixPool)

    // A pending edit the node will only pick up on its next start.
    readonly property bool restartRequired: root.loadedOnce
                                            && root.needsRestart(root.loaded, root.buildConfig())

    // Editable values, kept as strings and parsed on save.
    property string vLogLevel: "INFO"
    property string vQuotaGiB: ""
    // The byte count as read, so an untouched quota is written back unrounded.
    property var loadedQuota: undefined
    property string vListenPort: ""
    property string vDiscPort: ""
    property string vNatMode: "auto"
    property string vNatExtIp: ""
    property string vNatInterval: ""
    property string vNetwork: ""
    // JSON edited as it sits in the config, not split into records.
    property string vBootstrap: ""
    property string vMixProxies: ""
    property string vMixPool: ""

    // Read-only values.
    property string vDataDir: ""
    property bool vMixEnabled: false
    property string vConfigVersion: ""

    readonly property var logLevels: ["TRACE", "DEBUG", "INFO", "NOTICE", "WARN", "ERROR", "FATAL"]
    readonly property var natModes: ["auto", "extip"]
    readonly property var mixConfig: root.backend ? root.asJson(root.backend.mixConfigJson, {}) : ({})
    readonly property var networks: Object.keys(root.mixConfig)

    // A config can hold a value no preset lists. Offering it keeps it visible
    // and keeps a save that touches another field from dropping it.
    function optionsWith(options, value) {
        if (value === "" || options.indexOf(value) >= 0)
            return options
        return options.concat([value])
    }

    // An empty field means "no such key", which is valid.
    function isJson(text) {
        if (text.trim().length === 0)
            return true
        try {
            JSON.parse(text)
            return true
        } catch (e) {
            return false
        }
    }

    function asJson(text, fallback) {
        try {
            return JSON.parse(text)
        } catch (e) {
            return fallback
        }
    }

    // The raw value as the config carries it, one entry per line once indented.
    function toJsonText(value) {
        if (value === undefined || value === null)
            return ""
        return JSON.stringify(value, null, 2)
    }

    // mixRunning only says the config asked for Mix: the toggle reaches a live
    // module, so the node has to be up as well.
    readonly property bool mixReady: root.backend && root.backend.mixRunning
                                     && root.backend.status === StorageBackend.Running

    // A bootstrap list of their own is what the user joined instead of a preset.
    // Judged on the text, not on the parsed value: mid-typing the JSON does not
    // parse yet, and the preset must not flicker back on between keystrokes.
    readonly property bool hasCustomBootstrap: root.vBootstrap.trim().length > 0
                                               && root.vBootstrap.trim() !== "[]"

    // Keys the node only reads when it starts.
    readonly property var restartKeys: ["storage-quota", "listen-port", "disc-port", "nat",
                                        "network", "bootstrap-node", "dht-mix-proxy",
                                        "mix-pool-json", "nat-schedule-interval"]

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
            // Reopening: hold the previous values back until the file answers.
            root.loadedOnce = false
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
        root.loadedQuota = cfg["storage-quota"]
        root.vQuotaGiB = root.bytesToGiB(cfg["storage-quota"])
        root.vListenPort = cfg["listen-port"] !== undefined ? String(cfg["listen-port"]) : ""
        root.vDiscPort = cfg["disc-port"] !== undefined ? String(cfg["disc-port"]) : ""
        root.vNetwork = cfg["network"] || ""
        root.vNatInterval = cfg["nat-schedule-interval"] || ""
        root.vBootstrap = root.toJsonText(cfg["bootstrap-node"])

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
        root.vMixProxies = root.toJsonText(cfg["dht-mix-proxy"])
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

        // The field holds JSON: an empty one drops the key, anything else is
        // written parsed. Save is blocked while it does not parse.
        function putJson(key, text) {
            if (text.trim().length === 0)
                delete cfg[key]
            else
                cfg[key] = root.asJson(text, cfg[key])
        }

        cfg["log-level"] = root.vLogLevel.toLowerCase()

        // "auto" carries no key: the node picks its own strategy, and not every
        // module version accepts an explicit "auto".
        put("nat", root.vNatMode === "extip" && root.vNatExtIp.length > 0
            ? "extip:" + root.vNatExtIp : "")

        if (root.vQuotaGiB === root.bytesToGiB(root.loadedQuota))
            put("storage-quota", root.loadedQuota === undefined ? "" : root.loadedQuota)
        else
            put("storage-quota", root.giBToBytes(root.vQuotaGiB))

        put("nat-schedule-interval", root.vNatInterval)
        put("network", root.vNetwork)

        putJson("bootstrap-node", root.vBootstrap)
        putJson("dht-mix-proxy", root.vMixProxies)
        put("mix-pool-json", root.vMixPool)
        putInt("listen-port", root.vListenPort)
        putInt("disc-port", root.vDiscPort)

        return cfg
    }

    // The Mix relays are not part of the module's network preset, so switching
    // network has to move them too: dev relays on the test network reach nothing.
    function pickNetwork(network) {
        root.vNetwork = network
        const mix = root.mixConfig[network]
        if (!mix)
            return
        root.vMixProxies = root.toJsonText(mix["dht-mix-proxy"])
        root.vMixPool = mix["mix-pool-json"]
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
        background: SettingsFieldBackground {}
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

    // A long value shown on demand: peer records, relay pool. An editable one
    // reports every keystroke through edited(); the field holds no state.
    component Blob: ColumnLayout {
        id: blob

        property string title: ""
        property string summary: ""
        property string body: ""
        property bool expanded: false
        property bool editable: false
        property string fieldObjectName: ""

        readonly property bool bodyValid: !blob.editable || root.isJson(blob.body)

        signal edited(string text)

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
                objectName: blob.fieldObjectName
                readOnly: !blob.editable
                text: blob.body
                onTextChanged: {
                    if (blob.editable)
                        blob.edited(text)
                }
                wrapMode: Text.WrapAnywhere
                font.family: Theme.typography.mono
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.textSecondary
                selectByMouse: true
                background: Rectangle {
                    color: Theme.palette.backgroundElevated
                    radius: Theme.spacing.radiusSmall
                }
            }
        }

        // Save is blocked while this shows: say why.
        LogosText {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacing.small
            visible: !blob.bodyValid
            text: "Not valid JSON"
            font.pixelSize: Theme.typography.secondaryText
            color: Theme.palette.error
        }
    }

    Item {
        width: root.availableWidth
        implicitHeight: sections.implicitHeight + 2 * Theme.spacing.large

        // load() resolves over an async logos.watch(): showing the fields before
        // the values land invites edits that applyConfig then wipes.
        LogosText {
            anchors.centerIn: parent
            visible: !root.loadedOnce
            text: "Loading the configuration…"
            color: Theme.palette.textSecondary
        }

        ColumnLayout {
            id: sections
            visible: root.loadedOnce
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
                        model: root.optionsWith(root.logLevels, root.vLogLevel)
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
                        validator: RegularExpressionValidator {
                            regularExpression: /^((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){0,3}(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)?$/
                        }
                        onTextChanged: root.vNatExtIp = text
                    }
                }

                SettingRow {
                    title: "AutoNAT interval"
                    description: "How often the node asks its peers whether it is reachable."

                    SField {
                        objectName: "natIntervalField"
                        text: root.vNatInterval
                        placeholderText: "60s"
                        validator: RegularExpressionValidator {
                            regularExpression: /^\d+(ms|s|m|h)?$/
                        }
                        onTextChanged: root.vNatInterval = text
                    }
                }

                SettingRow {
                    title: "Network"
                    description: root.hasCustomBootstrap
                                 ? "Overridden by the bootstrap records below."
                                 : "The network preset the node bootstraps from."

                    SSelect {
                        objectName: "networkSelect"
                        enabled: !root.hasCustomBootstrap
                        model: root.optionsWith(root.networks, root.vNetwork)
                        value: root.vNetwork === "" ? root.networks[0] : root.vNetwork
                        onPicked: function (network) {
                            root.pickNetwork(network)
                        }
                    }
                }

                Blob {
                    title: "Bootstrap nodes"
                    summary: "Peer records the node dials first. Empty lets the network preset decide."
                    body: root.vBootstrap
                    editable: true
                    fieldObjectName: "bootstrapField"
                    onEdited: function (text) {
                        root.vBootstrap = text
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
                    description: root.mixReady
                                 ? "Applied immediately, no restart needed."
                                 : "Needs a node running with Mix enabled."

                    Item {
                        Layout.fillWidth: true
                    }

                    LogosSwitch {
                        checked: root.privateQueries
                        enabled: root.mixReady
                        onToggled: root.privateQueriesToggled(checked)
                    }
                }

                Blob {
                    title: "DHT mix proxies"
                    summary: root.hasCustomBootstrap
                             ? "Peer records used as proxy destinations."
                             : "Peer records used as proxy destinations, set by the network preset."
                    body: root.vMixProxies
                    editable: root.hasCustomBootstrap
                    fieldObjectName: "mixProxiesField"
                    onEdited: function (text) {
                        root.vMixProxies = text
                    }
                }

                Blob {
                    title: "Mix relay pool"
                    summary: root.hasCustomBootstrap
                             ? "The relay pool the node mixes through."
                             : "The relay pool the node mixes through, set by the network preset."
                    body: root.vMixPool
                    editable: root.hasCustomBootstrap
                    fieldObjectName: "mixPoolField"
                    onEdited: function (text) {
                        root.vMixPool = text
                    }
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
        }
    }
}

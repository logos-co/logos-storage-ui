import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

// qmllint disable unqualified
LogosFrame {
    id: root

    property var backend: MockBackend

    backgroundColor: Theme.palette.backgroundSecondary
    borderColor: "transparent"
    radius: Theme.spacing.radiusLarge

    // Full config as last loaded/saved, kept so unknown keys survive a save.
    property var loaded: ({})
    property string configBaseline: ""
    property bool loadedOnce: false
    property bool savedNote: false

    // Editable values (kept as strings for text inputs, parsed on save).
    property string vLogLevel: "info"
    property string vDataDir: ""
    property string vListenIp: ""
    property string vListenPort: ""
    property string vNatMode: "auto"
    property string vNatExtIp: ""
    property string vDiscPort: ""
    property string vBootstrapText: ""
    property string vNetwork: "logos.test"
    property string vDhtMixProxies: ""
    property bool vMixEnabled: false
    property string vMixPoolJson: ""
    property string vMaxPeers: ""
    property string vStorageQuota: ""
    property string vNatSchedule: ""
    property string vNatDiscoverTimeout: ""
    property string vNatMappingTimeout: ""
    property string vNatRecheck: ""

    property bool privateQueries: false

    readonly property var logLevels: ["TRACE", "DEBUG", "INFO", "WARN", "ERROR"]
    readonly property var networks: ["logos.test", "logos.dev"]
    readonly property var natModes: ["auto", "extip"]

    readonly property bool dirty: root.loadedOnce
                                  && JSON.stringify(root.buildConfig()) !== root.configBaseline

    onVisibleChanged: if (visible) root.load()
    Component.onCompleted: if (visible) root.load()

    function load() {
        if (!root.backend)
            return
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
        var cfg
        try {
            cfg = JSON.parse(text || "{}")
        } catch (e) {
            cfg = {}
        }
        root.loaded = cfg

        root.vLogLevel = (cfg["log-level"] || "info").toUpperCase()
        root.vDataDir = cfg["data-dir"] || ""
        root.vListenIp = cfg["listen-ip"] || ""
        root.vListenPort = cfg["listen-port"] !== undefined ? String(cfg["listen-port"]) : ""

        var nat = cfg["nat"] || "auto"
        if (nat.indexOf("extip:") === 0) {
            root.vNatMode = "extip"
            root.vNatExtIp = nat.substring(6)
        } else {
            root.vNatMode = "auto"
            root.vNatExtIp = ""
        }

        root.vDiscPort = cfg["disc-port"] !== undefined ? String(cfg["disc-port"]) : ""
        root.vBootstrapText = (cfg["bootstrap-node"] || []).join("\n")
        root.vNetwork = cfg["network"] || "logos.test"
        root.vDhtMixProxies = (cfg["dht-mix-proxy"] || []).join("\n")
        root.vMixEnabled = !!cfg["mix-enabled"]
        root.vMixPoolJson = cfg["mix-pool-json"] || ""
        root.vMaxPeers = cfg["max-peers"] !== undefined ? String(cfg["max-peers"]) : ""
        root.vStorageQuota = cfg["storage-quota"] !== undefined ? String(cfg["storage-quota"]) : ""
        root.vNatSchedule = cfg["nat-schedule-interval"] || ""
        root.vNatDiscoverTimeout = cfg["nat-port-mapping-discover-timeout"] !== undefined
                ? String(cfg["nat-port-mapping-discover-timeout"]) : ""
        root.vNatMappingTimeout = cfg["nat-port-mapping-timeout"] !== undefined
                ? String(cfg["nat-port-mapping-timeout"]) : ""
        root.vNatRecheck = cfg["nat-port-mapping-recheck-period"] !== undefined
                ? String(cfg["nat-port-mapping-recheck-period"]) : ""

        root.configBaseline = JSON.stringify(root.buildConfig())
        root.savedNote = false
        root.loadedOnce = true
    }

    // Merge edited values onto the loaded config, preserving unknown keys.
    function buildConfig() {
        var cfg = JSON.parse(JSON.stringify(root.loaded))

        cfg["log-level"] = root.vLogLevel.toLowerCase()
        cfg["listen-ip"] = root.vListenIp
        cfg["listen-port"] = parseInt(root.vListenPort) || 0
        cfg["nat"] = root.vNatMode === "extip" && root.vNatExtIp.length > 0
                ? "extip:" + root.vNatExtIp : "auto"
        cfg["disc-port"] = parseInt(root.vDiscPort) || 0
        cfg["network"] = root.vNetwork
        cfg["mix-pool-json"] = root.vMixPoolJson
        cfg["max-peers"] = parseInt(root.vMaxPeers) || 0
        cfg["storage-quota"] = root.vStorageQuota
        cfg["nat-schedule-interval"] = root.vNatSchedule
        cfg["nat-port-mapping-discover-timeout"] = parseInt(root.vNatDiscoverTimeout) || 0
        cfg["nat-port-mapping-timeout"] = parseInt(root.vNatMappingTimeout) || 0
        cfg["nat-port-mapping-recheck-period"] = parseInt(root.vNatRecheck) || 0

        var nodes = root.vBootstrapText.split("\n").map(function (s) {
            return s.trim()
        }).filter(function (s) {
            return s.length > 0
        })
        cfg["bootstrap-node"] = nodes

        return cfg
    }

    function save() {
        if (!root.backend)
            return
        var cfg = root.buildConfig()
        root.backend.saveUserConfig(JSON.stringify(cfg, null, 2))
        root.loaded = cfg
        root.configBaseline = JSON.stringify(cfg)
        root.savedNote = true
    }

    // Styled single-line field sitting on the card background.
    component SField: LogosTextField {
        Layout.fillWidth: true
        Layout.maximumWidth: 460
        background: CardFieldBackground {}
    }

    component SSelect: LogosComboBox {
        Layout.fillWidth: true
        Layout.maximumWidth: 460
    }

    component Section: LogosText {
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacing.large
        font.pixelSize: Theme.typography.subtitleText
        font.weight: Theme.typography.weightBold
        color: Theme.palette.text
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.large
        spacing: Theme.spacing.medium

        LogosText {
            text: "Settings"
            font.pixelSize: Theme.typography.titleText
            font.weight: Theme.typography.weightBold
            color: Theme.palette.text
        }

        ScrollView {
            id: settingsScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: settingsScroll.availableWidth
                spacing: Theme.spacing.large

                // ---------- General ----------
                Section { text: "General" }

                SettingRow {
                    title: "Log level"
                    description: "Verbosity of the node logs."
                    SSelect {
                        model: root.logLevels
                        currentIndex: root.logLevels.indexOf(root.vLogLevel)
                        onActivated: root.vLogLevel = root.logLevels[currentIndex]
                    }
                }

                SettingRow {
                    title: "Data directory"
                    description: "Where the node stores its configuration and data. Read-only."
                    SField {
                        readOnly: true
                        text: root.vDataDir
                        placeholderText: "Default data directory"
                    }
                }

                SettingRow {
                    title: "Storage quota"
                    description: "Total disk space dedicated to the node (e.g. 8GiB)."
                    requiresRestart: true
                    SField {
                        text: root.vStorageQuota
                        placeholderText: "8GiB"
                        onTextChanged: root.vStorageQuota = text
                    }
                }

                SettingRow {
                    title: "Max peers"
                    description: "Maximum number of peers to connect to."
                    requiresRestart: true
                    SField {
                        text: root.vMaxPeers
                        placeholderText: "160"
                        validator: IntValidator { bottom: 0 }
                        onTextChanged: root.vMaxPeers = text
                    }
                }

                SettingRow {
                    title: "Version"
                    description: "Storage UI version. Read-only."
                    SField {
                        readOnly: true
                        text: root.backend && root.backend.uiVersion ? root.backend.uiVersion : "unknown"
                    }
                }

                // ---------- Network ----------
                Section { text: "Network" }

                SettingRow {
                    title: "Listen IP"
                    description: "IP address to listen on for remote peer connections (IPv4 or IPv6)."
                    requiresRestart: true
                    SField {
                        text: root.vListenIp
                        placeholderText: "0.0.0.0"
                        onTextChanged: root.vListenIp = text
                    }
                }

                SettingRow {
                    title: "Listen port"
                    description: "TCP port for remote peer connections. 0 selects a random free port."
                    requiresRestart: true
                    SField {
                        text: root.vListenPort
                        placeholderText: "0"
                        validator: IntValidator { bottom: 0; top: 65535 }
                        onTextChanged: root.vListenPort = text
                    }
                }

                SettingRow {
                    title: "Discovery port"
                    description: "Discovery (UDP) port."
                    requiresRestart: true
                    SField {
                        text: root.vDiscPort
                        placeholderText: "8090"
                        validator: IntValidator { bottom: 0; top: 65535 }
                        onTextChanged: root.vDiscPort = text
                    }
                }

                SettingRow {
                    title: "NAT"
                    description: "Method to determine the public address: auto, or a fixed external IP."
                    requiresRestart: true
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacing.small
                        SSelect {
                            Layout.maximumWidth: 160
                            model: root.natModes
                            currentIndex: root.natModes.indexOf(root.vNatMode)
                            onActivated: root.vNatMode = root.natModes[currentIndex]
                        }
                        SField {
                            visible: root.vNatMode === "extip"
                            text: root.vNatExtIp
                            placeholderText: "External IP address"
                            onTextChanged: root.vNatExtIp = text
                        }
                    }
                }

                SettingRow {
                    title: "Network"
                    description: "The network preset to connect to."
                    requiresRestart: true
                    SSelect {
                        model: root.networks
                        currentIndex: root.networks.indexOf(root.vNetwork)
                        onActivated: root.vNetwork = root.networks[currentIndex]
                    }
                }

                SettingRow {
                    title: "Bootstrap nodes"
                    description: "Bootstrap peers, one signed peer record (spr:...) per line. Overrides the network preset."
                    requiresRestart: true
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 120
                        clip: true
                        LogosTextArea {
                            text: root.vBootstrapText
                            placeholderText: "spr:..."
                            backgroundColor: Theme.palette.backgroundInset
                            borderColor: Theme.palette.borderSubtle
                            font.family: "monospace"
                            font.pixelSize: Theme.typography.secondaryText
                            onTextChanged: root.vBootstrapText = text
                        }
                    }
                }

                // ---------- NAT tuning ----------
                Section { text: "NAT tuning" }

                SettingRow {
                    title: "NAT schedule interval"
                    description: "Interval between AutoNAT reachability checks (e.g. 2m)."
                    requiresRestart: true
                    SField {
                        text: root.vNatSchedule
                        placeholderText: "2m"
                        onTextChanged: root.vNatSchedule = text
                    }
                }

                SettingRow {
                    title: "Port mapping discover timeout"
                    description: "Timeout in milliseconds for UPnP/NAT-PMP/PCP device discovery."
                    requiresRestart: true
                    SField {
                        text: root.vNatDiscoverTimeout
                        placeholderText: "500"
                        validator: IntValidator { bottom: 1 }
                        onTextChanged: root.vNatDiscoverTimeout = text
                    }
                }

                SettingRow {
                    title: "Port mapping timeout"
                    description: "Timeout in milliseconds for creating a port mapping on the router."
                    requiresRestart: true
                    SField {
                        text: root.vNatMappingTimeout
                        placeholderText: "500"
                        validator: IntValidator { bottom: 1 }
                        onTextChanged: root.vNatMappingTimeout = text
                    }
                }

                SettingRow {
                    title: "Port mapping recheck period"
                    description: "Period in milliseconds between rechecks of existing port mappings."
                    requiresRestart: true
                    SField {
                        text: root.vNatRecheck
                        placeholderText: "300000"
                        validator: IntValidator { bottom: 1 }
                        onTextChanged: root.vNatRecheck = text
                    }
                }

                // ---------- Mix / Privacy ----------
                Section { text: "Mix / Privacy" }

                SettingRow {
                    title: "Mix enabled"
                    description: "Route DHT provider lookups through the Mix protocol. Read-only."
                    LogosSwitch {
                        enabled: false
                        checked: root.vMixEnabled
                    }
                }

                SettingRow {
                    title: "Private DHT queries"
                    description: "Route DHT queries over Mix on the running node. Requires the node to run with Mix enabled."
                    LogosSwitch {
                        enabled: root.backend && root.backend.mixRunning
                        checked: root.privateQueries
                        onToggled: {
                            var ok = root.backend.togglePrivateQueries(checked)
                            if (!ok)
                                checked = root.privateQueries
                            else
                                root.privateQueries = checked
                        }
                    }
                }

                SettingRow {
                    title: "DHT mix proxies"
                    description: "Peers used as dht-proxy destinations when Mix is enabled. Read-only."
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 100
                        clip: true
                        LogosTextArea {
                            readOnly: true
                            text: root.vDhtMixProxies
                            backgroundColor: Theme.palette.backgroundInset
                            borderColor: Theme.palette.borderSubtle
                            font.family: "monospace"
                            font.pixelSize: Theme.typography.secondaryText
                        }
                    }
                }

                SettingRow {
                    title: "Mix pool JSON"
                    description: "Inline JSON content of the Mix relay pool."
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 140
                        clip: true
                        LogosTextArea {
                            text: root.vMixPoolJson
                            placeholderText: "{ ... }"
                            backgroundColor: Theme.palette.backgroundInset
                            borderColor: Theme.palette.borderSubtle
                            font.family: "monospace"
                            font.pixelSize: Theme.typography.secondaryText
                            onTextChanged: root.vMixPoolJson = text
                        }
                    }
                }

                // ---------- Advanced ----------
                Section { text: "Advanced" }

                SettingRow {
                    title: "Restart onboarding"
                    description: "Return to the initial setup flow. The node keeps running and your data is untouched."
                    LogosButton {
                        text: "Restart onboarding"
                        radius: Theme.spacing.radiusLarge
                        onClicked: root.backend.restartOnboarding()
                    }
                }
            }
        }

        // ---------- Footer actions ----------
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.medium

            LogosText {
                visible: root.savedNote
                text: "Saved. Restart the node to apply changes."
                font.pixelSize: Theme.typography.secondaryText
                color: Theme.palette.success
            }

            Item { Layout.fillWidth: true }

            LogosButton {
                text: "Reset"
                radius: Theme.spacing.radiusLarge
                enabled: root.dirty
                onClicked: root.load()
            }

            LogosButton {
                text: "Save changes"
                radius: Theme.spacing.radiusLarge
                variant: LogosButton.Variant.Primary
                enabled: root.dirty
                onClicked: root.save()
            }
        }
    }
}

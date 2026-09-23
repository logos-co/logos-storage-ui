pragma Singleton

import QtQuick

QtObject {
    readonly property bool isMock: true
    property int status: 0
    property string debugLogs: "Hello!"
    property bool mixRunning: false
    property string natReachability: "Unknown"
    property string uiVersion: "0.0.0"
    property string moduleVersion: "0.0.0"
    function migrateConfig(configJson) {
        const cfg = JSON.parse(configJson)
        cfg["config-version"] = 3
        if (!cfg["mix-enabled"])
            return JSON.stringify(cfg)
        cfg["dht-mix-proxy"] = ["spr:mock-" + (cfg["network"] || "logos.test")]
        cfg["mix-pool-json"] = "{\"version\":1,\"relays\":[]}"
        return JSON.stringify(cfg)
    }

    property string defaultConfigJson: JSON.stringify({
                                                          "data-dir": "/home/user/.logos_storage/data",
                                                          "listen-port": 8500,
                                                          "nat-schedule-interval": "60s",
                                                          "mix-enabled": true
                                                      })

    signal ready
    signal startCompleted
    signal startFailed(string error)
    signal error(string message)
    signal peersUpdated(int count)
    signal debugInfoUpdated(var info)
    signal uploadStarted(real totalBytes)
    signal uploadChunk(real len)
    signal uploadCompleted(string cid)
    signal downloadStarted(string cid, string filename, real totalBytes)
    signal downloadChunk(real len)
    signal downloadCompleted(string cid)
    signal spaceUpdated(real total, real used)
    signal manifestsUpdated(var manifests)
    signal manifestFetchStarted(string cid)
    signal manifestFetchFailed(string cid, string error)
    signal removeStarted(string cid)
    signal removeFailed(string cid, string error)
    signal stopCompleted
    signal onboardingRestarted

    function start() {
        status = 2
    }
    function stop() {
        status = 0
    }
    function destroy() {}
    function fetchWidgetsData() {}
    function refreshNodeStatus() {
        natReachability = "Reachable"
        peersUpdated(3)
    }
    function uploadFile(url) {}
    function downloadFile(cid, url, totalBytes) {}
    function downloadManifest(cid) {
        manifestFetchStarted(cid)
    }
    function downloadManifests() {}
    function remove(cid) {
        removeStarted(cid)
    }
    function setAdvertise(cid, enabled) {}
    function logDebugInfo() {
        debugInfoUpdated({
                             "id": "16Uiu2HAmMockPeerIdForTheDesignPreview",
                             "addrs": ["/ip4/127.0.0.1/tcp/8500"],
                             "spr": "spr:mock",
                             "nat": {
                                 "reachability": "Reachable",
                                 "portMapping": "upnp",
                                 "relayRunning": false,
                                 "clientMode": false
                             },
                             "storage": {
                                 "version": "2.0.1",
                                 "revision": "0000000"
                             },
                             "table": {
                                 "nodes": [{
                                         "peerId": "16Uiu2HAmMockPeerA",
                                         "addresses": ["/ip4/127.0.0.1/tcp/8501"],
                                         "lastSeen": 1789131887
                                     }, {
                                         "peerId": "16Uiu2HAmMockPeerB",
                                         "addresses": ["/ip4/127.0.0.1/tcp/8502"],
                                         "lastSeen": 1789131800
                                     }]
                             },
                             "connections": [{
                                     "direct": true
                                 }]
                         })
    }
    function logPeerId() {}
    function logDataDir() {}
    function logSpr() {}
    function logVersion() {}
    function restartOnboarding() {}
    function saveUserConfig(json) {}
    function loadUserConfig() {}
    function reloadIfChanged(json) {}
    function togglePrivateQueries(enabled) {
        return false
    }
    function configJson() {
        return "{}"
    }
    function getUserConfig() {
        return JSON.stringify({
                                  "config-version": 3,
                                  "data-dir": "/home/user/.logos_storage/data",
                                  "log-level": "info",
                                  "listen-port": 8500,
                                  "mix-enabled": true,
                                  "dht-mix-proxy": ["spr:mock"],
                                  "mix-pool-json": "{\"version\":1,\"relays\":[]}"
                              })
    }
}

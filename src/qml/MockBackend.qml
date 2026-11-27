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
    property string defaultConfigJson: JSON.stringify({
                                                          "data-dir": "/home/user/.local/share/Logos/LogosStandalone/module_data/storage_module/0123456789ab/data",
                                                          "listen-port": 8500,
                                                          "nat-schedule-interval": "60s",
                                                          "mix-enabled": true,
                                                          "network": "logos.test"
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
    signal downloadCancelled(string cid)
    signal downloadFailed(string cid, string error)
    signal spaceUpdated(real total, real used)
    signal manifestsUpdated(var manifests)
    signal manifestFetchStarted(string cid, bool isPrivate)
    signal manifestFetchFailed(string cid, string error)
    signal removeStarted(string cid)
    signal removeFailed(string cid, string error)
    signal namePublishStarted(string label, string cid)
    signal namePublished(string label, string cid, string nameKey)
    signal namePublishFailed(string label, string cid, string error)
    signal nameUnpublished(string label)
    signal nameResolveStarted(string nameKey)
    signal nameResolved(string nameKey, string cid)
    signal nameResolveFailed(string nameKey, string error)
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
    function downloadFile(cid, url, totalBytes, isPrivate) {}
    function cancelDownload(cid) {
        downloadCancelled(cid)
    }
    function downloadManifest(cid, isPrivate) {
        manifestFetchStarted(cid, isPrivate)
    }
    function downloadManifests() {}
    function remove(cid) {
        removeStarted(cid)
    }
    function publishName(label, cid) {
        namePublishStarted(label, cid)
        namePublished(label, cid, "zMockNameKey" + label)
    }
    function unpublishName(label) {
        nameUnpublished(label)
    }
    // In the mock, a name key is any key that starts with "zMockNameKey".
    function fetchManifestOrName(key, isPrivate) {
        key = key.trim()
        if (key.indexOf("zMockNameKey") !== 0) {
            downloadManifest(key, isPrivate)
            return
        }
        nameResolveStarted(key)
        nameResolved(key, "zDvZRwzmMockResolvedCid")
        downloadManifest("zDvZRwzmMockResolvedCid", isPrivate)
    }
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
                                 }],
                             "serviceProviders": {
                                 "/logos-storage/1.0.0": [{
                                         "peerId": "16Uiu2HAmMockPeerA",
                                         "addresses": ["/ip4/127.0.0.1/tcp/8501"],
                                         "lastSeen": 1789131887
                                     }]
                             }
                         })
    }
    function logPeerId() {}
    function logDataDir() {}
    function logSpr() {}
    function logVersion() {}
    function restartOnboarding() {}
    function updateUserConfig(json) {}
    function getUserConfig() {
        return JSON.stringify({
                                  "config-version": 3,
                                  "data-dir": "/home/user/.local/share/Logos/LogosStandalone/module_data/storage_module/0123456789ab/data",
                                  "log-level": "info",
                                  "listen-port": 8500,
                                  "mix-enabled": true,
                                  "dht-mix-proxy": ["spr:mock"],
                                  "mix-pool-json": "{\"version\":1,\"relays\":[]}"
                              })
    }
    function getNodeConfig() {
        return JSON.stringify({
                                  "network": "logos.test",
                                  "bootstrap-node": ["spr:mock-bootstrap"]
                              })
    }
}

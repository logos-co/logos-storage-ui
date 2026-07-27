pragma Singleton

import QtQuick

QtObject {
    readonly property bool isMock: true
    property int status: 0
    property int defaultListenPort: 8500
    property bool mixRunning: false
    property string uiVersion: "mock"

    signal ready
    signal startCompleted
    signal startFailed(string error)
    signal error(string message)
    signal natExtConfigCompleted
    signal nodeIsUp
    signal nodeIsntUp(string reason)
    signal peersUpdated(int count)
    signal peersTableUpdated(var peers)
    signal logLines(var lines)
    signal uploadStarted(real totalBytes)
    signal uploadChunk(real len)
    signal uploadCompleted(string cid)
    signal downloadStarted(string cid, string filename, real totalBytes)
    signal downloadChunk(real len)
    signal downloadCompleted(string cid)
    signal spaceUpdated(real total, real used, var usage)
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
    function checkNodeIsUp() {}
    function fetchWidgetsData() {}
    function uploadFile(url) {}
    function downloadFile(cid, url, totalBytes) {}
    function downloadManifest(cid) {
        manifestFetchStarted(cid)
    }
    function downloadManifests() {}
    function remove(cid) {
        removeStarted(cid)
    }
    function logDebugInfo() {
        peersUpdated(3)
        peersTableUpdated([{
                               "peerId": "16Uiu2HAmJwAxtuRLfjP1SfjE7EWWr6zExFBFVLnUnTsc28fmvrpq",
                               "address": "24.144.78.200:8080",
                               "seen": true
                           }, {
                               "peerId": "16Uiu2HAmGJx2MWRH66M2A1RcD5TcY5Z2kReNdddpF9kRyfykBFwy",
                               "address": "188.166.200.119:8080",
                               "seen": true
                           }, {
                               "peerId": "16Uiu2HAmDF8zGjsuxM4h1N5x37hzUtGnDHtkVJ8jLiVty1DJyG92",
                               "address": "34.42.230.59:8080",
                               "seen": false
                           }])
    }
    function logPeerId() {}
    function logDataDir() {}
    function logSpr() {}
    function logVersion() {}
    function restartOnboarding() {}
    function getUserConfig() {
        return JSON.stringify({
                                  "log-level": "info",
                                  "data-dir": "/home/user/.cache/storage",
                                  "listen-ip": "0.0.0.0",
                                  "listen-port": 8500,
                                  "nat": "auto",
                                  "disc-port": 8090,
                                  "network": "logos.test",
                                  "bootstrap-node": [],
                                  "mix-enabled": true,
                                  "dht-mix-proxy": ["spr:example"],
                                  "mix-pool-json": "{\"version\":1,\"relays\":[]}",
                                  "max-peers": 160,
                                  "storage-quota": "8GiB"
                              }, null, 2)
    }
    function saveUserConfig(json) {}
    function saveCurrentConfig() {}
    function loadUserConfig() {}
    function reloadIfChanged(json) {}
    function enableUpnpConfig() {}
    function enableNatExtConfig(tcpPort) {
        natExtConfigCompleted()
    }
    function togglePrivateQueries(enabled) {
        return false
    }
    function configJson() {
        return "{}"
    }
}

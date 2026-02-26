pragma Singleton
import QtQuick

QtObject {
    readonly property bool isMock: true
    property int status: 0
    property string debugLogs: "Hello!"

    signal ready
    signal startCompleted
    signal startFailed(string error)
    signal error(string message)
    signal natExtConfigCompleted
    signal nodeIsUp
    signal nodeIsntUp(string reason)
    signal peersUpdated(int count)
    signal uploadStarted(real totalBytes)
    signal uploadChunk(real len)
    signal uploadCompleted(string cid)
    signal downloadStarted(string cid, string filename, real totalBytes)
    signal downloadChunk(real len)
    signal downloadCompleted(string cid)
    signal spaceUpdated(real total, real used)
    signal manifestsUpdated(var manifests)
    signal stopCompleted
    signal restartOnboarding

    function start() { status = 2 }
    function stop() { status = 0 }
    function destroy() {}
    function checkNodeIsUp() {}
    function fetchWidgetsData() {}
    function uploadFile(url) {}
    function downloadFile(cid, url, totalBytes) {}
    function downloadManifest(cid) {}
    function downloadManifests() {}
    function remove(cid) {}
    function logDebugInfo() {}
    function logPeerId() {}
    function logDataDir() {}
    function logSpr() {}
    function logVersion() {}
    function listSettings() {}
    function restartOnboarding() {}
    function saveUserConfig(json) {}
    function saveCurrentConfig() {}
    function loadUserConfig() {}
    function reloadIfChanged(json) {}
    function enableUpnpConfig() {}
    function enableNatExtConfig(tcpPort) { natExtConfigCompleted() }
    function configJson() { return "{}" }
}

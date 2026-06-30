#pragma once
#include "logos_api.h"
#include "logos_sdk.h"
#include "rep_StorageBackend_source.h"
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QObject>
#include <QString>
#include <QStringList>
#include <QTimer>

static const int RET_OK = 0;
static const int RET_PROGRESS = 3;
// static const QString ECHO_PROVIDER = "https://echo.codex.storage/";
static const QString ECHO_PROVIDER = "https://ipv4.icanhazip.com";
static const QString PORT_CHECKER_PROVIDER = "https://portchecker.io/api/";
static const QString APP_HOME = QDir::homePath() + "/.logos_storage";
static const QString DEFAULT_DATA_DIR = APP_HOME + "/data";
static const QString USER_CONFIG_PATH = APP_HOME + "/config.json";

static const int DEFAULT_LISTEN_PORT = 8500;
static const int DEFAULT_DISC_PORT = 9090;
static const int DEFAULT_CHUNK_SIZE = 1024 * 64;

// Default network preset of the storage module. The preset bundles its own
// bootstrap nodes, so a config carrying "network" needs no "bootstrap-node".
static const QString DEFAULT_NETWORK_PRESET = "logos.test";

// SPRs used as dht-mix-proxy destinations when Mix is enabled. Temporary
// single proxy until the network ships a preset of proxy nodes.
static const QStringList DHT_MIX_PROXY = {
      "spr:CiUIAhIhAlPbmW9J08tDI6pIV-C-XvvFTCDN_Vih8I3ZTOeOuf5rEgIDARo7CicAJQgCEiECU9uZb0nTy0MjqkhX4L5e-8VMIM39WKHwjdlM5465_msQ9tr10QYaCgoIBKX1-QUGH5AqRzBFAiEA3CSkMf8I8SMiM7F01OdfgyontOhd5GMa6SckSLwuJAYCIHkaIukQL1eB54G-kMg9-Vx3ALMlMtzzRJQtU4ySRvmZ",
      "spr:CiUIAhIhA4_xqh_E3HDnV4Gbe159LCAuv03UxcDoGloH1Dhoqy_qEgIDARo7CicAJQgCEiEDj_GqH8TccOdXgZt7Xn0sIC6_TdTFwOgaWgfUOGirL-oQltv10QYaCgoIBKRc8f0GH5AqRzBFAiEAhB-XTjnQoT7is8_DGzsAiBVCgwdobOPnF2X7hu7zXhICIEQ7GDRR6Wm_yIucbPwvacSYitZoBYtvAYOED7B4BFv8",
      "spr:CiUIAhIhAj5vZtyN69MB1cmKhnbxlUo4sp7KfeK1sMipjKpBD47dEgIDARo7CicAJQgCEiECPm9m3I3r0wHVyYqGdvGVSjiynsp94rWwyKmMqkEPjt0Qltv10QYaCgoIBC5lcMkGH5AqRzBFAiEAxXURxGqV4csw2uKITjNS4Rq64nbVBr7dTmhNwvQ_9zQCIDNQvVpQwrV42WbRFGa-ZrPANpaKUZQG20LAOGmd2mLG",
      "spr:CiUIAhIhAgX6x7NWUskBQ1a5CvhQ9qe6nAcgE-C6GLjAfnpyRK_6EgIDARo7CicAJQgCEiECBfrHs1ZSyQFDVrkK-FD2p7qcByAT4LoYuMB-enJEr_oQltv10QYaCgoIBKX194YGH5AqRjBEAiBskHSppya4Dah6QGTlYnvAG72mUbEyxO6QfDW5cNOTygIgVmHL40bgnGqxpZtDGI0jyNo5mk_DkriCmoDpreZ6x5o"
};

// Bundled Mix relay pool, passed inline to the module via the "mix-pool-json"
// config key (takes precedence over the "mix-pool" file path).
static const QString MIX_POOL_JSON = R"JSON({
  "version": 1,
  "relays": [
    {
      "peerId": "16Uiu2HAm1522ucToKCsrwrusNHbtkww8YPBBqF2e3RWHMf6EREe6",
      "multiAddr": "/ip4/165.245.249.5/tcp/8080",
      "mixPubKey": "6ec39559bd7ca3ca099852a1d41557d6111b77114c713558dcaf3ec819b3114e",
      "libp2pPubKey": "0253db996f49d3cb4323aa4857e0be5efbc54c20cdfd58a1f08dd94ce78eb9fe6b"
    },
    {
      "peerId": "16Uiu2HAmNLtP38EA2CMwqsoSninKFgA4sxcsV7AgPnR49dqDuTFw",
      "multiAddr": "/ip4/164.92.241.253/tcp/8080",
      "mixPubKey": "cf5e1396edb26b6e42a48b979108f481fa1737184a33252724977ac9b2bf995a",
      "libp2pPubKey": "038ff1aa1fc4dc70e757819b7b5e7d2c202ebf4dd4c5c0e81a5a07d43868ab2fea"
    },
    {
      "peerId": "16Uiu2HAkydPnHVbxBGsrxidSwL4TzT2vRkbiEzFTM1hNSG9HisUG",
      "multiAddr": "/ip4/46.101.112.201/tcp/8080",
      "mixPubKey": "2f95107b6db1f5eaebc6ae06e96539d9c66da0ac71daec5de17788dad1faac43",
      "libp2pPubKey": "023e6f66dc8debd301d5c98a8676f1954a38b29eca7de2b5b0c8a98caa410f8edd"
    },
    {
      "peerId": "16Uiu2HAkuq1ouxs1ACX8kMBykVQML9DkenLB6zYVf9sJjS8tvbr1",
      "multiAddr": "/ip4/165.245.247.134/tcp/8080",
      "mixPubKey": "cd28b4fd848bd064fe68c2ff524f10608809876997bf382ef7e1aadfa3c9a115",
      "libp2pPubKey": "0205fac7b35652c9014356b90af850f6a7ba9c072013e0ba18b8c07e7a7244affa"
    }
  ]
})JSON";

// The bootstrap nodes the UI used to write into config.json before the module
// switched to network presets. Kept only to detect un-migrated user configs.
static const QStringList LEGACY_BOOTSTRAP_NODES = {
    "spr:CiUIAhIhA-VlcoiRm02KyIzrcTP-ljFpzTljfBRRKTIvhMIwqBqWEgIDARpJCicAJQgCEiED5WVyiJGbTYrIjOtxM_6WMWnNOWN8FFEpMi-"
    "EwjCoGpYQs8n8wQYaCwoJBHTKubmRAnU6GgsKCQR0yrm5kQJ1OipHMEUCIQDwUNsfReB4ty7JFS5WVQ6n1fcko89qVAOfQEHixa03rgIgan2-"
    "uFNDT-r4s9TOkLe9YBkCbsRWYCHGGVJ25rLj0QE",
    "spr:CiUIAhIhApIj9p6zJDRbw2NoCo-"
    "tj98Y760YbppRiEpGIE1yGaMzEgIDARpJCicAJQgCEiECkiP2nrMkNFvDY2gKj62P3xjvrRhumlGISkYgTXIZozMQvcz8wQYaCwoJBAWhF3WRAnVEG"
    "gsKCQQFoRd1kQJ1RCpGMEQCIFZB84O_nzPNuViqEGRL1vJTjHBJ-i5ZDgFL5XZxm4HAAiB8rbLHkUdFfWdiOmlencYVn0noSMRHzn4lJYoShuVzlw",
    "spr:CiUIAhIhApqRgeWRPSXocTS9RFkQmwTZRG-"
    "Cdt7UR2N7POoz606ZEgIDARpJCicAJQgCEiECmpGB5ZE9JehxNL1EWRCbBNlEb4J23tRHY3s86jPrTpkQj8_"
    "8wQYaCwoJBAXfEfiRAnVOGgsKCQQF3xH4kQJ1TipGMEQCIGWJMsF57N1iIEQgTH7IrVOgEgv0J2P2v3jvQr5Cjy-RAiAy4aiZ8QtyDvCfl_K_"
    "w6SyZ9csFGkRNTpirq_M_QNgKw"};

class StorageBackend : public StorageBackendSimpleSource {
    Q_OBJECT
  public:
    explicit StorageBackend(LogosAPI* logosAPI = nullptr, QObject* parent = nullptr);
    ~StorageBackend();

  public slots:
    // Init the Storage Module using the config json
    // passed in parameter.
    // It subscribes to events:
    // 1- storageStart
    // 2- storageStop
    // 3- storageUploadProgress
    // 4- storageUploadDone
    // 5- storageDownloadProgress
    // 6- storageDownloadProgress
    void init(QString configJson) override;

    // Start the node
    // If the user configuration has changed, it will
    // reloaded it.
    void start() override;

    // Destroy the Storage Module
    void destroy() override;

    // Emit stopCompleted() on completion of it the module is not started
    void stop() override;

    // Log debug info
    // Emit peersUpdated(int peers)
    void logDebugInfo() override;

    // Other log methods for debug
    void logDataDir() override;
    void logVersion() override;
    void restartOnboarding() override;
    void logSpr() override;
    void logPeerId() override;

    void exists(QString cid) override;
    void remove(QString cid) override;

    // Fetch a cid in background
    void fetch(QString cid) override;

    // Upload a file from the url
    // Emit uploadStarted(totalBytes) when the upload begins
    // Emit uploadChunk(len) on each storageUploadProgress event
    // Emit uploadCompleted(cid) on storageUploadDone
    void uploadFile(QUrl url) override;

    // Upload a file from the url
    // Emit downloadStarted(cid, filename, totalBytes) when download begins
    // Emit downloadChunk(len) on each storageDownloadProgress event
    // Emit downloadCompleted(cid) on storageDownloadDone
    void downloadFile(QString cid, QUrl url, qint64 totalBytes) override;

    // Emit manifestsUpdated
    void downloadManifest(QString cid) override;

    // Download all the manifests and notify
    // Emit manifestsUpdated
    void downloadManifests() override;

    // Call space from the Storage Module
    // Emit spaceUpdated to refresh the widget
    void refreshSpace() override;

    // Save the user config passed in parameter
    // into the user config json.
    void saveUserConfig(QString configJson) override;

    // Save the current config object
    // into the user config json.
    void saveCurrentConfig() override;

    // Load the user config saved previously
    void loadUserConfig() override;

    // Get the content of the user config file
    QString getUserConfig() override;

    // Take a new config json and reload the Storage context
    // if the configuration has changed.
    //
    // This method cannot be used if the Storage Module
    // is running, starting or stopping.
    //
    // If the Storage Module was already created,
    // it will be destroyed first.
    //
    // On success, the status will be set to Stopped.
    //
    void reloadIfChanged(QString configJson) override;

    // Enables the upnp in the config
    // and re-create a context with the new configuration
    void enableUpnpConfig() override;

    // Enables the net external in the config
    // and re-create a context with the new configuration
    // Emit natExtConfigCompleted
    void enableNatExtConfig(int tcpPort) override;

    // Toggle private DHT queries over Mix on the running node.
    // Requires the node to run with mix-enabled and a non-empty dht-mix-proxy.
    // Emit error(message) and return false on failure.
    bool togglePrivateQueries(bool enabled) override;

    // This method will ensure that the node is ready to be used.
    //
    // 1- Make a call to debug function in the storage module and
    // make sure that the node has peer. If not, the UI should suggest
    // to modifiy the discovery port (8090) in the advance settings (to come).
    //
    // 2- Ensure that the tcp port is open to remote connection. If not,
    // the UI should suggest to change go back and try another port and double
    // check that the port forwarding is enabled on the router.
    //
    // Emit nodeIsUp() on success
    // Emit nodeIsntUp(error) on failure
    void checkNodeIsUp() override;

    // Fetch multiple data for the widgets: manifests, debug..
    void fetchWidgetsData() override;

    QString configJson() override;

  private:
    // Provide a default config for onboarding
    static QJsonDocument defaultConfig();

    // Rewrite the persisted config.json in place if it still uses the legacy
    // "bootstrap-node" default instead of the "network" preset.
    void migrateUserConfigFile();

    // Pure transform: return configJson migrated to the network preset format,
    // or unchanged if already migrated or carrying a custom bootstrap list.
    QString migrateConfig(QString configJson);

    // True when the array matches the bootstrap list the UI used to ship,
    // i.e. the user never set their own bootstrap nodes.
    static bool isLegacyBootstrap(const QJsonArray& bootstrap);

    // Display debug (or message) in the terminal and
    // add it to the debugLogs to make it accessible
    // from the debug panel.
    // Default level is debug, can be "warning" to display warning
    // messages.
    void debug(const QString& log, const QString& level = "debug");

    // Display log and add it to debugLogs
    // Emit error(message)
    void reportError(const QString& message);

    // Logos related variables
    LogosAPI* m_logosAPI;
    LogosModules* m_logos;

    bool m_eventsSubscribed = false;

    // Internal configuration object. It can be updated by
    // upnp or port forwarning methods.
    QJsonDocument m_config;
};

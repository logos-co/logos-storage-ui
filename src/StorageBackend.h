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
static const QString DEFAULT_NETWORK_PRESET = "logos.dev";

// SPRs used as dht-mix-proxy destinations when Mix is enabled. Temporary
// single proxy until the network ships a preset of proxy nodes.
static const QStringList DHT_MIX_PROXY = {
  "spr:CiUIAhIhA11LamlswboRlyrpEXBubPQAr2WRmqjgWRC4JsvFptrCEgIDARpHCicAJQgCEiEDXUtqaWzBuhGXKukRcG5s9ACvZZGaqOBZELgmy8Wm2sIQnO-N0gYaCgoIBBiQTsgGH5AaCgoIBBiQTsgGH5AqRjBEAiAjgWii--TgYd2tPwyekCu4H3yDw-qngLo1SfbmDcL7SAIgE2o_HdzRO3MXyn3MtMMmPJtUdnhBS3uMJrxGy6sf6xY",
  "spr:CiUIAhIhAzZMgD-qjJe5tlKjSoF78qo7MM4sxRSLWPmgkye9R6YsEgIDARpHCicAJQgCEiEDNkyAP6qMl7m2UqNKgXvyqjswzizFFItY-aCTJ71HpiwQgOiN0gYaCgoIBLymyHcGH5AaCgoIBLymyHcGH5AqRjBEAiBx0mCFW3Zr2f7ck_VsZYCuzw2XhDlohttGnKOIB2OeMAIgCfE2efI0_GKYOKjxu5mSJJmQAV7Vnty_Ob_8kVhfLow",
  "spr:CiUIAhIhAwi_g5xHmn-aLe9OVMxOaBADpkjm2uiQItF5cUbCqLQ9EgIDARpHCicAJQgCEiEDCL-DnEeaf5ot705UzE5oEAOmSOba6JAi0XlxRsKotD0Q5OaN0gYaCgoIBCIq5jsGH5AaCgoIBCIq5jsGH5AqRjBEAiATmAcBpRdG1_33TfuX_XlVqN6D7XLgvuNkl13Mv8hGLQIgAVVq_pLJUThfo_yXI5HaMXQIiT9cYx_vjyjGil6cqpE",
  "spr:CiUIAhIhAiwKmSwu6gxwCcUU_EeE8dPdE_GJDlw17E5qORPHvjflEgIDARpHCicAJQgCEiECLAqZLC7qDHAJxRT8R4Tx090T8YkOXDXsTmo5E8e-N-UQyeiN0gYaCgoIBCI7UnMGH5AaCgoIBCI7UnMGH5AqRjBEAiBoss-6Bel-mSmeEAhWoF0VbIJ_TwEKBmeWDTy7RhCKaQIgByK8s5__HQ1iYxBL_1_iHiq0mfowhtTbntKBCL6F7PY",
  "spr:CiUIAhIhAuc7v0KnrAyWlwcAw72SvOxVDRG0yAA3ldfwAz6ArdCOEgIDARpHCicAJQgCEiEC5zu_QqesDJaXBwDDvZK87FUNEbTIADeV1_ADPoCt0I4Qy-WN0gYaCgoIBC_u5W8GH5AaCgoIBC_u5W8GH5AqRzBFAiEA_23ADTmzzORJAxsGTt3apZi1J_Y9JPbTuCmbdzFAUlcCIEsnRXEKWLZKj0XgRSu5JVX8m51n4fCLv4L8JdNQn7Rj",
  "spr:CiUIAhIhAm-BN7CX8n1CSWBqCX76J1ppr8R8Zwd0a6SVEZeiHvvSEgIDARpHCicAJQgCEiECb4E3sJfyfUJJYGoJfvonWmmvxHxnB3RrpJURl6Ie-9IQvueN0gYaCgoIBC9WIsoGH5AaCgoIBC9WIsoGH5AqRjBEAiAVW8C1zXUFM-dEq_RFdINy2EuxJHzm-OYpbpVCGX7R4AIgJ3T_qtFtEBY0-UCWEVxxpbJ-HYXq4yf8YmoH84nEcyM"
};

// Bundled Mix relay pool, passed inline to the module via the "mix-pool-json"
// config key (takes precedence over the "mix-pool" file path).
static const QString MIX_POOL_JSON = R"JSON({
  "version": 1,
  "relays": [
    {
      "peerId": "16Uiu2HAmJwAxtuRLfjP1SfjE7EWWr6zExFBFVLnUnTsc28fmvrpq",
      "mixPubKey": "d2bad8ab91f9a63c8a60b1e305fc1045224891ed00719ada2991abe9bc627540",
      "libp2pPubKey": "035d4b6a696cc1ba11972ae911706e6cf400af65919aa8e05910b826cbc5a6dac2",
      "multiAddr": "/ip4/24.144.78.200/tcp/8080"
    },
    {
      "peerId": "16Uiu2HAmGJx2MWRH66M2A1RcD5TcY5Z2kReNdddpF9kRyfykBFwy",
      "mixPubKey": "410d987b608e5164ec1748b964a0ee6d636af4e62667a5a207e7fd766ec42268",
      "libp2pPubKey": "03364c803faa8c97b9b652a34a817bf2aa3b30ce2cc5148b58f9a09327bd47a62c",
      "multiAddr": "/ip4/188.166.200.119/tcp/8080"
    },
    {
      "peerId": "16Uiu2HAmDF8zGjsuxM4h1N5x37hzUtGnDHtkVJ8jLiVty1DJyG92",
      "mixPubKey": "0a9b87d4a03fca9ffd9b0d7b21dd9950741f08d72fc0716bf79c8ad83e702e34",
      "libp2pPubKey": "0308bf839c479a7f9a2def4e54cc4e681003a648e6dae89022d1797146c2a8b43d",
      "multiAddr": "/ip4/34.42.230.59/tcp/8080"
    },
    {
      "peerId": "16Uiu2HAkxPbHtGidyULiTjtzRRfSbEL2DPX5cr8HgpvHsjA2T1WL",
      "mixPubKey": "11fcb95bfe9932339eae0aeef85ecd7b51299a91a6c9ff58f8a1d7d423331614",
      "libp2pPubKey": "022c0a992c2eea0c7009c514fc4784f1d3dd13f1890e5c35ec4e6a3913c7be37e5",
      "multiAddr": "/ip4/34.59.82.115/tcp/8080"
    },
    {
      "peerId": "16Uiu2HAmAzJztKiAAMSixFAhUjfWdKB3bGcXGfDFqaut6nc5PTRf",
      "mixPubKey": "04dddf75ad5090f8975836f8617b7b87cf926a7f2938a5059c9f5e0000509513",
      "libp2pPubKey": "02e73bbf42a7ac0c96970700c3bd92bcec550d11b4c8003795d7f0033e80add08e",
      "multiAddr": "/ip4/47.238.229.111/tcp/8080"
    },
    {
      "peerId": "16Uiu2HAm2vwWq3aoJsdk5ovigGJjDL7xDvXFckEyknpJzBL7YENd",
      "mixPubKey": "cda3b372494a7310c214b2d58644d95410af9878740a0bfe8e998483819d755b",
      "libp2pPubKey": "026f8137b097f27d4249606a097efa275a69afc47c6707746ba4951197a21efbd2",
      "multiAddr": "/ip4/47.86.34.202/tcp/8080"
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

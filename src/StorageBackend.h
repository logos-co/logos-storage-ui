#pragma once
#include "logos_api.h"
#include "logos_sdk.h"
#include "rep_StorageBackend_source.h"
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonObject>
#include <QObject>
#include <QString>
#include <QStringList>
#include <QTimer>

static const int RET_OK = 0;
static const int RET_PROGRESS = 3;
static const QString APP_HOME = QDir::homePath() + "/.logos_storage";
static const QString DEFAULT_DATA_DIR = APP_HOME + "/data";
static const QString USER_CONFIG_PATH = APP_HOME + "/config.json";

static const int DEFAULT_LISTEN_PORT = 8500;
static const int DEFAULT_DISC_PORT = 9090;
static const int DEFAULT_CHUNK_SIZE = 1024 * 64;

// AutoNAT rounds every two minutes is the node's own default, and a verdict
// takes several rounds: too slow for a user watching the dashboard.
static const QString DEFAULT_NAT_SCHEDULE_INTERVAL = "60s";

// Config schema version
// Increment it and add migrateVXtoVY methods when the config schema changes.
static const int CURRENT_CONFIG_VERSION = 2;

// Default network preset.
// Presets are defined in logos storage nim repo.
static const QString DEFAULT_NETWORK = "logos.test";

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

    // Log the raw node debug info
    void logDebugInfo() override;

    // Read the node debug info: NAT reachability and connected peers.
    // Emit peersUpdated(int peers)
    void refreshNodeStatus() override;

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

    // Toggle private DHT queries over Mix on the running node.
    // Requires the node to run with mix-enabled and a non-empty dht-mix-proxy.
    // Emit error(message) and return false on failure.
    bool togglePrivateQueries(bool enabled) override;

    // Fetch multiple data for the widgets: manifests, debug..
    void fetchWidgetsData() override;

    QString configJson() override;

  private:
    // Provide a default config for onboarding
    static QJsonDocument defaultConfig();

    // Run the persisted config.json through migrateConfig() and rewrite.
    void migrateUserConfigFile();

    // Transform the config json from an old version to the current version.
    QString migrateConfig(QString configJson);

    // Individual migration steps.
    static QJsonObject migrateV0toV1(QJsonObject obj);
    static QJsonObject migrateV1toV2(QJsonObject obj);

    // Mix config for a given network preset.
    // It is used to fill the dht-mix-proxy and mix-enabled fields.
    static QJsonObject mixConfig(const QString& network);

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

#pragma once
#include "logos_api.h"
#include "logos_sdk.h"
#include "logos_ui_plugin_context.h"
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

static const int DEFAULT_LISTEN_PORT = 8500;
static const int DEFAULT_CHUNK_SIZE = 1024 * 64;

// AutoNAT rounds every two minutes is the node's own default, and a verdict
// takes several rounds: too slow for a user watching the dashboard.
static const QString DEFAULT_NAT_SCHEDULE_INTERVAL = "60s";

class StorageBackend : public StorageBackendSimpleSource, public LogosUiPluginContext {
    Q_OBJECT
  public:
    explicit StorageBackend(QObject* parent = nullptr);
    ~StorageBackend();

    // Called once modules() is ready.
    void onContextReady() override;

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

    // Init a new context with the user config, then start the node.
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

    // Keep the user config passed in parameter for the next start,
    // whose init persists it through the Storage Module.
    void updateUserConfig(QString configJson) override;

    // Get the content of the user config file
    QString getUserConfig() override;

    // Toggle private DHT queries over Mix on the running node.
    // Requires the node to run with mix-enabled and a non-empty dht-mix-proxy.
    // Emit error(message) and return false on failure.
    bool togglePrivateQueries(bool enabled) override;

    // Fetch multiple data for the widgets: manifests, debug..
    void fetchWidgetsData() override;

  protected:
    // Leaves the shared node running.
    LogosShutdown aboutToUnload() override;

  private:
    // Provide a default config for onboarding
    static QJsonDocument defaultConfig();

    // The config set by updateUserConfig, else the one the module persisted,
    // migrated by the module.
    QString userConfig();

    // Display debug (or message) in the terminal and
    // add it to the debugLogs to make it accessible
    // from the debug panel.
    // Default level is debug, can be "warning" to display warning
    // messages.
    void debug(const QString& log, const QString& level = "debug");

    // Display log and add it to debugLogs
    // Emit error(message)
    void reportError(const QString& message);

    LogosModules* m_logos;

    bool m_eventsSubscribed = false;

    // Config saved by the user, applied on the next start.
    QJsonDocument m_userConfig;
};

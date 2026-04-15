#pragma once
#include "logos_api.h"
#include "logos_sdk.h"
#include "rep_StorageBackend_source.h"
#include <QDir>
#include <QFile>
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

// Add manual SPR from https://spr.codex.storage/devnet
static const QStringList BOOTSTRAP_NODES = {
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
    void listSettings() override;
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
    QString defaultConfigJson() override;

  private:
    // Provide a default config for onboarding
    static QJsonDocument defaultConfig();

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

    // Internal configuration object. It can be updated by
    // upnp or port forwarning methods.
    QJsonDocument m_config;
};

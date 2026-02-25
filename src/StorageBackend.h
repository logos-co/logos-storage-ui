#pragma once
#include "logos_api.h"
#include "logos_sdk.h"
#include <QDir>
#include <QFile>
#include <QObject>
#include <QString>
#include <QStringList>
#include <QTimer>
#include <QtQml/qqml.h>

static const int RET_OK = 0;
static const int RET_PROGRESS = 3;
// static const QString ECHO_PROVIDER = "https://echo.codex.storage/";
static const QString ECHO_PROVIDER = "https://ipv4.icanhazip.com";
static const QString PORT_CHECKER_PROVIDER = "https://portchecker.io/api/";
static const QString APP_HOME = QDir::homePath() + "/.logos_storage";
static const QString DEFAULT_DATA_DIR = APP_HOME + "/data";
static const QString USER_CONFIG_PATH = APP_HOME + "/config.json";

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

class StorageBackend : public QObject {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString debugLogs READ debugLogs NOTIFY debugLogsChanged)
    Q_PROPERTY(StorageStatus status READ status NOTIFY statusChanged)
  public:
    enum StorageStatus {
        // Stopped means that the context is created but the module is not started
        Stopped = 0,

        Starting,

        // Running means the module is started
        Running,

        Stopping,

        // Destroyed means the context is not created (or has been destroyed).
        Destroyed
    };
    Q_ENUM(StorageStatus)

    QString debugLogs() const;
    StorageStatus status() const;
    Q_INVOKABLE QString configJson() const;

    // Provide a default config for onboarding
    static QJsonDocument defaultConfig();

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
    LogosResult init(const QString& configJson);

    // Start the node
    // If a configuration is passed (not empty string),
    // the configuration will be reloaded before trying
    // to start.
    LogosResult start(const QString& configJson = "");

    // Destroy the Storage Module
    void destroy();

    // Emit stopCompleted() on completion of it the module is not started
    void stop();

    // Log debug info
    // Emit peersUpdated(int peers)
    void logDebugInfo();

    // Other log methods for debug
    void logDataDir();
    void logVersion();
    void logSpr();
    void logPeerId();

    void exists(const QString& cid);
    void remove(const QString& cid);

    // Fetch a cid in background
    void fetch(const QString& cid);

    // Upload a file from the url
    // Emit uploadStarted(totalBytes) when the upload begins
    // Emit uploadChunk(len) on each storageUploadProgress event
    // Emit uploadCompleted(cid) on storageUploadDone
    void uploadFile(const QUrl& url);

    // Upload a file from the url
    // Emit downloadStarted(cid, filename, totalBytes) when download begins
    // Emit downloadChunk(len) on each storageDownloadProgress event
    // Emit downloadCompleted(cid) on storageDownloadDone
    void downloadFile(const QString& cid, const QUrl& url, qint64 totalBytes = 0);

    // Emit manifestsUpdated
    void downloadManifest(const QString& cid);

    // Download all the manifests and notify
    // Emit manifestsUpdated
    void downloadManifests();

    // Call space from the Storage Module
    // Emit spaceUpdated to refresh the widget
    void refreshSpace();

    // Save the user config passed in parameter
    // into the user config json.
    void saveUserConfig(const QString& configJson);

    // Save the current config object
    // into the user config json.
    void saveCurrentConfig();

    // Load the user config saved previously
    void loadUserConfig();

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
    void reloadIfChanged(const QString& configJson);

    // Enables the upnp in the config
    // and re-create a context with the new configuration
    void enableUpnpConfig();

    // Enables the net external in the config
    // and re-create a context with the new configuration
    // Emit natExtConfigCompleted
    void enableNatExtConfig(int tcpPort);

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
    void checkNodeIsUp();

    // Fetch multiple data for the widgets: manifests, debug..
    void fetchWidgetsData();

  signals:
    // Used to start the Storage Module
    // if the onboarding is already done
    void ready();

    // Used in StartNode component to detect
    // success in the onboarding.
    void startCompleted();

    // Used in StartNode component to detect
    // failure in the onboarding.
    void startFailed(const QString& error);

    // Refresh the node state indicator
    void statusChanged();

    // Refresh the debug logs panel.
    void debugLogsChanged();

    // Used in the shutdown process
    void stopCompleted();

    // Used to refresh the disk widgets
    void spaceUpdated(qlonglong total, qlonglong used);

    // Emitted when an upload starts, with the total file size
    void uploadStarted(qint64 totalBytes);

    // Emitted for each chunk received during upload
    void uploadChunk(qint64 len);

    // Used to refresh the Manifests table
    void manifestsUpdated(const QVariantList& manifests);

    // Used in the on boarding to detect success
    void natExtConfigCompleted();

    void uploadCompleted(const QString& cid);

    // Emitted when a download starts
    void downloadStarted(const QString& cid, const QString& filename, qint64 totalBytes);

    // Emitted for each chunk received during download
    void downloadChunk(qint64 len);

    void downloadCompleted(const QString& cid);

    // Display a toast message on error
    void error(const QString& message);

    // Emitted when the node port is reachable from the internet
    void nodeIsUp();

    // Emitted when the node port is not reachable, with a reason
    void nodeIsntUp(const QString& reason);

    // Emitted when the peer count changes (from checkNodeIsUp)
    void peersUpdated(int count);

  private slots:

  private:
    // Update the status
    // Emit statusUpdated if the status was different from the previous status
    void setStatus(StorageStatus newStatus);

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

    // Status of the Storage Module
    StorageStatus m_status;

    // List of debug logs displayed to the application.
    QString m_debugLogs;

    // Internal configuration object. It can be updated by
    // upnp or port forwarning methods.
    QJsonDocument m_config;
};

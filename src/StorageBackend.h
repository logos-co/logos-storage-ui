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
static const QUrl ECHO_PROVIDER("https://echo.codex.storage/");
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
    Q_PROPERTY(StorageStatus status READ status WRITE status NOTIFY statusChanged)
    Q_PROPERTY(QString cid READ cid NOTIFY cidChanged)
    Q_PROPERTY(int uploadProgress READ uploadProgress NOTIFY uploadProgressChanged)
    Q_PROPERTY(QString uploadStatus READ uploadStatus NOTIFY uploadStatusChanged)
    Q_PROPERTY(QVariantList manifests READ manifests NOTIFY manifestsChanged)
    Q_PROPERTY(qint64 quotaMaxBytes READ quotaMaxBytes NOTIFY quotaChanged)
    Q_PROPERTY(qint64 quotaUsedBytes READ quotaUsedBytes NOTIFY quotaChanged)
    Q_PROPERTY(qint64 quotaReservedBytes READ quotaReservedBytes NOTIFY quotaChanged)

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

    QString cid() const;
    QString debugLogs() const;
    StorageStatus status() const;
    QString configJson() const;
    int uploadProgress() const;
    QString uploadStatus() const;
    QVariantList manifests() const;
    qint64 quotaMaxBytes() const;
    qint64 quotaUsedBytes() const;
    qint64 quotaReservedBytes() const;

    static QJsonDocument defaultConfig();

    explicit StorageBackend(LogosAPI* logosAPI = nullptr, QObject* parent = nullptr);
    ~StorageBackend();

  public slots:
    LogosResult start(const QString& configJson = "");
    void destroy();
    void stop();
    void tryPeerConnect(const QString& peerId);
    void tryDebug();
    void tryUpload();
    void tryUploadFinalize();
    void exists(const QString& cid);
    void remove(const QString& cid);
    void fetch(const QString& cid);
    void tryUploadFile(const QUrl& url);
    void tryDownloadFile(const QString& cid, const QUrl& url);
    void dataDir();
    void version();
    void spr();
    void showPeerId();
    void downloadManifest(const QString& cid);
    void downloadManifests();
    void space();
    LogosResult init(const QString& configJson);
    void updateLogLevel(const QString& logLevel);
    void status(StorageStatus status);

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
    // Emit initCompleted on success.
    // Emit initFailed on failure.
    void reloadIfChanged(const QString& configJson);

    // Enables the upnp in the config
    // and re-create a context with the new configuration
    void enableUpnpConfig();

    // Enables the net external in the config
    // and re-create a context with the new configuration
    void enableNatExtConfig(int tcpPort);

    // This method try to get guidance about the resolution
    // of the misconfiguration for the node.
    // The idea is to check if:
    //
    // 1- upnp is enabled. In this case, the user should go back
    // and try to configure the port forwarding
    // 2- port forwarning is enabled. Indicate that the port has to
    // be free and open to remote connection.
    void guessResolution();

    // This method will ensure that the node is ready to be used.
    // 1- Make a call to debug function in the storage module and
    // make sure that the node has peer. If not, the UI should suggest
    // to modifiy the discovery port (8090) in the advance settings (to come).
    // 2- Ensure that the tcp port is open to remote connection. If not,
    // the UI should suggest to change go back and try another port and double
    // check that the port forwarding is enabled on the router.
    void checkNodeIsUp();

  signals:
    void ready();
    void startCompleted();
    void startFailed(const QString& error);
    void statusChanged();
    void debugLogsChanged();
    void stopCompleted();
    void cidChanged();
    void uploadProgressChanged();
    void uploadStatusChanged();
    void manifestsChanged();
    void quotaChanged();
    void initCompleted();
    void natExtConfigCompleted();
    void error(const QString& message);

  private slots:

  private:
    void setStatus(StorageStatus newStatus);
    void peerConnect(const QString& peerId);
    void debug(const QString& log);
    void reportError(const QString& message);

    LogosAPI* m_logosAPI;
    LogosModules* m_logos;
    StorageStatus m_status;
    QString m_debugLogs;
    QString m_cid;
    int m_uploadProgress = 0;
    QString m_uploadStatus = "";
    qint64 m_uploadTotalBytes = 0;
    qint64 m_uploadedBytes = 0;
    QVariantList m_manifests;
    qint64 m_quotaMaxBytes = 0;
    qint64 m_quotaUsedBytes = 0;
    qint64 m_quotaReservedBytes = 0;
    QJsonDocument m_config;
};

#pragma once
#include "logos_api.h"
#include "logos_sdk.h"
#include <QFile>
#include <QObject>
#include <QString>
#include <QStringList>
#include <QTimer>
#include <QtQml/qqml.h>

static const int RET_OK = 0;
static const int RET_PROGRESS = 3;

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
    Q_PROPERTY(QString configJson READ configJson NOTIFY configJsonChanged)
    Q_PROPERTY(int uploadProgress READ uploadProgress NOTIFY uploadProgressChanged)
    Q_PROPERTY(QString uploadStatus READ uploadStatus NOTIFY uploadStatusChanged)
    Q_PROPERTY(QVariantList manifests READ manifests NOTIFY manifestsChanged)
    Q_PROPERTY(qint64 quotaMaxBytes READ quotaMaxBytes NOTIFY quotaChanged)
    Q_PROPERTY(qint64 quotaUsedBytes READ quotaUsedBytes NOTIFY quotaChanged)
    Q_PROPERTY(qint64 quotaReservedBytes READ quotaReservedBytes NOTIFY quotaChanged)

  public:
    enum StorageStatus { Stopped = 0, Starting, Running, Stopping, Destroyed };
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

    Q_INVOKABLE static QString defaultDataDir();
    static QString getUserConfig();
    static QString getUserConfigPath();

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
    void reloadIfChanged(const QString& configJson);
    void status(StorageStatus status);
    QString buildConfig(const QString& dataDir, int discPort, int tcpPort);
    QString buildUpnpConfig(const QString& dataDir);
    QString buildNatExtConfig(const QString& dataDir, int tcpPort);
    QString buildConfigFromFile(const QString& path);
    void saveUserConfig(const QString& configJson);

  signals:
    void startCompleted();
    void startFailed(const QString& error);
    void statusChanged();
    void debugLogsChanged();
    void stopCompleted();
    void cidChanged();
    void configJsonChanged();
    void uploadProgressChanged();
    void uploadStatusChanged();
    void manifestsChanged();
    void quotaChanged();
    void initCompleted();

  private slots:

  private:
    void setStatus(StorageStatus newStatus);
    void peerConnect(const QString& peerId);
    void debug(const QString& log);

    LogosAPI* m_logosAPI;
    LogosModules* m_logos;
    StorageStatus m_status;
    QString m_debugLogs;
    QString m_cid;
    QString m_configJson;
    int m_uploadProgress = 0;
    QString m_uploadStatus = "";
    qint64 m_uploadTotalBytes = 0;
    qint64 m_uploadedBytes = 0;
    QVariantList m_manifests;
    qint64 m_quotaMaxBytes = 0;
    qint64 m_quotaUsedBytes = 0;
    qint64 m_quotaReservedBytes = 0;
};

#pragma once
#include "logos_api.h"
#include "logos_sdk.h"
#include <QObject>
#include <QString>
#include <QStringList>
#include <QTimer>
#include <QtQml/qqml.h>

static const int RET_OK = 0;
static const int RET_PROGRESS = 3;

class StorageBackend : public QObject {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString debugLogs READ debugLogs NOTIFY debugLogsChanged)
    Q_PROPERTY(StorageStatus status READ status NOTIFY statusChanged)
    Q_PROPERTY(QString cid READ cid NOTIFY cidChanged)
    Q_PROPERTY(QString configJson READ configJson NOTIFY configJsonChanged)
    Q_PROPERTY(int uploadProgress READ uploadProgress NOTIFY uploadProgressChanged)
    Q_PROPERTY(QString uploadStatus READ uploadStatus NOTIFY uploadStatusChanged)

  public:
    enum StorageStatus { Stopped = 0, Starting, Running, Stopping, Destroyed };
    Q_ENUM(StorageStatus)

    QString cid() const;
    QString debugLogs() const;
    StorageStatus status() const;
    QString configJson() const;
    int uploadProgress() const;
    QString uploadStatus() const;

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

  signals:
    void statusChanged();
    void debugLogsChanged();
    void stopped();
    void cidChanged();
    void configJsonChanged();
    void uploadProgressChanged();
    void uploadStatusChanged();

  private slots:

  private:
    void setStatus(StorageStatus newStatus);
    void peerConnect(const QString& peerId);
    void debug(const QString& log);
    void reloadIfChanged(const QString& configJson);

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
};

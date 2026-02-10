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
    Q_PROPERTY(bool canStartStop READ canStartStop NOTIFY statusChanged)
    Q_PROPERTY(bool isRunning READ isRunning NOTIFY statusChanged)
    Q_PROPERTY(bool showDebug READ showDebug WRITE setShowDebug NOTIFY showDebugChanged)
    Q_PROPERTY(QString startStopText READ startStopText NOTIFY statusChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusChanged)
    Q_PROPERTY(QString cidText READ cidText NOTIFY cidChanged)
    Q_PROPERTY(QString peerId READ peerId WRITE setPeerId NOTIFY peerIdChanged)
    Q_PROPERTY(QString debugLogs READ debugLogs NOTIFY debugLogsChanged)

  public:
    enum StorageStatus { Stopped = 0, Starting, Running, Stopping, Destroyed };
    Q_ENUM(StorageStatus)

    QString startStopText() const;
    QString statusText() const;
    QString cidText() const;
    QString peerId() const;
    QString debugLogs() const;

    bool showDebug() const;
    bool canStartStop() const;
    bool isRunning() const;

    void setPeerId(const QString& peerId);
    void setShowDebug(const bool showDebug);

    explicit StorageBackend(LogosAPI* logosAPI = nullptr, QObject* parent = nullptr);
    ~StorageBackend();

  public slots:
    void startStop();
    void destroy();
    bool isRunning();
    void stop();
    void tryPeerConnect();
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
    void updateLogLevel(const QString& logLevel);

    bool isInitialised() const;

  signals:
    void statusChanged();
    void peerIdChanged();
    void showDebugChanged();
    void debugLogsChanged();
    void cidChanged();
    void stopped();
    void test(int code, const QString& msg);

  private slots:

  private:
    void setStatus(StorageStatus newStatus, const QString& statusText);
    void peerConnect(const QString& peerId);
    void debug(const QString& log);
    void initStorage();

    StorageStatus m_status;
    LogosAPI* m_logosAPI;
    LogosModules* m_logos;

    QString m_statusText;
    QString m_cid;
    QString m_sessionId;
    QString m_peerId;
    QString m_debugLogs;

    bool m_showDebug;
};

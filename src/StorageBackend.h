#pragma once
#include "logos_api.h"
#include "logos_sdk.h"
#include <QObject>
#include <QString>
#include <QStringList>
#include <QTimer>
#include <QtQml/qqml.h>

static const int RET_OK = 0;

enum StorageStatus { Stopped = 0, Starting, Running, Stopping, Destroyed };

class StorageBackend : public QObject {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool canStartStop READ canStartStop NOTIFY statusChanged)
    Q_PROPERTY(bool isRunning READ isRunning NOTIFY statusChanged)
    Q_PROPERTY(QString startStopText READ startStopText NOTIFY statusChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusChanged)
    Q_PROPERTY(QString cidText READ cidText NOTIFY cidChanged)
    Q_PROPERTY(QString peerId READ peerId WRITE setPeerId NOTIFY peerIdChanged)
    Q_ENUM(StorageStatus)

  public:
    QString startStopText() const;
    QString statusText() const;
    QString cidText() const;
    QString peerId() const;

    bool canStartStop() const;
    void setPeerId(QString peerId);

    explicit StorageBackend(LogosAPI* logosAPI = nullptr, QObject* parent = nullptr);
    ~StorageBackend();

  public slots:
    void startStop();
    void destroy();
    void stop();
    void tryPeerConnect();
    void tryUpload();
    void tryUploadFinalize();
    void tryUploadFile(const QUrl& url);
    bool isRunning() const;
    bool isInitialised() const;

  signals:
    void statusChanged();
    void peerIdChanged();
    void cidChanged();
    void stopped();

  private slots:

  private:
    void setStatus(StorageStatus newStatus, QString statusText);
    void initStorage();
    void peerConnect(QString peerId);

    StorageStatus m_status;
    LogosAPI* m_logosAPI;
    LogosModules* m_logos;

    QString m_statusText;
    QString m_cid;
    QString m_sessionId;
    QString m_peerId;
};

#pragma once
#include "logos_api.h"
#include "logos_sdk.h"
#include <QObject>
#include <QString>
#include <QStringList>
#include <QTimer>
#include <QtQml/qqml.h>

static const int RET_OK = 0;

class StorageBackend : public QObject {
    Q_OBJECT
    QML_ELEMENT

  public:
    enum StorageStatus { Stopped = 0, Starting, Running, Stopping, Destroyed };
    Q_ENUM(StorageStatus)

    Q_PROPERTY(bool canStartStop READ canStartStop NOTIFY statusChanged)
    bool canStartStop() const;

    Q_PROPERTY(QString startStopText READ startStopText NOTIFY statusChanged)
    QString startStopText() const;

    Q_PROPERTY(QString statusText READ statusText NOTIFY statusChanged)
    QString statusText() const;

    explicit StorageBackend(LogosAPI* logosAPI = nullptr, QObject* parent = nullptr);
    ~StorageBackend();

  public slots:
    void startStop();
    void destroy();
    bool isRunning();
    bool isInitialised();
    void stop();

  signals:
    void statusChanged();
    void stopped();

  private slots:

  private:
    void setStatus(StorageStatus newStatus, QString statusText);
    void initStorage();

    StorageStatus m_status;
    LogosAPI* m_logosAPI;
    LogosModules* m_logos;

    QString m_statusText;
};

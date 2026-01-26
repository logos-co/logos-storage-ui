#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QTimer>
#include "logos_api.h"
#include "logos_api_client.h"
#include "logos_sdk.h"

class StorageBackend : public QObject {
    Q_OBJECT

public:
    enum StorageStatus {
        NotStarted = 0,
        Starting,
        Running,
        Stopping,
        Stopped,
        Error
    };
    Q_ENUM(StorageStatus)

    Q_PROPERTY(StorageStatus status READ status NOTIFY statusChanged)

    explicit StorageBackend(LogosAPI* logosAPI = nullptr, QObject* parent = nullptr);
    ~StorageBackend();

    StorageStatus status() const { return m_status; }

public slots:
    Q_INVOKABLE void startStorage();
    Q_INVOKABLE void stopStorage();

signals:
    void statusChanged();

private slots:
    // void onConnectedPeersResponse(const QVariantList& data);

private:
    void setStatus(StorageStatus newStatus);

    StorageStatus m_status;
    LogosAPI* m_logosAPI;
    LogosModules* m_logos;
};
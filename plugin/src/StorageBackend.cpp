#include "StorageBackend.h"
#include <QDebug>
#include <QDateTime>
#include <QLocale>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

StorageBackend::StorageBackend(LogosAPI* logosAPI, QObject* parent)
    : QObject(parent),
      m_status(NotStarted),
      m_logosAPI(nullptr),
      m_logos(nullptr)
{
    qDebug() << "Initializing StorageBackend...";
    
    if (logosAPI) {
        m_logosAPI = logosAPI;
    } else {
        m_logosAPI = new LogosAPI("core", this);
    }
    
    m_logos = new LogosModules(m_logosAPI);
}

StorageBackend::~StorageBackend()
{
    stopStorage();
}

void StorageBackend::setStatus(StorageStatus newStatus)
{
    if (m_status != newStatus) {
        m_status = newStatus;
        emit statusChanged();
        qDebug() << "StorageBackend: Status changed to" << m_status;
    }
}

void StorageBackend::startStorage()
{
    setStatus(Starting);

    auto& storageModule = m_logos->storage_module;

    QString configStr = R"({

    })";

    if (!storageModule.initStorage(configStr)) {
        setStatus(Error);
        return;
    }

    // Subscribe to connectedPeersResponse events
    // if (!storageModule.on("connectedPeersResponse", [this](const QVariantList& data) {
    //         if (data.size() < 1) {
    //             qWarning() << "StorageBackend: connectedPeersResponse payload missing fields";
    //             return;
    //         }
    //         onConnectedPeersResponse(data);
    //     })) {
    //     qWarning() << "StorageBackend: failed to subscribe to connectedPeersResponse events";
    // }

    if (!storageModule.startStorage()) {
        setStatus(Error);
        return;
    }

    setStatus(Running);

    // Refresh peers and metrics after a delay to allow Storage to fully start
    // QTimer::singleShot(1000, this, [this]() {
    //     refreshPeers();
    //     refreshMetrics();
    // });
}

void StorageBackend::stopStorage()
{
    if (m_status != Running && m_status != Starting) {
        return;
    }

    setStatus(Stopping);

    auto& storageModule = m_logos->storage_module;

    if (!storageModule.stopStorage()) {
        qWarning() << "StorageBackend::stopStorage: stopStorage() returned false";
        setStatus(Error);
        return;
    }

    setStatus(Stopped);
}

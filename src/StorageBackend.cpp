#include "StorageBackend.h"
#include <QDateTime>
#include <QDebug>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocale>

StorageBackend::StorageBackend(LogosAPI* logosAPI, QObject* parent)
    : QObject(parent), m_status(Destroyed), m_logosAPI(nullptr), m_logos(nullptr) {
    qDebug() << "Initializing StorageBackend...";
    
    if (logosAPI) {
        m_logosAPI = logosAPI;
    } else {
        m_logosAPI = new LogosAPI("core", this);
    }
    
    m_logos = new LogosModules(m_logosAPI);

    initStorage();
}

StorageBackend::~StorageBackend()
{
    m_logosAPI = nullptr;
    m_logos = nullptr;
}

void StorageBackend::initStorage() {
    qDebug() << "StorageBackend::initStorage called";

    bool result = m_logos->storage_module.init("{}");

    qDebug() << "StorageBackend::initStorage: init result =" << result;

    if (!result) {
        qDebug() << "StorageBackend: Failed to initialise Storage module.";
        setStatus(Destroyed, "Failed to initialise Storage module.");
        return;
    }

    setStatus(Stopped, "Storage module ready.");

    if (!m_logos->storage_module.on("storageStart", [this](const QVariantList& data) {
            int code = data[0].toInt();

            if (code != RET_OK) {
                qDebug() << "StorageBackend: storageStart event failure with code" << code;
                setStatus(Stopped, "Failed to start Storage module.");
            } else {
                qDebug() << "StorageBackend: storageStart event success";
                setStatus(Running, "Storage module started.");
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageStart events";
    }

    if (!m_logos->storage_module.on("storageStop", [this](const QVariantList& data) {
            int code = data[0].toInt();

            if (code != RET_OK) {
                qDebug() << "StorageBackend: storageStop event failure with code" << code;
                setStatus(Running, "Failed to stop Storage module.");
            } else {
                qDebug() << "StorageBackend: storageStop event success";
                setStatus(Stopped, "Storage module stopped.");
                emit stopped();
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageStop events";
    }

    startStop();
}

void StorageBackend::setStatus(StorageStatus newStatus, QString statusText) {
    if (m_status != newStatus || m_statusText != statusText) {
        m_status = newStatus;
        m_statusText = statusText;
        emit statusChanged();
        qDebug() << "StorageBackend: Status changed to" << m_status;
    }
}

void StorageBackend::startStop() {
    qDebug() << "StorageBackend: startStop method called";

    if (m_status == Destroyed || m_status == Starting || m_status == Stopping) {
        qDebug() << "StorageBackend: Cannot start/stop Storage in current state:" << m_status;
        return;
    }

    if (m_status != Running) {
        qDebug() << "StorageBackend: Starting Storage...";
        setStatus(Starting, "Starting Storage module...");

        bool result = m_logos->storage_module.start();

        if (!result) {
            qDebug() << "StorageBackend: Failed to start Storage.";
            setStatus(Stopped, "Failed to start Storage module.");
            return;
        }

        qDebug() << "StorageBackend: start command sent, waiting for events.";
    } else {
        stop();
    }
}

void StorageBackend::stop() {
    qDebug() << "StorageBackend: Stopping Storage...";
    setStatus(Stopping, "Stopping Storage module...");

    bool result = m_logos->storage_module.stop();

    if (!result) {
        qDebug() << "StorageBackend: Failed to stop Storage.";
        setStatus(Running, "Failed to stop Storage module.");
        return;
    }

    qDebug() << "StorageBackend: stop command sent, waiting for events.";
}

void StorageBackend::destroy() {
    qDebug() << "StorageBackend: destroy method called";

    StorageStatus status = m_status;
    int result = m_logos->storage_module.destroy();

    if (!result) {
        qDebug() << "StorageBackend: Failed to destroy Storage module." << result;
        setStatus(status, "Failed to destroy Storage module.");
        return;
    }

    qDebug() << "StorageBackend: Storage module destroyed.";
}

QString StorageBackend::statusText() const { return m_statusText; }

QString StorageBackend::startStopText() const {
    if (m_status != Running) {
        return "Start";
    } else {
        return "Stop";
    }
}

bool StorageBackend::canStartStop() const { return m_status == Running || m_status == Stopped; }

bool StorageBackend::isRunning() { return m_status == Running; }

bool StorageBackend::isInitialised() { return m_status != Destroyed; }

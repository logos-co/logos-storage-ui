#include "StorageBackend.h"
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
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

    // Check if file config.json exists
    qDebug() << QDir::currentPath();

    QString jsonConfig = "{}";

    QFileInfo info("config.json");
    if (info.exists() && info.isFile()) {
        qDebug() << "StorageBackend::initStorage found config.json";

        QFile file("config.json");
        if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            jsonConfig = QString::fromUtf8(file.readAll());

            qDebug() << "StorageBackend::initStorage found config=" << jsonConfig;
        }
    }

    bool result = m_logos->storage_module.init(jsonConfig);

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

    if (!m_logos->storage_module.on("storageConnect", [this](const QVariantList& data) {
            int code = data[0].toInt();

            if (code != RET_OK) {
                qDebug() << "StorageBackend: storageConnect event failure with code" << code;
            } else {
                qDebug() << "StorageBackend: storageConnect event success";
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageConnect events";
    }

    if (!m_logos->storage_module.on("storageUploadProgress", [this](const QVariantList& data) {
            int code = data[0].toInt();

            if (code != RET_OK) {
                qDebug() << "StorageBackend: storageUploadProgress event failure with code" << code;
            } else {
                QString sessionId = data[1].toString();
                int len = data[2].toInt();
                qDebug() << "StorageBackend: storageUploadProgress event success with sessionId =" << sessionId
                         << "len =" << len;
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageUploadProgress events";
    }

    if (!m_logos->storage_module.on("storageUploadDone", [this](const QVariantList& data) {
            int code = data[0].toInt();

            if (code != RET_OK) {
                qDebug() << "StorageBackend: storageUploadDone event failure with code" << code;
            } else {
                QString sessionId = data[1].toString();
                m_cid = data[2].toString();
                qDebug() << "StorageBackend: storageUploadDone event success with sessionId =" << sessionId
                         << "cid =" << m_cid;
                emit cidChanged();
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageUploadProgress events";
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

bool StorageBackend::isRunning() const { return m_status == Running; }

QString StorageBackend::peerId() const { return m_peerId; };

void StorageBackend::setPeerId(QString peerId) { m_peerId = peerId; }

bool StorageBackend::isInitialised() const { return m_status != Destroyed; }

void StorageBackend::tryPeerConnect() {
    qDebug() << "StorageBackend: tryPeerConnect called with peerId=" << m_peerId;

    // QString peerId = m_logos->storage_module.peerId();

    // if (peerId.isEmpty()) {
    //     qDebug() << "StorageBackend: Peer ID is empty.";
    //     return;
    // }
    bool result = m_logos->storage_module.connect(m_peerId, QStringList());

    qDebug() << "StorageBackend: peerConnect result =" << result;
    // QString filename = "test.txt";
    // QString sessionId = m_logos->storage_module.uploadInit(filename);

    // qDebug() << "StorageBackend: uploadInit sessionId =" << sessionId;

    // bool result = m_logos->storage_module.uploadCancel(sessionId);

    // qDebug() << "StorageBackend: uploadCancel result =" << result;
}

void StorageBackend::tryUpload() {
    qDebug() << "StorageBackend: tryUpload called";

    QString filename = "test.txt";
    m_sessionId = m_logos->storage_module.uploadInit(filename);

    qDebug() << "StorageBackend: uploadInit sessionId =" << m_sessionId;

    QByteArray chunk = "Sample data chunk for upload.";
    bool result = m_logos->storage_module.uploadChunk(m_sessionId, chunk);

    qDebug() << "StorageBackend: uploadChunk result =" << result;
}

void StorageBackend::tryUploadFinalize() {
    qDebug() << "StorageBackend: tryFinalize called";

    m_cid = m_logos->storage_module.uploadFinalize(m_sessionId);

    qDebug() << "StorageBackend: uploadFinalize result =" << m_cid;

    emit cidChanged();
}

void StorageBackend::tryUploadFile(const QUrl& url) {
    qDebug() << "StorageBackend: tryUploadFile called";

    if (!url.isLocalFile()) {
        qWarning() << "Not a local file";
        m_statusText = "The provided URL is not a local file.";
        emit statusChanged();
        return;
    }

    // QString filename = url.toLocalFile();

    // // QString filename = "/home/arnaud/Work/logos/logos-storage-ui/README.md";
    // QString sessionId = m_logos->storage_module.uploadInit(filename);

    // qDebug() << "StorageBackend: uploadInit sessionId =" << sessionId;

    QString sessionId = m_logos->storage_module.uploadFromPath(url);

    qDebug() << "StorageBackend: uploadFromPath result =" << sessionId;
}

QString StorageBackend::cidText() const {
    if (m_cid.isEmpty()) {
        return "No CID available.";
    } else {
        return m_cid;
    }
}

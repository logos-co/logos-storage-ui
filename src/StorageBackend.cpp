#include "StorageBackend.h"
#include <QDateTime>
#include <QDebug>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocale>

// StorageBackend is responsible for managing the interaction with the storage module.
// It is mocked in the QML.
// There are currently 2 ways to display debug information:
// - the first one is to log only in the console using qDebug/qWarning. This is basically
// for developers: entering a function, sending a command to the storage module...
// - the second one is to use the "debug" helper that logs both in the console and in a
// QString property that can be displayed in the UI. This is more for users to understand
// what is happening.
StorageBackend::StorageBackend(LogosAPI* logosAPI, QObject* parent)
    : QObject(parent), m_status(Destroyed), m_logosAPI(nullptr), m_logos(nullptr) {
    qDebug() << "Initializing StorageBackend...";
    
    if (logosAPI) {
        m_logosAPI = logosAPI;
    } else {
        m_logosAPI = new LogosAPI("core", this);
    }
    
    m_logos = new LogosModules(m_logosAPI);
    m_showDebug = false;

    initStorage();
}

StorageBackend::~StorageBackend()
{
    m_logosAPI = nullptr;
    m_logos = nullptr;
}

void StorageBackend::initStorage() {
    qDebug() << "StorageBackend::initStorage called";

    QString jsonConfig = "{}";

    QFileInfo info("config.json");
    if (info.exists() && info.isFile()) {
        debug("config.json is found, let's try to load it...");

        QFile file("config.json");
        if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            jsonConfig = QString::fromUtf8(file.readAll());

            debug("config.json content is: " + jsonConfig);
        } else {
            debug("Failed to load config.json");
        }
    }

    LogosResult result = m_logos->storage_module.init(jsonConfig);

    qDebug() << "StorageBackend::initStorage: init result =" << result.success;

    if (!result.success) {
        setStatus(Destroyed, result.getValue<QString>());
        return;
    }

    setStatus(Stopped, "Storage module ready.");

    if (!m_logos->storage_module.on("storageStart", [this](const QVariantList& data) {
            bool success = data[0].toBool();

            if (!success) {
                QString message = data[1].toString();
                setStatus(Stopped, "Failed to start Storage module:" + message);
            } else {
                setStatus(Running, "Storage module started.");
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageStart events";
    }

    if (!m_logos->storage_module.on("storageStop", [this](const QVariantList& data) {
            bool success = data[0].toBool();

            if (!success) {
                QString message = data[1].toString();
                setStatus(Running, "Failed to stop Storage module:" + message);
            } else {
                setStatus(Stopped, "Storage module stopped.");
                emit stopped();
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageStop events";
    }

    if (!m_logos->storage_module.on("storageConnect", [this](const QVariantList& data) {
            bool success = data[0].toBool();

            if (!success) {
                QString message = data[1].toString();
                debug("Failed to connect: " + message);
            } else {
                // TODO add the peer id
                debug("Successfully connected to peer.");
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageConnect events";
    }

    if (!m_logos->storage_module.on("storageUploadProgress", [this](const QVariantList& data) {
            bool success = data[0].toBool();

            if (!success) {
                QString message = data[1].toString();
                debug("Failure during upload progress: " + message);
            } else {
                QString sessionId = data[1].toString();
                int len = data[2].toInt();
                // debug("Uploaded " + QString::number(len) + " bytes for session " + sessionId);
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageUploadProgress events";
    }

    if (!m_logos->storage_module.on("storageUploadDone", [this](const QVariantList& data) {
            bool success = data[0].toBool();

            if (!success) {
                QString message = data[1].toString();
                debug("Failed to upload: " + message);
            } else {
                QString sessionId = data[1].toString();
                m_cid = data[2].toString();
                emit cidChanged();
                debug("Upload completed for session " + sessionId + " with CID " + m_cid);
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageUploadProgress events";
    }

    if (!m_logos->storage_module.on("storageDownloadProgress", [this](const QVariantList& data) {
            bool success = data[0].toBool();

            if (!success) {
                QString message = data[1].toString();
                debug("Failure during download progress: " + message);
            } else {
                QString sessionId = data[1].toString();
                int len = data[2].toInt();
                debug("Downloaded " + QString::number(len) + " bytes for session " + sessionId);
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageDownloadProgress events";
    }

    if (!m_logos->storage_module.on("storageDownloadDone", [this](const QVariantList& data) {
            bool success = data[0].toBool();

            if (!success) {
                QString message = data[1].toString();
                debug("Failed to download: " + message);
            } else {
                QString sessionId = data[1].toString();
                m_cid = data[2].toString();
                emit cidChanged();
                debug("Download completed for session " + sessionId + " with CID " + m_cid);
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageDownloadProgress events";
    }

    startStop();
}

void StorageBackend::setStatus(StorageStatus newStatus, const QString& statusText) {
    if (m_status != newStatus || m_statusText != statusText) {
        m_status = newStatus;
        m_statusText = statusText;
        emit statusChanged();

        debug(statusText);
    }
}

void StorageBackend::startStop() {
    qDebug() << "StorageBackend: startStop method called";

    // QString s = "hello";
    // emit test(0, s);
    if (m_status == Destroyed || m_status == Starting || m_status == Stopping) {
        // TODO display the m_status properly
        debug("StorageBackend: Cannot start/stop Storage in current state:" + m_status);
        return;
    }

    if (m_status != Running) {
        setStatus(Starting, "Starting Storage module...");

        auto result = m_logos->storage_module.start();

        if (!result.success) {
            setStatus(Stopped, result.getValue<QString>());
            return;
        }

        qDebug() << "StorageBackend: start command sent, waiting for events.";
    } else {
        stop();
    }
}

void StorageBackend::stop() {
    setStatus(Stopping, "Stopping Storage module...");

    auto result = m_logos->storage_module.stop();

    if (!result.success) {
        setStatus(Running, result.getValue<QString>());
        return;
    }

    qDebug() << "StorageBackend: stop command sent, waiting for events.";
}

void StorageBackend::destroy() {
    qDebug() << "StorageBackend: destroy method called";

    StorageStatus status = m_status;
    auto result = m_logos->storage_module.destroy();

    if (!result.success) {
        setStatus(status, result.getValue<QString>());
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

QString StorageBackend::peerId() const { return m_peerId; };

void StorageBackend::setPeerId(const QString& peerId) { m_peerId = peerId; }

bool StorageBackend::showDebug() const { return m_showDebug; };

void StorageBackend::setShowDebug(const bool showDebug) {
    m_showDebug = showDebug;
    emit showDebugChanged();
}

QString StorageBackend::debugLogs() const { return m_debugLogs; };

void StorageBackend::debug(const QString& log) {
    if (!m_debugLogs.isEmpty()) {
        m_debugLogs += "\n";
    }

    QString timestamp = QDateTime::currentDateTime().toString(Qt::ISODate);
    m_debugLogs += timestamp + ": " + log;
    emit debugLogsChanged();

    qDebug() << "StorageBackend: " << log;
}

bool StorageBackend::isInitialised() const { return m_status != Destroyed; }

void StorageBackend::tryDebug() {
    auto result = m_logos->storage_module.debug();

    debug("Debug " + result.getValue<QString>());
}
void StorageBackend::tryPeerConnect() {
    qDebug().noquote() << "StorageBackend: tryPeerConnect called with peerId=" << m_peerId;

    // LogosResult result2 = m_logos->storage_module.space();
    // QVariantMap space = result2.getValue<QVariantMap>();
    // int quotaMaxBytes = space["quotaMaxBytes"].toInt();
    // int quotaUsedBytes = space["quotaUsedBytes"].toInt();
    // int quotaReservedBytes = space["quotaReservedBytes"].toInt();

    // int totalBlocks = result2.getValue<int>("totalBlocks");

    // debug("totalBlocks " + QString::number(totalBlocks));
    // debug("quotaMaxBytes " + QString::number(quotaMaxBytes));
    // debug("quotaUsedBytes " + QString::number(quotaUsedBytes));
    // debug("quotaReservedBytes " + QString::number(quotaReservedBytes));

    // LogosResult result = m_logos->storage_module.dataDir();
    // QString myDataDir = result.getValue<QString>();
    // qDebug() << "StorageBackend: tryPeerConnect dataDir=" << myDataDir;

    // QString peerId = m_logos->storage_module.peerId();

    // if (peerId.isEmpty()) {
    //     qDebug() << "StorageBackend: Peer ID is empty.";
    //     return;
    // }
    auto result = m_logos->storage_module.connect(m_peerId, QStringList());

    qDebug() << "StorageBackend: peerConnect result =" << result.value;
    // auto result = m_logos->storage_module.debug();

    // debug("Debug " + result.getValue<QString>());
    // QString filename = "test.txt";
    // QString sessionId = m_logos->storage_module.uploadInit(filename);

    // qDebug() << "StorageBackend: uploadInit sessionId =" << sessionId;

    // bool result = m_logos->storage_module.uploadCancel(sessionId);

    // qDebug() << "StorageBackend: uploadCancel result =" << result;
}

void StorageBackend::tryUpload() {
    qDebug() << "StorageBackend: tryUpload called";

    // QString filename = "test.txt";
    // m_sessionId = m_logos->storage_module.uploadInit(filename);

    // qDebug() << "StorageBackend: uploadInit sessionId =" << m_sessionId;

    // QByteArray chunk = "Sample data chunk for upload.";
    // bool result = m_logos->storage_module.uploadChunk(m_sessionId, chunk);

    // qDebug() << "StorageBackend: uploadChunk result =" << result;
}

void StorageBackend::tryUploadFinalize() {
    qDebug() << "StorageBackend: tryFinalize called";

    // m_cid = m_logos->storage_module.uploadFinalize(m_sessionId);

    // qDebug() << "StorageBackend: uploadFinalize result =" << m_cid;

    // emit cidChanged();
}

void StorageBackend::tryUploadFile(const QUrl& url) {
    qDebug() << "StorageBackend: tryUploadFile called";
    qDebug() << "  URL toString():" << url.toString();
    qDebug() << "  URL toLocalFile():" << url.toLocalFile();
    qDebug() << "  URL path():" << url.path();

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

    // QtConcurrent::run([this, url]() {
    //     LogosResult result = m_logos->storage_module.uploadUrl(url);

    // Go back to the main thread
    //     // Better to use signal
    //     QMetaObject::invokeMethod(
    //         this,
    //         [this, result]() {
    //             if (!result.success) {
    //                 setStatus(m_status, result.getValue<QString>());
    //                 return;
    //             }

    //             QString sessionId = result.value.value<QString>();

    //             qDebug() << "StorageBackend: uploadFromPath result =" << sessionId;
    //         },
    //         Qt::QueuedConnection);
    // });
    // QTimer::singleShot(0, this, [this, url]() {
    LogosResult result = m_logos->storage_module.uploadUrl(url);

    if (!result.success) {
        setStatus(m_status, result.getValue<QString>());
        return;
    }

    QString sessionId = result.value.value<QString>();
    //});
    qDebug() << "StorageBackend: tryUploadFile result =" << sessionId;
}

// void StorageBackend::tryUploadFile(const QUrl& url) {
//     qDebug() << "StorageBackend:tryUploadFile called";

//     if (!url.isLocalFile()) {
//         qWarning() << "Not a local file";
//         m_statusText = "The provided URL is not a local file.";
//         emit statusChanged();
//         return;
//     }

//     QString localPath = url.toLocalFile();
//     qDebug() << "  Uploading from:" << localPath;

//     QFile file(localPath);
//     if (!file.open(QIODevice::ReadOnly)) {
//         qWarning() << "Cannot open file for reading:" << localPath;
//         m_statusText = "Cannot open file for reading: " + localPath;
//         emit statusChanged();
//         return;
//     }

//     const qint64 chunkSize = 1024 * 64; // 64KB
//     qint64 totalSize = file.size();
//     qint64 bytesRead = 0;

//     QFileInfo fileInfo(localPath);
//     QString filename = fileInfo.fileName();

//     LogosResult result = m_logos->storage_module.uploadInit("test.txt", chunkSize);

//     if (!result.success) {
//         debug(result.getValue<QString>());
//         file.close();
//         return;
//     }

//     QString sessionId = result.getValue<QString>();

//     while (!file.atEnd()) {
//         QByteArray chunk = file.read(chunkSize);
//         bytesRead += chunk.size();

//         qDebug() << "  Read chunk:" << chunk.size() << "bytes"
//                  << "Progress:" << bytesRead << "/" << totalSize;

//         result = m_logos->storage_module.uploadChunk(sessionId, chunk);

//         if (!result.success) {
//             qWarning("StorageBackend:tryUploadFile failed to send uploadChunk command");
//             file.close();
//             return;
//         }

//         // Calculate progress percentage
//         int progress = (bytesRead * 100) / totalSize;
//         qDebug() << "  Progress:" << progress << "%";
//     }

//     file.close();

//     result = m_logos->storage_module.uploadFinalize(sessionId);

//     if (!result.success) {
//         qWarning("StorageBackend:tryUploadFile failed to send uploadFinalize command");
//         file.close();
//         return;
//     }

//     qDebug() << "Upload complete, CID:" << result.getValue<QString>();

//     file.close();
// }

void StorageBackend::tryDownloadFile(const QString& cid, const QUrl& url) {
    qDebug() << "StorageBackend: tryDownloadFile called";

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

    LogosResult result = m_logos->storage_module.downloadToUrl(cid, url, false);

    if (!result.success) {
        setStatus(m_status, result.getValue<QString>());
        return;
    }

    QString sessionId = result.value.value<QString>();

    qDebug() << "StorageBackend: tryDownloadFile result =" << sessionId;
}

void StorageBackend::exists(const QString& cid) {
    qDebug() << "StorageBackend::exists called";

    LogosResult result = m_logos->storage_module.exists(cid);

    if (!result.success) {
        debug("StorageBackend::exists failed with error=" + result.getValue<QString>());
        return;
    }

    debug("Does " + cid + " exists ? " + QVariant(result.getValue<bool>()).toString());
}

void StorageBackend::remove(const QString& cid) {
    qDebug() << "StorageBackend::remove called";

    LogosResult result = m_logos->storage_module.remove(cid);

    if (!result.success) {
        debug("StorageBackend::remove failed with error=" + result.getValue<QString>());
        return;
    }

    debug("Cid " + cid + " removed.");
}

void StorageBackend::fetch(const QString& cid) {
    qDebug() << "StorageBackend::fetch called";

    LogosResult result = m_logos->storage_module.fetch(cid);

    if (!result.success) {
        debug("StorageBackend::fetch failed with error=" + result.getValue<QString>());
        return;
    }

    debug("Cid " + cid + " fetched.");
}

void StorageBackend::version() {
    qDebug() << "StorageBackend::version called";

    LogosResult result = m_logos->storage_module.version();

    if (!result.success) {
        debug("StorageBackend::version failed with error=" + result.getValue<QString>());
        return;
    }

    debug("Version: " + result.getValue<QString>());
}

void StorageBackend::showPeerId() {
    qDebug() << "StorageBackend::peerId called";

    LogosResult result = m_logos->storage_module.peerId();

    if (!result.success) {
        debug("StorageBackend::peerId failed with error=" + result.getValue<QString>());
        return;
    }

    debug("Peer ID: " + result.getValue<QString>());
}

void StorageBackend::spr() {
    qDebug() << "StorageBackend::spr called";

    LogosResult result = m_logos->storage_module.spr();

    if (!result.success) {
        debug("StorageBackend::spr failed with error=" + result.getValue<QString>());
        return;
    }

    debug("SPR: " + result.getValue<QString>());
}

void StorageBackend::dataDir() {
    qDebug() << "StorageBackend::dataDir called";

    LogosResult result = m_logos->storage_module.dataDir();

    if (!result.success) {
        debug("StorageBackend::dataDir failed with error=" + result.getValue<QString>());
        return;
    }

    debug("Data dir: " + result.getValue<QString>());
}

void StorageBackend::downloadManifest(const QString& cid) {
    qDebug() << "StorageBackend::downloadManifest called with cid=" << cid;

    LogosResult result = m_logos->storage_module.downloadManifest(cid);

    if (!result.success) {
        debug("StorageBackend::downloadManifest failed with error=" + result.getValue<QString>());
        return;
    }

    debug("Manifest tree cid: " + result.getValue<QString>("treeCid"));
    debug(QString("Manifest datasetSize %1").arg(result.getValue<int>("datasetSize")));
    debug(QString("Manifest blockSize %1").arg(result.getValue<int>("blockSize")));
    debug("Manifest filename: " + result.getValue<QString>("filename"));
    debug("Manifest mimetype: " + result.getValue<QString>("mimetype"));
}

void StorageBackend::downloadManifests() {
    qDebug() << "StorageBackend::downloadManifests called";

    LogosResult result = m_logos->storage_module.manifests();

    if (!result.success) {
        debug("StorageBackend::downloadManifests failed with error=" + result.getValue<QString>());
        return;
    }

    QVariantList manifestsList = result.getValue<QVariantList>();
    int count = manifestsList.size();

    debug(QString("Found %1 manifests").arg(count));

    // for (const QVariant& manifestVariant : manifestsList) {
    //     QVariantMap manifest = manifestVariant.toMap();

    //     QString cid = manifest["cid"].toString();
    //     QString treeCid = manifest["treeCid"].toString();
    //     QString filename = manifest["filename"].toString();
    //     qint64 datasetSize = manifest["datasetSize"].toLongLong();

    //     debug(QString("Manifest: %1, treeCid: %2, size: %3")
    //               .arg(filename)
    //               .arg(treeCid.isEmpty() ? "EMPTY" : treeCid)
    //               .arg(datasetSize));
    // }
}

void StorageBackend::space() {
    qDebug() << "StorageBackend::space called";

    LogosResult result = m_logos->storage_module.space();

    if (!result.success) {
        debug("StorageBackend::space failed with error=" + result.getValue<QString>());
        return;
    }

    debug(QString("Space datasetSize %1").arg(result.getValue<int>("totalBlocks")));
    debug(QString("Space quotaMaxBytes %1").arg(result.getValue<int>("quotaMaxBytes")));
    debug(QString("Space quotaUsedBytes %1").arg(result.getValue<int>("quotaUsedBytes")));
    debug(QString("Space quotaReservedBytes %1").arg(result.getValue<int>("quotaReservedBytes")));
}

void StorageBackend::updateLogLevel(const QString& logLevel) {
    qDebug() << "StorageBackend::updateLogLevel called with logLevel=" << logLevel;

    LogosResult result = m_logos->storage_module.updateLogLevel(logLevel);

    if (!result.success) {
        debug("StorageBackend::updateLogLevel failed with error=" + result.getValue<QString>());
        return;
    }

    debug("Log level updated to " + logLevel);
}

QString StorageBackend::cidText() const {
    if (m_cid.isEmpty()) {
        return "No CID available.";
    } else {
        return m_cid;
    }
}

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
}

StorageBackend::~StorageBackend()
{
    m_logosAPI = nullptr;
    m_logos = nullptr;
}

LogosResult StorageBackend::init(const QString& configJson = "{}") {
    qDebug() << "StorageBackend::initStorage called";

    if (configJson != "{}") {
        m_configJson = configJson;
    }

    bool result = m_logos->storage_module.init(m_configJson);

    qDebug() << "StorageBackend::initStorage: init";

    if (!result) {
        setStatus(Destroyed);
        debug("Failed to init storage");
        return {false, "", "Filed to init storage"};
    }

    setStatus(Stopped);

    if (!m_logos->storage_module.on("storageStart", [this](const QVariantList& data) {
            bool success = data[0].toBool();

            if (!success) {
                QString message = data[1].toString();
                setStatus(Stopped);
                debug("Failed to start Storage module:" + message);
                emit startFailed(message);
            } else {
                setStatus(Running);
                debug("Storage module started.");
                QMetaObject::invokeMethod(this, &StorageBackend::downloadManifests, Qt::QueuedConnection);
                emit startCompleted();
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageStart events";
    }

    if (!m_logos->storage_module.on("storageStop", [this](const QVariantList& data) {
            bool success = data[0].toBool();

            if (!success) {
                QString message = data[1].toString();
                setStatus(Running);
                debug("Failed to stop Storage module:" + message);
            } else {
                setStatus(Stopped);
                debug("Storage module stopped.");
            }

            emit stopCompleted();
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
                m_uploadStatus = "Error: " + message;
                emit uploadStatusChanged();
            } else {
                QString sessionId = data[1].toString();
                qint64 len = data[2].toLongLong();

                m_uploadedBytes += len;

                // Calcule le pourcentage
                if (m_uploadTotalBytes > 0) {
                    m_uploadProgress = (m_uploadedBytes * 100) / m_uploadTotalBytes;
                }

                m_uploadStatus = QString("Uploading: %1 / %2 bytes (%3%)")
                    .arg(m_uploadedBytes)
                    .arg(m_uploadTotalBytes)
                    .arg(m_uploadProgress);

                emit uploadProgressChanged();
                emit uploadStatusChanged();
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageUploadProgress events";
    }

    if (!m_logos->storage_module.on("storageUploadDone", [this](const QVariantList& data) {
            bool success = data[0].toBool();

            if (!success) {
                QString message = data[1].toString();
                debug("Failed to upload: " + message);
                m_uploadProgress = 0;
                m_uploadStatus = "Upload failed";
                emit uploadProgressChanged();
                emit uploadStatusChanged();
            } else {
                QString sessionId = data[1].toString();
                m_cid = data[2].toString();
                emit cidChanged();
                debug("Upload completed for session " + sessionId + " with CID " + m_cid);

                // Complète la progress bar
                m_uploadProgress = 100;
                m_uploadStatus = "Upload completed!";
                emit uploadProgressChanged();
                emit uploadStatusChanged();
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

    if (configJson != "{}") {
        m_configJson = configJson;
        emit configJsonChanged();
        debug("new config is: " + m_configJson);
    }

    return {true, ""};
}

void StorageBackend::setStatus(StorageStatus newStatus) {
    if (m_status != newStatus) {
        m_status = newStatus;
        emit statusChanged();
    }
}

LogosResult StorageBackend::start(const QString& newConfigJson) {
    qDebug() << "StorageBackend: start method called";

    if (newConfigJson != "") {
        reloadIfChanged(newConfigJson);
    }

    if (m_status != Stopped) {
        debug("The Storage Module is not initialised properly.");
        return {false, "", "The Storage Module is not initialised properly."};
    }

    if (m_status == Running) {
        debug("The Storage Module is already started.");
        return {false, "", "The Storage Module is already started."};
    }

    setStatus(Starting);
    debug("Starting Storage module...");

    auto result = m_logos->storage_module.start();

    if (!result) {
        setStatus(Stopped);
        debug("Failed to start storage");
        return {false, "", "Failed to start storage"};
    }

    qDebug() << "StorageBackend: start command sent, waiting for events.";

    return {true, ""};
}

void StorageBackend::stop() {
    qDebug() << "StorageBackend: stop method called";

    if (m_status == StorageStatus::Stopping) {
        debug("The Storage Module is already stopping.");
        emit stopCompleted();
        return;
    }

    if (m_status != StorageStatus::Running) {
        debug("The Storage Module is not started.");
        emit stopCompleted();
        return;
    }

    setStatus(Stopping);
    debug("Stopping Storage module...");

    auto result = m_logos->storage_module.stop();

    if (!result.success) {
        setStatus(Running);
        debug(result.getError());
        return;
    }

    qDebug() << "StorageBackend: stop command sent, waiting for events.";
}

void StorageBackend::destroy() {
    qDebug() << "StorageBackend: destroy method called";

    StorageStatus status = m_status;
    auto result = m_logos->storage_module.destroy();

    if (!result.success) {
        debug(result.getError());
        return;
    }

    qDebug() << "StorageBackend: Storage module destroyed.";
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

void StorageBackend::tryDebug() {
    auto result = m_logos->storage_module.debug();

    debug("Debug " + result.getString());
}
void StorageBackend::tryPeerConnect(const QString& peerId) {
    qDebug().noquote() << "StorageBackend: tryPeerConnect called with peerId=" << peerId;

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
    // QString myDataDir = result.getString();
    // qDebug() << "StorageBackend: tryPeerConnect dataDir=" << myDataDir;

    // QString peerId = m_logos->storage_module.peerId();

    // if (peerId.isEmpty()) {
    //     qDebug() << "StorageBackend: Peer ID is empty.";
    //     return;
    // }
    auto result = m_logos->storage_module.connect(peerId, QStringList());

    qDebug() << "StorageBackend: peerConnect result =" << result.value;
    // auto result = m_logos->storage_module.debug();

    // debug("Debug " + result.getString());
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
        debug("The provided URL is not a local file.");
        return;
    }

    // Reset and initialize progress tracking
    m_uploadProgress = 0;
    m_uploadedBytes = 0;
    m_uploadTotalBytes = QFileInfo(url.toLocalFile()).size();
    m_uploadStatus = "Starting upload...";
    emit uploadProgressChanged();
    emit uploadStatusChanged();

    debug(QString("Starting upload of file: %1 bytes").arg(m_uploadTotalBytes));

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
    //                 setStatus(m_status, result.getString());
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
        debug(result.getError());
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
//         debug(result.getString());
//         file.close();
//         return;
//     }

//     QString sessionId = result.getString();

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

//     qDebug() << "Upload complete, CID:" << result.getString();

//     file.close();
// }

void StorageBackend::tryDownloadFile(const QString& cid, const QUrl& url) {
    qDebug() << "StorageBackend: tryDownloadFile called";

    if (!url.isLocalFile()) {
        qWarning() << "Not a local file";
        debug("The provided URL is not a local file.");
        return;
    }

    // QString filename = url.toLocalFile();

    // // QString filename = "/home/arnaud/Work/logos/logos-storage-ui/README.md";
    // QString sessionId = m_logos->storage_module.uploadInit(filename);

    // qDebug() << "StorageBackend: uploadInit sessionId =" << sessionId;

    LogosResult result = m_logos->storage_module.downloadToUrl(cid, url, false);

    if (!result.success) {
        debug(result.getError());
        return;
    }

    QString sessionId = result.value.value<QString>();

    qDebug() << "StorageBackend: tryDownloadFile result =" << sessionId;
}

void StorageBackend::exists(const QString& cid) {
    qDebug() << "StorageBackend::exists called";

    LogosResult result = m_logos->storage_module.exists(cid);

    if (!result.success) {
        debug("StorageBackend::exists failed with error=" + result.getError());
        return;
    }

    debug("Does " + cid + " exists ? " + QVariant(result.getValue<bool>()).toString());
}

void StorageBackend::remove(const QString& cid) {
    qDebug() << "StorageBackend::remove called";

    LogosResult result = m_logos->storage_module.remove(cid);

    if (!result.success) {
        debug("StorageBackend::remove failed with error=" + result.getError());
        return;
    }

    debug("Cid " + cid + " removed.");
}

void StorageBackend::fetch(const QString& cid) {
    qDebug() << "StorageBackend::fetch called";

    LogosResult result = m_logos->storage_module.fetch(cid);

    if (!result.success) {
        debug("StorageBackend::fetch failed with error=" + result.getError());
        return;
    }

    debug("Cid " + cid + " fetched.");
}

void StorageBackend::version() {
    qDebug() << "StorageBackend::version called";

    LogosResult result = m_logos->storage_module.version();

    if (!result.success) {
        debug("StorageBackend::version failed with error=" + result.getError());
        return;
    }

    debug("Version: " + result.getString());
}

void StorageBackend::showPeerId() {
    qDebug() << "StorageBackend::peerId called";

    LogosResult result = m_logos->storage_module.peerId();

    if (!result.success) {
        debug("StorageBackend::peerId failed with error=" + result.getError());
        return;
    }

    debug("Peer ID: " + result.getString());
}

void StorageBackend::spr() {
    qDebug() << "StorageBackend::spr called";

    LogosResult result = m_logos->storage_module.spr();

    if (!result.success) {
        debug("StorageBackend::spr failed with error=" + result.getError());
        return;
    }

    debug("SPR: " + result.getString());
}

void StorageBackend::dataDir() {
    qDebug() << "StorageBackend::dataDir called";

    LogosResult result = m_logos->storage_module.dataDir();

    if (!result.success) {
        debug("StorageBackend::dataDir failed with error=" + result.getError());
        return;
    }

    debug("Data dir: " + result.getString());
}

void StorageBackend::downloadManifest(const QString& cid) {
    qDebug() << "StorageBackend::downloadManifest called with cid=" << cid;

    LogosResult result = m_logos->storage_module.downloadManifest(cid);

    if (!result.success) {
        debug("StorageBackend::downloadManifest failed with error=" + result.getError());
        return;
    }

    QString treeCid = result.getString("treeCid");
    qint64 datasetSize = result.getInt("datasetSize");
    qint64 blockSize = result.getInt("blockSize");
    QString filename = result.getString("filename");
    QString mimetype = result.getString("mimetype");

    debug("Manifest tree cid: " + treeCid);
    debug(QString("Manifest datasetSize %1").arg(datasetSize));
    debug(QString("Manifest blockSize %1").arg(blockSize));
    debug("Manifest filename: " + filename);
    debug("Manifest mimetype: " + mimetype);

    // Add to manifests list
    QVariantMap manifest;
    manifest["cid"] = cid;
    manifest["treeCid"] = treeCid;
    manifest["filename"] = filename;
    manifest["mimetype"] = mimetype;
    manifest["datasetSize"] = datasetSize;
    manifest["blockSize"] = blockSize;

    m_manifests.append(manifest);
    emit manifestsChanged();
}

QVariantList StorageBackend::manifests() const { return m_manifests; }

void StorageBackend::downloadManifests() {
    qDebug() << "StorageBackend::downloadManifests called";

    LogosResult result = m_logos->storage_module.manifests();

    if (!result.success) {
        debug("StorageBackend::downloadManifests failed with error=" + result.getError());
        return;
    }

    QVariantList manifestsList = result.getList();
    int count = manifestsList.size();
    debug(QString("Found %1 manifests").arg(count));

    m_manifests.clear();

    for (const QVariant& manifestVariant : manifestsList) {
        QVariantMap src = manifestVariant.toMap();

        QVariantMap manifest;
        manifest["cid"]         = src.value("cid").toString();
        manifest["treeCid"]     = src.value("treeCid").toString();
        manifest["filename"]    = src.value("filename").toString();
        manifest["mimetype"]    = src.value("mimetype").toString();
        manifest["datasetSize"] = src.value("datasetSize").toLongLong();
        manifest["blockSize"]   = src.value("blockSize").toLongLong();

        m_manifests.append(manifest);
    }

    emit manifestsChanged();
}

void StorageBackend::space() {
    qDebug() << "StorageBackend::space called";

    LogosResult result = m_logos->storage_module.space();

    if (!result.success) {
        debug("StorageBackend::space failed with error=" + result.getError());
        return;
    }

    debug(QString("Space datasetSize %1").arg(result.getInt("totalBlocks")));
    debug(QString("Space quotaMaxBytes %1").arg(result.getInt("quotaMaxBytes")));
    debug(QString("Space quotaUsedBytes %1").arg(result.getInt("quotaUsedBytes")));
    debug(QString("Space quotaReservedBytes %1").arg(result.getInt("quotaReservedBytes")));
}

void StorageBackend::updateLogLevel(const QString& logLevel) {
    qDebug() << "StorageBackend::updateLogLevel called with logLevel=" << logLevel;

    LogosResult result = m_logos->storage_module.updateLogLevel(logLevel);

    if (!result.success) {
        debug("StorageBackend::updateLogLevel failed with error=" + result.getError());
        return;
    }

    debug("Log level updated to " + logLevel);
}

StorageBackend::StorageStatus StorageBackend::status() const { return m_status; }

QString StorageBackend::cid() const { return m_cid; }

QString StorageBackend::configJson() const { return m_configJson; }

int StorageBackend::uploadProgress() const { return m_uploadProgress; }

QString StorageBackend::uploadStatus() const { return m_uploadStatus; }

void StorageBackend::reloadIfChanged(const QString& configJson) {
    if (configJson == m_configJson) {
        debug("No change detected in the config");
        return;
    }

    debug("New config detected");

    QJsonDocument doc = QJsonDocument::fromJson(configJson.toUtf8());
    if (doc.isNull()) {
        debug("Invalid json detected !");

        m_configJson = configJson;
        emit configJsonChanged();

        return;
    }

    if (m_status == StorageStatus::Running || m_status == StorageStatus::Stopping ||
        m_status == StorageStatus::Starting) {
        debug("Cannot reload the config while running, stopping or starting...");
        return;
    }

    if (m_status == StorageStatus::Stopped) {
        LogosResult result = m_logos->storage_module.destroy();

        if (!result.success) {
            debug("Failed to destroy the context error=" + result.getError());
            return;
        } else {
            setStatus(StorageStatus::Destroyed);
        }
    }

    bool result = m_logos->storage_module.init(configJson);

    if (!result) {
        debug("Failed to init context with new config, will rollback.");

        bool result = m_logos->storage_module.init(m_configJson);

        if (!result) {
            debug("Failed to init context with old config, that's a serious issue.");
        } else {
            debug("Old config restored");
            setStatus(StorageStatus::Stopped);

            m_configJson = configJson;
            emit configJsonChanged();
        }
        return;
    }

    debug("New config loaded successfully");

    m_configJson = configJson;
    setStatus(StorageStatus::Stopped);
    emit configJsonChanged();
}

bool StorageBackend::validateDataDir(const QString& path) {
    QFileInfo info(path);
    return info.exists() && info.isDir() && info.isReadable() && info.isWritable();
}

QString StorageBackend::buildConfig(const QString& dataDir, int discPort, int tcpPort) {
    debug("StorageBackend::updateBasicConfig called with dataDir=" + dataDir);

    QJsonDocument doc = QJsonDocument::fromJson(m_configJson.toUtf8());
    QJsonObject obj = doc.object();

    obj["data-dir"] = dataDir;
    obj["disc-port"] = discPort;

    QJsonArray listenAddrs = {QString("/ip4/0.0.0.0/tcp/%1").arg(tcpPort)};
    obj["listen-addrs"] = listenAddrs;

    QJsonArray bootstrapArray;
    for (const QString& node : BOOTSTRAP_NODES) {
        bootstrapArray.append(node);
    }
    obj["bootstrap-node"] = bootstrapArray;

    return QJsonDocument(obj).toJson(QJsonDocument::Indented);
}

QString StorageBackend::buildConfigFromFile(const QString& path) {
    qDebug() << "StorageBackend::buildConfigFromFile called";

    QFile file(path);
    if (file.exists() && file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QString configJson = QString::fromUtf8(file.readAll());

        debug("StorageUIPlugin: config.json is found, configJson=" + configJson);

        return configJson;
    }

    debug("StorageUIPlugin: Failed to load config.json");
    return "{}";
}

void StorageBackend::status(StorageStatus status) { m_status = status; }

QString StorageBackend::defaultDataDir() {
    QString home = QDir::homePath();
#ifdef Q_OS_WIN
    return home + "/AppData/Roaming/Storage";
#elif defined(Q_OS_MACOS)
    return home + "/Library/Application Support/Storage";
#else
    return home + "/.cache/storage";
#endif
}

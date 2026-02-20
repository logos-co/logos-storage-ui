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
#include <QNetworkAccessManager>
#include <QNetworkProxyFactory>
#include <QNetworkReply>
#include <QSslSocket>

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

    // Disable system proxy detection — it crashes in Nix/some Linux environments
    QNetworkProxyFactory::setUseSystemConfiguration(false);
    
    if (logosAPI) {
        m_logosAPI = logosAPI;
    } else {
        m_logosAPI = new LogosAPI("core", this);
    }
    
    m_logos = new LogosModules(m_logosAPI);

    emit ready();
}

StorageBackend::~StorageBackend()
{
    m_logosAPI = nullptr;
    m_logos = nullptr;
}

LogosResult StorageBackend::init(const QString& configJson) {
    qDebug() << "StorageBackend::initStorage called";

    m_config = QJsonDocument::fromJson(configJson.toUtf8());
    if (m_config.isNull()) {
        qDebug() << "StorageBackend::initStorage invalid json config" << configJson;
        reportError("Failed to create the storage: invalid JSON config");
        return {false, "", "Failed to create the storage, invalid json config"};
    }

    bool result = m_logos->storage_module.init(configJson);

    qDebug() << "StorageBackend::initStorage: init";

    if (!result) {
        setStatus(Destroyed);
        reportError("Failed to init storage");
        return {false, "", "Failed to init storage"};
    }

    setStatus(Stopped);

    if (!m_logos->storage_module.on("storageStart", [this](const QVariantList& data) {
            bool success = data[0].toBool();

            if (!success) {
                QString message = data[1].toString();
                setStatus(Stopped);
                debug("Failed to start Storage module:" + message);
                emit startFailed(message);
                reportError("Failed to start: " + message);
            } else {
                setStatus(Running);
                debug("Storage module started.");
                //  QMetaObject::invokeMethod(this, &StorageBackend::downloadManifests, Qt::QueuedConnection);
                // QMetaObject::invokeMethod(this, &StorageBackend::space, Qt::QueuedConnection);
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

                QMetaObject::invokeMethod(this, &StorageBackend::space, Qt::QueuedConnection);
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

    emit initCompleted();
    debug("new config is: " + configJson);

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

    // TODO trach the start attempts in a file

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

void StorageBackend::reportError(const QString& message) {
    debug(message);
    emit error(message);
}

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
        // Log but continue — manifest might not have local data, remove it from the list anyway
        debug("StorageBackend::remove: storage returned error=" + result.getError() + " (removing from list regardless)");
    } else {
        debug("Cid " + cid + " removed from storage.");
    }

    // Always remove from manifests list
    for (int i = 0; i < m_manifests.size(); ++i) {
        if (m_manifests[i].toMap().value("cid").toString() == cid) {
            m_manifests.removeAt(i);
            emit manifestsChanged();
            break;
        }
    }

    QMetaObject::invokeMethod(this, &StorageBackend::space, Qt::QueuedConnection);
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

    qDebug() << "StorageBackend::space raw value:" << result.value;

    static constexpr qint64 DEFAULT_QUOTA = 20LL * 1024 * 1024 * 1024; // 20 GB

    // Check config for a quota-max-bytes override
    qint64 configQuota = m_config.object().value("quota-max-bytes").toVariant().toLongLong();
    qint64 apiQuota = result.getInt("quotaMaxBytes");
    m_quotaMaxBytes      = apiQuota > 0 ? apiQuota : (configQuota > 0 ? configQuota : DEFAULT_QUOTA);
    m_quotaUsedBytes     = result.getInt("quotaUsedBytes");
    m_quotaReservedBytes = result.getInt("quotaReservedBytes");
    emit quotaChanged();

    debug(QString("Space totalBlocks %1").arg(result.getInt("totalBlocks")));
    debug(QString("Space quotaMaxBytes %1").arg(m_quotaMaxBytes));
    debug(QString("Space quotaUsedBytes %1").arg(m_quotaUsedBytes));
    debug(QString("Space quotaReservedBytes %1").arg(m_quotaReservedBytes));
}

qint64 StorageBackend::quotaMaxBytes()      const { return m_quotaMaxBytes; }
qint64 StorageBackend::quotaUsedBytes()     const { return m_quotaUsedBytes; }
qint64 StorageBackend::quotaReservedBytes() const { return m_quotaReservedBytes; }

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

int StorageBackend::uploadProgress() const { return m_uploadProgress; }

QString StorageBackend::uploadStatus() const { return m_uploadStatus; }

void StorageBackend::reloadIfChanged(const QString& configJson) {
    QJsonDocument config = QJsonDocument::fromJson(configJson.toUtf8());
    if (config.isNull()) {
        debug("Invalid json detected !");
        return;
    }

    if (m_config == config) {
        debug("No change detected in the config");
        return;
    }

    debug("New config detected");

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

    LogosResult result = init(configJson);

    if (!result.success) {
        debug("Failed to init context with new config: " + result.getError());
        return;
    }

    debug("New config loaded successfully");

    m_config = config;
    setStatus(StorageStatus::Stopped);
}

void StorageBackend::saveCurrentConfig() {
    qDebug() << "StorageBackend::saveUserConfig";
    saveUserConfig(QString::fromUtf8(m_config.toJson(QJsonDocument::Indented)));
}

void StorageBackend::saveUserConfig(const QString& configJson) {
    qDebug() << "StorageBackend::saveUserConfig";

    QString folderPath = QFileInfo(USER_CONFIG_PATH).absolutePath();
    QDir().mkpath(folderPath);
    QFile file(USER_CONFIG_PATH);
    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        file.write(configJson.toUtf8());
        file.close();
        debug("Config saved to " + USER_CONFIG_PATH);
    } else {
        debug("Failed to save config to " + USER_CONFIG_PATH);
    }
}

QJsonDocument StorageBackend::defaultConfig() {
    QJsonDocument doc = QJsonDocument();
    QJsonObject obj = doc.object();

    QJsonArray bootstrapArray;
    for (const QString& node : BOOTSTRAP_NODES) {
        bootstrapArray.append(node);
    }
    obj["bootstrap-node"] = bootstrapArray;

    obj["data-dir"] = DEFAULT_DATA_DIR;

    return QJsonDocument(obj);
}

void StorageBackend::enableUpnpConfig() {
    debug("StorageBackend::enableUpnpConfig called");

    QJsonDocument doc = defaultConfig();
    QJsonObject obj = doc.object();

    obj["nat"] = "upnp";

    reloadIfChanged(QString::fromUtf8(QJsonDocument(obj).toJson(QJsonDocument::Indented)));
}

void StorageBackend::enableNatExtConfig(int tcpPort) {
    qDebug() << "StorageBackend::enableNatExtConfig called with tcpPort" << tcpPort;

    QJsonDocument doc = defaultConfig();
    QJsonObject obj = doc.object();

    QJsonArray listenAddrs = {QString("/ip4/0.0.0.0/tcp/%1").arg(tcpPort)};
    obj["listen-addrs"] = listenAddrs;

    // Fetch the public IP asynchronously so we can set nat=extip:IP in the config.
    // If the request fails, we proceed without the IP (node will still start, just without extip NAT).
    debug("Retrieving public IP...");

    QNetworkAccessManager* manager = new QNetworkAccessManager(this);
    QNetworkRequest request(ECHO_PROVIDER);

    // Set text/plain to receive only the IP
    request.setRawHeader("Accept", "text/plain");

    QNetworkReply* reply = manager->get(request);

    connect(reply, &QNetworkReply::finished, this, [this, reply, manager, obj]() mutable {
        reply->deleteLater();
        manager->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            debug("Failed to retrieve public IP: " + reply->errorString() + ". Proceeding without extip NAT.");
        } else {
            QString ip = QString::fromUtf8(reply->readAll()).trimmed();
            debug("Public IP: " + ip);
            obj["nat"] = "extip:" + ip;
        }

        reloadIfChanged(QString::fromUtf8(QJsonDocument(obj).toJson(QJsonDocument::Compact)));
        emit natExtConfigCompleted();
    });
}

void StorageBackend::checkNodeIsUp() {
    qDebug() << "StorageBackend::checkNodeIsUp called.";

    // First we get the debug info in order to get the peers and
    // the announceAddresses
    LogosResult result = m_logos->storage_module.debug();
    if (!result.success) {
        qDebug() << "Failed to get node debug info: " << result.getError();
        emit nodeIsntUp("Failed to get node debug info: " + result.getError());
        return;
    }

    // Ensure that the node has at least one peer.
    QVariantMap table = result.getValue<QVariantMap>("table");
    QVariantList nodes = table["nodes"].toList();

    debug(QString("Connected peers: %1").arg(nodes.size()));
    if (nodes.isEmpty()) {
        emit nodeIsntUp("No peers connected. "
                        "Try modifying the discovery port (default 8090) in the advanced settings.");
        return;
    }

    debug("DHT seems okay, found peers");

    // Extract TCP ports from announceAddresses.
    // Format: "/ip4/1.2.3.4/tcp/PORT"
    QVariantList announceAddresses = result.getValue<QVariantList>("announceAddresses");
    QList<int> ports;
    for (const QVariant& addr : announceAddresses) {
        QStringList parts = addr.toString().split("/");
        // "/ip4/1.2.3.4/tcp/8079" splits to ["", "ip4", "1.2.3.4", "tcp", "8079"]
        int tcpIndex = parts.indexOf("tcp");
        if (tcpIndex >= 0 && tcpIndex + 1 < parts.size()) {
            int port = parts[tcpIndex + 1].toInt();
            if (port > 0 && !ports.contains(port)) {
                ports.append(port);
            }
        }
    }

    QString nat = m_config.object()["nat"].toString();

    if (ports.isEmpty()) {
        debug("No TCP ports found in announce addresses, considering node as not up");
        if (nat == "upnp") {
            emit nodeIsntUp("UPnP is configured but there is no announced addresses. "
                            "Try going back and configure port forwarding manually on your router.");
        } else {
            emit nodeIsntUp("No announced addresses found. Your TCP port is propably incorrect. "
                            "Try going back and check your port forwarding configuration.");
        }

        return;
    }

    debug(QString("Checking reachability for %1 port(s)...").arg(ports.size()));

    // Check each port via the echo service, one by one.
    bool foundReachable = false;
    for (int port : ports) {
        QNetworkAccessManager manager;
        QNetworkRequest request(QUrl(QString("%1/port/%2").arg(ECHO_PROVIDER).arg(port)));
        QNetworkReply* reply = manager.get(request);

        QEventLoop loop;
        connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
        loop.exec();

        if (reply->error() == QNetworkReply::NoError) {
            bool reachable = QJsonDocument::fromJson(reply->readAll()).object()["reachable"].toBool();
            debug("Port " + QString::number(port) + (reachable ? " is reachable" : " is not reachable"));
            if (reachable) {
                foundReachable = true;
            }
        } else {
            debug("Port check failed for port " + QString::number(port) + ": " + reply->errorString());
        }

        reply->deleteLater();
    }

    if (foundReachable) {
        emit nodeIsUp();
    } else {
        if (nat == "upnp") {
            emit nodeIsntUp("UPnP is configured but the node is not reachable from the internet. "
                            "Try going back and configure port forwarding manually on your router.");
        } else {
            emit nodeIsntUp("No ports are reachable from the internet. "
                            "Try going back and check your port forwarding configuration.");
        }
    }
}

void StorageBackend::status(StorageStatus status) { m_status = status; }

void StorageBackend::loadUserConfig() {
    qDebug() << "StorageBackend::loadUserConfig called.";

    QFile file(USER_CONFIG_PATH);
    LogosResult result;

    if (file.exists() && file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        result = init(QString::fromUtf8(file.readAll()));
    } else {
        qWarning() << "StorageBackend::loadUserConfig Failed to read the user config file, fallback to default config";
        result = init(QString::fromUtf8(defaultConfig().toJson(QJsonDocument::Indented)));
    }

    if (!result.success) {
        qWarning() << "StorageBackend::loadUserConfig Failed to load the user config: " + result.getError();
    } else {
        debug("User config loaded successfully");
    }
}

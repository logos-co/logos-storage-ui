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
#include <QSettings>

#ifndef STORAGE_UI_VERSION
#define STORAGE_UI_VERSION "unknown"
#endif

static constexpr int STORAGE_READINESS_RETRIES = 2;
static constexpr int STORAGE_READINESS_RETRY_DELAY_MS = 500;

// StorageBackend is responsible for managing the interaction with the storage module.
// It is mocked in the QML.
// There are currently 2 ways to display debug information:
// - the first one is to log only in the console using qDebug/qWarning. This is basically
// for developers: entering a function, sending a command to the storage module...
// - the second one is to use the "debug" helper that logs both in the console and in a
// QString property that can be displayed in the UI. This is more for users to understand
// what is happening.
StorageBackend::StorageBackend(LogosAPI* logosAPI, QObject* parent)
    : StorageBackendSimpleSource(parent), m_logosAPI(nullptr), m_logos(nullptr) {
    qDebug() << "Initializing StorageBackend...";

    setStatus(Destroyed);
    setDefaultListenPort(DEFAULT_LISTEN_PORT);
    setDefaultConfigJson(QString::fromUtf8(defaultConfig().toJson(QJsonDocument::Indented)));

    // Disable system proxy detection — it crashes in Nix/some Linux environments
    QNetworkProxyFactory::setUseSystemConfiguration(false);

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

void StorageBackend::reportError(const QString& message) {
    debug(message, "warning");
    emit error(message);
}

void StorageBackend::debug(const QString& log, const QString& level) {
    QString current = debugLogs();
    if (!current.isEmpty()) {
        current += "\n";
    }

    QString timestamp = QDateTime::currentDateTime().toString(Qt::ISODate);
    current += timestamp + ": " + log;

    setDebugLogs(current);

    if (level == "warning") {
        qWarning() << "StorageBackend: " << log;
    } else {
        qDebug() << "StorageBackend: " << log;
    }
}

void StorageBackend::logLifecyclePeers(const QString& phase) {
    LogosResult result = m_logos->storage_module.debug();
    if (!result.success) {
        qDebug() << "StorageBackend lifecycle" << phase << "debug failed:" << result.getError();
        return;
    }

    QVariantMap map = result.getMap();
    QVariantList nodes = map.value("table").toMap().value("nodes").toList();
    qDebug() << "StorageBackend lifecycle" << phase << "peer count:" << nodes.size();
}

void StorageBackend::enqueueStorageOp(std::function<void()> op) {
    m_storageOps.enqueue(std::move(op));
    updateBusy();

    if (!m_storageOpRunning) {
        QTimer::singleShot(0, this, &StorageBackend::runNextStorageOp);
    }
}

void StorageBackend::runNextStorageOp() {
    if (m_storageOpRunning || m_storageOps.isEmpty()) {
        updateBusy();
        return;
    }

    m_storageOpRunning = true;
    updateBusy();
    auto op = m_storageOps.dequeue();
    op();
    m_storageOpRunning = false;
    updateBusy();

    if (!m_storageOps.isEmpty()) {
        QTimer::singleShot(0, this, &StorageBackend::runNextStorageOp);
    }
}

void StorageBackend::updateBusy() {
    setBusy(m_storageOpRunning || !m_storageOps.isEmpty());
}

void StorageBackend::requestWidgetRefresh() {
    if (m_widgetRefreshQueued) {
        return;
    }

    m_widgetRefreshQueued = true;
    enqueueStorageOp([this]() { doRefreshSpace(); });
    enqueueWidgetManifestRefresh();
}

void StorageBackend::enqueueWidgetManifestRefresh(int attempt) {
    enqueueStorageOp([this, attempt]() {
        if (status() != Running) {
            m_widgetRefreshQueued = false;
            return;
        }

        const bool finalAttempt = attempt >= STORAGE_READINESS_RETRIES;
        if (doDownloadManifests(finalAttempt)) {
            m_widgetRefreshQueued = false;
            return;
        }

        if (finalAttempt) {
            m_widgetRefreshQueued = false;
            return;
        }

        QTimer::singleShot(STORAGE_READINESS_RETRY_DELAY_MS, this, [this, attempt]() {
            enqueueWidgetManifestRefresh(attempt + 1);
        });
    });
}

void StorageBackend::init(QString configJson) {
    enqueueStorageOp([this, configJson]() { doInit(configJson); });
}

void StorageBackend::doInit(QString configJson) {
    qDebug() << "StorageBackend::initStorage called";

    m_config = QJsonDocument::fromJson(configJson.toUtf8());
    if (m_config.isNull()) {
        reportError("Failed to create the storage: invalid JSON config:" + configJson);
        emit initCompleted(false, "Failed to create the storage, invalid json config");
        return;
    }

    bool result = m_logos->storage_module.init(configJson);

    qDebug() << "StorageBackend::initStorage: init";

    if (!result) {
        m_contextInitialized = false;
        setStatus(Destroyed);
        reportError("Failed to init storage");
        emit initCompleted(false, "Failed to init storage");
        return;
    }

    m_contextInitialized = true;
    setStatus(Stopped);

    if (m_eventsSubscribed) {
        debug("new config is: " + configJson);
        emit initCompleted(true, QString());
        return;
    }

    if (!m_logos->storage_module.on("storageStart", [this](const QVariantList& data) {
            QJsonObject payload = QJsonDocument::fromJson(data[0].toString().toUtf8()).object();
            qDebug() << "StorageBackend lifecycle storageStart payload:"
                     << QString::fromUtf8(QJsonDocument(payload).toJson(QJsonDocument::Compact));
            bool success = payload["success"].toBool();

            if (!success) {
                QString message = payload["message"].toString();
                setStatus(Stopped);

                emit startFailed(message);

                reportError("Failed to start Storage Module: " + message);
            } else {
                setStatus(Running);

                debug("Storage module started.");

                fetchWidgetsData();

                emit startCompleted();
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageStart events";
    }

    if (!m_logos->storage_module.on("storageStop", [this](const QVariantList& data) {
            QJsonObject payload = QJsonDocument::fromJson(data[0].toString().toUtf8()).object();
            qDebug() << "StorageBackend lifecycle storageStop payload:"
                     << QString::fromUtf8(QJsonDocument(payload).toJson(QJsonDocument::Compact));
            bool success = payload["success"].toBool();

            if (!success) {
                setStatus(Running);

                QString message = payload["message"].toString();
                reportError("Failed to stop Storage module:" + message);
            } else {
                setStatus(Stopped);
                m_widgetRefreshQueued = false;

                debug("Storage module stopped.");

                enqueueStorageOp([this]() {
                    qDebug() << "StorageBackend lifecycle destroying context after stop";
                    LogosResult destroyResult = m_logos->storage_module.destroy();
                    const QString destroyError = destroyResult.success ? QString() : destroyResult.getError();
                    qDebug() << "StorageBackend lifecycle post-stop destroy result success:"
                             << destroyResult.success << "error:" << destroyError;

                    if (!destroyResult.success) {
                        reportError("Error when trying to destroy stopped context: " + destroyError);
                        return;
                    }

                    m_contextInitialized = false;
                });
            }

            emit stopCompleted();
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageStop events";
    }

    if (!m_logos->storage_module.on("storageUploadProgress", [this](const QVariantList& data) {
            QJsonObject payload = QJsonDocument::fromJson(data[0].toString().toUtf8()).object();
            bool success = payload["success"].toBool();

            if (!success) {
                QString message = payload["error"].toString();
                reportError("Failure during upload progress: " + message);
            } else {
                qint64 len = payload["bytes"].toInteger();
                emit uploadChunk(len);
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageUploadProgress events";
    }

    if (!m_logos->storage_module.on("storageUploadDone", [this](const QVariantList& data) {
            QJsonObject payload = QJsonDocument::fromJson(data[0].toString().toUtf8()).object();
            bool success = payload["success"].toBool();

            if (!success) {
                QString message = payload["error"].toString();
                reportError("Failed to upload: " + message);
            } else {
                QString cid = payload["cid"].toString();
                emit uploadCompleted(cid);
                requestWidgetRefresh();
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageUploadDone events";
    }

    if (!m_logos->storage_module.on("storageDownloadProgress", [this](const QVariantList& data) {
            QJsonObject payload = QJsonDocument::fromJson(data[0].toString().toUtf8()).object();
            bool success = payload["success"].toBool();

            if (!success) {
                QString message = payload["error"].toString();
                reportError("Failure during download progress: " + message);
            } else {
                qint64 len = payload["bytes"].toInteger();
                emit downloadChunk(len);
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageDownloadProgress events";
    }

    if (!m_logos->storage_module.on("storageDownloadDone", [this](const QVariantList& data) {
            QJsonObject payload = QJsonDocument::fromJson(data[0].toString().toUtf8()).object();
            bool success = payload["success"].toBool();

            if (!success) {
                QString message = payload["error"].toString();
                reportError("Failed to download: " + message);
            } else {
                // The download session id is the cid.
                QString cid = payload["sessionId"].toString();

                emit downloadCompleted(cid);

                QMetaObject::invokeMethod(this, &StorageBackend::refreshSpace, Qt::QueuedConnection);

                debug("Download completed for cid " + cid);
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageDownloadDone events";
    }

    debug("new config is: " + configJson);
    m_eventsSubscribed = true;

    emit initCompleted(true, QString());
}

void StorageBackend::start() {
    enqueueStorageOp([this]() { doStart(); });
}

void StorageBackend::doStart() {
    qDebug() << "StorageBackend: start method called";
    qDebug() << "StorageBackend lifecycle start requested, current status:" << status();

    migrateUserConfigFile();

    QFile file(USER_CONFIG_PATH);

    if (file.exists() && file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QString configJsonStr = QString::fromUtf8(file.readAll());
        doReloadIfChanged(configJsonStr);
    } else {
        debug("Cannot open the user config file.", "warning");
    }

    if (status() == Stopped && !m_contextInitialized) {
        if (m_config.isNull()) {
            reportError("Failed to start storage: missing configuration.");
            emit startFailed("Failed to start storage: missing configuration.");
            return;
        }

        qDebug() << "StorageBackend lifecycle reinitializing context before start";
        doInit(QString::fromUtf8(m_config.toJson(QJsonDocument::Compact)));
    }

    if (status() != Stopped) {
        debug("The Storage Module is not initialised properly.");
        emit startFailed("The Storage Module is not initialised properly.");
        return;
    }

    setStatus(Starting);
    debug("Starting Storage module...");
    logLifecyclePeers("before start");

    auto result = m_logos->storage_module.start();
    qDebug() << "StorageBackend lifecycle start command result:" << result;

    if (!result) {
        setStatus(Stopped);
        reportError("Failed to start storage");
        emit startFailed("Failed to start storage");
        return;
    }

    qDebug() << "StorageBackend: start command sent, waiting for events.";
}

void StorageBackend::stop() {
    enqueueStorageOp([this]() { doStop(); });
}

void StorageBackend::doStop() {
    qDebug() << "StorageBackend: stop method called";
    qDebug() << "StorageBackend lifecycle stop requested, current status:" << status();

    if (status() == Stopping) {
        debug("The Storage Module is already stopping.");
        return;
    }

    if (status() != Running) {
        debug("The Storage Module is not started.");
        emit stopCompleted();
        return;
    }

    setStatus(Stopping);
    debug("Stopping Storage module...");
    logLifecyclePeers("before stop");

    auto result = m_logos->storage_module.stop();
    const QString stopError = result.success ? QString() : result.getError();
    qDebug() << "StorageBackend lifecycle stop command result success:" << result.success
             << "error:" << stopError;

    if (!result.success) {
        setStatus(Running);
        reportError("Error when trying to stop: " + stopError);
        return;
    }

    qDebug() << "StorageBackend: stop command sent, waiting for events.";
}

void StorageBackend::destroy() {
    enqueueStorageOp([this]() { doDestroy(); });
}

void StorageBackend::doDestroy() {
    qDebug() << "StorageBackend: destroy method called";

    if (!m_contextInitialized) {
        qDebug() << "StorageBackend: Storage module context already destroyed.";
        return;
    }

    auto result = m_logos->storage_module.destroy();

    if (!result.success) {
        reportError("Error when trying to destroy: " + result.getError());
        return;
    }

    m_contextInitialized = false;
    qDebug() << "StorageBackend: Storage module destroyed.";
}

void StorageBackend::logDebugInfo() {
    enqueueStorageOp([this]() { doLogDebugInfo(); });
}

void StorageBackend::doLogDebugInfo() {
    auto result = m_logos->storage_module.debug();

    if (!result.success) {
        reportError("Failed to get debug info: " + result.getError());
        return;
    }

    QVariantMap map = result.getMap();
    debug(QString::fromUtf8(QJsonDocument::fromVariant(map).toJson(QJsonDocument::Indented)));

    QVariantList nodes = map.value("table").toMap().value("nodes").toList();
    emit peersUpdated(nodes.size());
}

void StorageBackend::uploadFile(QUrl url) {
    enqueueStorageOp([this, url]() { doUploadFile(url); });
}

void StorageBackend::doUploadFile(QUrl url) {
    qDebug() << "StorageBackend: uploadFile called";

    if (!url.isLocalFile()) {
        reportError("The provided URL is not a local file.");
        return;
    }

    qint64 totalBytes = QFileInfo(url.toLocalFile()).size();
    debug(QString("Starting upload of file: %1 bytes").arg(totalBytes));
    emit uploadStarted(totalBytes);

    LogosResult result = m_logos->storage_module.uploadUrl(url.toLocalFile(), DEFAULT_CHUNK_SIZE);

    if (!result.success) {
        reportError("Failed to upload file:" + result.getError());
        return;
    }

    QString sessionId = result.value.value<QString>();

    qDebug() << "StorageBackend: uploadFile result =" << sessionId;
}

void StorageBackend::downloadFile(QString cid, QUrl url, qint64 totalBytes) {
    enqueueStorageOp([this, cid, url, totalBytes]() { doDownloadFile(cid, url, totalBytes); });
}

void StorageBackend::doDownloadFile(QString cid, QUrl url, qint64 totalBytes) {
    qDebug() << "StorageBackend: downloadFile called";

    if (!url.isLocalFile()) {
        reportError("The provided URL is not a local file.");
        return;
    }

    QString filename = QFileInfo(url.toLocalFile()).fileName();
    debug(QString("Starting download of cid: %1, filename: %2, total: %3 bytes")
              .arg(cid, filename)
              .arg(totalBytes));
    emit downloadStarted(cid, filename, totalBytes);

    LogosResult result = m_logos->storage_module.downloadToUrl(cid, url.toLocalFile(), false, DEFAULT_CHUNK_SIZE);

    if (!result.success) {
        reportError("Failed to download file:" + result.getError());
        return;
    }

    QString sessionId = result.value.value<QString>();

    qDebug() << "StorageBackend: downloadFile result =" << sessionId;
}

void StorageBackend::exists(QString cid) {
    enqueueStorageOp([this, cid]() { doExists(cid); });
}

void StorageBackend::doExists(QString cid) {
    qDebug() << "StorageBackend::exists called";

    LogosResult result = m_logos->storage_module.exists(cid);

    if (!result.success) {
        reportError("StorageBackend::exists failed with error=" + result.getError());
        return;
    }

    debug("Does " + cid + " exists ? " + QVariant(result.getValue<bool>()).toString());
}

void StorageBackend::remove(QString cid) {
    enqueueStorageOp([this, cid]() { doRemove(cid); });
}

void StorageBackend::doRemove(QString cid) {
    qDebug() << "StorageBackend::remove called with cid=" << cid;

    LogosResult result = m_logos->storage_module.remove(cid);
    if (!result.success) {
        reportError("Failed to remove " + cid + ": " + result.getError());
        requestWidgetRefresh();
        return;
    }

    debug("Cid " + cid + " removed from local storage.");

    requestWidgetRefresh();
}

void StorageBackend::fetch(QString cid) {
    enqueueStorageOp([this, cid]() { doFetch(cid); });
}

void StorageBackend::doFetch(QString cid) {
    qDebug() << "StorageBackend::fetch called";

    LogosResult result = m_logos->storage_module.fetch(cid);

    if (!result.success) {
        reportError("Failed to fetch cid " + cid + ": " + result.getError());
        return;
    }

    debug("Cid " + cid + " fetched.");
}

void StorageBackend::logVersion() {
    enqueueStorageOp([this]() { doLogVersion(); });
}

void StorageBackend::doLogVersion() {
    qDebug() << "StorageBackend::version called";

    LogosResult result = m_logos->storage_module.version();

    if (!result.success) {
        reportError("Failed to log version: " + result.getError());
        return;
    }

    // Module version is hardcoded until the module exposes it through the API.
    debug("Logos Storage Module=1.1.0");
    debug("Logos Storage Nim=" + result.getString().section('-', -1));
    debug("Logos Storage UI=1.0.0");
}

void StorageBackend::listSettings() {
    qDebug() << "StorageBackend::listSettings called";

    QSettings settings;

    debug("Settings file: " + settings.fileName());

    QStringList lines;
    for (const QString &key : settings.allKeys()) {
        if (key.startsWith("Storage")){
          lines << key + " = " + settings.value(key).toString();
        }
    }
    QString all = lines.join("\n");
    debug("All settings:\n" + all);
}

void StorageBackend::restartOnboarding() {
    qDebug() << "StorageBackend::restartOnboarding called";

    QSettings settings;
    settings.setValue("Storage/onboardingCompleted", false);
    settings.sync();
    StorageBackend::listSettings();
    emit onboardingRestarted();
}

void StorageBackend::logPeerId() {
    enqueueStorageOp([this]() { doLogPeerId(); });
}

void StorageBackend::doLogPeerId() {
    qDebug() << "StorageBackend::peerId called";

    LogosResult result = m_logos->storage_module.peerId();

    if (!result.success) {
        reportError("Failed to log peerId: " + result.getError());
        return;
    }

    debug("Peer ID: " + result.getString());
}

void StorageBackend::logSpr() {
    enqueueStorageOp([this]() { doLogSpr(); });
}

void StorageBackend::doLogSpr() {
    qDebug() << "StorageBackend::spr called";

    LogosResult result = m_logos->storage_module.spr();

    if (!result.success) {
        reportError("Failed to log spr: " + result.getError());
        return;
    }

    debug("SPR: " + result.getString());
}

void StorageBackend::logDataDir() {
    enqueueStorageOp([this]() { doLogDataDir(); });
}

void StorageBackend::doLogDataDir() {
    qDebug() << "StorageBackend::dataDir called";

    LogosResult result = m_logos->storage_module.dataDir();

    if (!result.success) {
        reportError("Failed to log dataDir: " + result.getError());
        return;
    }

    debug("Data dir: " + result.getString());
}

void StorageBackend::downloadManifest(QString cid) {
    enqueueStorageOp([this, cid]() { doDownloadManifest(cid); });
}

void StorageBackend::doDownloadManifest(QString cid) {
    qDebug() << "StorageBackend::downloadManifest called with cid=" << cid;

    LogosResult result = m_logos->storage_module.downloadManifest(cid);

    if (!result.success) {
        reportError("Failed to download manifest cid " + cid + ": " + result.getError());
        return;
    }

    QString treeCid = result.getString("treeCid");
    qint64 datasetSize = result.getInt("datasetSize");
    qint64 blockSize = result.getInt("blockSize");
    QString filename = result.getString("filename");
    QString mimetype = result.getString("mimetype");

    QVariantMap manifest;
    manifest["cid"]         = cid;
    manifest["treeCid"]     = treeCid;
    manifest["filename"]    = filename;
    manifest["mimetype"]    = mimetype;
    manifest["datasetSize"] = datasetSize;
    manifest["blockSize"]   = blockSize;

    requestWidgetRefresh();
}

void StorageBackend::downloadManifests() {
    enqueueStorageOp([this]() { doDownloadManifests(); });
}

bool StorageBackend::doDownloadManifests(bool reportErrors) {
    qDebug() << "StorageBackend::downloadManifests called";

    if (status() != Running) {
        qDebug() << "StorageBackend::downloadManifests skipped because storage is not running";
        return true;
    }

    LogosResult result = m_logos->storage_module.manifests();

    if (!result.success) {
        if (reportErrors) {
            reportError("Failed to download manifests: " + result.getError());
        }
        return false;
    }

    emit manifestsUpdated(result.getList());
    return true;
}

void StorageBackend::refreshSpace() {
    enqueueStorageOp([this]() { doRefreshSpace(); });
}

void StorageBackend::doRefreshSpace() {
    qDebug() << "StorageBackend::refreshSpace called";

    if (status() != Running) {
        qDebug() << "StorageBackend::refreshSpace skipped because storage is not running";
        return;
    }

    LogosResult result = m_logos->storage_module.space();

    if (!result.success) {
        reportError("Failed to refresh space: " + result.getError());
        return;
    }

    const qlonglong total = result.getValue<qlonglong>("quotaMaxBytes");
    const qlonglong used =
        result.getValue<qlonglong>("quotaUsedBytes") + result.getValue<qlonglong>("quotaReservedBytes");

    emit spaceUpdated(total, used);
}

void StorageBackend::reloadIfChanged(QString configJsonStr) {
    enqueueStorageOp([this, configJsonStr]() { doReloadIfChanged(configJsonStr); });
}

void StorageBackend::doReloadIfChanged(QString configJsonStr) {
    QJsonDocument config = QJsonDocument::fromJson(configJsonStr.toUtf8());
    if (config.isNull()) {
        debug("Invalid json detected !");
        return;
    }

    if (m_config == config) {
        debug("No change detected in the config");
        return;
    }

    debug("New config detected");

    if (status() == Running || status() == Stopping ||
        status() == Starting) {
        debug("Cannot reload the config while running, stopping or starting...");
        return;
    }

    if (status() == Stopped && m_contextInitialized) {
        LogosResult result = m_logos->storage_module.destroy();

        if (!result.success) {
            reportError("Failed to destroy the context error=" + result.getError());
            return;
        } else {
            m_contextInitialized = false;
            setStatus(Destroyed);
        }
    }

    doInit(configJsonStr);

    m_config = config;
    saveUserConfig(configJsonStr);
    setStatus(Stopped);
}

void StorageBackend::saveCurrentConfig() {
    qDebug() << "StorageBackend::saveCurrentConfig";
    saveUserConfig(configJson());
}

void StorageBackend::saveUserConfig(QString configJsonStr) {
    qDebug() << "StorageBackend::saveUserConfig";

    QString folderPath = QFileInfo(USER_CONFIG_PATH).absolutePath();
    QDir().mkpath(folderPath);
    QFile file(USER_CONFIG_PATH);
    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        file.write(configJsonStr.toUtf8());
        file.close();
        debug("Config saved to " + USER_CONFIG_PATH);
    } else {
        reportError("Failed to save config to " + USER_CONFIG_PATH);
    }

    QJsonDocument config = QJsonDocument::fromJson(configJsonStr.toUtf8());
    if (config.isNull()) {
        reportError("Invalid json config" + configJsonStr);
        return;
    }
}

QJsonDocument StorageBackend::defaultConfig() {
    QJsonDocument doc = QJsonDocument();
    QJsonObject obj = doc.object();

    obj["network"] = DEFAULT_NETWORK_PRESET;

    obj["data-dir"] = DEFAULT_DATA_DIR;
    obj["listen-port"] = DEFAULT_LISTEN_PORT;
    obj["disc-port"] = DEFAULT_DISC_PORT;
    obj["nat"] = "none";

    return QJsonDocument(obj);
}

bool StorageBackend::isLegacyBootstrap(const QJsonArray& bootstrap) {
    if (bootstrap.size() != LEGACY_BOOTSTRAP_NODES.size()) {
        return false;
    }
    for (const QJsonValue& node : bootstrap) {
        if (!LEGACY_BOOTSTRAP_NODES.contains(node.toString())) {
            return false;
        }
    }
    return true;
}

QString StorageBackend::migrateConfig(QString configJsonStr) {
    QJsonDocument doc = QJsonDocument::fromJson(configJsonStr.toUtf8());
    if (!doc.isObject()) {
        return configJsonStr;
    }

    QJsonObject obj = doc.object();

    // Already on the new format: the "network" preset field is present.
    if (obj.contains("network")) {
        return configJsonStr;
    }

    // A custom bootstrap list means the user joined their own network: keep it,
    // it intentionally overrides the preset.
    QJsonArray bootstrap = obj.value("bootstrap-node").toArray();
    if (!bootstrap.isEmpty() && !isLegacyBootstrap(bootstrap)) {
        return configJsonStr;
    }

    // Default (or empty) bootstrap list: drop it so the network preset applies.
    obj.remove("bootstrap-node");
    obj["network"] = DEFAULT_NETWORK_PRESET;

    return QString::fromUtf8(QJsonDocument(obj).toJson(QJsonDocument::Indented));
}

void StorageBackend::migrateUserConfigFile() {
    QFile file(USER_CONFIG_PATH);
    if (!file.exists() || !file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return;
    }
    QString current = QString::fromUtf8(file.readAll());
    file.close();

    QString migrated = migrateConfig(current);
    if (migrated == current) {
        return;
    }

    saveUserConfig(migrated);
    debug("Migrated user config to the network preset format.");
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

    obj["listen-ip"] = "0.0.0.0";
    obj["listen-port"] = tcpPort;

    qDebug() << "StorageBackend:: Retrieving public IP...";

    QNetworkAccessManager* manager = new QNetworkAccessManager(this);
    QNetworkRequest request(ECHO_PROVIDER);

    request.setRawHeader("Accept", "text/plain");

    QNetworkReply* reply = manager->get(request);

    connect(reply, &QNetworkReply::finished, this, [this, reply, manager, obj]() mutable {
        reply->deleteLater();
        manager->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            qWarning() << "Failed to retrieve public IP: " << reply->errorString() << ". Proceeding without extip NAT.";
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
    enqueueStorageOp([this]() { doCheckNodeIsUp(); });
}

void StorageBackend::doCheckNodeIsUp() {
    qDebug() << "StorageBackend::checkNodeIsUp called.";

    LogosResult result = m_logos->storage_module.debug();
    if (!result.success) {
        qWarning() << "StorageBackend::checkNodeIsUp Failed to get node debug info: " << result.getError();
        emit nodeIsntUp("Failed to get node debug info: " + result.getError());
        return;
    }

    QVariantMap table = result.getValue<QVariantMap>("table");
    QVariantList nodes = table["nodes"].toList();

    debug(QString("Connected peers: %1").arg(nodes.size()));

    if (nodes.isEmpty()) {
        qWarning() << "StorageBackend::checkNodeIsUp No peers connected";
        emit nodeIsntUp("No peers connected. "
                        "Try modifying the discovery port (default 8090) in the advanced settings.");
        return;
    }

    qDebug() << "StorageBackend::checkNodeIsUp DHT seems okay, found peers";

    QVariantList announceAddresses = result.getValue<QVariantList>("announceAddresses");
    QList<QPair<QString, int>> endpoints;
    for (const QVariant& addr : announceAddresses) {
        const QStringList parts = addr.toString().split("/");
        const int tcpIndex = parts.indexOf("tcp");
        if (tcpIndex >= 1 && tcpIndex + 1 < parts.size()) {
            const QString ip   = parts[tcpIndex - 1];
            const int port = parts[tcpIndex + 1].toInt();
            if (port > 0 && !ip.isEmpty())
                endpoints.append({ ip, port });
        }
    }

    QString nat = m_config.object()["nat"].toString();

    if (endpoints.isEmpty()) {
        qDebug() << "StorageBackend::checkNodeIsUp No TCP endpoints found in announce addresses";

        if (nat == "upnp") {
            emit nodeIsntUp("UPnP is configured but there is no announced addresses. "
                            "Try going back and configure port forwarding manually on your router.");
        } else {
            emit nodeIsntUp("No announced addresses found. Your TCP port is probably incorrect. "
                            "Try going back and check your port forwarding configuration.");
        }
        return;
    }

    QTimer::singleShot(0, this, [this, endpoints, nat]() {
        qDebug() << "Checking reachability for " << endpoints.size() << "endpoint(s)...";

        bool foundReachable = false;
        for (const auto& [ip, port] : endpoints) {
            QNetworkAccessManager manager;
            const QUrl url(QString("%1/%2/%3").arg(PORT_CHECKER_PROVIDER).arg(ip).arg(port));
            QNetworkReply* reply = manager.get(QNetworkRequest(url));

            QEventLoop loop;
            connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
            loop.exec();

            if (reply->error() == QNetworkReply::NoError) {
                const bool reachable = reply->readAll() == "True";

                QString statusStr = reachable ? "reachable" : "not reachable";
                qDebug() << "StorageBackend::checkNodeIsUp " << ip << ":" << port << statusStr;

                if (reachable) {
                    foundReachable = true;
                }
            } else {
                qDebug() << "StorageBackend::checkNodeIsUp Port check failed for" << ip << ":" << port
                         << reply->errorString();
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
    });
}

void StorageBackend::fetchWidgetsData() {
    enqueueStorageOp([this]() { doLogDebugInfo(); });
    requestWidgetRefresh();
}

void StorageBackend::loadUserConfig() {
    qDebug() << "StorageBackend::loadUserConfig called.";

    migrateUserConfigFile();

    QFile file(USER_CONFIG_PATH);

    if (file.exists() && file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        init(QString::fromUtf8(file.readAll()));
    } else {
        debug("Failed to read the user config file, fallback to default config");
        init(QString::fromUtf8(defaultConfig().toJson(QJsonDocument::Indented)));
    }
}

QString StorageBackend::getUserConfig() {
    qDebug() << "StorageBackend::getUserConfig called.";

    QFile file(USER_CONFIG_PATH);

    if (file.exists() && file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return QString::fromUtf8(file.readAll());
    } else {
        debug("Failed to read the user config file, use current config.");
        return configJson();
    }
}

QString StorageBackend::configJson() { return QString::fromUtf8(m_config.toJson(QJsonDocument::Indented)); }

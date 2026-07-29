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
#include <QNetworkProxyFactory>
#include <QSet>
#include <QSslSocket>
#include <QSettings>

#ifndef STORAGE_UI_VERSION
#define STORAGE_UI_VERSION "unknown"
#endif

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
    setNatReachability("Unknown");
    setDefaultConfigJson(QString::fromUtf8(defaultConfig().toJson(QJsonDocument::Indented)));
    setUiVersion(STORAGE_UI_VERSION);

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

static int seenPeerCount(const QVariantList& nodes) {
    int count = 0;
    for (const QVariant& node : nodes) {
        if (node.toMap().value("seen").toBool()) {
            ++count;
        }
    }
    return count;
}

void StorageBackend::debug(const QString& log, const QString& level) {
    if (level == "warning") {
        qWarning() << "StorageBackend: " << log;
    } else {
        qDebug() << "StorageBackend: " << log;
    }
}

void StorageBackend::startLogTail() {
    m_logFile.close();
    m_logFile.setFileName(m_logPath);
    m_logOffset = 0;
    m_logPartial.clear();

    if (!m_logPoll) {
        m_logPoll = new QTimer(this);
        m_logPoll->setInterval(500);
        connect(m_logPoll, &QTimer::timeout, this, &StorageBackend::readLogTail);
    }
    m_logPoll->start();
}

void StorageBackend::stopLogTail() {
    if (m_logPoll) {
        m_logPoll->stop();
    }
    readLogTail();
    m_logFile.close();
}

void StorageBackend::readLogTail() {
    if (!m_logFile.isOpen() && !m_logFile.open(QIODevice::ReadOnly)) {
        return;
    }

    qint64 size = m_logFile.size();
    if (size < m_logOffset) {  // the node truncated the file on restart
        m_logOffset = 0;
        m_logPartial.clear();
    }
    if (size == m_logOffset) {
        return;
    }

    m_logFile.seek(m_logOffset);
    m_logPartial += QString::fromUtf8(m_logFile.readAll());
    m_logOffset = m_logFile.pos();

    QStringList lines;
    int nl;
    while ((nl = m_logPartial.indexOf('\n')) >= 0) {
        lines.append(m_logPartial.left(nl));
        m_logPartial.remove(0, nl + 1);
    }

    if (!lines.isEmpty()) {
        emit logLines(lines);
    }
}

void StorageBackend::init(QString configJson) {
    qDebug() << "StorageBackend::initStorage called";

    m_config = QJsonDocument::fromJson(configJson.toUtf8());
    if (m_config.isNull()) {
        reportError("Failed to create the storage: invalid JSON config:" + configJson);
        emit initCompleted(false, "Failed to create the storage, invalid json config");
        return;
    }

    // Tail the log file the node writes to. Keep the user's log-file if they
    // set one, otherwise force a known default so we know where to read.
    QJsonObject cfgObj = m_config.object();
    m_logPath = cfgObj.value("log-file").toString();
    if (m_logPath.isEmpty()) {
        m_logPath = LOG_FILE_PATH;
        cfgObj["log-file"] = m_logPath;
        m_config = QJsonDocument(cfgObj);
        configJson = QString::fromUtf8(m_config.toJson(QJsonDocument::Indented));
    }

    bool result = m_logos->storage_module.init(configJson);

    qDebug() << "StorageBackend::initStorage: init";

    if (!result) {
        setStatus(Destroyed);
        reportError("Failed to init storage");
        emit initCompleted(false, "Failed to init storage");
        return;
    }

    setStatus(Stopped);
    setMixRunning(m_config.object().value("mix-enabled").toBool(false));

    if (m_eventsSubscribed) {
        debug("new config is: " + configJson);
        emit initCompleted(true, QString());
        return;
    }

    if (!m_logos->storage_module.on("storageStart", [this](const QVariantList& data) {
            QJsonObject payload = QJsonDocument::fromJson(data[0].toString().toUtf8()).object();
            bool success = payload["success"].toBool();

            if (!success) {
                QString message = payload["message"].toString();
                setStatus(Stopped);

                emit startFailed(message);

                reportError("Failed to start Storage Module: " + message);
            } else {
                setStatus(Running);

                debug("Storage module started.");

                startLogTail();
                StorageBackend::fetchWidgetsData();

                emit startCompleted();
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageStart events";
    }

    if (!m_logos->storage_module.on("storageStop", [this](const QVariantList& data) {
            QJsonObject payload = QJsonDocument::fromJson(data[0].toString().toUtf8()).object();
            bool success = payload["success"].toBool();

            if (!success) {
                setStatus(Running);

                QString message = payload["message"].toString();
                reportError("Failed to stop Storage module:" + message);
            } else {
                debug("Storage module stopped.");
                stopLogTail();
                QTimer::singleShot(0, this, [this]() {
                    LogosResult destroyResult = m_logos->storage_module.destroy();
                    if (!destroyResult.success) {
                        reportError("Error when trying to destroy stopped context: ");
                        setStatus(Stopped);
                    } else {
                        qDebug() << "StorageBackend: Storage module destroyed after stop.";
                        setStatus(Destroyed);
                    }
                    emit stopCompleted();
                });
                return;
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
                QMetaObject::invokeMethod(this, &StorageBackend::refreshSpace, Qt::QueuedConnection);
                QMetaObject::invokeMethod(this, &StorageBackend::downloadManifests, Qt::QueuedConnection);
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

    if (!m_logos->storage_module.on("storageDownloadManifestDone", [this](const QVariantList& data) {
            QJsonObject payload = QJsonDocument::fromJson(data[0].toString().toUtf8()).object();
            bool success = payload["success"].toBool();
            QString cid = payload["cid"].toString();

            if (!success) {
                QString message = payload["error"].toString();
                emit manifestFetchFailed(cid, message);
                reportError("Failed to fetch manifest: " + message);
            } else {
                debug("Manifest fetched for cid " + cid);
                QMetaObject::invokeMethod(this, &StorageBackend::downloadManifests, Qt::QueuedConnection);
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageDownloadManifestDone events";
    }

    if (!m_logos->storage_module.on("storageRemoveDone", [this](const QVariantList& data) {
            QJsonObject payload = QJsonDocument::fromJson(data[0].toString().toUtf8()).object();
            bool success = payload["success"].toBool();
            QString cid = payload["cid"].toString();

            if (!success) {
                QString message = payload["error"].toString();
                emit removeFailed(cid, message);
                reportError("Failed to remove " + cid + ": " + message);
            } else {
                debug("Cid " + cid + " removed from local storage.");
                QMetaObject::invokeMethod(this, &StorageBackend::refreshSpace, Qt::QueuedConnection);
                QMetaObject::invokeMethod(this, &StorageBackend::downloadManifests, Qt::QueuedConnection);
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageRemoveDone events";
    }

    debug("new config is: " + configJson);
    m_eventsSubscribed = true;

    emit initCompleted(true, QString());
}

void StorageBackend::start() {
    qDebug() << "StorageBackend: start method called";

    // AutoNAT has no verdict until the node has run for a while.
    setNatReachability("Unknown");

    migrateUserConfigFile();

    // Migration: Mix must run with a dht-mix-proxy and relay pool. Fill in the
    // bundled presets only when missing, so user-set values are preserved.
    QJsonObject cfg = QJsonDocument::fromJson(getUserConfig().toUtf8()).object();
    bool changed = false;
    // TEMP FIX: Mix is broken with the latest storage-nim, force it off.
    if (cfg.value("mix-enabled").toBool(false)) {
        cfg["mix-enabled"] = false;
        changed = true;
    }
    if (cfg.value("dht-mix-proxy").toArray().isEmpty()) {
        cfg["dht-mix-proxy"] = QJsonArray::fromStringList(DHT_MIX_PROXY);
        changed = true;
    }
    if (cfg.value("mix-pool-json").toString().isEmpty()) {
        cfg["mix-pool-json"] = QString::fromUtf8(
            QJsonDocument::fromJson(MIX_POOL_JSON.toUtf8()).toJson(QJsonDocument::Compact));
        changed = true;
    }

    if (changed) {
        saveUserConfig(QString::fromUtf8(QJsonDocument(cfg).toJson(QJsonDocument::Indented)));
    }

    QFile file(USER_CONFIG_PATH);

    if (file.exists() && file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QString configJsonStr = QString::fromUtf8(file.readAll());
        reloadIfChanged(configJsonStr);
    } else {
        debug("Cannot open the user config file.", "warning");
    }

    if (status() == Destroyed) {
        if (m_config.isNull()) {
            debug("Failed to start node: m_config not set.");
            emit startFailed("Failed to start node: configuration not set.");
            return;
        }

        init(QString::fromUtf8(m_config.toJson(QJsonDocument::Compact)));
    }

    if (status() != Stopped) {
        debug("The Storage Module is not initialised properly.");
        emit startFailed("The Storage Module is not initialised properly.");
        return;
    }

    setStatus(Starting);
    debug("Starting Storage module...");

    auto result = m_logos->storage_module.start();

    if (!result) {
        setStatus(Stopped);
        reportError("Failed to start storage");
        emit startFailed("Failed to start storage");
        return;
    }

    qDebug() << "StorageBackend: start command sent, waiting for events.";
}

void StorageBackend::stop() {
    qDebug() << "StorageBackend: stop method called";

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

    auto result = m_logos->storage_module.stop();

    if (!result.success) {
        setStatus(Running);
        reportError("Error when trying to stop: " + result.getError());
        return;
    }

    qDebug() << "StorageBackend: stop command sent, waiting for events.";
}

void StorageBackend::destroy() {
    qDebug() << "StorageBackend: destroy method called";

    if (status() == Destroyed) {
        qDebug() << "StorageBackend: Storage module context already destroyed.";
        return;
    }

    auto result = m_logos->storage_module.destroy();

    if (!result.success) {
        reportError("Error when trying to destroy: " + result.getError());
        return;
    }

    setStatus(Destroyed);
    qDebug() << "StorageBackend: Storage module destroyed.";
}

void StorageBackend::refreshNodeStatus() {
    auto result = m_logos->storage_module.debug();

    if (!result.success) {
        reportError("Failed to get debug info: " + result.getError());
        return;
    }

    QVariantMap info = result.getMap();

    const QString reachability = info.value("nat").toMap().value("reachability").toString();
    setNatReachability(reachability.isEmpty() ? QStringLiteral("Unknown") : reachability);

    QVariantList nodes = info.value("table").toMap().value("nodes").toList();
    const int peers = seenPeerCount(nodes);
    emit peersUpdated(peers);

    debug(QString("Peers: %1, NAT reachability: %2").arg(peers).arg(natReachability()));

    emit debugInfoUpdated(info);

    QSet<QString> directPeers;
    for (const QVariant& connection : info.value("connections").toList()) {
        const QVariantMap open = connection.toMap();
        directPeers.insert(open.value("peerId").toString());
    }

    QVariantList peerRows;
    for (const QVariant& n : nodes) {
        QVariantMap node = n.toMap();
        QVariant addr = node.value("address");
        QString addrStr;
        if (addr.typeId() == QMetaType::QString) {
            addrStr = addr.toString();
        } else if (addr.isValid() && !addr.isNull()) {
            addrStr = QString::fromUtf8(QJsonDocument::fromVariant(addr).toJson(QJsonDocument::Compact));
        }

        QVariantMap row;
        row["peerId"] = node.value("peerId").toString();
        row["address"] = addrStr;
        row["seen"] = node.value("seen").toBool();
        row["direct"] = directPeers.contains(row["peerId"].toString());
        peerRows.append(row);
    }
    emit peersTableUpdated(peerRows);
}

void StorageBackend::uploadFile(QUrl url) {
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
    qDebug() << "StorageBackend::exists called";

    LogosResult result = m_logos->storage_module.exists(cid);

    if (!result.success) {
        reportError("StorageBackend::exists failed with error=" + result.getError());
        return;
    }

    debug("Does " + cid + " exists ? " + QVariant(result.getValue<bool>()).toString());
}

void StorageBackend::remove(QString cid) {
    qDebug() << "StorageBackend::remove called with cid=" << cid;

    LogosResult result = m_logos->storage_module.remove(cid);
    if (!result.success) {
        reportError("Failed to remove " + cid + ": " + result.getError());
        return;
    }

    // The removal runs in the background: the outcome arrives later via the
    // "storageRemoveDone" event. Signal the start so the UI can show a pending
    // state.
    emit removeStarted(cid);
}

void StorageBackend::fetch(QString cid) {
    qDebug() << "StorageBackend::fetch called";

    LogosResult result = m_logos->storage_module.fetch(cid);

    if (!result.success) {
        reportError("Failed to fetch cid " + cid + ": " + result.getError());
        return;
    }

    debug("Cid " + cid + " fetched.");
}

void StorageBackend::restartOnboarding() {
    qDebug() << "StorageBackend::restartOnboarding called";

    QSettings settings;
    settings.setValue("Storage/onboardingCompleted", false);
    settings.sync();
    emit onboardingRestarted();
}

void StorageBackend::downloadManifest(QString cid) {
    qDebug() << "StorageBackend::downloadManifest called with cid=" << cid;

    LogosResult result = m_logos->storage_module.downloadManifest(cid);

    if (!result.success) {
        reportError("Failed to fetch manifest cid " + cid + ": " + result.getError());
        return;
    }

    // The fetch runs in the background: the manifest arrives later via the
    // "storageDownloadManifestDone" event. Signal the start so the UI can show
    // a pending row.
    emit manifestFetchStarted(cid);
}

void StorageBackend::downloadManifests() {
    qDebug() << "StorageBackend::downloadManifests called";

    LogosResult result = m_logos->storage_module.manifests();

    if (!result.success) {
        reportError("Failed to download manifests: " + result.getError());
        return;
    }

    emit manifestsUpdated(result.getList());
}

void StorageBackend::refreshSpace() {
    qDebug() << "StorageBackend::refreshSpace called";

    LogosResult result = m_logos->storage_module.space();

    if (!result.success) {
        reportError("Failed to refresh space: " + result.getError());
        return;
    }

    debug("space: " + QString::fromUtf8(
        QJsonDocument::fromVariant(result.getMap()).toJson(QJsonDocument::Indented)));

    const qlonglong total = result.getValue<qlonglong>("quotaMaxBytes");
    const qlonglong used =
        result.getValue<qlonglong>("quotaUsedBytes") + result.getValue<qlonglong>("quotaReservedBytes");

    emit spaceUpdated(total, used, result.getValue<QVariantList>("usage"));
}

void StorageBackend::reloadIfChanged(QString configJsonStr) {
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

    if (status() == Stopped) {
        LogosResult result = m_logos->storage_module.destroy();

        if (!result.success) {
            reportError("Failed to destroy the context error=" + result.getError());
            return;
        } else {
            setStatus(Destroyed);
        }
    }

    init(configJsonStr);

    m_config = config;
    saveUserConfig(configJsonStr);
    setStatus(Stopped);
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

    obj["data-dir"] = DEFAULT_DATA_DIR;
    obj["listen-port"] = DEFAULT_LISTEN_PORT;
    obj["disc-port"] = DEFAULT_DISC_PORT;

    obj["mix-enabled"] = false; // TEMP FIX: broken with the latest storage-nim
    obj["dht-mix-proxy"] = QJsonArray::fromStringList(DHT_MIX_PROXY);
    obj["mix-pool-json"] = QString::fromUtf8(
        QJsonDocument::fromJson(MIX_POOL_JSON.toUtf8()).toJson(QJsonDocument::Compact));

    return QJsonDocument(obj);
}

bool StorageBackend::isLegacyBootstrap(const QJsonArray& bootstrap) {
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

bool StorageBackend::togglePrivateQueries(bool enabled) {
    qDebug() << "StorageBackend::togglePrivateQueries called with" << enabled;

    LogosResult result = m_logos->storage_module.togglePrivateQueries(enabled);
    if (!result.success) {
        reportError("Failed to toggle private queries: " + result.getError());
        return false;
    }
    return true;
}

void StorageBackend::fetchWidgetsData() {
    QMetaObject::invokeMethod(this, &StorageBackend::refreshNodeStatus, Qt::QueuedConnection);
    QMetaObject::invokeMethod(this, &StorageBackend::refreshSpace, Qt::QueuedConnection);
    QMetaObject::invokeMethod(this, &StorageBackend::downloadManifests, Qt::QueuedConnection);
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
    }

    // No config file yet (first run): the current config, or the defaults if
    // the module was never initialised.
    debug("Failed to read the user config file, use current config.");
    return m_config.isNull() ? defaultConfigJson() : configJson();
}

QString StorageBackend::configJson() { return QString::fromUtf8(m_config.toJson(QJsonDocument::Indented)); }

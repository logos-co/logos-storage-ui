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

void StorageBackend::reportError(const QString& message) {
    debug(message, "warning");
    emit error(message);
}

void StorageBackend::debug(const QString& log, const QString& level) {
    if (!m_debugLogs.isEmpty()) {
        m_debugLogs += "\n";
    }

    QString timestamp = QDateTime::currentDateTime().toString(Qt::ISODate);
    m_debugLogs += timestamp + ": " + log;

    // Notify the property bind debugLogs
    emit debugLogsChanged();

    if (level == "warning") {
        qWarning() << "StorageBackend: " << log;
    } else {
        qDebug() << "StorageBackend: " << log;
    }
}

LogosResult StorageBackend::init(const QString& configJson) {
    qDebug() << "StorageBackend::initStorage called";

    m_config = QJsonDocument::fromJson(configJson.toUtf8());
    if (m_config.isNull()) {
        reportError("Failed to create the storage: invalid JSON config:" + configJson);
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

                // Used in StartNode component to detect
                // failure in the onboarding.
                emit startFailed(message);

                reportError("Failed to start Storage Module: " + message);
            } else {
                setStatus(Running);

                debug("Storage module started.");

                // Fetch data to in order to come on the app
                // with fresh data.
                StorageBackend::fetchWidgetsData();

                // Used in StartNode component to detect
                // success in the onboarding.
                emit startCompleted();
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageStart events";
    }

    if (!m_logos->storage_module.on("storageStop", [this](const QVariantList& data) {
            bool success = data[0].toBool();

            if (!success) {
                setStatus(Running);

                QString message = data[1].toString();
                reportError("Failed to stop Storage module:" + message);
            } else {
                setStatus(Stopped);

                debug("Storage module stopped.");
            }

            // Send stop completed signal event on failure
            // to not block the shutdown process
            emit stopCompleted();
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageStop events";
    }

    if (!m_logos->storage_module.on("storageUploadProgress", [this](const QVariantList& data) {
            bool success = data[0].toBool();

            if (!success) {
                QString message = data[1].toString();
                reportError("Failure during upload progress: " + message);
            } else {
                qint64 len = data[2].toLongLong();
                emit uploadChunk(len);
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageUploadProgress events";
    }

    if (!m_logos->storage_module.on("storageUploadDone", [this](const QVariantList& data) {
            bool success = data[0].toBool();

            if (!success) {
                QString message = data[1].toString();
                reportError("Failed to upload: " + message);
            } else {
                QString sessionId = data[1].toString();
                QString cid = data[2].toString();
                debug("Upload completed for session " + sessionId + " with CID " + cid);
                emit uploadCompleted(cid);
                QMetaObject::invokeMethod(this, &StorageBackend::refreshSpace, Qt::QueuedConnection);
                QMetaObject::invokeMethod(this, &StorageBackend::downloadManifests, Qt::QueuedConnection);
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageUploadProgress events";
    }

    if (!m_logos->storage_module.on("storageDownloadProgress", [this](const QVariantList& data) {
            bool success = data[0].toBool();

            if (!success) {
                QString message = data[1].toString();
                reportError("Failure during download progress: " + message);
            } else {
                QString sessionId = data[1].toString();
                int len = data[2].toInt();
                debug("Downloaded " + QString::number(len) + " bytes for session " + sessionId);
                // TODO display progress here
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageDownloadProgress events";
    }

    if (!m_logos->storage_module.on("storageDownloadDone", [this](const QVariantList& data) {
            bool success = data[0].toBool();

            if (!success) {
                QString message = data[1].toString();
                reportError("Failed to download: " + message);
            } else {
                QString sessionId = data[1].toString();
                QString cid = data[2].toString();

                // Notify the QML to display something (TBU) on download completed
                emit downloadCompleted(cid);

                // Call refreshSpace to fetch the new space used by the node
                // and reflect on the widget.
                QMetaObject::invokeMethod(this, &StorageBackend::refreshSpace, Qt::QueuedConnection);

                debug("Download completed for session " + sessionId + " with CID " + cid);
            }
        })) {
        qWarning() << "StorageWidget: failed to subscribe to storageDownloadProgress events";
    }

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

    // TODO trace the start attempts in a file

    auto result = m_logos->storage_module.start();

    if (!result) {
        setStatus(Stopped);
        reportError("Failed to start storage");
        return {false, "", "Failed to start storage"};
    }

    qDebug() << "StorageBackend: start command sent, waiting for events.";

    return {true, ""};
}

void StorageBackend::stop() {
    qDebug() << "StorageBackend: stop method called";

    if (m_status == StorageStatus::Stopping) {
        debug("The Storage Module is already stopping.");
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
        reportError("Error when trying to stop: " + result.getError());
        return;
    }

    qDebug() << "StorageBackend: stop command sent, waiting for events.";
}

void StorageBackend::destroy() {
    qDebug() << "StorageBackend: destroy method called";

    auto result = m_logos->storage_module.destroy();

    if (!result.success) {
        reportError("Error when trying to destroy: " + result.getError());
        return;
    }

    qDebug() << "StorageBackend: Storage module destroyed.";
}

void StorageBackend::logDebugInfo() {
    auto result = m_logos->storage_module.debug();

    debug("Peer ID: " + result.getString("id"));
    debug("SPR: " + result.getString("spr"));

    QStringList addrs = result.getValue<QStringList>("addrs");
    for (const QString& addr : addrs) {
        debug("Listen address: " + addr);
    }

    QStringList announceAddresses = result.getValue<QStringList>("announceAddresses");
    for (const QString& addr : announceAddresses) {
        debug("Announce address: " + addr);
    }

    QVariantMap table = result.getValue<QVariantMap>("table");
    QVariantList nodes = table["nodes"].toList();

    for (const QVariant& nodeVar : nodes) {
        QVariantMap node = nodeVar.toMap();
        QString peerId = node["peerId"].toString();
        bool seen = node["seen"].toBool();
        debug("Peer found, peerId=" + peerId + ", seen=" + (seen ? "true" : "false"));
    }

    emit peersUpdated(nodes.size());
}

void StorageBackend::uploadFile(const QUrl& url) {
    qDebug() << "StorageBackend: uploadFile called";

    if (!url.isLocalFile()) {
        reportError("The provided URL is not a local file.");
        return;
    }

    qint64 totalBytes = QFileInfo(url.toLocalFile()).size();
    debug(QString("Starting upload of file: %1 bytes").arg(totalBytes));
    emit uploadStarted(totalBytes);

    LogosResult result = m_logos->storage_module.uploadUrl(url);

    if (!result.success) {
        reportError("Failed to upload file:" + result.getError());
        return;
    }

    QString sessionId = result.value.value<QString>();

    qDebug() << "StorageBackend: uploadFile result =" << sessionId;
}

void StorageBackend::downloadFile(const QString& cid, const QUrl& url) {
    qDebug() << "StorageBackend: downloadFile called";

    if (!url.isLocalFile()) {
        reportError("The provided URL is not a local file.");
        return;
    }

    LogosResult result = m_logos->storage_module.downloadToUrl(cid, url, false);

    if (!result.success) {
        reportError("Failed to download file:" + result.getError());
        return;
    }

    QString sessionId = result.value.value<QString>();

    qDebug() << "StorageBackend: downloadFile result =" << sessionId;
}

void StorageBackend::exists(const QString& cid) {
    qDebug() << "StorageBackend::exists called";

    LogosResult result = m_logos->storage_module.exists(cid);

    if (!result.success) {
        reportError("StorageBackend::exists failed with error=" + result.getError());
        return;
    }

    debug("Does " + cid + " exists ? " + QVariant(result.getValue<bool>()).toString());
}

void StorageBackend::remove(const QString& cid) {
    qDebug() << "StorageBackend::remove called with cid=" << cid;

    LogosResult result = m_logos->storage_module.exists(cid);

    if (!result.success) {
        reportError("Failed to check exists: " + result.getError());
        return;
    }

    if (!result.getBool()) {
        debug("Blocks don't exist in store.");
        return;
    }

    result = m_logos->storage_module.remove(cid);
    if (!result.success) {
        reportError("Failed to remove " + cid + ": " + result.getError());
        return;
    }

    debug("Cid " + cid + " removed from local storage.");

    // Refresh space data for Disk widget
    QMetaObject::invokeMethod(this, &StorageBackend::refreshSpace, Qt::QueuedConnection);
}

void StorageBackend::fetch(const QString& cid) {
    qDebug() << "StorageBackend::fetch called";

    LogosResult result = m_logos->storage_module.fetch(cid);

    if (!result.success) {
        reportError("Failed to fetch cid " + cid + ": " + result.getError());
        return;
    }

    debug("Cid " + cid + " fetched.");
}

void StorageBackend::logVersion() {
    qDebug() << "StorageBackend::version called";

    LogosResult result = m_logos->storage_module.version();

    if (!result.success) {
        reportError("Failed to log version: " + result.getError());
        return;
    }

    debug("Version: " + result.getString());
}

void StorageBackend::logPeerId() {
    qDebug() << "StorageBackend::peerId called";

    LogosResult result = m_logos->storage_module.peerId();

    if (!result.success) {
        reportError("Failed to log peerId: " + result.getError());
        return;
    }

    debug("Peer ID: " + result.getString());
}

void StorageBackend::logSpr() {
    qDebug() << "StorageBackend::spr called";

    LogosResult result = m_logos->storage_module.spr();

    if (!result.success) {
        reportError("Failed to log spr: " + result.getError());
        return;
    }

    debug("SPR: " + result.getString());
}

void StorageBackend::logDataDir() {
    qDebug() << "StorageBackend::dataDir called";

    LogosResult result = m_logos->storage_module.dataDir();

    if (!result.success) {
        reportError("Failed to log dataDir: " + result.getError());
        return;
    }

    debug("Data dir: " + result.getString());
}

void StorageBackend::downloadManifest(const QString& cid) {
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

    // Refresh the table
    downloadManifests();
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

    const qlonglong total = result.getValue<qlonglong>("quotaMaxBytes");
    const qlonglong used =
        result.getValue<qlonglong>("quotaUsedBytes") + result.getValue<qlonglong>("quotaReservedBytes");

    emit spaceUpdated(total, used);
}

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
            reportError("Failed to destroy the context error=" + result.getError());
            return;
        } else {
            setStatus(StorageStatus::Destroyed);
        }
    }

    LogosResult result = init(configJson);

    if (!result.success) {
        reportError("Failed to init context with new config: " + result.getError());
        return;
    }

    debug("New config loaded successfully");

    m_config = config;
    setStatus(StorageStatus::Stopped);
}

void StorageBackend::saveCurrentConfig() {
    qDebug() << "StorageBackend::saveUserConfig";
    saveUserConfig(configJson());
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
        reportError("Failed to save config to " + USER_CONFIG_PATH);
    }

    QJsonDocument config = QJsonDocument::fromJson(configJson.toUtf8());
    if (config.isNull()) {
        reportError("Invalid json config" + configJson);
        return;
    }

    m_config = config;
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

// Note that debug is not used because the debug panel is not accessible yet
void StorageBackend::enableNatExtConfig(int tcpPort) {
    qDebug() << "StorageBackend::enableNatExtConfig called with tcpPort" << tcpPort;

    QJsonDocument doc = defaultConfig();
    QJsonObject obj = doc.object();

    QJsonArray listenAddrs = {QString("/ip4/0.0.0.0/tcp/%1").arg(tcpPort)};
    obj["listen-addrs"] = listenAddrs;

    // Fetch the public IP asynchronously so we can set nat=extip:IP in the config.
    qDebug() << "StorageBackend:: Retrieving public IP...";

    QNetworkAccessManager* manager = new QNetworkAccessManager(this);
    QNetworkRequest request(ECHO_PROVIDER);

    // Set text/plain to receive only the IP
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

// Note that debug is not used because the debug panel is not accessible yet
void StorageBackend::checkNodeIsUp() {
    qDebug() << "StorageBackend::checkNodeIsUp called.";

    // First we get the debug info in order to get the peers and
    // the announceAddresses
    LogosResult result = m_logos->storage_module.debug();
    if (!result.success) {
        qWarning() << "StorageBackend::checkNodeIsUp Failed to get node debug info: " << result.getError();
        emit nodeIsntUp("Failed to get node debug info: " + result.getError());
        return;
    }

    // Ensure that the node has at least one peer.
    QVariantMap table = result.getValue<QVariantMap>("table");
    QVariantList nodes = table["nodes"].toList();

    debug(QString("Connected peers: %1").arg(nodes.size()));

    if (nodes.isEmpty()) {
        qWarning() << "StorageBackend::checkNodeIsUp Not peers connected";
        emit nodeIsntUp("No peers connected. "
                        "Try modifying the discovery port (default 8090) in the advanced settings.");
        return;
    }

    qDebug() << "StorageBackend::checkNodeIsUp DHT seems okay, found peers";

    // Extract IP+port pairs from announceAddresses.
    // Format: "/ip4/1.2.3.4/tcp/PORT"
    QVariantList announceAddresses = result.getValue<QVariantList>("announceAddresses");
    QList<QPair<QString, int>> endpoints;
    for (const QVariant& addr : announceAddresses) {
        const QStringList parts = addr.toString().split("/");
        // ["", "ip4", "1.2.3.4", "tcp", "8079"]
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

            QString status = reachable ? "reachable" : "not reachable";
            qDebug() << "StorageBackend::checkNodeIsUp " << ip << ":" << port << status;

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
}

void StorageBackend::fetchWidgetsData() {
    QMetaObject::invokeMethod(this, &StorageBackend::logDebugInfo, Qt::QueuedConnection);
    QMetaObject::invokeMethod(this, &StorageBackend::refreshSpace, Qt::QueuedConnection);
    QMetaObject::invokeMethod(this, &StorageBackend::downloadManifests, Qt::QueuedConnection);
}

void StorageBackend::loadUserConfig() {
    qDebug() << "StorageBackend::loadUserConfig called.";

    QFile file(USER_CONFIG_PATH);
    LogosResult result;

    if (file.exists() && file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        result = init(QString::fromUtf8(file.readAll()));
    } else {
        debug("Failed to read the user config file, fallback to default config");
        result = init(QString::fromUtf8(defaultConfig().toJson(QJsonDocument::Indented)));
    }

    if (!result.success) {
        reportError("Failed to load the user config: " + result.getError());
    } else {
        debug("User config loaded successfully");
    }
}

QString StorageBackend::debugLogs() const { return m_debugLogs; };

QString StorageBackend::configJson() const { return QString::fromUtf8(m_config.toJson(QJsonDocument::Indented)); }

StorageBackend::StorageStatus StorageBackend::status() const { return m_status; }


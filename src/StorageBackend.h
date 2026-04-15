#pragma once
#include "logos_api.h"
#include "logos_sdk.h"
#include "rep_StorageBackend_source.h"
#include <QDir>
#include <QFile>
#include <QObject>
#include <QString>
#include <QStringList>
#include <QTimer>

static const int RET_OK = 0;
static const int RET_PROGRESS = 3;
// static const QString ECHO_PROVIDER = "https://echo.codex.storage/";
static const QString ECHO_PROVIDER = "https://ipv4.icanhazip.com";
static const QString PORT_CHECKER_PROVIDER = "https://portchecker.io/api/";
static const QString APP_HOME = QDir::homePath() + "/.logos_storage";
static const QString DEFAULT_DATA_DIR = APP_HOME + "/data";
static const QString USER_CONFIG_PATH = APP_HOME + "/config.json";

static const int DEFAULT_LISTEN_PORT = 8500;
static const int DEFAULT_DISC_PORT = 9090;

// Add manual SPR from https://spr.codex.storage/devnet
static const QStringList BOOTSTRAP_NODES = {
    "spr:CiUIAhIhA-VlcoiRm02KyIzrcTP-ljFpzTljfBRRKTIvhMIwqBqWEgIDARpJCicAJQgCEiED5WVyiJGbTYrIjOtxM_6WMWnNOWN8FFEpMi-"
    "EwjCoGpYQs8n8wQYaCwoJBHTKubmRAnU6GgsKCQR0yrm5kQJ1OipHMEUCIQDwUNsfReB4ty7JFS5WVQ6n1fcko89qVAOfQEHixa03rgIgan2-"
    "uFNDT-r4s9TOkLe9YBkCbsRWYCHGGVJ25rLj0QE",
    "spr:CiUIAhIhApIj9p6zJDRbw2NoCo-"
    "tj98Y760YbppRiEpGIE1yGaMzEgIDARpJCicAJQgCEiECkiP2nrMkNFvDY2gKj62P3xjvrRhumlGISkYgTXIZozMQvcz8wQYaCwoJBAWhF3WRAnVEG"
    "gsKCQQFoRd1kQJ1RCpGMEQCIFZB84O_nzPNuViqEGRL1vJTjHBJ-i5ZDgFL5XZxm4HAAiB8rbLHkUdFfWdiOmlencYVn0noSMRHzn4lJYoShuVzlw",
    "spr:CiUIAhIhApqRgeWRPSXocTS9RFkQmwTZRG-"
    "Cdt7UR2N7POoz606ZEgIDARpJCicAJQgCEiECmpGB5ZE9JehxNL1EWRCbBNlEb4J23tRHY3s86jPrTpkQj8_"
    "8wQYaCwoJBAXfEfiRAnVOGgsKCQQF3xH4kQJ1TipGMEQCIGWJMsF57N1iIEQgTH7IrVOgEgv0J2P2v3jvQr5Cjy-RAiAy4aiZ8QtyDvCfl_K_"
    "w6SyZ9csFGkRNTpirq_M_QNgKw"};

class StorageBackend : public StorageBackendSimpleSource {
    Q_OBJECT
  public:
    explicit StorageBackend(LogosAPI* logosAPI = nullptr, QObject* parent = nullptr);
    ~StorageBackend();

  public slots:
    // Overrides of the pure-virtual slots generated from the .rep.
    // Note: .rep generates value-type parameters (QString, QUrl), not const refs.

    void init(QString configJson) override;
    void start() override;
    void destroy() override;
    void stop() override;

    void logDebugInfo() override;
    void logDataDir() override;
    void logVersion() override;
    void listSettings() override;
    void restartOnboarding() override;
    void logSpr() override;
    void logPeerId() override;

    void exists(QString cid) override;
    void remove(QString cid) override;
    void fetch(QString cid) override;

    void uploadFile(QUrl url) override;
    void downloadFile(QString cid, QUrl url, qint64 totalBytes) override;

    void downloadManifest(QString cid) override;
    void downloadManifests() override;

    void refreshSpace() override;

    void saveUserConfig(QString configJson) override;
    void saveCurrentConfig() override;
    void loadUserConfig() override;
    QString getUserConfig() override;

    void reloadIfChanged(QString configJson) override;

    void enableUpnpConfig() override;
    void enableNatExtConfig(int tcpPort) override;

    void checkNodeIsUp() override;
    void fetchWidgetsData() override;

    QString configJson() override;
    QString defaultConfigJson() override;

  private:
    // Provide a default config for onboarding
    static QJsonDocument defaultConfig();

    // Display debug (or message) in the terminal and
    // add it to the debugLogs to make it accessible
    // from the debug panel.
    void debug(const QString& log, const QString& level = "debug");

    // Display log and add it to debugLogs
    // Emit error(message)
    void reportError(const QString& message);

    // Logos related variables
    LogosAPI* m_logosAPI;
    LogosModules* m_logos;

    // Internal configuration object.
    QJsonDocument m_config;
};

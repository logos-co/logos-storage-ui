#include "StorageUIPlugin.h"
#include "StorageBackend.h"
#include <QCoreApplication>
#include <QDebug>
#include <QFile>
#include <QFileInfo>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickItem>
#include <QQuickWidget>
#include <QSettings>

QWidget* StorageUIPlugin::createWidget(LogosAPI* logosAPI) {
    qDebug() << "StorageUIPlugin::createWidget called";

    QCoreApplication::setOrganizationName("Logos");
    QCoreApplication::setApplicationName("LogosStorage");

    QQuickWidget* quickWidget = new QQuickWidget();
    quickWidget->setResizeMode(QQuickWidget::SizeRootObjectToView);

    // Add import path for Logos QML modules (Logos.Theme, Logos.Controls)
    QQmlEngine* engine = quickWidget->engine();
    QString qmlModulesPath = QCoreApplication::applicationDirPath() + "/../lib";
    engine->addImportPath(qmlModulesPath);

    qDebug() << "StorageUIPlugin: Loading settings...";

    // Default constructor uses QCoreApplication org/domain/app — same path as QML QtCore.Settings
    // QSettings settings;
    // int discoveryPort = settings.value("Storage/discoveryPort", 8090).toInt();
    // int tcpPort = settings.value("Storage/tcpPort", 0).toInt();
    // QString dataDir = settings.value("Storage/dataDir", "").toString();
    // bool onboardingCompleted = settings.value("Storage/onboardingCompleted", false).toBool();

    // qDebug() << "StorageUIPlugin: Settings file:" << settings.fileName();
    // qDebug() << "StorageUIPlugin: onboardingCompleted=" << onboardingCompleted;
    // qDebug() << "StorageUIPlugin: dataDir=" << dataDir;
    // qDebug() << "StorageUIPlugin: discoveryPort=" << discoveryPort;
    // qDebug() << "StorageUIPlugin: tcpPort=" << tcpPort;

    // Always load Main.qml — QML handles navigation (onboarding vs startNode)
    StorageBackend* backend = new StorageBackend(logosAPI, quickWidget);

    quickWidget->setSource(QUrl("qrc:/Main.qml"));

    if (quickWidget->status() == QQuickWidget::Error) {
        qWarning() << "StorageUIPlugin: Failed to load QML:" << quickWidget->errors();
    }

    // Set backend as context property
    QQuickItem* root = quickWidget->rootObject();
    Q_ASSERT(root);

    root->setProperty("backend", QVariant::fromValue(static_cast<QObject*>(backend)));

    // Build config from settings if onboarding was done, otherwise use empty config
    QString configJson = StorageBackend::getUserConfig();
    qDebug() << "UserConfig" << StorageBackend::getUserConfigPath();
    qDebug() << "configJson" << configJson;
    // if (onboardingCompleted && !dataDir.isEmpty()) {
    //     configJson = backend->buildConfig(dataDir, discoveryPort, tcpPort);
    // }

    // config.json overrides everything (dev/debug use)
    // QFileInfo info("config.json");
    // if (info.exists() && info.isFile()) {
    //     qWarning() << "StorageUIPlugin: config.json found — overriding settings config";
    //     configJson = backend->buildConfigFromFile("config.json");
    // }

    // qDebug() << "StorageUIPlugin: configJson=" << configJson;

    LogosResult result = backend->init(configJson);

    if (!result.success) {
        qWarning() << "StorageUIPlugin: Failed to init backend:" << result.getError();
    }

    return quickWidget;
}

// Destroy the widget and clean up the backend.
// It will block the event loop up to 2 seconds to ensure proper cleanup.
// It will try to stop the backend if it is running.`
void StorageUIPlugin::destroyWidget(QWidget* widget) {
    qDebug() << "StorageUIPlugin: Destroy widget";

    auto* quickWidget = qobject_cast<QQuickWidget*>(widget);
    if (!quickWidget) {
        delete widget;
        return;
    }

    QQuickItem* root = quickWidget->rootObject();
    if (!root) {
        qWarning() << "StorageUIPlugin::destroyWidget: No rootObject, deleting widget";
        quickWidget->deleteLater();
        return;
    }

    // Disable QML to ensure that not updated are pushed in the UI
    root->setEnabled(false);

    // Retrieve the backend object from the root element
    // as it was set in createWidget
    QObject* value = root->property("backend").value<QObject*>();
    auto* backend = qobject_cast<StorageBackend*>(value);
    if (!backend) {
        qWarning() << "StorageUIPlugin::destroyWidget: No backend found on root property 'backend'.";
        quickWidget->deleteLater();
        return;
    }

    if (backend->status() != StorageBackend::StorageStatus::Destroyed) {
        qDebug() << "StorageUIPlugin::destroyWidget: backend is not initialised so let's detroy it.";
        quickWidget->deleteLater();
        return;
    }

    if (backend->status() == StorageBackend::StorageStatus::Running) {
        qDebug() << "StorageUIPlugin::destroyWidget: backend is not running so let's detroy it.";

        backend->destroy();

        quickWidget->deleteLater();

        return;
    }

    qDebug() << "StorageUIPlugin::destroyWidget: backend is running so let's stop it.";

    // Here we create a QEventLoop to wait for the stopped signal
    QEventLoop loop;
    QTimer timeout;
    // Single shot means that the timer will only fire once.
    timeout.setSingleShot(true);

    // Connect to timeout and unblock the event loop after 2 seconds
    QObject::connect(&timeout, &QTimer::timeout, &loop, [&]() {
        qWarning() << "StorageUIPlugin::destroyWidget: stop timeout";
        loop.quit();
    });

    // Connect to stop signal
    QObject::connect(backend, &StorageBackend::stopCompleted, &loop, [&]() { loop.quit(); }, Qt::QueuedConnection);

    // Call the stop method asynchronously
    QMetaObject::invokeMethod(backend, "stop", Qt::QueuedConnection);

    // Set the timeout to 2 sec
    timeout.start(2000);

    // Block
    loop.exec();

    // Try to cleanup, event if the stop method failed
    backend->destroy();

    delete quickWidget;
}

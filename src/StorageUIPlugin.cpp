#include "StorageUIPlugin.h"
#include "StorageBackend.h"
#include <QDebug>
#include <QFile>
#include <QFileInfo>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickItem>
#include <QQuickWidget>

QWidget* StorageUIPlugin::createWidget(LogosAPI* logosAPI) {
    qDebug() << "StorageUIPlugin::createWidget called";

    QQuickWidget* quickWidget = new QQuickWidget();
    quickWidget->setResizeMode(QQuickWidget::SizeRootObjectToView);

    QString qmlPath = "qrc:/StorageView.qml";

    quickWidget->setSource(QUrl(qmlPath));

    if (quickWidget->status() == QQuickWidget::Error) {
        qWarning() << "StorageUIPlugin: Failed to load QML:" << quickWidget->errors();
    }

    // Create backend instance
    StorageBackend* backend = new StorageBackend(logosAPI, quickWidget);

    // Set backend as context property
    QQuickItem* root = quickWidget->rootObject();
    Q_ASSERT(root);

    root->setProperty("backend", QVariant::fromValue(static_cast<QObject*>(backend)));

    QFileInfo info("config.json");
    QString configJson = "{}";

    if (info.exists() && info.isFile()) {
        qDebug() << "StorageUIPlugin: config.json is found, let's try to load it...";

        QFile file("config.json");
        if (file.exists() && file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            configJson = QString::fromUtf8(file.readAll());

            qDebug() << "StorageUIPlugin: config.json is found, let's try to load it... configJson=" << configJson;
        } else {
            qDebug() << "StorageUIPlugin: Failed to load config.json";
        }
    }

    LogosResult result = backend->init(configJson);

    if (!result.success) {
        QString error = result.getError();
        qWarning() << "StorageUIPlugin: Failed to init backend, will use mock version:" << error;
    } else {
        result = backend->start();

        if (!result.success) {
            qWarning() << "StorageUIPlugin: Failed to init backend, will use mock version:" << result.getError();
        }
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
    QObject::connect(backend, &StorageBackend::stopped, &loop, [&]() { loop.quit(); }, Qt::QueuedConnection);

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

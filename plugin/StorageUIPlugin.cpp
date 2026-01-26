#include "StorageUIPlugin.h"
#include "src/StorageBackend.h"
#include <QQuickWidget>
#include <QQmlContext>
#include <QQmlEngine>
#include <QDebug>
#include <QFileInfo>
#include <QFile>

QWidget* StorageUIPlugin::createWidget(LogosAPI* logosAPI) {
    qDebug() << "StorageUIPlugin::createWidget called";

    QQuickWidget* quickWidget = new QQuickWidget();
    quickWidget->setResizeMode(QQuickWidget::SizeRootObjectToView);

    // Register StorageBackend type with QML engine to expose the enum
    qmlRegisterType<StorageBackend>("StorageBackend", 1, 0, "StorageBackend");

    // Create backend instance
    StorageBackend* backend = new StorageBackend(logosAPI, quickWidget);
    
    // Set backend as context property
    quickWidget->rootContext()->setContextProperty("backend", backend);

    // For development: check environment variable, otherwise use qrc
    QString qmlPath = "qrc:/StorageView.qml";
    QString envPath = qgetenv("STORAGE_UI_QML_PATH");
    if (!envPath.isEmpty() && QFile::exists(envPath)) {
        qmlPath = QUrl::fromLocalFile(QFileInfo(envPath).absoluteFilePath()).toString();
        qDebug() << "Loading QML from file system:" << qmlPath;
    }
    
    quickWidget->setSource(QUrl(qmlPath));
    
    if (quickWidget->status() == QQuickWidget::Error) {
        qWarning() << "StorageUIPlugin: Failed to load QML:" << quickWidget->errors();
    }

    return quickWidget;
}

void StorageUIPlugin::destroyWidget(QWidget* widget) {
    delete widget;
}
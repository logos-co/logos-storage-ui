#include "StorageUIPlugin.h"
#include "StorageBackend.h"

#include <QDebug>
#include <QEventLoop>
#include <QMetaObject>
#include <QTimer>

using StorageStatus = StorageBackendSimpleSource::StorageStatus;

StorageUIPlugin::StorageUIPlugin(QObject* parent)
    : QObject(parent)
{
}

StorageUIPlugin::~StorageUIPlugin()
{
    StorageBackend* backend = m_backend;
    if (!backend)
        return;

    const StorageStatus s = backend->status();

    if (s != StorageBackendSimpleSource::Running) {
        qDebug() << "StorageUIPlugin: backend not running, teardown skipped";
        return;
    }

    qDebug() << "StorageUIPlugin: stopping backend during teardown";

    QEventLoop loop;
    QTimer timeout;
    timeout.setSingleShot(true);

    QObject::connect(&timeout, &QTimer::timeout, &loop, [&]() {
        qWarning() << "StorageUIPlugin: stop timeout during teardown";
        loop.quit();
    });

    QObject::connect(backend, &StorageBackend::stopCompleted, &loop, [&]() { loop.quit(); },
                     Qt::QueuedConnection);

    QMetaObject::invokeMethod(backend, "stop", Qt::QueuedConnection);

    timeout.start(2000);
    loop.exec();
}

void StorageUIPlugin::initLogos(LogosAPI* api)
{
    if (m_backend) return;
    m_backend = new StorageBackend(api, this);
    setBackend(m_backend);
    qDebug() << "StorageUIPlugin: backend initialized";
}

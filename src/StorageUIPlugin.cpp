#include "StorageUIPlugin.h"
#include "StorageBackend.h"

#include <QDebug>

StorageUIPlugin::StorageUIPlugin(QObject* parent)
    : QObject(parent)
{
}

StorageUIPlugin::~StorageUIPlugin()
{
    if (m_backend) {
        m_backend->stop();
        m_backend->destroy();
    }
}

void StorageUIPlugin::initLogos(LogosAPI* api)
{
    if (m_backend) return;
    m_backend = new StorageBackend(api, this);
    setBackend(m_backend);
    qDebug() << "StorageUIPlugin: backend initialized";
}

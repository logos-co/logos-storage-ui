#ifndef STORAGE_UI_PLUGIN_H
#define STORAGE_UI_PLUGIN_H

#include <QObject>
#include <QString>
#include <QtPlugin>          // for Q_PLUGIN_METADATA, Q_INTERFACES
#include "StorageInterface.h"
#include "LogosViewPluginBase.h"

class LogosAPI;
class StorageBackend;

// Thin plugin entry point. Holds a StorageBackend and lets the
// generated view-plugin base expose it to ui-host.
class StorageUIPlugin : public QObject,
                        public StorageInterface,
                        public StorageBackendViewPluginBase
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID StorageInterface_iid FILE "../metadata.json")
    Q_INTERFACES(StorageInterface)

public:
    explicit StorageUIPlugin(QObject* parent = nullptr);
    ~StorageUIPlugin() override;

    QString name()    const override { return "storage_ui"; }
    QString version() const override { return "1.0.0"; }

    // Called by ui-host after plugin load. Creates the backend and wires
    // it up with the provided LogosAPI.
    Q_INVOKABLE void initLogos(LogosAPI* api);

private:
    StorageBackend* m_backend = nullptr;
};

#endif

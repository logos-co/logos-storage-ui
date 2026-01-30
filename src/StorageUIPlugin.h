#pragma once

#include <IComponent.h>
#include <QObject>

class StorageUIPlugin : public QObject, public IComponent {
    Q_OBJECT
    Q_INTERFACES(IComponent)
    Q_PLUGIN_METADATA(IID IComponent_iid FILE "metadata.json")

public:
    Q_INVOKABLE QWidget* createWidget(LogosAPI* logosAPI = nullptr) override;
    Q_INVOKABLE void destroyWidget(QWidget* widget) override;
};

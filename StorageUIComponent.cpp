#include "StorageUIComponent.h"
#include "src/StorageWidget.h"

QWidget* StorageUIComponent::createWidget(LogosAPI* logosAPI) {
    // LogosAPI parameter available but not used - StorageWidget creates its own
    return new StorageWidget();
}

void StorageUIComponent::destroyWidget(QWidget* widget) {
    delete widget;
}
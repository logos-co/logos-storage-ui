#include "DebugWidget.h"
#include <QDebug>

// Static pointer to the active StorageWidget for callbacks
static StorageWidget* activeWidget = nullptr;

StorageWidget::StorageWidget(QWidget* parent) : QWidget(parent) {

    // Set as the active widget
    activeWidget = this;

    // m_logosAPI = new LogosAPI("core", this);
    // logos = new LogosModules(m_logosAPI);

    // Main vertical layout
    mainLayout = new QVBoxLayout(this);
}

StorageWidget::~StorageWidget() {
    // Reset the active widget if it's this instance
    if (activeWidget == this) {
        activeWidget = nullptr;
    }
}

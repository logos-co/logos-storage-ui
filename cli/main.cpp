#include "logos_manager.h"

#include <QCoreApplication>
#include <QDir>
#include <iostream>

#include "storage_module_api.h"

int main(int argc, char* argv[]) {
    QCoreApplication app(argc, argv);

    QCoreApplication::setOrganizationName("Logos");
    QCoreApplication::setApplicationName("LogosStorageCLI");

    // Set the plugins directory
    QString pluginsDir = QDir::cleanPath(QCoreApplication::applicationDirPath() + "/../modules");

    // Initialize Logos Core and load required plugins
    Logos logos(pluginsDir);
    if (!logos.init()) {
        std::cerr << "Failed to initialize Logos" << std::endl;
        return 1;
    }

    // Use the Storage Module
    StorageModule storage(logos.api());

    // Echo: get version (does not require the node to be started)
    LogosResult result = storage.version();
    if (result.success) {
        std::cout << "Storage version: " << result.getString().toStdString() << std::endl;
    } else {
        std::cerr << "Failed to get storage version: " << result.getError().toStdString() << std::endl;
    }

    // logos destructor calls cleanup() automatically
    return 0;
}

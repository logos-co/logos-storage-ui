#include "mainwindow.h"
#include <QApplication>
#include <QCoreApplication>
#include <QDebug>
#include <QLabel>
#include <QPluginLoader>
#include <QVBoxLayout>

extern "C" {
void logos_core_cleanup();
}

void MainWindow::destroy() {
    qDebug() << "MainWindow: Destroying MainWindow...";

    if (plugin && storageWidget) {
        QMetaObject::invokeMethod(plugin, "destroyWidget", Qt::DirectConnection, Q_ARG(QWidget*, storageWidget));
    }
}

MainWindow::MainWindow(QWidget* parent) : QMainWindow(parent) { setupUi(); }

MainWindow::~MainWindow() {}

void MainWindow::setupUi() {
    // Determine the appropriate plugin extension based on the platform
    QString pluginExtension;

#if defined(Q_OS_WIN)
    pluginExtension = ".dll";
#elif defined(Q_OS_MAC)
    pluginExtension = ".dylib";
#else // Linux and other Unix-like systems
    pluginExtension = ".so";
#endif

    // Load the storage_ui plugin with the appropriate extension
    QString pluginPath = QCoreApplication::applicationDirPath() + "/../storage_ui" + pluginExtension;
    QPluginLoader loader(pluginPath);

    QWidget* widget = nullptr;

    if (loader.load()) {
        plugin = loader.instance();
        if (plugin) {
            // Try to create the storage widget using the plugin's createWidget method
            QMetaObject::invokeMethod(plugin, "createWidget", Qt::DirectConnection, Q_RETURN_ARG(QWidget*, widget));
        }
    }

    if (widget) {
        storageWidget = widget;
        setCentralWidget(storageWidget);
    } else {
        qWarning() << "================================================";
        qWarning() << "Failed to load storage UI plugin from:" << pluginPath;
        qWarning() << "Error:" << loader.errorString();
        qWarning() << "================================================";

        // Fallback: show a message when plugin is not found
        QWidget* fallbackWidget = new QWidget(this);
        QVBoxLayout* layout = new QVBoxLayout(fallbackWidget);

        QLabel* messageLabel = new QLabel("Storage UI module not loaded", fallbackWidget);
        QFont font = messageLabel->font();
        font.setPointSize(14);
        messageLabel->setFont(font);
        messageLabel->setAlignment(Qt::AlignCenter);

        layout->addWidget(messageLabel);
        setCentralWidget(fallbackWidget);
    }

    // Set window title and size
    setWindowTitle("Logos Storage UI App");
    resize(1400, 800);
}

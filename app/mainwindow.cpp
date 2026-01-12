#include "mainwindow.h"
#include <QApplication>
#include <QCoreApplication>
#include <QPluginLoader>
#include <QDebug>
#include <QLabel>
#include <QVBoxLayout>
#include <QDir>
#include <QCloseEvent>

extern "C" {
    void logos_core_cleanup();
}

void MainWindow::cleanup()
{
    qDebug() << "MainWindow: Cleaning up before exit...";

    if (storageWidget) { 
        bool running = false;
        if (storageWidget) {
            QMetaObject::invokeMethod(storageWidget, "isStorageRunning",
                                    Qt::DirectConnection,
                                    Q_RETURN_ARG(bool, running));
        }

        if (running) {
            qDebug() << "MainWindow: Stopping Storage before destroying...";

            QEventLoop loop;
            QObject::connect(storageWidget, SIGNAL(storageStop()), &loop, SLOT(quit()));
            QMetaObject::invokeMethod(storageWidget, "stopStorage", Qt::QueuedConnection);
            loop.exec();
    
            qDebug() << "MainWindow: Storage stopped.";
        }

        qDebug() << "MainWindow: Destroying Storage...";

        QEventLoop loop;
        QObject::connect(storageWidget, SIGNAL(storageCleanup()), &loop, SLOT(quit()));
        QMetaObject::invokeMethod(storageWidget, "destroy", Qt::QueuedConnection);
        loop.exec();

        qDebug() << "MainWindow: Storage destroyed.";
    }
}

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
{
    setupUi();
}

MainWindow::~MainWindow()
{
}

void MainWindow::setupUi()
{
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
        QObject* plugin = loader.instance();
        if (plugin) {
            // Try to create the storage widget using the plugin's createWidget method
            QMetaObject::invokeMethod(plugin, "createWidget",
                                    Qt::DirectConnection,
                                    Q_RETURN_ARG(QWidget*, widget));
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
    // resize(800, 600);
}

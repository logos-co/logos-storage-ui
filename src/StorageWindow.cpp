#include "StorageWindow.h"
#include <QAction>
#include <QDebug>
#include <QMessageBox>

StorageWindow::StorageWindow(QWidget* parent) : QMainWindow(parent) {
    // Create central widget
    storageWidget = new StorageWidget(this);
    setCentralWidget(storageWidget);

    // Setup the UI
    // setupMenu();
    setupStatusBar();

    // Set window properties
    setMinimumSize(640, 480);

    // connect(stor, &StorageWindow::onDebugButtonClicked, this, [this] {
    //     debugDock->show();
    //     debugDock->raise();
    //     debugDock->setFocus();
    // });
}

StorageWindow::~StorageWindow() {
    // StorageWidget will be deleted automatically as it's a child of this window
}

void StorageWindow::setupStatusBar() {
    statusBar = new QStatusBar(this);
    setStatusBar(statusBar);
    statusBar->showMessage("Ready");
}

void StorageWindow::onAboutAction() {
    QMessageBox::about(this, "About Logos Storage",
                       "Logos Storage Application\n\n"
                       "A sample Qt application demonstrating Storage integration.");
}

void StorageWindow::onInitStorage() {
    qDebug() << "Initializing Storage from menu";
    storageWidget->initStorage();
    statusBar->showMessage("Storage initialization requested");
}

// void StorageWindow::onStopStorage() {
//     qDebug() << "Stopping Storage from menu";
//     // storageWidget->stopStorage();
//     statusBar->showMessage("Storage stop requested");
// }

// void StorageWindow::showAbout() {
//     QString version;

//     qDebug() << "StorageWindow: Retrieving Storage version for About Dialog...";

//     QMetaObject::invokeMethod(storageWidget, "storageVersion", Qt::DirectConnection, Q_RETURN_ARG(QString, version));

//     qDebug() << "StorageWindow: Showing About Dialog, version:" << version;
//     AboutDialog dlg(this, version);
//     dlg.exec();
// }

// void MainWindow::showDebug() {
//     QString debug;

//     qDebug() << "MainWindow: Retrieving Storage debug for Debug Dialog...";

//     QMetaObject::invokeMethod(storageWidget, "storageDebug", Qt::DirectConnection, Q_RETURN_ARG(QString, debug));

//     qDebug() << "MainWindow: Showing Debug Dialog, debug:" << debug;
//     DebugDialog dlg(this, debug);
//     dlg.exec();
// }

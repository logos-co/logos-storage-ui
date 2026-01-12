#include "StorageWindow.h"
#include <QMenuBar>
#include <QMenu>
#include <QAction>
#include <QMessageBox>
#include <QDebug>

StorageWindow::StorageWindow(QWidget *parent) : QMainWindow(parent)
{
    // Create central widget
    storageWidget = new StorageWidget(this);
    setCentralWidget(storageWidget);

    // Setup the UI
    setupMenu();
    setupStatusBar();

    // Set window properties
    setMinimumSize(640, 480);
}

StorageWindow::~StorageWindow()
{
    // StorageWidget will be deleted automatically as it's a child of this window
}

void StorageWindow::setupMenu()
{
    // Create main menu
    QMenu *fileMenu = menuBar()->addMenu("&File");
    QMenu *storageMenu = menuBar()->addMenu("&Storage");
    QMenu *helpMenu = menuBar()->addMenu("&Help");

    // File menu actions
    QAction *exitAction = fileMenu->addAction("E&xit");
    connect(exitAction, &QAction::triggered, this, &QMainWindow::close);

    // Storage menu actions
    QAction *initStorageAction = storageMenu->addAction("&Initialize Storage");
    connect(initStorageAction, &QAction::triggered, this, &StorageWindow::onInitStorage);

    QAction *stopStorageAction = storageMenu->addAction("&Stop Storage");
    connect(stopStorageAction, &QAction::triggered, this, &StorageWindow::onStopStorage);

    // Help menu actions
    QAction *aboutAction = helpMenu->addAction("&About");
    connect(aboutAction, &QAction::triggered, this, &StorageWindow::onAboutAction);
}

void StorageWindow::setupStatusBar()
{
    statusBar = new QStatusBar(this);
    setStatusBar(statusBar);
    statusBar->showMessage("Ready");
}

void StorageWindow::onAboutAction()
{
    QMessageBox::about(this, "About Logos Storage",
                       "Logos Storage Application\n\n"
                       "A sample Qt application demonstrating Storage integration.");
}

void StorageWindow::onInitStorage()
{
    qDebug() << "Initializing Storage from menu";
    storageWidget->initStorage();
    statusBar->showMessage("Storage initialization requested");
}

void StorageWindow::onStopStorage()
{
    qDebug() << "Stopping Storage from menu";
    storageWidget->stopStorage();
    statusBar->showMessage("Storage stop requested");
}

#include <QApplication>
#include <QDebug>
#include "StorageWindow.h"

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    
    qDebug() << "Starting Storage Qt Application";
    
    // Create and show the main window
    StorageWindow mainWindow;
    mainWindow.setWindowTitle("Logos Storage App");
    mainWindow.resize(800, 600);
    mainWindow.show();
    
    return app.exec();
} 
#pragma once

#include <QMainWindow>
#include <QVBoxLayout>
#include <QMenuBar>
#include <QStatusBar>
#include "StorageWidget.h"

class StorageWindow : public QMainWindow {
    Q_OBJECT

public:
    explicit StorageWindow(QWidget* parent = nullptr);
    ~StorageWindow();

private slots:
    void onAboutAction();
    void onInitStorage();
    void onStopStorage();

private:
    void setupMenu();
    void setupStatusBar();
    
    StorageWidget* storageWidget;
    QStatusBar* statusBar;
}; 
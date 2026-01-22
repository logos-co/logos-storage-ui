#pragma once

#include "StorageWidget.h"
#include <QMainWindow>
#include <QMenuBar>
#include <QStatusBar>
#include <QVBoxLayout>

class StorageWindow : public QMainWindow {
    Q_OBJECT

  public:
    explicit StorageWindow(QWidget* parent = nullptr);
    ~StorageWindow();

  private slots:
    void onAboutAction();
    void onInitStorage();

  private:
    void setupStatusBar();

    StorageWidget* storageWidget;
    QStatusBar* statusBar;
};

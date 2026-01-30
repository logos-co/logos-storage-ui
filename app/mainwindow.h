#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>

class QCloseEvent;

class MainWindow : public QMainWindow {
    Q_OBJECT

  public:
    MainWindow(QWidget* parent = nullptr);
    ~MainWindow();
    void destroy();

  private:
    void setupUi();
    void setupMenu();

    QWidget* storageWidget = nullptr;
    QObject* plugin = nullptr;
};

#endif // MAINWINDOW_H

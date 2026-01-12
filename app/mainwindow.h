#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>

class QCloseEvent;

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();
    void cleanup();

private:
    void setupUi();

private:
    QWidget *storageWidget = nullptr;
};

#endif // MAINWINDOW_H

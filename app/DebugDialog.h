#pragma once
#include <QDialog>

class DebugDialog : public QDialog {
    Q_OBJECT
  public:
    explicit DebugDialog(QWidget* parent = nullptr, const QString& debug = "");
};
#pragma once

#include <QVBoxLayout>
#include <QWidget>

class DebugWidget : public QWidget {
    Q_OBJECT

  public:
    explicit DebugWidget(QWidget* parent = nullptr);
    ~DebugWidget();

    //   private slots:
    //     void onSendButtonClicked();
    //     void onStartButtonClicked();
    //     void onDebugButtonClicked();

  private:
    // UI elements
    QVBoxLayout* mainLayout;
};

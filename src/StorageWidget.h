#pragma once

#include "logos_api.h"
#include "logos_api_client.h"
#include "logos_sdk.h"
#include <QHBoxLayout>
#include <QLabel>
#include <QLineEdit>
#include <QPushButton>
// #include <QQuickWidget>
#include <QTextEdit>
#include <QVBoxLayout>
#include <QWidget>
#include <string>

using StringCallback = std::function<void(int, const std::string&)>;

class StorageWidget : public QWidget {
    Q_OBJECT
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusTextChanged)
    Q_PROPERTY(bool storageRunning READ storageRunning NOTIFY storageRunningChanged)

  public:
    explicit StorageWidget(QWidget* parent = nullptr);
    ~StorageWidget();

    Q_INVOKABLE void requestDebug();

    QString statusText() const;
    bool storageRunning() const;

    // Storage operations
    Q_INVOKABLE void initStorage();
    Q_INVOKABLE void startStorage();
    Q_INVOKABLE void stopStorage();
    Q_INVOKABLE QString storageVersion() const;
    Q_INVOKABLE QString storageDebug() const;
    Q_INVOKABLE void destroy();

  private slots:
    void onSendButtonClicked();
    void onStartButtonClicked();
    void onDebugButtonClicked();

  private:
    // UI elements
    // QQuickWidget* quickWidget;
    QString m_statusText;

    QVBoxLayout* mainLayout;
    QHBoxLayout* inputLayout;
    QHBoxLayout* statusLayout;
    QHBoxLayout* channelLayout;

    QTextEdit* storageDisplay;
    QLineEdit* messageInput;
    QLineEdit* channelInput;
    QPushButton* sendButton;
    QPushButton* startButton;
    QPushButton* debugButton;
    QLabel* statusLabel;

    // LogosAPI instance for remote method calls
    LogosAPI* m_logosAPI;
    LogosModules* logos;

    // Connection status
    bool isStorageInitialized;
    bool m_isStorageRunning;
    QString currentPubSubTopic;
    QString currentChannel;
    bool response;

    // Helper methods
    void updateStatus(const QString& message);
    void displayMessage(const QString& sender, const QString& message);
    void emitEvent(const QString& eventName, const QVariantList& data);

  signals:
    void storageCleanup();
    void storageStop();
    void debug();
    void statusTextChanged();
    void storageRunningChanged();
};

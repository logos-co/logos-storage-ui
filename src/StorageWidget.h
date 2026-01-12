#pragma once

#include <QWidget>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QPushButton>
#include <QTextEdit>
#include <QLineEdit>
#include <QLabel>
#include <string>
#include "logos_api.h"
#include "logos_api_client.h"
#include "logos_sdk.h"

using StringCallback = std::function<void(int,  const std::string&)>;

class StorageWidget : public QWidget
{
    Q_OBJECT

public:
    explicit StorageWidget(QWidget *parent = nullptr);
    ~StorageWidget();

    // Storage operations
    Q_INVOKABLE void initStorage();
    Q_INVOKABLE void startStorage();
    Q_INVOKABLE void stopStorage();
    Q_INVOKABLE void destroy();
    Q_INVOKABLE bool isStorageRunning() const;

private slots:
    void onSendButtonClicked();
    void onStartButtonClicked();

private:
    // UI elements
    QVBoxLayout *mainLayout;
    QHBoxLayout *inputLayout;
    QHBoxLayout *statusLayout;
    QHBoxLayout *channelLayout;

    QTextEdit *storageDisplay;
    QLineEdit *messageInput;
    QLineEdit *channelInput;
    QPushButton *sendButton;
    QPushButton *startButton;
    QLabel *statusLabel;

    // LogosAPI instance for remote method calls
    LogosAPI *m_logosAPI;
    LogosModules *logos;

    // Connection status
    bool isStorageInitialized;
    bool m_isStorageRunning;
    QString currentPubSubTopic;
    QString currentChannel;
    bool response;

    // Helper methods
    void updateStatus(const QString &message);
    void displayMessage(const QString &sender, const QString &message);
    void emitEvent(const QString& eventName, const QVariantList& data);

signals:
    void storageCleanup();
    void storageStop();
};

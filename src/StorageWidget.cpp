#include "StorageWidget.h"
#include <QDebug>
#include <QDateTime>
#include <QMessageBox>
#include <iostream>
#include <csignal>
#include <QTimer>
#include "logos_api_client.h"

int RET_OK = 0;

// Static pointer to the active StorageWidget for callbacks
static StorageWidget *activeWidget = nullptr;

StorageWidget::StorageWidget(QWidget *parent)
    : QWidget(parent),
      isStorageInitialized(false),
      m_isStorageRunning(false),
      m_logosAPI(nullptr)
{

    // Set as the active widget
    activeWidget = this;

    m_logosAPI = new LogosAPI("core", this);
    logos = new LogosModules(m_logosAPI);

    // Main vertical layout
    mainLayout = new QVBoxLayout(this);

    // Create status label
    statusLayout = new QHBoxLayout();
    statusLabel = new QLabel("Status: Not initialized", this);
    statusLabel->setFrameStyle(QFrame::Panel | QFrame::Sunken);
    statusLabel->setLineWidth(1);
    statusLabel->setAlignment(Qt::AlignLeft | Qt::AlignVCenter);
    statusLabel->setMinimumHeight(30);
    
    startButton = new QPushButton("Start", this);

    statusLayout->addWidget(statusLabel, 4);
    statusLayout->addWidget(startButton, 1);

    // Create display
    // storageDisplay = new QTextEdit(this);
    // storageDisplay->setReadOnly(true);
    // storageDisplay->setMinimumHeight(300);

    // Create input layout
    // inputLayout = new QHBoxLayout();
    // messageInput = new QLineEdit(this);
    // messageInput->setPlaceholderText("Type your message here...");
    // sendButton = new QPushButton("Send", this);

    // inputLayout->addWidget(messageInput, 4);
    // inputLayout->addWidget(sendButton, 1);

    // Add all components to main layout
    mainLayout->addLayout(statusLayout);
    // mainLayout->addWidget(storageDisplay);
    // mainLayout->addLayout(inputLayout);

    // Set spacing and margins
    mainLayout->setSpacing(10);
    mainLayout->setContentsMargins(20, 20, 20, 20);

    // Connect signals to slots
    connect(startButton, &QPushButton::clicked, this, &StorageWidget::onStartButtonClicked);
    // connect(messageInput, &QLineEdit::returnPressed, this, &StorageWidget::onStartButtonClicked);

    // Disable UI components until Storage is initialized
    // messageInput->setEnabled(false);
    // sendButton->setEnabled(false);
    startButton->setEnabled(false);

    // Auto-initialize Storage
    initStorage();
}

StorageWidget::~StorageWidget()
{
    // Reset the active widget if it's this instance
    if (activeWidget == this)
    {
        activeWidget = nullptr;
    }
}

void StorageWidget::initStorage()
{
    updateStatus("Initializing Storage...");

    response = logos->storage_module.init("{}");
    
    qDebug() << "StorageWidget: Storage module init response:" << response;

    isStorageInitialized = true;
    m_isStorageRunning = false;
    
    updateStatus("Storage initialized.");

    if (!logos->storage_module.on("storageStart", [this](const QVariantList& data) {
        int code = data[0].toInt();

        if (code != RET_OK) {
            updateStatus("Error starting Storage.");
        } else {
            updateStatus("Storage started successfully.");
            m_isStorageRunning = true;
            startButton->setText("Stop");

            // messageInput->setEnabled(true);
            // sendButton->setEnabled(true);
        }

        startButton->setEnabled(true);
    })) {
        qWarning() << "StorageWidget: failed to subscribe to storageStart events";
    }

    if (!logos->storage_module.on("storageStop", [this](const QVariantList& data) {
        int code = data[0].toInt();

        if (code != RET_OK) {
            updateStatus("Error stopping Storage.");
        } else {
            updateStatus("Storage stopped successfully.");
            m_isStorageRunning = false;
            startButton->setText("Start");
            // messageInput->setEnabled(false);
            // sendButton->setEnabled(false);
        }

        startButton->setEnabled(true);

        emit storageStop();
    })) {
        qWarning() << "StorageWidget: failed to subscribe to storageStop events";
    }

    startStorage();
    // if (!storageModule.on("storageVersion", [this]
    //     std::string version = data[1].toString().toStdString();(const QVariantList& data) {
    //     qDebug() << "Storage Version:" << QString::fromStdString(version);
    //   })) {
    //      qWarning() << "ChatWidget: failed to subscribe to historyMessage events";
    //   }   
    //   if (!storageModule.on("storageVersion", [this]
    //     std::string version = data[1].toString().toStdString();(const QVariantList& data) {
    //     qDebug() << "Storage Version:" << QString::fromStdString(version);
    //   })) {
    //      qWarning() << "ChatWidget: failed to subscribe to historyMessage events";
    //   }   
}

bool StorageWidget::isStorageRunning() const
{
    return m_isStorageRunning;
}

void StorageWidget::startStorage()
{
    updateStatus("Starting Storage...");

    if (!isStorageInitialized)
    {
        qDebug() << "StorageWidget: Storage not initialized, nothing to start.";
        return;
    }

    if (m_isStorageRunning)
    {
        qDebug() << "StorageWidget: Storage already started.";
        return;
    } 

    if (!logos->storage_module.start()) {
        qWarning() << "StorageWidget: Failed to send start command to Storage.";
    } else {
        qDebug() << "StorageWidget: Start command sent to Storage.";
    }
}

void StorageWidget::stopStorage()
{
    updateStatus("Stopping Storage...");

    if (!isStorageInitialized)
    {
        qDebug() << "StorageWidget: Storage not initialized, nothing to stop.";
        emit storageStop();
        return;
    }

    if (!m_isStorageRunning)
    {
        qDebug() << "StorageWidget: Storage already stopped.";
        emit storageStop();
        return;
    } 

    if (!logos->storage_module.stop()) {
        qWarning() << "StorageWidget: Failed to send stop command to Storage.";
    } else {
        qDebug() << "StorageWidget: Stop command sent to Storage.";
    }
}

void StorageWidget::destroy()
{
    qDebug() << "StorageWidget: destroy function called...";

    if (!isStorageInitialized)
    {
        qDebug() << "StorageWidget: Storage not initialized, nothing to stop.";
        return;
    }

    if (!logos->storage_module.destroy()) {
        qWarning() << "StorageWidget: Failed to send destroy command to Storage.";
    } else {
        qDebug() << "StorageWidget: Destroy command sent to Storage.";
    }

    qDebug() << "StorageWidget: Emitting storageCleanup signal.";

    emit storageCleanup();
}

void StorageWidget::onStartButtonClicked()
{
    qDebug() << "Starting Storage from button";

    startButton->setEnabled(false);

    if (m_isStorageRunning)
    {
        stopStorage();
    }
    else
    {
        startStorage();
    }
}

void StorageWidget::onSendButtonClicked()
{
    QString message = messageInput->text().trimmed();
    if (message.isEmpty())
    {
        QMessageBox::warning(this, "Storage Error", "Message is empty.");

        return;
    }

    // Check if Storage is running
    if (!m_isStorageRunning)
    {
        QMessageBox::warning(this, "Storage Error", "Storage is not running. Please initialize Storage first.");
        return;
    }
    logos->storage_module.version();
    // if (m_logosAPI && m_logosAPI->getClient("storage")->isConnected())
    // {

    //     logos->storage_module.storageVersion();
    // }
    // else
    // {
    //     qDebug() << "LogosAPI not connected";
    // }

    qDebug() << "LogosAPI not connected!!";

    // Clear input field
    messageInput->clear();
}

void StorageWidget::updateStatus(const QString &message)
{
    statusLabel->setText(message);
    qDebug() << "StorageWidget Status:" << message;
}

void StorageWidget::displayMessage(const QString &sender, const QString &message)
{
    QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss");
    QString formattedMessage = QString("[%1] %2: %3").arg(timestamp, sender, message);
    storageDisplay->append(formattedMessage);
}

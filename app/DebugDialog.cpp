#include "DebugDialog.h"
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLabel>
#include <QPixmap>
#include <QStandardPaths>
#include <QStringList>
#include <QVBoxLayout>

DebugDialog::DebugDialog(QWidget* parent, const QString& json) : QDialog(parent) {
    setWindowTitle("Debug Logos Storage UI");
    setFixedSize(300, 220);

    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(json.toUtf8(), &err);

    if (err.error != QJsonParseError::NoError) {
        qWarning() << "JSON parse error:" << err.errorString();
        return;
    }

    if (!doc.isObject()) {
        qWarning() << "Expected JSON object";
        return;
    }

    QJsonObject obj = doc.object();
    QString id = obj.value("id").toString();

    qDebug() << "DebugDialog: Plugin name from JSON:" << id;

    auto* layout = new QVBoxLayout(this);

    // auto* logo = new QLabel(this);
    // logo->setPixmap(
    //     QPixmap(":/images/assets/logos.png").scaled(128, 128, Qt::KeepAspectRatio, Qt::SmoothTransformation));
    // logo->setAlignment(Qt::AlignCenter);

    // auto* text = new QLabel(this);
    // text->setAlignment(Qt::AlignCenter);
    // text->setText("Logos Storage UI\nUI version: 1.0.0\nStorage version " + version);
    // text->setTextFormat(Qt::PlainText);

    // layout->addWidget(logo);
    // layout->addWidget(text);
}

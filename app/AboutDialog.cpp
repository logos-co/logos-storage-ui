// AboutDialog.cpp
#include "AboutDialog.h"
#include <QVBoxLayout>
#include <QLabel>
#include <QPixmap>

AboutDialog::AboutDialog(QWidget *parent)
    : QDialog(parent)
{
    setWindowTitle("About Logos Storage UI");
    setFixedSize(300, 220);

    auto *layout = new QVBoxLayout(this);

    auto *logo = new QLabel(this);
    logo->setPixmap(
        QPixmap(":/images/assets/logos.png")
            .scaled(128, 128, Qt::KeepAspectRatio, Qt::SmoothTransformation)
    );
    logo->setAlignment(Qt::AlignCenter);

    auto *text = new QLabel(
        "<b>Logos Storage UI</b><br>"
        "Version 1.0.0",
        this
    );
    text->setAlignment(Qt::AlignCenter);
    text->setTextFormat(Qt::RichText);

    layout->addWidget(logo);
    layout->addWidget(text);
}

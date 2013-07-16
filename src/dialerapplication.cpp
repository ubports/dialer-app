/*
 * Copyright (C) 2012 Canonical, Ltd.
 *
 * This file is part of dialer-app.
 *
 * dialer-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * dialer-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "dialerapplication.h"

#include <QDir>
#include <QUrl>
#include <QDebug>
#include <QStringList>
#include <QQuickItem>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQuickView>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDBusConnectionInterface>
#include <QLibrary>
#include "config.h"
#include "dialerappdbus.h"
#include <QQmlEngine>

static void printUsage(const QStringList& arguments)
{
    qDebug() << "usage:"
             << arguments.at(0).toUtf8().constData()
             << "[call://PHONE_NUMBER]"
             << "[voicemail://]"
             << "[--fullscreen]"
             << "[--test-contacts]"
             << "[--help]"
             << "[-testability]";
}

DialerApplication::DialerApplication(int &argc, char **argv)
    : QGuiApplication(argc, argv), m_view(0), m_applicationIsReady(false)
{
    setApplicationName("DialerApp");
    m_dbus = new DialerAppDBus(this);
}

bool DialerApplication::setup()
{
    static QList<QString> validSchemes;
    bool fullScreen = false;
    QString contactEngine = "folks";

    if (validSchemes.isEmpty()) {
        validSchemes << "call";
        validSchemes << "voicemail";
    }

    QString contactKey;
    QStringList arguments = this->arguments();

    if (arguments.contains("--help")) {
        printUsage(arguments);
        return false;
    }

    if (arguments.contains("--fullscreen")) {
        arguments.removeAll("--fullscreen");
        fullScreen = true;
    }

    if (arguments.contains("--test-contacts")) {
        arguments.removeAll("--test-contacts");
        contactEngine = "memory";
    }

    // The testability driver is only loaded by QApplication but not by QGuiApplication.
    // However, QApplication depends on QWidget which would add some unneeded overhead => Let's load the testability driver on our own.
    if (arguments.contains("-testability")) {
        arguments.removeAll("-testability");
        QLibrary testLib(QLatin1String("qttestability"));
        if (testLib.load()) {
            typedef void (*TasInitialize)(void);
            TasInitialize initFunction = (TasInitialize)testLib.resolve("qt_testability_init");
            if (initFunction) {
                initFunction();
            } else {
                qCritical("Library qttestability resolve failed!");
            }
        } else {
            qCritical("Library qttestability load failed!");
        }
    }

    /* Ubuntu APP Manager gathers info on the list of running applications from the .desktop
       file specified on the command line with the desktop_file_hint switch, and will also pass a stage hint
       So app will be launched like this:

       /usr/bin/dialer-app --desktop_file_hint=/usr/share/applications/dialer-app.desktop
                          --stage_hint=main_stage

       So remove whatever --arg still there before continue parsing
    */
    for (int i = arguments.count() - 1; i >=0; --i) {
        if (arguments[i].startsWith("--")) {
            arguments.removeAt(i);
        }
    }

    if (arguments.size() == 2) {
        QUrl uri(arguments.at(1));
        if (validSchemes.contains(uri.scheme())) {
            m_arg = arguments.at(1);
        }
    }

    // check if the app is already running, if it is, send the message to the running instance
    QDBusReply<bool> reply = QDBusConnection::sessionBus().interface()->isServiceRegistered("com.canonical.DialerApp");
    if (reply.isValid() && reply.value()) {
        QDBusInterface appInterface("com.canonical.DialerApp",
                                    "/com/canonical/DialerApp",
                                    "com.canonical.DialerApp");
        appInterface.call("SendAppMessage", m_arg);
        return false;
    }

    if (!m_dbus->connectToBus()) {
        qWarning() << "Failed to expose com.canonical.DialerApp on DBUS.";
    }

    m_view = new QQuickView();
    QObject::connect(m_view, SIGNAL(statusChanged(QQuickView::Status)), this, SLOT(onViewStatusChanged(QQuickView::Status)));
    QObject::connect(m_view->engine(), SIGNAL(quit()), SLOT(quit()));
    m_view->setResizeMode(QQuickView::SizeRootObjectToView);
    m_view->setTitle("Dialer");
    m_view->rootContext()->setContextProperty("application", this);
    m_view->rootContext()->setContextProperty("contactKey", contactKey);
    m_view->rootContext()->setContextProperty("dbus", m_dbus);
    m_view->rootContext()->setContextProperty("contactEngine", contactEngine);
    m_view->engine()->setBaseUrl(QUrl::fromLocalFile(dialerAppDirectory()));

    QString pluginPath = ubuntuPhonePluginPath();
    if (!pluginPath.isNull()) {
        m_view->engine()->addImportPath(pluginPath);
    }

    m_view->setSource(QUrl::fromLocalFile("dialer-app.qml"));
    if (fullScreen) {
        m_view->showFullScreen();
    } else {
        m_view->show();
    }

    connect(m_dbus,
            SIGNAL(request(QString)),
            SLOT(onMessageReceived(QString)));

    return true;
}

DialerApplication::~DialerApplication()
{
    if (m_view) {
        delete m_view;
    }
}

void DialerApplication::onViewStatusChanged(QQuickView::Status status)
{
    if (status != QQuickView::Ready) {
        return;
    }

    QQuickItem *mainView = m_view->rootObject();
    if (mainView) {
        QObject::connect(mainView, SIGNAL(applicationReady()), this, SLOT(onApplicationReady()));
    }
}

void DialerApplication::onApplicationReady()
{
    QObject::disconnect(QObject::sender(), SIGNAL(applicationReady()), this, SLOT(onApplicationReady()));
    m_applicationIsReady = true;
    parseArgument(m_arg);
    m_arg.clear();
}

void DialerApplication::parseArgument(const QString &arg)
{
    if (arg.isEmpty()) {
        return;
    }

    QStringList args = arg.split("://");
    if (args.size() != 2) {
        return;
    }

    QString scheme = args[0];
    QString value = args[1];

    QQuickItem *mainView = m_view->rootObject();
    if (!mainView) {
        return;
    }
    const QMetaObject *mo = mainView->metaObject();


    if (scheme == "call") {
        int index = mo->indexOfMethod("callNumber(QVariant)");
        if (index != -1) {
            QMetaMethod method = mo->method(index);
            method.invoke(mainView, Q_ARG(QVariant, QVariant(value)));
        }
    } else if (scheme == "voicemail") {
        int index = mo->indexOfMethod("showVoicemail()");
        if (index != -1) {
            QMetaMethod method = mo->method(index);
            method.invoke(mainView);
        }
    }
}

void DialerApplication::onMessageReceived(const QString &message)
{
    if (m_applicationIsReady) {
        parseArgument(message);
        m_arg.clear();
        activateWindow();
    } else {
        m_arg = message;
    }
}

void DialerApplication::activateWindow()
{
    if (m_view) {
        m_view->raise();
        m_view->requestActivate();
    }
}

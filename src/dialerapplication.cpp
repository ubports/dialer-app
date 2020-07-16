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
#include <QUrlQuery>
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
#include <QQmlEngine>
#include <QDir>

static void printUsage(const QStringList& arguments)
{
    qDebug() << "usage:"
             << arguments.at(0).toUtf8().constData()
             << "[tel:[///]PHONE_NUMBER]"
             << "[tel:[///]voicemail]"
             << "[dialer:[///]?view=<view name>]"
             << "[--fullscreen]"
             << "[--help]"
             << "[-testability]";
}

//this is necessary to work on desktop
//On desktop use: export DIALER_APP_ICON_THEME=ubuntu-mobile
static void installIconPath()
{
    qDebug() << __PRETTY_FUNCTION__;
    QByteArray iconTheme = qgetenv("DIALER_APP_ICON_THEME");
    if (!iconTheme.isEmpty()) {
        QIcon::setThemeName(iconTheme);
    }
}


DialerApplication::DialerApplication(int &argc, char **argv)
    : QGuiApplication(argc, argv), m_view(0), m_applicationIsReady(false), m_fullScreen(false)
{
    setApplicationName("DialerApp");
    setOrganizationName("com.ubuntu.dialer-app");
}

bool DialerApplication::setup()
{
    installIconPath();

    if (mValidSchemes.isEmpty()) {
        mValidSchemes << "tel" << "dialer";
    }

    QStringList arguments = this->arguments();

    if (arguments.contains("--help")) {
        printUsage(arguments);
        return false;
    }

    if (arguments.contains("--fullscreen")) {
        arguments.removeAll("--fullscreen");
        m_fullScreen = true;
    }

    // The testability driver is only loaded by QApplication but not by QGuiApplication.
    // However, QApplication depends on QWidget which would add some unneeded overhead => Let's load the testability driver on our own.
    if (arguments.contains("-testability") || qgetenv("QT_LOAD_TESTABILITY") == "1") {
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
        if (mValidSchemes.contains(uri.scheme())) {
            m_arg = arguments.at(1);
        }
    }

    m_view = new QQuickView();
    QObject::connect(m_view, SIGNAL(statusChanged(QQuickView::Status)), this, SLOT(onViewStatusChanged(QQuickView::Status)));
    QObject::connect(m_view->engine(), SIGNAL(quit()), SLOT(quit()));
    m_view->setResizeMode(QQuickView::SizeRootObjectToView);
    m_view->setTitle("Dialer");
    m_view->rootContext()->setContextProperty("application", this);
    m_view->rootContext()->setContextProperty("i18nDirectory", I18N_DIRECTORY);
    m_view->rootContext()->setContextProperty("view", m_view);

    // check if there is a contacts backend override
    QString contactsBackend = qgetenv("QTCONTACTS_MANAGER_OVERRIDE");
    if (!contactsBackend.isEmpty()) {
        qDebug() << "Overriding the contacts backend, using:" << contactsBackend;
        m_view->rootContext()->setContextProperty("QTCONTACTS_MANAGER_OVERRIDE", contactsBackend);
    }

    // used by autopilot tests to load vcards during tests
    QByteArray testData = qgetenv("QTCONTACTS_PRELOAD_VCARD");
    m_view->rootContext()->setContextProperty("QTCONTACTS_PRELOAD_VCARD", testData);

    QString pluginPath = ubuntuPhonePluginPath();
    if (!pluginPath.isNull()) {
        m_view->engine()->addImportPath(pluginPath);
    }

    m_view->engine()->setBaseUrl(QUrl::fromLocalFile(dialerAppDirectory()));
    m_view->setSource(QUrl::fromLocalFile(QString("%1/dialer-app.qml").arg(dialerAppDirectory())));
    if (m_fullScreen) {
        m_view->showFullScreen();
    } else {
        m_view->show();
    }

    return true;
}

bool DialerApplication::fullScreen() const
{
    return m_fullScreen;
}

void DialerApplication::setFullScreen(bool value)
{
    m_fullScreen = value;
    m_view->setWindowState(m_fullScreen ? Qt::WindowFullScreen : Qt::WindowNoState);
    Q_EMIT fullScreenChanged();
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

    onApplicationReady();
}

void DialerApplication::onApplicationReady()
{
    m_applicationIsReady = true;
    parseArgument(m_arg);
    m_arg.clear();
}

void DialerApplication::parseArgument(const QString &arg)
{
    if (arg.isEmpty()) {
        return;
    }

    QUrl url(arg);
    QString scheme = url.scheme();
    // we can't fill value with url.path() as it might contain the # character and QUrl will drop it.
    QString value;
    if (!mValidSchemes.contains(url.scheme())) {
        qWarning() << "Url scheme not valid for dialer-app";
        return;
    } else if (url.scheme() == "tel") {
        // remove the initial tel:, it doesn't matter if it contains /// or //, as we
        // now use libphonenumber and it will remove these invalid characters when in the beginning
        // of the number
        value = arg;
        value = QUrl::fromPercentEncoding(value.remove("tel:").toLatin1());
    }

    QQuickItem *mainView = m_view->rootObject();
    if (!mainView) {
        return;
    }

    if (scheme == "tel") {
        if (value == "voicemail") {
            // FIXME: check if we should call the voicemail directly or just populate it
            QMetaObject::invokeMethod(mainView, "callVoicemail");
        } else {

            bool startcall = value.contains("startcall");
            if (startcall) {
                value = value.remove("&startcall"); 
                QMetaObject::invokeMethod(mainView, "startCall", Q_ARG(QVariant, value));
            } else {
                // do not call the number directly, instead only populate the dialpad view
                QMetaObject::invokeMethod(mainView, "populateDialpad", Q_ARG(QVariant, value), Q_ARG(QVariant, QString()));
            }

        }
    } else if (scheme == "dialer") {
        QUrlQuery query(url);
        QString viewName = query.queryItemValue("view");
        if (viewName == "liveCall") {
            QMetaObject::invokeMethod(mainView, "switchToLiveCall", Q_ARG(QVariant, QVariant()), Q_ARG(QVariant, QVariant()));
        }

    }
}

void DialerApplication::activateWindow()
{
    if (m_view) {
        m_view->raise();
        m_view->requestActivate();
    }
}

QStringList DialerApplication::mmiPluginList()
{
    QStringList plugins;
    QString mmiDirectory = dialerAppDirectory() + "/MMI";
    QString mmiCustomDirectory = "/custom" + mmiDirectory;
    QDir directory(mmiDirectory);
    QDir customDirectory(mmiCustomDirectory);
    Q_FOREACH(const QString &file, directory.entryList(QStringList() << "*.qml")) {
        plugins << directory.filePath(file);
    }
    Q_FOREACH(const QString &file, customDirectory.entryList(QStringList() << "*.qml")) {
        plugins << customDirectory.filePath(file);
    }
    return plugins;
}

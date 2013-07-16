/*
 * Copyright (C) 2012-2013 Canonical, Ltd.
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

#ifndef DIALERAPPLICATION_H
#define DIALERAPPLICATION_H

#include <QObject>
#include <QQuickView>
#include <QGuiApplication>

class DialerAppDBus;

class DialerApplication : public QGuiApplication
{
    Q_OBJECT

public:
    DialerApplication(int &argc, char **argv);
    virtual ~DialerApplication();

    bool setup();

public Q_SLOTS:
    void activateWindow();

private:
    void parseArgument(const QString &arg);

private Q_SLOTS:
    void onMessageReceived(const QString &message);
    void onViewStatusChanged(QQuickView::Status status);
    void onApplicationReady();

private:
    QQuickView *m_view;
    DialerAppDBus *m_dbus;
    QString m_arg;
    bool m_applicationIsReady;
};

#endif // DIALERAPPLICATION_H

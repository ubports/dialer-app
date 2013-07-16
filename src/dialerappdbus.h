/*
 * Copyright (C) 2012-2013 Canonical, Ltd.
 *
 * Authors:
 *  Ugo Riboni <ugo.riboni@canonical.com>
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

#ifndef DIALERAPPDBUS_H
#define DIALERAPPDBUS_H

#include <QtCore/QObject>
#include <QtDBus/QDBusContext>

/**
 * DBus interface for the phone app
 */
class DialerAppDBus : public QObject, protected QDBusContext
{
    Q_OBJECT

public:
    DialerAppDBus(QObject* parent=0);
    ~DialerAppDBus();

    bool connectToBus();

public Q_SLOTS:
    Q_NOREPLY void ShowVoicemail();
    Q_NOREPLY void CallNumber(const QString &number);
    Q_NOREPLY void SendAppMessage(const QString &message);

Q_SIGNALS:
    void request(const QString &message);
};

#endif // DIALERAPPDBUS_H

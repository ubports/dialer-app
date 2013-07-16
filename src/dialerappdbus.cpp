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

#include "dialerappdbus.h"
#include "dialerappadaptor.h"

// Qt
#include <QtDBus/QDBusConnection>

static const char* DBUS_SERVICE = "com.canonical.DialerApp";
static const char* DBUS_OBJECT_PATH = "/com/canonical/DialerApp";

DialerAppDBus::DialerAppDBus(QObject* parent) : QObject(parent)
{
}

DialerAppDBus::~DialerAppDBus()
{
}

bool
DialerAppDBus::connectToBus()
{
    bool ok = QDBusConnection::sessionBus().registerService(DBUS_SERVICE);
    if (!ok) {
        return false;
    }
    new DialerAppAdaptor(this);
    QDBusConnection::sessionBus().registerObject(DBUS_OBJECT_PATH, this);

    return true;
}

void DialerAppDBus::ShowVoicemail()
{
    Q_EMIT request(QString("voicemail://"));
}

void
DialerAppDBus::CallNumber(const QString &number)
{
    Q_EMIT request(QString("call://%1").arg(number));
}

void DialerAppDBus::SendAppMessage(const QString &message)
{
    Q_EMIT request(message);
}

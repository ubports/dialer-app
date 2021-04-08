/*
 * Copyright 2020 Ubports Foundation.
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

#include "contactutils.h"

QTCONTACTS_USE_NAMESPACE

namespace ContactUtils
{

QContactManager *sharedManager(const QString &engine)
{
    QString finalEngine = engine;
    static QContactManager *instance = new QContactManager(finalEngine);

    return instance;
}

}

/*
 * This file is part of dialer-app
 *
 * Copyright (C) 2017 Canonical Ltd.
 *
 * Authors: Gustavo Pichorim Boiko <gustavo.boiko@canonical.com>
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 3, as published
 * by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranties of
 * MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItems

ListItems.SingleValue {
    property var account: null
    text: i18n.tr("%1 Number Rewrite").arg(account.displayName)
    progression: true
    value: account.accountProperties.numberRewrite ? i18n.tr("On") : i18n.tr("Off")
    onClicked: pageStackNormalMode.push(Qt.resolvedUrl("SipNumberRewrite.qml"), { "account": account })
}

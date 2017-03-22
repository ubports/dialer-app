/*
 * Copyright 2012-2013 Canonical Ltd.
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

import QtQuick 2.4
import Ubuntu.Telephony 0.1
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3

Dialog {
    id: imeiDialog
    visible: false
    title: i18n.tr("IMEI")
    text: {
        var finalString = ""
        for (var i in telepathyHelper.phoneAccounts.all) {
            var account = telepathyHelper.phoneAccounts.all[i]
            finalString += account.displayName
            finalString += ":\n"
            finalString += account.serial
            finalString += "\n\n"
        }
        return finalString
    }
    Button {
        text: i18n.tr("Dismiss")
        onClicked: PopupUtils.close(imeiDialog)
    }
}

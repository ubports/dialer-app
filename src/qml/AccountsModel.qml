/*
 * Copyright 2016 Canonical Ltd.
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

Item {
    property QtObject defaultCallAccount: {
        // we only use the default account property if we have more
        // than one account, otherwise we use always the first one
        if (multipleAccounts) {
            return telepathyHelper.defaultCallAccount
        } else if (activeAccounts.length > 0) {
            return activeAccounts[0]
        }
        return null
    }
    property int defaultCallAccountIndex: {
        var index = -1;
        for (var i in activeAccounts) {
            if (activeAccounts[i] == defaultCallAccount) {
                index = i;
                break;
            }
        }
        return index;
    }

    property var activeAccounts: telepathyHelper.voiceAccounts.displayed
    property var activeAccountNames: {
        var accountNames = []
        for (var i in activeAccounts) {
            accountNames.push(activeAccounts[i].displayName)
        }
        return accountNames
    }

    // other helper properties
    property bool multipleAccounts: activeAccounts.length > 1

}


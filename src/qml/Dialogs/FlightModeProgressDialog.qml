/*
 * Copyright 2012-2016 Canonical Ltd.
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

import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Telephony 0.1

Dialog {
    id: flightModeProgressDialog
    property bool emergencyMode: false
    visible: false
    title: i18n.tr("Disabling flight mode")
    ActivityIndicator {
        running: parent.visible
    }
    Connections {
        target: telepathyHelper
        onEmergencyCallsAvailableChanged: {
            if (!emergencyMode) {
                PopupUtils.close(flightModeProgressDialog)
                return
            }
            flightModeTimer.start()
        }
    }
    // FIXME: workaround to give modems some time to become available
    Timer {
        id: flightModeTimer
        interval: 10000
        repeat: false
        onTriggered: {
            PopupUtils.close(flightModeProgressDialog)
            if (telepathyHelper.emergencyCallsAvailable && mainView.pendingNumberToDial !== "") {
                if (!isEmergencyNumber(mainView.pendingNumberToDial)) {
                    return;
                }

                mainView.callEmergency(mainView.pendingNumberToDial);
                mainView.pendingNumberToDial = "";
            }
        }
    }
}

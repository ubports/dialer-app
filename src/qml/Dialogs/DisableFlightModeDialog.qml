/*
 * Copyright 2015 Canonical Ltd.
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

Component {
    Dialog {
        id: dialogue
        title: i18n.tr("Flight Mode")
        text: i18n.tr("You have to disable flight mode in order to make calls")

        Button {
            objectName: "disableFlightModeDialogDisableButton"
            text: i18n.tr("Disable")
            color: theme.palette.selected.focus

            onClicked: {
                telepathyHelper.flightMode = false
                PopupUtils.open(Qt.resolvedUrl("FlightModeProgressDialog.qml"), mainView)
                PopupUtils.close(dialogue)
                Qt.inputMethod.hide()
            }
        }

        Button {
            objectName: "disableFlightModeDialogCancelButton"
            text: i18n.tr("Cancel")

            onClicked: {
                PopupUtils.close(dialogue)
                Qt.inputMethod.hide()
            }
        }
    }
}

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
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Telephony 0.1

Component {
    Dialog {
        id: dialogue
        property string phoneNumber: ""
        property string accountId: ""
        // TRANSLATORS: this refers to which SIM card will be used as default for calls
        text: i18n.tr("Change all Call associations to %1?").arg(mainView.account.displayName)

        Button {
            objectName: "setDefaultSimCardDialogYes"
            text: i18n.tr("Change")
            color: theme.palette.selected.focus
            onClicked: {
                telepathyHelper.setDefaultAccount(TelepathyHelper.Voice, mainView.account)
                PopupUtils.close(dialogue)
                mainView.call(phoneNumber, true)
                Qt.inputMethod.hide()
            }
        }

        Button {
            objectName: "setDefaultSimCardDialogNo"
            text: i18n.tr("Cancel")
            onClicked: {
                PopupUtils.close(dialogue)
                mainView.call(phoneNumber, true)
                Qt.inputMethod.hide()
            }
        }

        Row {
            spacing: units.gu(1)

            CheckBox {
                id: dontAskAgainCheckbox
                checked: false
                onCheckedChanged: settings.dialPadDontAsk = checked
            }

            Label {
                text: i18n.tr("Don't ask again")
                anchors.verticalCenter: dontAskAgainCheckbox.verticalCenter
                MouseArea {
                    anchors.fill: parent
                    onClicked: dontAskAgainCheckbox.checked = !dontAskAgainCheckbox.checked
                }
            }
        }

    }
}

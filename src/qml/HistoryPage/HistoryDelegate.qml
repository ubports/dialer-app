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

import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Telephony 0.1
import "dateUtils.js" as DateUtils

Item {
    id: communicationDelegate

    property bool incoming: model.senderId != "self"

    height: units.gu(6)

    function selectIcon()  {
        if (model.callMissed) {
            return "../assets/missed-call.png";
        } else if (incoming) {
            return "../assets/incoming-call.png";
        } else {
            return "../assets/outgoing-call.png";
        }
    }

    ContactWatcher {
        id: contactWatcher
        phoneNumber: model.senderId
        onPhoneNumberChanged: console.log("PhoneNumber is " + phoneNumber)
    }

    Row {
        id: mainSection
        anchors.left: parent.left
        anchors.right: phoneIcon.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: units.gu(1)

        UbuntuShape {
            anchors.verticalCenter: parent.verticalCenter
            height: units.gu(3)

            Text {
                anchors.centerIn: parent
                text: Qt.formatTime(model.timestamp)
            }
        }

        UbuntuShape {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: height
            image: Image {
                source: contactWatcher.alias
            }
        }
    }

    Image {
        id: phoneIcon
        anchors.right: parent.right
        anchors.rightMargin: units.gu(2)
        anchors.verticalCenter: parent.verticalCenter
        source: selectIcon()
    }
}

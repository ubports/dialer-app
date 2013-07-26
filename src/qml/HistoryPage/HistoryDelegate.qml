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

ListItem.Empty {
    id: communicationDelegate

    property bool incoming: model.senderId != "self"
    property bool unknownContact: contactWatcher.contactId == ""

    height: units.gu(8)

    onClicked: mainView.call(model.participants[0])

    function selectIcon()  {
        if (model.callMissed) {
            return "../assets/missed-call.png";
        } else if (incoming) {
            return "../assets/incoming-call.png";
        } else {
            return "../assets/outgoing-call.png";
        }
    }

    Item {
        ContactWatcher {
            id: contactWatcher
            // FIXME: handle conf calls
            phoneNumber: model.participants[0]
        }
    }

    Row {
        id: mainSection
        anchors.left: parent.left
        anchors.right: phoneIcon.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: units.gu(1)
        spacing: units.gu(1)

        UbuntuShape {
            anchors.verticalCenter: parent.verticalCenter
            height: units.gu(3)

            Label {
                anchors.centerIn: parent
                text: Qt.formatTime(model.timestamp)
            }
        }

        UbuntuShape {
            id: avatar
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: height
            image: Image {
                source: {
                    if(!unknownContact) {
                        if (contactWatcher.avatar != "") {
                            return contactWatcher.avatar
                        }
                    }
                    return Qt.resolvedUrl("../assets/avatar-default.png")
                }
            }
        }
        Column {
            width: childrenRect.width
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            Label {
                text: contactWatcher.alias != "" ? contactWatcher.alias : i18n.tr("Unknown")
            }

            Label {
                // FIXME: handle conference call
                text: model.participants[0]
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

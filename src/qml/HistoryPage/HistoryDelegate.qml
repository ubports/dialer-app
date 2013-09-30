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
import Ubuntu.Components.Popups 0.1
import Ubuntu.Telephony 0.1
import Ubuntu.Contacts 0.1
import QtContacts 5.0
import "dateUtils.js" as DateUtils

ListItem.Empty {
    id: communicationDelegate

    property bool incoming: model.senderId != "self"
    property bool unknownContact: contactWatcher.contactId == ""
    property string phoneNumberSubTypeLabel: ""
    property alias isFirst: timeline.isFirst

    height: units.gu(9)
    removable: true
    showDivider: false
    backgroundIndicator: Rectangle {
        anchors.fill: parent
        color: Theme.palette.selected.base
        Label {
            text: i18n.tr("Delete")
            anchors {
                fill: parent
                margins: units.gu(2)
            }
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment:  communicationDelegate.swipingState === "SwipingLeft" ? Text.AlignLeft : Text.AlignRight
        }
    }

    onItemRemoved: {
        historyEventModel.removeEvent(model.accountId, model.threadId, model.eventId, model.type)
    }


    function selectIcon()  {
        if (model.callMissed) {
            return "missed-call";
        } else if (incoming) {
            return "incoming-call";
        } else {
            return "outgoing-call";
        }
    }

    Item {
        id: helper
        function updateSubTypeLabel() {
            phoneNumberSubTypeLabel = contactWatcher.isUnknown ? model.participants[0] : phoneTypeModel.get(phoneTypeModel.getTypeIndex(phoneDetail)).label
        }
        Component.onCompleted: updateSubTypeLabel()

        ContactWatcher {
            id: contactWatcher
            // FIXME: handle conf calls
            phoneNumber: model.participants[0]
            onPhoneNumberContextsChanged: helper.updateSubTypeLabel()
            onPhoneNumberSubTypesChanged: helper.updateSubTypeLabel()
            onIsUnknownChanged: helper.updateSubTypeLabel()
        }


        PhoneNumber {
            id: phoneDetail
            contexts: contactWatcher.phoneNumberContexts
            subTypes: contactWatcher.phoneNumberSubTypes
        }

        ContactDetailPhoneNumberTypeModel {
            id: phoneTypeModel
            Component.onCompleted: helper.updateSubTypeLabel()
        }

        Component {
            id: newcontactPopover

            Popover {
                id: popover
                Column {
                    id: containerLayout
                    anchors {
                        left: parent.left
                        top: parent.top
                        right: parent.right
                    }
                    ListItem.Standard { text: i18n.tr("Add to existing contact") }
                    ListItem.Standard {
                        text: i18n.tr("Create new contact")
                        onClicked: {
                            applicationUtils.switchToAddressbookApp("create://" + contactWatcher.phoneNumber)
                            popover.hide()
                        }
                    }
                }
            }
        }
    }

    Item {
        id: mainSection
        anchors.left: parent.left
        anchors.right: phoneIcon.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        UbuntuShape {
            id: time
            anchors.verticalCenter: parent.verticalCenter
            height: units.gu(4)
            anchors.left: parent.left
            anchors.leftMargin: units.gu(2)
            width: units.gu(4.5)
            color: "white"

            Label {
                anchors.centerIn: parent
                color: "#221E1C"
                fontSize: "x-small"
                font.weight: Font.Bold
                text: Qt.formatTime(model.timestamp, "hh:mm")
            }
        }

        Timeline {
            id: timeline
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: time.right
            anchors.leftMargin: units.gu(0.5)
        }

        UbuntuShape {
            id: avatar
            anchors.left: timeline.right
            anchors.leftMargin: units.gu(1)
            anchors.verticalCenter: parent.verticalCenter
            height: units.gu(7)
            width: height
            image: Image {
                source: {
                    if(!unknownContact) {
                        if (contactWatcher.avatar != "") {
                            return contactWatcher.avatar
                        }
                        return Qt.resolvedUrl("../assets/avatar-default.png")
                    }
                    return Qt.resolvedUrl("../assets/new-contact.svg")
                }
            }
            MouseArea {
                anchors.fill: avatar
                onClicked: {
                    if(contactWatcher.isUnknown) {
                        PopupUtils.open(newcontactPopover, avatar)
                    } else {
                        applicationUtils.switchToAddressbookApp("contact://" + contactWatcher.contactId)
                    }
                }
                onPressAndHold: {
                    if(contactWatcher.isUnknown) {
                        PopupUtils.open(newcontactPopover, avatar)
                    }
                }
            }
        }

        Column {
            width: childrenRect.width
            anchors.top: avatar.top
            anchors.bottom: parent.bottom
            anchors.left: avatar.right
            anchors.leftMargin: units.gu(2)
            spacing: units.gu(0.5)

            Label {
                fontSize: "medium"
                text: contactWatcher.alias != "" ? contactWatcher.alias : i18n.tr("Unknown")
            }

            Label {
                fontSize: "small"
                opacity: 0.2
                // FIXME: handle conference call
                text: phoneNumberSubTypeLabel
            }
        }
    }

    Icon {
        id: phoneIcon
        anchors.right: parent.right
        anchors.rightMargin: units.gu(3)
        anchors.verticalCenter: parent.verticalCenter
        width:  units.gu(2)
        height: units.gu(2)
        name: selectIcon()
    }
}

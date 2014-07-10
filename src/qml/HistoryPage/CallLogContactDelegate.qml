/*
 * Copyright (C) 2012-2013 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
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
import Ubuntu.Contacts 0.1

Item {
    property string phoneNumber: ""
    property string contactId: ""
    property string accountId: ""
    property bool unknownContact: contactId === ""

    signal itemClicked()

    height: details.height + units.gu(1)



    Component {
        id: addPhoneNumberToContactSheet
        DefaultSheet {
            id: sheet
            title: i18n.tr("Add Contact")
            doneButton: false
            modal: true
            contentsHeight: parent.height
            contentsWidth: parent.width
            ContactListView {
                anchors.fill: parent
                /*onContactClicked: {
                    mainView.addPhoneNumberToExistingContact(contact.contactId, phoneNumber)
                    PopupUtils.close(sheet)
                }*/
            }
        }
    }

    UbuntuShape {
        id: details
        height: childrenRect.height
        color: Qt.rgba(0,0,0,0.1)
        anchors {
            top: parent.top
            left: parent.left
            leftMargin: units.gu(2)
            right: parent.right
            rightMargin: units.gu(2)
        }

        Column {
            id: detailItems
            anchors.top: parent.top
            height: childrenRect.height
            width: parent.width
            ExpandableButton {
                objectName: "logCallButton"
                text: i18n.tr("Call now")
                fontSize: "medium"
                iconName: "call-start"
                onClicked: {
                    mainView.call(phoneNumber, accountId)
                    itemClicked()
                }
            }
            ExpandableButton {
                objectName: "logMessageButton"
                text: i18n.tr("Send text message")
                fontSize: "small"
                iconName: "messages"
                onClicked: {
                    mainView.sendMessage(phoneNumber)
                }
            }
            ExpandableButton {
                objectName: "logAddContactButton"
                showDivider: false
                text: unknownContact ? i18n.tr("Save contact") : i18n.tr("View contact")
                fontSize: "small"
                iconName: unknownContact ? "new-contact" : "contact"
                onClicked: {
                    if (unknownContact) {
                        PopupUtils.open(newContactDialog)
                    } else {
                        mainView.viewContact(contactId)
                    }
                }
            }
        }
    }
}


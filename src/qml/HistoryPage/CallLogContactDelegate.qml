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
    property bool unknownContact: contactId === ""

    height: details.height + units.gu(2)
    anchors {
        left: parent.left
        right: parent.right
    }

    Component {
         id: newContactDialog
         Dialog {
             id: dialogue
             title: i18n.tr("Save contact")
             text: i18n.tr("How do you want to save the contact?")
             Button {
                 text: i18n.tr("Add to existing contact")
                 color: UbuntuColors.orange
                 onClicked: {
                     PopupUtils.open(addPhoneNumberToContactSheet)
                     PopupUtils.close(dialogue)
                 }
             }
             Button {
                 text: i18n.tr("Create new contact")
                 color: UbuntuColors.warmGrey
                 onClicked: {
                     mainView.addNewContact(phoneNumber)
                     PopupUtils.close(dialogue)
                 }
             }
             Button {
                 text: i18n.tr("Cancel")
                 color: UbuntuColors.warmGrey
                 onClicked: {
                     PopupUtils.close(dialogue)
                 }
             }
         }
    }

    Component {
        id: addPhoneNumberToContactSheet
        DefaultSheet {
            // FIXME: workaround to set the contact list
            // background to black
            Rectangle {
                anchors.fill: parent
                anchors.margins: -units.gu(1)
                color: "#221e1c"
            }
            id: sheet
            title: i18n.tr("Add Contact")
            doneButton: false
            modal: true
            contentsHeight: parent.height
            contentsWidth: parent.width
            ContactListView {
                anchors.fill: parent
                onContactClicked: {
                    mainView.addPhoneNumberToExistingContact(contact.contactId, phoneNumber)
                    PopupUtils.close(sheet)
                }
            }
            onDoneClicked: PopupUtils.close(sheet)
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
            ListItem.Empty {
                showDivider: false
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: units.gu(2)
                    anchors.rightMargin: units.gu(2)
                    Label {
                        text: i18n.tr("Call")
                        fontSize: "medium"
                    }
                }
                onClicked: mainView.call(phoneNumber)
            }
            ListItem.Empty {
                showDivider: false
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: units.gu(2)
                    anchors.rightMargin: units.gu(2)
                    Label {
                        text: i18n.tr("Send text message")
                        fontSize: "medium"
                    }
                }
                ListItem.ThinDivider {
                    anchors {
                        bottom: parent.top
                        right: parent.right
                        left: parent.left
                    }
                }
                onClicked: mainView.sendMessage(phoneNumber)
            }
            ListItem.Empty {
                showDivider: false
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: units.gu(2)
                    anchors.rightMargin: units.gu(2)
                    Label {
                        text: unknownContact ? i18n.tr("Save contact") : i18n.tr("View contact")
                        fontSize: "medium"
                    }
                }
                ListItem.ThinDivider {
                    anchors {
                        bottom: parent.top
                        right: parent.right
                        left: parent.left
                    }
                }
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


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
import Ubuntu.Contacts 0.1
import QtContacts 5.0

Page {
    id: contactsPage
    objectName: "contactsPage"
    title: i18n.tr("Contacts")
    property QtObject contact

    __customHeaderContents: TextField {
        id: searchField

        anchors {
            left: parent.left
            leftMargin: units.gu(2)
            right: parent.right
            rightMargin: units.gu(2)
            topMargin: units.gu(1.5)
            bottomMargin: units.gu(1.5)
            verticalCenter: parent.verticalCenter
        }
        onTextChanged: contactList.currentIndex = -1
        inputMethodHints: Qt.ImhNoPredictiveText
        placeholderText: i18n.tr("Type a name or phone to search")
    }

    ContactListView {
        id: contactList
        anchors.fill: parent
        onInfoRequested: {
           mainView.viewContact(contact.contactId)
        }
        filterTerm: searchField.text
        detailToPick: ContactDetail.PhoneNumber
        onDetailClicked: {
            pageStack.pop()
            if (callManager.hasCalls) {
                mainView.call(detail.number);
            } else {
                mainView.populateDialpad(detail.number)
            }
        }
        onCountChanged: {
            // move list up if searching
            if (searchField.text !== "") {
                contactList.positionViewAtBeginning()
            }
        }
    }
}


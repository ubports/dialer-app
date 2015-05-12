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
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Components.Popups 0.1
import Ubuntu.Contacts 0.1
import QtContacts 5.0

Page {
    id: contactsPage
    objectName: "contactsPage"

    property string phoneToAdd: ""
    property QtObject contactIndex: null

    function moveListToContact(contact)
    {
        if (active) {
            contactsPage.contactIndex = null
            contactList.positionViewAtContact(contact)
        } else {
            contactsPage.contactIndex = contact
        }
    }

    Connections {
        target: contactList.listModel
        onContactsChanged: {
            if (contactsPage.contactIndex) {
                contactList.positionViewAtContact(contactsPage.contactIndex)
                contactsPage.contactIndex = null
            }
        }
    }

    title: i18n.tr("Contacts")
    TextField {
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
        placeholderText: i18n.tr("Search...")
        visible: false
    }

    state: "default"
    states: [
        PageHeadState {
            id: defaultState

            name: "default"
            actions: [
                Action {
                    text: i18n.tr("Search")
                    iconName: "search"
                    onTriggered: {
                        contactsPage.state = "searching"
                        contactList.showAllContacts()
                        searchField.forceActiveFocus()
                    }
                }
            ]
            PropertyChanges {
                target: contactsPage.head
                actions: defaultState.actions
                sections.model: [i18n.ctr("All Contacts", "All"), i18n.tr("Favorites")]
            }
            PropertyChanges {
                target: searchField
                text: ""
                visible: false
            }
        },
        PageHeadState {
            id: searchingState

            name: "searching"
            backAction: Action {
                iconName: "close"
                text: i18n.tr("Cancel")
                onTriggered: {
                    contactList.forceActiveFocus()
                    contactsPage.state = "default"
                    contactsPage.head.sections.selectedIndex = 0
                }
            }

            PropertyChanges {
                target: contactsPage.head
                backAction: searchingState.backAction
                contents: searchField
            }

            PropertyChanges {
                target: searchField
                text: ""
                visible: true
            }
        }
    ]

    Connections {
        target: contactsPage.head.sections
        onSelectedIndexChanged: {
            switch (contactsPage.head.sections.selectedIndex) {
            case 0:
                contactList.showAllContacts()
                break;
            case 1:
                contactList.showFavoritesContacts()
                break;
            default:
                break;
            }
        }
    }

    // background
    Rectangle {
        anchors.fill: parent
        color: Theme.palette.normal.background
    }

    ContactListView {
        id: contactList

        anchors{
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: keyboardRect.top
        }

        showAddNewButton: true
        showImportOptions: (contactList.count === 0) &&
                           (filterTerm === "") &&
                           (contactsPage.phoneToAdd === "")
        onAddNewContactClicked: {
            var newContact = ContactsJS.createEmptyContact(contactsPage.phoneToAdd, contactsPage)
            pageStack.push(Qt.resolvedUrl("../ContactEditorPage/DialerContactEditorPage.qml"),
                           { model: contactList.listModel,
                             contact: newContact,
                             initialFocusSection: (contactsPage.phoneToAdd != "" ? "phones" : "name"),
                             contactListPage: contactsPage
                           })
        }
        onInfoRequested: mainView.viewContact(contact.contactId, contactList.listModel)

        filterTerm: searchField.text
        detailToPick: (contactsPage.phoneToAdd != "") ? -1 : ContactDetail.PhoneNumber
        onDetailClicked: {
            if (action === "message") {
                Qt.openUrlExternally("message:///" + encodeURIComponent(detail.number))
                return
            }

            console.debug("PHONTE TO ADD:" + contactsPage.phoneToAdd)
            if (contactsPage.phoneToAdd != "") {
                mainView.addPhoneToContact(contact.contactId,
                                           contactsPage.phoneToAdd,
                                           contactsPage,
                                           contactList.listModel)
                return
            }

            pageStackNormalMode.pop()
            if (callManager.hasCalls) {
                mainView.call(detail.number, mainView.account.accountId);
            } else {
                mainView.populateDialpad(detail.number)
            }
        }
        onAddDetailClicked: mainView.addPhoneToContact(contact.contactId,
                                                       " ",
                                                       contactsPage,
                                                       contactList.listModel)
    }

    Component.onCompleted: {
        if (QTCONTACTS_PRELOAD_VCARD !== "") {
            contactList.listModel.importContacts("file://" + QTCONTACTS_PRELOAD_VCARD)
        }
    }

    KeyboardRectagle {
        id: keyboardRect
    }
}


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
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.Components.Popups 1.3
import Ubuntu.Contacts 0.1
import QtContacts 5.0

Page {
    id: contactsPage
    objectName: "contactsPage"

    property string phoneToAdd: ""
    property QtObject contactIndex: null
    property alias initialState: contactsPage.state
    property alias initialTab: pageHeaderSections.selectedIndex

    function moveListToContact(contact)
    {
        if (active) {
            contactsPage.contactIndex = null
            contactList.positionViewAtContact(contact)
        } else {
            contactsPage.contactIndex = contact
        }
    }

    function contactSelected(selectedContact) {
        // no phone number case:
        if (selectedContact.phoneNumbers.length === 0) {
            mainView.viewContact(selectedContact,
                                 contactsPage,
                                 contactList.listModel)
        } else {
            // we have several phone numbers, open a popup to select to desired one
            if (selectedContact.phoneNumbers.length > 1) {
                var dialog = PopupUtils.open(chooseNumberDialog, contactsPage, {
                    'contact': selectedContact
                });
                dialog.selectedPhoneNumber.connect(
                            function(number) {
                                mainView.populateDialpad(number)
                                PopupUtils.close(dialog);
                            })
            } else {
                mainView.populateDialpad(selectedContact.phoneNumber.number)
            }
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

    header: PageHeader {
        id: pageHeader

        property alias leadingActions: leadingBar.actions
        property alias trailingActions: trailingBar.actions

        title: i18n.tr("Contacts")
        flickable: contactList.view

        leadingActionBar {
            id: leadingBar
        }
        trailingActionBar {
            id: trailingBar
        }

        extension: Sections {
            id: pageHeaderSections
            objectName: "headerSections"
            anchors {
                left: parent ? parent.left : undefined
                leftMargin: units.gu(2)
                bottom: parent ? parent.bottom : undefined
            }
            model:  [i18n.ctr("All Contacts", "All"), i18n.tr("Favorites")]
            onSelectedIndexChanged: {
                switch (selectedIndex) {
                case 0:
                    contactList.showAllContacts();
                    break;
                case 1:
                    contactList.showFavoritesContacts()
                    break;
                default:
                    break;
                }
            }
        }
    }

    state: "default"
    states: [
        State {
            id: defaultState

            name: "default"
            property list<QtObject> trailingActions: [
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
                target: pageHeader
                trailingActions: defaultState.trailingActions
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
            property list<QtObject> leadingActions: [
                Action {
                    iconName: "back"
                    text: i18n.tr("Cancel")
                    onTriggered: {
                        contactList.forceActiveFocus()
                        contactsPage.state = "default"
                        pageHeaderSections.selectedIndex = 0
                    }
                }
            ]

            PropertyChanges {
                target: pageHeader
                leadingActions: searchingState.leadingActions
                contents: searchField
                extension: null
            }

            PropertyChanges {
                target: searchField
                text: ""
                visible: true
            }
        }
    ]

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

        fetchHint: FetchHint {
            detailTypesHint: [
                ContactDetail.DisplayLabel,
                ContactDetail.PhoneNumber,
                ContactDetail.Email,
                ContactDetail.Name,
                ContactDetail.Avatar,
                ContactDetail.Tag
            ]
        }

        showAddNewButton: true
        showImportOptions: (contactList.count === 0) &&
                           (filterTerm === "") &&
                           (contactsPage.phoneToAdd === "")
        filterTerm: searchField.text

        onAddNewContactClicked: {
            var newContact = ContactsJS.createEmptyContact(contactsPage.phoneToAdd, contactsPage)
            pageStack.push(Qt.resolvedUrl("../ContactEditorPage/DialerContactEditorPage.qml"),
                           { model: contactList.listModel,
                             contact: newContact,
                             initialFocusSection: (contactsPage.phoneToAdd != "" ? "phones" : "name"),
                             contactListPage: contactsPage
                           })
        }
        onContactClicked: {
            if (contactsPage.phoneToAdd != "") {
                mainView.addPhoneToContact(contact,
                                           contactsPage.phoneToAdd,
                                           contactsPage,
                                           contactList.listModel)
            } else {
                contactSelected(contact)
            }
        }
        rightSideActions: [
               Action {
                   iconName: "contact"
                   text: i18n.tr("view contact")
                   onTriggered: {
                       var contact = contactList.listModel.contacts[value.contactIndex]
                       mainView.viewContact(contact,
                                            contactsPage,
                                            contactList.listModel)
                   }
               }

           ]
       }


   Component {
       id: chooseNumberDialog
       Dialog {
           id: dialog
           property var contact
           title: i18n.tr("Please select a phone number")
           modal:true

           signal selectedPhoneNumber(string number)

           ListItem.ItemSelector {
               id: phoneNumberList
               anchors {
                   left: parent.left
                   right: parent.right
               }
               activeFocusOnPress: false
               expanded: true
               text: i18n.tr("Numbers") + ":"
               model: contact.phoneNumbers
               selectedIndex: -1
               delegate: OptionSelectorDelegate {
                   highlightWhenPressed: true
                   text: modelData.number
                   activeFocusOnPress: false
               }
               onDelegateClicked: selectedPhoneNumber(contact.phoneNumbers[index].number)
           }

           Connections {
               target: __eventGrabber
               onPressed: PopupUtils.close(dialog)
           }
       }
   }

    Component.onCompleted: {
        if (QTCONTACTS_PRELOAD_VCARD !== "") {
            contactList.listModel.importContacts("file://" + QTCONTACTS_PRELOAD_VCARD)
        }
	// focus the search field / show the keyboard on start
        //state = "searching";
        //state = initialState;
    }

    onActiveChanged: {
        if (active && (state === "searching")) {
            searchField.forceActiveFocus()
        }
    }

    KeyboardRectagle {
        id: keyboardRect
    }
}


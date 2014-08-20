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

    property QtObject contact

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
                        searchField.forceActiveFocus()
                    }
                }
            ]
            PropertyChanges {
                target: contactsPage.head
                actions: defaultState.actions
                sections.model: [i18n.tr("All"), i18n.tr("Favorites")]
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


        header: Item {
            id: addNewContactButton
            objectName: "addNewContact"

            anchors {
                left: parent.left
                right: parent.right
            }
            height: units.gu(8)

            Rectangle {
                anchors.fill: parent
                color: Theme.palette.selected.background
                opacity: addNewContactButtonArea.pressed ?  1.0 : 0.0
            }

            UbuntuShape {
                id: addIcon

                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                    margins: units.gu(1)
                }
                width: height
                radius: "medium"
                color: Theme.palette.normal.overlay
                Image {
                    anchors.centerIn: parent
                    width: units.gu(2)
                    height: units.gu(2)
                    source: "image://theme/add"
                }
            }

            Label {
                id: name

                anchors {
                    left: addIcon.right
                    leftMargin: units.gu(2)
                    verticalCenter: parent.verticalCenter
                    right: parent.right
                    rightMargin: units.gu(2)
                }
                color: UbuntuColors.lightAubergine
                // TRANSLATORS: this refers to a new contact
                text: i18n.tr("+ Create New")
                elide: Text.ElideRight
            }

            MouseArea {
                id: addNewContactButtonArea

                anchors.fill: parent
                onClicked: mainView.createNewContactForPhone(" ")
            }
        }

        onInfoRequested: {
           mainView.viewContact(contact.contactId)
        }
        filterTerm: searchField.text
        detailToPick: ContactDetail.PhoneNumber
        onDetailClicked: {
            if (action === "message") {
                Qt.openUrlExternally("message:///" + encodeURIComponent(detail.number))
                return
            }
            pageStack.pop()
            if (callManager.hasCalls) {
                mainView.call(detail.number, mainView.account.accountId);
            } else {
                mainView.populateDialpad(detail.number)
            }
        }
        onAddDetailClicked: mainView.addPhoneToContact(contact.contactId, " ")
    }

    KeyboardRectagle {
        id: keyboardRect
    }
}


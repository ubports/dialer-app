/*
 * Copyright 2015 Canonical Ltd.
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


import QtQuick 2.2
import QtContacts 5.0

import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3 as Popups
import Ubuntu.Contacts 0.1

import Ubuntu.AddressBook.Base 0.1
import Ubuntu.AddressBook.ContactView 0.1
import Ubuntu.AddressBook.ContactShare 0.1

ContactViewPage {
    id: root
    objectName: "contactViewPage"

    readonly property string contactEditorPageURL: Qt.resolvedUrl("../ContactEditorPage/DialerContactEditorPage.qml")
    property string addPhoneToContact: ""
    property var contactListPage: null

    function addPhoneToContactImpl(contact, phoneNumber)
    {
        var detailSourceTemplate = "import QtContacts 5.0; PhoneNumber{ number: \"" + phoneNumber.trim() + "\" }"
        var newDetail = Qt.createQmlObject(detailSourceTemplate, contact)
        if (newDetail) {
            contact.addDetail(newDetail)
            pageStack.push(root.contactEditorPageURL,
                           { model: root.model,
                             contact: contact,
                             initialFocusSection: "phones",
                             newDetails: [newDetail],
                             contactListPage: root.contactListPage })
            root.addPhoneToContact = ""
        } else {
            console.warn("Fail to create phone number detail")
        }
    }

    model: null
    headerActions: [
        Action {
            objectName: "share"
            text: i18n.tr("Share")
            iconName: "share"
            onTriggered: {
                pageStack.push(contactShareComponent,
                               {contactModel: root.model, contacts: [root.contact]})
            }
        },
        Action {
            objectName: "edit"
            text: i18n.tr("Edit")
            iconName: "edit"
            onTriggered: {
                pageStack.push(contactEditorPageURL,
                               { model: root.model,
                                 contact: root.contactMainConstituent,
                                 contactListPage: root.contactListPage })
            }
        }
    ]

    extensions: ContactDetailSyncTargetView {
        contact: root.contact
        anchors {
            left: parent.left
            right: parent.right
        }
        height: implicitHeight
    }

    onContactRemoved: pageStack.pop()
    onActionTrigerred: {
        if ((action == "tel") || (action == "default")) {
            mainView.populateDialpad(detail.number)
        } else {
            Qt.openUrlExternally(("%1:%2").arg(action).arg(detail.value(0)))
        }
    }

    Component {
        id: contactShareComponent
        ContactSharePage {}
    }

    onContactFetched: {
        root.contact = contact
        if (root.active && root.addPhoneToContact != "") {
            root.addPhoneToContactImpl(root.contactMainConstituent, root.addPhoneToContact)
            root.addPhoneToContact = ""
        }
    }

    Component {
        id: contactModelComponent

        ContactListModel {
            id: contactModelHelper

            manager: ContactManager.manager()
            autoUpdate: false
        }
    }

    onActiveChanged: {
        if (active && root.contactMainConstituent && root.addPhoneToContact != "") {
            root.addPhoneToContactImpl(root.contactMainConstituent, root.addPhoneToContact)
            root.addPhoneToContact = ""
        }
    }

    Component.onCompleted: {
        if (!root.model) {
            root.model = contactModelComponent.createObject(root)
        }
    }
}

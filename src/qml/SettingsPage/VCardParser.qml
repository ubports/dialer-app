/*
 * Copyright (C) 2015-2017 Canonical, Ltd.
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

import QtQuick 2.4
import QtContacts 5.0

QtObject {
    id: root

    property string vCardUrl
    property alias contacts: contactsModel.contacts
    property var _model

    signal vcardParsed(int error)

    function clearModel()
    {
        if (contactsModel.contacts.length === 0)
            return;

        var ids = []
        for(var i=0, iMax=contactsModel.contacts.length; i < iMax; i++) {
            ids.push(contactsModel.contacts[i].contactId)
        }
        contactsModel.removeContacts(ids)
    }

    _model: ContactModel {
        id: contactsModel

        manager: "memory"

        onImportCompleted: vcardParsed(error)
    }

    onVCardUrlChanged: {
        if (vCardUrl.length > 0) {
            clearModel()
            contactsModel.importContacts(vCardUrl)
        }
    }
}

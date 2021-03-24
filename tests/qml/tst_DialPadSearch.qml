/*
 * Copyright 2020 Ubports Foundation.
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
import QtTest 1.0
import QtContacts 5.0
import Ubuntu.Test 0.1
import '../../src/qml/DialerPage'

Item {
    id: root

    width: units.gu(40)
    height: units.gu(60)

    function emptyContacts(model) {
        if (!model.autoUpdate)
            model.update();
        var count = model.contacts.length;
        if (count == 0)
            return;
        for (var i = 0; i < count; i++) {
            var id = model.contacts[0].contactId;
            model.removeContact(id);
            if (!model.autoUpdate)
                model.update()
            spy.wait();
            spy.clear();
        }
    }

    Filter {
        id:noFilter
    }

    Contact {
        id: contact1;
        DisplayLabel {
            label: "contactA"
        }

        Name {
            firstName: "contactA"
        }
        PhoneNumber {
            number: "1111111111"
        }
    }

    Contact {
        id: contact2

        DisplayLabel {
            label: "contactB"
        }

        Name {
            firstName: "contactB"
            lastName:"zorro"
        }

        PhoneNumber {
            number: "3333333333"
            subTypes:[PhoneNumber.Mobile]
        }

        PhoneNumber {
            number: "4444444444"
            subTypes:[PhoneNumber.Fax]
        }
    }

    function appendPattern(p) {
        dialPadSearch.phoneNumberField = dialPadSearch.phoneNumberField + p
        dialPadSearch.push(p)
    }

    function pop() {
        dialPadSearch.phoneNumberField = dialPadSearch.phoneNumberField.substring(0, dialPadSearch.phoneNumberField.length-1)
        dialPadSearch.pop()
    }

    ContactDialPadSearch {
        id: dialPadSearch
        width:parent.width
    }

    SignalSpy {
        id: spyOnContactSelected
        target: dialPadSearch
        signalName: 'contactSelected'
    }

    SignalSpy {
        id: spyOnManagerChanged
        signalName: 'managerChanged'
    }

    SignalSpy {
        id: spyOnFilterChanged
        signalName: 'filterChanged'
    }

    SignalSpy {
        id: spyOnContactsChanged
        signalName: 'contactsChanged'
    }

    SignalSpy {
        id: spyOnCountChanged
        signalName: 'countChanged'
    }

    SignalSpy {
        id: spyOnCurrentIndexChanged
        signalName: 'currentIndexChanged'
    }

    SignalSpy {
        id: spyOnModelChanged
        signalName: 'modelChanged'
    }

    TestCase {
        id: dialPadSearchStatesTestCase
        name: 'dialPadSearchTestCase'

        when: windowShown

        function init() {
            waitForRendering(dialPadSearch);
            dialPadSearch.phoneNumberField = ''
            dialPadSearch.clearAll()
        }

        function cleanup() {
            spyOnContactSelected.clear()
        }

        function test_init() {
            tryCompare(dialPadSearch, 'state', 'NO_FILTER');
            var listView = findChild(dialPadSearch, 'listView')
            tryCompare(listView, 'count', 0);
        }

        function test_shouldSwitchToNameFilter() {
            appendPattern('A')
            verify(dialPadSearch.searchHistory.length > 0)
            tryCompare(dialPadSearch, 'state', 'NAME_SEARCH');
        }

        function test_shouldSwitchToPhoneFilter() {
            appendPattern('0')
            appendPattern('1')
            verify(dialPadSearch.searchHistory.length > 0)
            tryCompare(dialPadSearch, 'state', 'NUMBER_SEARCH');
        }

        function test_shouldReturnToNoFilter() {
            appendPattern('A')
            appendPattern('B')
            pop()
            tryCompare(dialPadSearch, 'state', 'NO_FILTER');
            verify(dialPadSearch.searchHistory.length == 0)
            appendPattern('A')
            //user have reset the field
            dialPadSearch.clearAll()
            tryCompare(dialPadSearch, 'state', 'NO_FILTER');
        }

        function test_shouldBackToNameFilter() {
            appendPattern('A')
            appendPattern('B')
            appendPattern('C')
            pop()
            tryCompare(dialPadSearch, 'state', 'NAME_SEARCH');
        }

    }

    TestCase {
        id: contactsTestCase
        when: windowShown

        function initTestCase() {
            var contactModel = findChild(dialPadSearch, 'contactModel')
            spyOnFilterChanged.target = contactModel
            spyOnContactsChanged.target = contactModel
            spyOnManagerChanged.target = contactModel

            //init model, reset memory db and append 2 contacts
            contactModel.manager = "memory"
            spyOnManagerChanged.wait()
            //we need no filter in order to have all contacts
            var currentFilter = contactModel.filter
            contactModel.filter = noFilter
            spyOnFilterChanged.wait()

            emptyContacts(contactModel)
            contactModel.saveContact(contact1);
            spyOnContactsChanged.wait()
            contactModel.saveContact(contact2);
            spyOnContactsChanged.wait()

            contactModel.filter = currentFilter
            spyOnFilterChanged.wait()
            spyOnContactsChanged.wait()

            var listView = findChild(dialPadSearch, 'listView')
            spyOnCountChanged.target = listView
            spyOnCurrentIndexChanged.target = listView
        }


        function cleanup() {
            var contactModel = findChild(dialPadSearch, 'contactModel')
            dialPadSearch.phoneNumberField = ""
            dialPadSearch.clearAll()
            spyOnFilterChanged.wait()
            spyOnCountChanged.wait()

            spyOnContactSelected.clear()
            spyOnCountChanged.clear()
            spyOnContactsChanged.clear()
        }

        function test_asinglePhoneNumberSelection(){
            var listView = findChild(dialPadSearch, 'listView')
            waitForRendering(listView)
            appendPattern('1')
            appendPattern('1')
            spyOnCountChanged.wait()
            compare(listView.count, 1)
            tryVerify(function(){ return listView.currentItem })
            var contactItem = findChild(listView.currentItem, 'contactItem')
            compare(contactItem.text, "contactA")

            mouseClick(listView.currentItem)
            spyOnContactSelected.wait()
            compare(spyOnContactSelected.count, 1)
        }

        // contact number is guessed according to phoneNumberField number
        function test_multiPhoneNumberSelectionGuessed() {
            var listView = findChild(dialPadSearch, 'listView')
            appendPattern('3')
            appendPattern('3')

            spyOnCountChanged.wait()
            tryCompare(listView, "count", 1)

            tryVerify(function(){ return listView.currentItem })
            var contactItem = findChild(listView.currentItem, 'contactItem')
            compare(contactItem.text, "contactB")
            mouseClick(listView.currentItem)
            spyOnContactSelected.wait()
            compare(spyOnContactSelected.count, 1)

            var args = spyOnContactSelected.signalArguments[0]
            compare(args[0].phoneNumber.number, "3333333333")
        }

        // test user interaction to select the correct number
        function test_multiPhoneNumberSelectionPopup() {
            appendPattern('z')
            appendPattern('o')
            spyOnCountChanged.wait()

            var listView = findChild(dialPadSearch, 'listView')
            tryVerify(function(){ return listView.currentItem })
            var contactItem = findChild(listView.currentItem, 'contactItem')
            compare(contactItem.text, "contactB")

            mouseClick(listView.currentItem)
            wait(200) //wait popup to display

            var phoneNumberChoice = findChild(root.parent, "phoneNumberChoice")
            waitForRendering(phoneNumberChoice)
            compare(phoneNumberChoice.count, 2)
            verify(phoneNumberChoice.visible)

            tryVerify(function(){ return phoneNumberChoice.currentItem })
            mouseClick(phoneNumberChoice.currentItem)
            spyOnContactSelected.wait()
            compare(spyOnContactSelected.count, 1)
        }
    }
}

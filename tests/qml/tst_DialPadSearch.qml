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

    ContactDialPadSearch {
        id: dialPadSearch
        width:parent.width
    }

    SignalSpy {
        id: spyOnContactSelected
        target: dialPadSearch
        signalName: 'contactSelected'
    }

    TestCase {
        id: contactsTestCase
        when: windowShown

        function cleanup() {
            spyOnContactSelected.clear()
            dialPadSearch.phoneNumberField = ""
        }

        function test_singlePhoneNumberSelection(){
            var listView = findChild(dialPadSearch, 'listView')
            waitForRendering(listView)
            dialPadSearch.phoneNumberField = "111"
            var contact = {displayLabel:"ContactA", phoneNumbers: ["111111111"]};

            dialPadSearch.selectContact(contact)
            spyOnContactSelected.wait()
            compare(spyOnContactSelected.count, 1)
            var args = spyOnContactSelected.signalArguments[0]
            compare(args["0"], contact.phoneNumbers[0])

        }

        // contact number is guessed according to phoneNumberField number
        function test_multiPhoneNumberSelectionGuessed() {
            var listView = findChild(dialPadSearch, 'listView')
            waitForRendering(listView)
            dialPadSearch.phoneNumberField = "222"
            var contact = {displayLabel:"ContactA", phoneNumbers: ["111111111", "2222222"]};

            dialPadSearch.selectContact(contact)
            spyOnContactSelected.wait()
            compare(spyOnContactSelected.count, 1)

            var args = spyOnContactSelected.signalArguments[0]
            compare(args["0"], contact.phoneNumbers[1])
        }

        // test user interaction to select the correct number
        function test_multiPhoneNumberSelectionPopup() {

            var listView = findChild(dialPadSearch, 'listView')
            waitForRendering(listView)
            dialPadSearch.phoneNumberField = "Co"
            var contact = {displayLabel:"ContactA", phoneNumbers: ["111111111", "2222222"]};

            dialPadSearch.selectContact(contact)
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

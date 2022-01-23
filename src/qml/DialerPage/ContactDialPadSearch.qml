/*
 * Copyright 2020 Ubports Foundation
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
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components 1.3
import Ubuntu.Contacts 0.1
import Ubuntu.Telephony.PhoneNumber 0.1

import dialerapp.private 0.1

Item {
    id:root
    objectName: "root"

    property string phoneNumberField: ""
    signal contactSelected(string phoneNumber)


    function pop() {
        dialPadSearch.pop();
    }

    function push(pattern) {
        dialPadSearch.push(pattern, phoneNumberField);
    }

    function clearAll() {
        dialPadSearch.clearAll()
    }

    function selectContact(contact) {
        if (contact.phoneNumbers.length > 1) {
            // try to determine the right number if user search with numbers
            for (var i=0; i < contact.phoneNumbers.length; i++) {
                if (contact.phoneNumbers[i].replace(/ /g,'').startsWith(phoneNumberField.replace(/ /g,''))) {
                    contactSelected(contact.phoneNumbers[i])
                    return
                }
            }
            // otherwise, ask user to select the right number
            var dialog = PopupUtils.open(chooseNumberDialog, fakeItemPositionner, {
                                                           'phoneNumbers': contact.phoneNumbers
                                                        });
            dialog.selectedPhoneNumber.connect(
                                        function(number) {
                                            PopupUtils.close(dialog);
                                            contactSelected(number)
                                        })
        } else {
            // we take the first phone number from the list
            contactSelected(contact.phoneNumbers[0])
        }
    }

    onContactSelected: dialPadSearch.clearAll()

    DialPadSearch {
        id: dialPadSearch
        objectName: "dialPadSearchModel"
        manager: ContactManager.defaultManager
        countryCode:  PhoneUtils.getCountryCodePrefix(PhoneUtils.defaultRegion)

        phoneNumber: root.phoneNumberField
    }

    ListView {
        id: listView
        objectName: "listView"
        orientation: ListView.Horizontal
        anchors.fill: parent
        model: dialPadSearch
        spacing: units.gu(2)
        delegate: Rectangle {

            width: lbl.width + units.gu(2)
            height: root.height
            color: theme.palette.normal.foreground
            border.color: UbuntuColors.silk
            radius: 10

            Label {
                id:lbl
                objectName: "contactItem"
                fontSize: "medium"
                text:  displayLabel
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    var contact = dialPadSearch.get(index)
                    root.selectContact(contact)
                }
            }
        }
    }

    // fake item to allow popover to position under the listView
    Item {
        id: fakeItemPositionner
        objectName: "fakeItemPositionner"
        x: parent.width /2
        y: units.gu(12)
    }

    Component {
        id: chooseNumberDialog

        Popover {
            id: popover

            property var phoneNumbers
            signal selectedPhoneNumber(string number)

            ListView {
                id: phoneNumberChoice
                objectName: "phoneNumberChoice"

                model: phoneNumbers
                highlightMoveDuration : 0

                height: units.gu(6) * phoneNumbers.length
                width: parent.width
                delegate: ListItem {
                    divider.visible: true
                    height: layout.height + (divider.visible ? divider.height : 0)
                    onClicked: selectedPhoneNumber(phoneNumbers[index])

                    ListItemLayout {
                        id: layout
                        title.text: modelData
                    }
                }
            }
        }
    }
}

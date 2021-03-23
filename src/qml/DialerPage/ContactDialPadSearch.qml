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
import QtContacts 5.0

Item {
    id:root
    objectName: "root"
    state: "NO_FILTER"

    property var searchHistory : []
    property  string phoneNumberField: ""
    property int nameSearchLastIndex: 0
    property bool emptySearch: phoneNumberField.length === 0
    //this is a work around for contact not being fetched while user is addind more patterns
    // it becomes true when either there is a search result, or after a period of time ( see Timer )
    property bool fetchComplete: false

    signal contactSelected(QtObject contact)

    function _cartesianProduct(a) { // a = array of array
        var i, j, l, m, a1, o = [];
        if (!a || a.length == 0) return a;

        a1 = a.splice(0, 1)[0]; // the first array of a
        a = _cartesianProduct(a);
        for (i = 0, l = a1.length; i < l; i++) {
            if (a && a.length) for (j = 0, m = a.length; j < m; j++)
                    o.push(a1[i].concat(a[j]));
            else
                o.push(a1[i]);
        }
        return o;
    }

    function clearAll() {
        searchHistory = []
        nameSearchLastIndex = 0
        state = "NO_FILTER"
        fetchComplete = false
        generateFilters()
    }

    function pop() {
        searchHistory.pop()
        if (state === "NO_FILTER" && !emptySearch) {
            // user have selected a contact and hit back space
            state = "NUMBER_SEARCH"
        } else if (searchHistory.length > 0 && searchHistory.length === nameSearchLastIndex){
            // return to name search
            state = "NAME_SEARCH"
        } else if (emptySearch || phoneNumberField.length === 1) {
            clearAll()
        }

        generateFilters()

    }

    function push(pattern) {
        if (pattern && pattern.length > 0) {
            searchHistory.push(pattern)

            if (state === "NO_FILTER" && phoneNumberField.length === 1 && searchHistory.length === 1) {
                //first time
                state = "NAME_SEARCH"

            } else {
                if (state === "NAME_SEARCH" && fetchComplete && contactModel.contacts.length === 0) {
                    //start to search for phone numbers if no contact found
                    state = "NUMBER_SEARCH"
                    // store here the last time we did a textSearch
                    nameSearchLastIndex = searchHistory.length
                }
            }
            fetchComplete = false
            searchTimer.start()
        }
    }

    Timer {
        id:searchTimer
        interval: 300; running: false; repeat: false
        onTriggered: {
            generateFilters()
        }
    }

    Timer {
        id:checkTimer
        interval: 300; running: false; repeat: false
        onTriggered: {
            fetchComplete = true
        }
    }

    function generateTextFilters() {
        var i, f, newFilters = []

        //generate patterns
        var tmp = []
        for (var i = 0; i < searchHistory.length; i++) {
            tmp.push(searchHistory[i].split(""))
        }
        var searchPatterns =  _cartesianProduct(tmp)

        for(i = 0; i < searchPatterns.length; i++) {
            f = lastNameFilter.createObject(parent, { value: searchPatterns[i]});
            newFilters.push(f)
            f = firstNameFilter.createObject(parent, { value: searchPatterns[i]});
            newFilters.push(f)
        }
        return newFilters
    }

    function generateFilters() {
        var tmpFilters
        if (state === 'NAME_SEARCH') {
            tmpFilters = generateTextFilters()
        } else if (state === 'NUMBER_SEARCH') {
            phoneNumberFilter.value = phoneNumberField.replace(/ /g,'')
            tmpFilters = [fakeFilter, phoneNumberFilter]
        } else {
            tmpFilters = [invalidFilter]
        }
        contactModel.filters = tmpFilters
        checkTimer.start()
    }

    onContactSelected: clearAll()

    Component {
        id: firstNameFilter
        DetailFilter {
            detail: ContactDetail.Name
            field: Name.FirstName
            matchFlags: DetailFilter.MatchStartsWith
        }
    }

    Component {
        id: lastNameFilter
        DetailFilter {
            detail: ContactDetail.Name
            field: Name.LastName
            matchFlags: DetailFilter.MatchStartsWith
        }
    }

    DetailFilter {
        id: phoneNumberFilter
        detail: ContactDetail.PhoneNumber
        field: PhoneNumber.Number
        matchFlags: (DetailFilter.MatchPhoneNumber | DetailFilter.MatchStartsWith)
    }

    // mandatory fake filter used with phoneNumberFilter, otherwise we will have no result
    DetailFilter{
        id: fakeFilter
        detail: ContactDetail.Timestamp
        field: Timestamp.Timestamp
        matchFlags: DetailFilter.MatchExactly
        value: -1
    }

    InvalidFilter {
        id: invalidFilter
    }

    ContactModel {
        id: contactModel
        objectName: "contactModel"
        manager: "galera"
        property alias filters: _filters.filters
        sortOrders: [
            SortOrder {
                id: sortOrder
                detail: ContactDetail.DisplayLabel
                field: DisplayLabel.Label
                direction: Qt.AscendingOrder
                blankPolicy: SortOrder.BlanksLast
                caseSensitivity: Qt.CaseInsensitive
            }
        ]

        fetchHint: FetchHint {
            detailTypesHint: [
                ContactDetail.DisplayLabel,
                ContactDetail.PhoneNumber
            ]
        }

        filter: UnionFilter {
            id: _filters
            filters: [invalidFilter]
        }

        onContactsChanged: {
            if (state === "NAME_SEARCH" && contacts.length === 0) {
                //start to search for phone numbers if no contact found
                state = "NUMBER_SEARCH"
                //store here the last time we did a successfull textSearch
                nameSearchLastIndex = searchHistory.length -1
                generateFilters()
            }
        }

        onErrorChanged: {
            if (error) {
                console.error("Contact List error:" + error)
            }
        }
    }

    ListView {
        id: listView
        objectName: "listView"
        orientation: ListView.Horizontal
        anchors.fill: parent
        model: contactModel
        spacing: units.gu(2)
        delegate: Rectangle {

            width: lbl.width + units.gu(2)
            height: root.height
            color: theme.palette.normal.foreground
            border.color: UbuntuColors.silk
            radius: 10

            Label {
                id:lbl
                fontSize: "medium"
                text:  contact.displayLabel.label
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (contact.phoneNumbers.length > 1) {
                        // try to determine the right number if user search with numbers
                        for (var i=0; i < contact.phoneNumbers.length; i++) {
                            if (contact.phoneNumbers[i].number.startsWith(phoneNumberField.replace(/ /g,''))) {
                                contact.phoneNumber.number = contact.phoneNumbers[i].number
                                contactSelected(contact)
                                return
                            }
                        }
                        // otherwise, ask user to select the right number
                        var dialog = PopupUtils.open(chooseNumberDialog, fakeItemPositionner, {
                                                                       'contact': contact
                                                                    });
                        dialog.selectedPhoneNumber.connect(
                                                    function(number) {
                                                        //we replace temporarely the default phone number
                                                        contact.phoneNumber.number = number
                                                        PopupUtils.close(dialog);
                                                        contactSelected(contact)
                                                    })
                    } else {
                        contactSelected(contact)
                    }
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

            property var contact
            signal selectedPhoneNumber(string number)

            ListView {
                id: phoneNumberChoice
                objectName: "phoneNumberChoice"

                model: contact.phoneNumbers
                highlightMoveDuration : 0

                height: units.gu(6) * contact.phoneNumbers.length
                width: parent.width

                delegate: ListItem {
                    divider.visible: true
                    height: layout.height + (divider.visible ? divider.height : 0)
                    onClicked: selectedPhoneNumber(contact.phoneNumbers[index].number)

                    ListItemLayout {
                        id: layout
                        title.text: modelData.number
                    }
                }
            }
        }
    }
}

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

Item {
    id: tabs
    anchors.topMargin: header.height
    anchors.fill: parent
    property int currentTab: 0
    Item {
        id: tabMenu
        anchors.left: parent.left
        anchors.right: parent.right
        height: units.gu(8)

        property variant items: ["keypad.png", "live_call_contacts.png", "calllog.png"]
        Grid {
            rows: 1
            columns: 3
            spacing: units.gu(8)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            Repeater {
                model: 3
                Image {
                    clip: true
                    id: text
                    height: units.gu(4)
                    width: units.gu(4)
                    source: "../qml/assets/" + tabMenu.items[index]
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            tabs.currentTab = index
                        }
                    }
                }
            }
        }
        z: 1
    }

    Item {

        anchors.top: tabMenu.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        Loader {
            id: dialerPage
            visible: tabs.currentTab == 0
            source: Qt.resolvedUrl("DialerPage/DialerPage.qml")
            anchors.fill: parent
        }

        Loader {
            id: contactsPage
            visible: tabs.currentTab == 1
            source: Qt.resolvedUrl("ContactsPage/ContactsPage.qml")
            asynchronous: true
            anchors.fill: parent
        }

        Loader {
            id: historyPage
            visible: tabs.currentTab == 2
            source: Qt.resolvedUrl("HistoryPage/HistoryPage.qml")
            asynchronous: true
            anchors.fill: parent
        }
    }
}

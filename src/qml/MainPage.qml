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

    TabMenu {
        id: tabMenu
        anchors.left: parent.left
        anchors.right: parent.right
        onTabChanged: tabs.currentTab = index
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

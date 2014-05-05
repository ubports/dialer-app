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
    id: mainPage
    property alias currentTab: tabs.selectedTabIndex

    anchors.fill: parent

    Tabs {
        id: tabs
        anchors.fill: parent

        Tab {
            objectName: "keypadTab"
            title: i18n.tr("Keypad")
            page: Loader{
                id: dialerPage
                source: Qt.resolvedUrl("DialerPage/DialerPage.qml")
                anchors.fill: parent
            }
        }

        Tab {
            objectName: "contactsTab"
            title: i18n.tr("Contacts")
            page: Loader{
                id: contactsPage
                source: Qt.resolvedUrl("ContactsPage/ContactsPage.qml")
                asynchronous: true
                anchors.fill: parent
            }
        }
    }
}

/*
 * Copyright 2014 Canonical Ltd.
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
import Ubuntu.Test 0.1

Item {
    id: root

    width: units.gu(40)
    height: units.gu(60)

    Item {
        id: application
        function mmiPluginList() {
            return []
        }
    }

    Item {
        id: greeter
        property bool greeterActive: false
    }

    Loader {
        id: mainViewLoader
        property string i18nDirectory: ""
        source: '../../src/qml/dialer-app.qml'
    }

    UbuntuTestCase {
        id: dialerPageTestCase
        name: 'dialerPageTestCase'

        when: windowShown

        function init() {
        }

        function cleanup() {
        }

        function test_dialerPageHeaderTitleWhenAppIsInBackground() {
            tryCompare(mainViewLoader.item, 'applicationActive', true)
            tryCompare(mainViewLoader.item.currentStack, 'depth', 1)

            mainViewLoader.item.telepathyReady = true
            tryCompare(mainViewLoader.item.currentStack.currentPage, 'title', i18n.tr('No network'))

            // we should still display the title on regular states
            mainViewLoader.item.applicationActive = false
            tryCompare(mainViewLoader.item.currentStack.currentPage, 'title', i18n.tr('No network'))

            // app must always display "emergency calls" when the greeter is active and app is in foreground
            mainViewLoader.item.applicationActive = true
            greeter.greeterActive = true
            tryCompare(mainViewLoader.item.currentStack.currentPage, 'title', i18n.tr('Emergency Calls'))

            mainViewLoader.item.applicationActive = false
            tryCompare(mainViewLoader.item.currentStack.currentPage, 'title', ' ')
        }
    }
}

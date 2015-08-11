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
import Ubuntu.Telephony 0.1

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

    QtObject {
        id: testAccount
        property string accountId: "ofono/ofono/account0"
        property var emergencyNumbers: [ "444", "555"]
        property int type: AccountEntry.PhoneAccount
        property string displayName: "SIM 1"
        property bool connected: true
        property bool emergencyCallsAvailable: true
        property bool active: true
        property string networkName: "Network name"
        property bool simLocked: false
    }

    Item {
        id: telepathyHelper
        function registerChannelObserver() {}
        function unregisterChannelObserver() {}
        property bool emergencyCallsAvailable: true
        property bool flightMode: false
        property var activeAccounts: [testAccount]
        property alias accounts: telepathyHelper.activeAccounts
    }

    Item {
        id: callManager
        signal callStarted
        function startCall(phoneNumber, accountId) {
            callManager.callStarted(phoneNumber, accountId)
        }
    }

    SignalSpy {
       id: callSpy
       target: callManager
       signalName: "callStarted"
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
            mainViewLoader.item.switchToKeypadView()
            tryCompare(mainViewLoader.item, 'applicationActive', true)
            tryCompare(mainViewLoader.item.currentStack, 'depth', 1)

            mainViewLoader.item.telepathyReady = true
            greeter.greeterActive = false
            tryCompare(mainViewLoader.item.currentStack.currentPage, 'title', i18n.tr('Network name'))

            // we should still display the title on regular states
            mainViewLoader.item.applicationActive = false
            tryCompare(mainViewLoader.item.currentStack.currentPage, 'title', i18n.tr('Network name'))

            // app must always display "emergency calls" when the greeter is active and app is in foreground
            mainViewLoader.item.applicationActive = true
            greeter.greeterActive = true
            tryCompare(mainViewLoader.item.currentStack.currentPage, 'title', i18n.tr('Emergency Calls'))

            mainViewLoader.item.applicationActive = false
            tryCompare(mainViewLoader.item.currentStack.currentPage, 'title', ' ')
        }

        function test_dialerPageEmergencyNumbers() {
            tryCompare(mainViewLoader.item, 'applicationActive', true)
            tryCompare(mainViewLoader.item.currentStack, 'depth', 1)

            mainViewLoader.item.telepathyReady = true
            mainViewLoader.item.accountReady = true
            greeter.greeterActive = false
            mainViewLoader.item.switchToKeypadView()

            var dialerPage = mainViewLoader.item.currentStack.currentPage
            var keypadEntry = findChild(mainViewLoader, "keypadEntry")
            var callButton = findChild(mainViewLoader, "callButton")

            // regular number when connected
            testAccount.connected = true
            keypadEntry.value = "123"
            callButton.clicked()
            compare(callSpy.count, 1)
            callSpy.clear()
            mainViewLoader.item.switchToKeypadView()

            // regular number when disconnected
            testAccount.connected = false
            keypadEntry.value = "123"
            callButton.clicked()
            compare(callSpy.count, 0)
            callSpy.clear()
            mainViewLoader.item.switchToKeypadView()

            // regular number in greeter mode
            testAccount.connected = true
            greeter.greeterActive = true
            keypadEntry.value = "123"
            callButton.clicked()
            compare(callSpy.count, 0)
            callSpy.clear()
            mainViewLoader.item.switchToKeypadView()

            // emergency number in greeter mode when connected
            testAccount.connected = true
            greeter.greeterActive = true
            keypadEntry.value = "444"
            callButton.clicked()
            compare(callSpy.count, 1)
            callSpy.clear()
            mainViewLoader.item.switchToKeypadView()

            // emergency number in greeter mode when disconnected
            testAccount.connected = false
            greeter.greeterActive = true
            keypadEntry.value = "444"
            callButton.clicked()
            compare(callSpy.count, 1)
            callSpy.clear()
            mainViewLoader.item.switchToKeypadView()

            // emergency number in flight mode
            testAccount.connected = false
            telepathyHelper.emergencyCallsAvailable = false
            telepathyHelper.flightMode = true
            greeter.greeterActive = false
            keypadEntry.value = "444"
            callButton.clicked()
            telepathyHelper.emergencyCallsAvailable = true
            wait(15000)
            compare(callSpy.count, 1)
            callSpy.clear()
            mainViewLoader.item.switchToKeypadView()
 
            // emergency number in flight mode and greeter mode
            testAccount.connected = false
            telepathyHelper.emergencyCallsAvailable = false
            telepathyHelper.flightMode = true
            greeter.greeterActive = true
            keypadEntry.value = "444"
            callButton.clicked()
            telepathyHelper.emergencyCallsAvailable = true
            wait(15000)
            compare(callSpy.count, 1)
            callSpy.clear()
            mainViewLoader.item.switchToKeypadView()
        }
    }
}

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
import Ubuntu.Telephony 0.1

MainView {
    id: mainView

    property bool applicationActive: Qt.application.active
    property string pendingCallNumber: ""
    property string pendingCallAccountId: ""
    automaticOrientation: false
    width: units.gu(40)
    height: units.gu(71)

    signal applicationReady

    onApplicationActiveChanged: {
        if (applicationActive) {
            telepathyHelper.registerChannelObserver()
        } else {
            telepathyHelper.unregisterChannelObserver()
        }
    }

    function viewContact(contactId) {
        Qt.openUrlExternally("addressbook:///contact?id=" + encodeURIComponent(contactId))
    }

    function addNewContact(phoneNumber) {
        Qt.openUrlExternally("addressbook:///create?phone=" + encodeURIComponent(phoneNumber))
    }

    function addPhoneNumberToExistingContact(contactId, phoneNumber) {
        Qt.openUrlExternally("addressbook:///addphone?id=" + encodeURIComponent(contactId) + "&phone=" + encodeURIComponent(phoneNumber))
    }

    function sendMessage(phoneNumber) {
        Qt.openUrlExternally("message:///" + encodeURIComponent(phoneNumber))
    }

    function callVoicemail() {
        call(callManager.voicemailNumber);
    }

    function checkUSSD(number) {
        var endString = "#"
        // check if it ends with #
        if (number.slice(-endString.length) == endString) {
            // check if it starts with any of these strings
            var startStrings = ["*", "#", "**", "##", "*#"]
            for(var i in startStrings) {
                if (number.slice(0, startStrings[i].length) == startStrings[i]) {
                    return true
                }
            }
        }
        return false
    }

    function call(number, accountId) {
        if (!telepathyHelper.connected  || number === "") {
            return
        }
        if (mainView.pendingCallNumber === "" && checkUSSD(number)) {
            mainView.pendingCallNumber = number
            mainView.pendingCallAccountId = accountId ? accountId : ""
            ussdManager.initiate(number, accountId)
            return
        }
        mainView.pendingCallNumber = ""
        mainView.pendingCallAccountId = ""
        if (pageStack.depth === 1 && !callManager.hasCalls)  {
            pageStack.push(Qt.resolvedUrl("LiveCallPage/LiveCall.qml"))
        }
        if (accountId && telepathyHelper.accountIds.indexOf(accountId) != -1) {
            callManager.startCall(number, accountId);
            return
        }
        callManager.startCall(number);
    }

    function switchToCallLogView() {
        pageStack.currentPage.currentTab = 2;
    }

    Component.onCompleted: {
        Theme.name = "Ubuntu.Components.Themes.SuruGradient";
        pageStack.push(Qt.createComponent("MainPage.qml"))

        // if there are calls, even if we don't have info about them yet, push the livecall view
        if (callManager.hasCalls) {
            pageStack.push(Qt.resolvedUrl("LiveCallPage/LiveCall.qml"));
        }
    }

    Connections {
        target: telepathyHelper
        onAccountReady: {
            mainView.applicationReady()
        }
    }

    Connections {
        target: callManager
        onForegroundCallChanged: {
            if(!callManager.hasCalls) {
                while (pageStack.depth > 1) {
                    pageStack.pop();
                }
                return
            }
            // if there are no calls, or if the views are already loaded, do not continue processing
            if ((callManager.foregroundCall || callManager.backgroundCall) && pageStack.depth === 1) {
                pageStack.push(Qt.resolvedUrl("LiveCallPage/LiveCall.qml"));
                application.activateWindow();
            }
        }
    }

    Connections {
        target: UriHandler
        onOpened: {
           for (var i = 0; i < uris.length; ++i) {
               application.parseArgument(uris[i])
           }
       }
    }

    Connections {
        target: ussdManager
        onInitiateFailed: call(mainView.pendingCallNumber, mainView.pendingCallAccountId)
        onInitiateUSSDComplete: {
            mainView.pendingCallNumber = ""
            mainView.pendingCallAccountId = ""
        }
    }

    PageStack {
        id: pageStack
        anchors.fill: parent
    }
}

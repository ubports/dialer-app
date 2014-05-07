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
import Ubuntu.Components.Popups 0.1
import Ubuntu.Telephony 0.1

MainView {
    id: mainView

    property bool applicationActive: Qt.application.active
    property string ussdResponseTitle: ""
    property string ussdResponseText: ""
    automaticOrientation: false
    width: units.gu(40)
    height: units.gu(71)
    useDeprecatedToolbar: false

    signal applicationReady
    signal closeUSSDProgressIndicator

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
        if (number === "") {
            return
        }

        if (checkUSSD(number)) {
            PopupUtils.open(ussdProgressDialog)
            ussdManager.initiate(number, accountId)
            return
        }

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
        pageStack.push(Qt.createComponent("DialerPage/DialerPage.qml"))

        // if there are calls, even if we don't have info about them yet, push the livecall view
        if (callManager.hasCalls) {
            pageStack.push(Qt.resolvedUrl("LiveCallPage/LiveCall.qml"));
        }
    }

    Component {
        id: ussdProgressDialog
        Dialog {
            id: ussdProgressIndicator
            visible: false
            title: i18n.tr("Please wait")
            ActivityIndicator {
                running: parent.visible
            }
            Connections {
                target: mainView
                onCloseUSSDProgressIndicator: {
                    PopupUtils.close(ussdProgressIndicator)
                }

            }
        }
    }

    Component {
        id: ussdErrorDialog
        Dialog {
            id: ussdError
            visible: false
            title: i18n.tr("Error")
            text: i18n.tr("Invalid USSD code")
            Button {
                text: i18n.tr("Dismiss")
                onClicked: PopupUtils.close(ussdError)
            }
        }
    }

    Component {
        id: ussdResponseDialog
        Dialog {
            id: ussdResponse
            visible: false
            title: mainView.ussdResponseTitle
            text: mainView.ussdResponseText
            Button {
                text: i18n.tr("Dismiss")
                onClicked: PopupUtils.close(ussdResponse)
            }
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
        onInitiateFailed: {
            mainView.closeUSSDProgressIndicator()
            PopupUtils.open(ussdErrorDialog)
        }
        onInitiateUSSDComplete: {
            mainView.closeUSSDProgressIndicator()
        }
        onBarringComplete: {
            mainView.closeUSSDProgressIndicator()
            mainView.ussdResponseTitle = String(i18n.tr("Call Barring") + " - " + cbService + "\n" + ssOp)
            mainView.ussdResponseText = ""
            for (var prop in cbMap) {
                if (cbMap[prop] !== "") {
                    mainView.ussdResponseText += String(prop + ": " + cbMap[prop] + "\n")
                }
            }
            PopupUtils.open(ussdResponseDialog)
        }
        onForwardingComplete: {
            mainView.closeUSSDProgressIndicator()
            mainView.ussdResponseTitle = String(i18n.tr("Call Forwarding") + " - " + cfService + "\n" + ssOp)
            mainView.ussdResponseText = ""
            for (var prop in cfMap) {
                if (cfMap[prop] !== "") {
                    mainView.ussdResponseText += String(prop + ": " + cfMap[prop] + "\n")
                }
            }
            PopupUtils.open(ussdResponseDialog)
        }
        onWaitingComplete: {
            mainView.closeUSSDProgressIndicator()
            mainView.ussdResponseTitle = String(i18n.tr("Call Waiting") + " - " + ssOp)
            mainView.ussdResponseText = ""
            for (var prop in cwMap) {
                if (cwMap[prop] !== "") {
                    mainView.ussdResponseText += String(prop + ": " + cwMap[prop] + "\n")
                }
            }
            PopupUtils.open(ussdResponseDialog)
        }
        onCallingLinePresentationComplete: {
            mainView.closeUSSDProgressIndicator()
            mainView.ussdResponseTitle = String(i18n.tr("Calling Line Presentation") + " - " + ssOp)
            mainView.ussdResponseText = status
            PopupUtils.open(ussdResponseDialog)
        }
        onConnectedLinePresentationComplete: {
            mainView.closeUSSDProgressIndicator()
            mainView.ussdResponseTitle = String(i18n.tr("Connected Line Presentation") + " - " + ssOp)
            mainView.ussdResponseText = status
            PopupUtils.open(ussdResponseDialog)
        }
        onCallingLineRestrictionComplete: {
            mainView.closeUSSDProgressIndicator()
            mainView.ussdResponseTitle = String(i18n.tr("Calling Line Restriction") + " - " + ssOp)
            mainView.ussdResponseText = status
            PopupUtils.open(ussdResponseDialog)
        }
        onConnectedLineRestrictionComplete: {
            mainView.closeUSSDProgressIndicator()
            mainView.ussdResponseTitle = String(i18n.tr("Connected Line Restriction") + " - " + ssOp)
            mainView.ussdResponseText = status
            PopupUtils.open(ussdResponseDialog)
        }
    }

    PageStack {
        id: pageStack
        anchors.fill: parent
    }
}

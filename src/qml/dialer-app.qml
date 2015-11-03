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
import Qt.labs.settings 1.0

import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Telephony 0.1
import Ubuntu.Contacts 0.1

MainView {
    id: mainView

    objectName: "mainView"

    property bool applicationActive: Qt.application.active
    property string ussdResponseTitle: ""
    property string ussdResponseText: ""
    property bool multiplePhoneAccounts: {
        var numAccounts = 0
        for (var i in telepathyHelper.activeAccounts) {
            if (telepathyHelper.activeAccounts[i].type == AccountEntry.PhoneAccount) {
                numAccounts++
            }
        }
        return numAccounts > 1
    }
 
    property QtObject account: defaultPhoneAccount()
    property bool greeterMode: (state == "greeterMode")
    property bool lastHasCalls: callManager.hasCalls
    property bool telepathyReady: false
    property var currentStack: mainView.greeterMode ? pageStackGreeterMode : pageStackNormalMode

    function defaultPhoneAccount() {
        // we only use the default account property if we have more
        // than one account, otherwise we use always the first one
        if (multiplePhoneAccounts) {
            return telepathyHelper.defaultCallAccount
        } else {
            for (var i in telepathyHelper.activeAccounts) {
                var tmpAccount = telepathyHelper.activeAccounts[i]
                if (tmpAccount.type == AccountEntry.PhoneAccount) {
                    return tmpAccount
                }
            }
        }
        return null
    }

    automaticOrientation: false
    width: units.gu(40)
    height: units.gu(71)

    property bool hasCalls: callManager.hasCalls

    signal applicationReady
    signal closeUSSDProgressIndicator

    property string pendingNumberToDial: ""
    property bool accountReady: false

    onApplicationActiveChanged: {
        if (applicationActive) {
            telepathyHelper.registerChannelObserver()

            if (!callManager.hasCalls) {
                // if on contacts page in a live call and no calls are found, pop it out
                if (pageStackNormalMode.depth > 2 && pageStackNormalMode.currentPage.objectName == "contactsPage") {
                    pageStackNormalMode.pop();
                }

                // pop live call views from both stacks if we have no calls.
                if (pageStackNormalMode.depth > 1 && pageStackNormalMode.currentPage.objectName == "pageLiveCall") {
                    pageStackNormalMode.pop();
                }
                if (pageStackGreeterMode.depth > 1 && pageStackGreeterMode.currentPage.objectName == "pageLiveCall") {
                    pageStackGreeterMode.pop();
                }
            }
        } else {
            telepathyHelper.unregisterChannelObserver()
        }
    }

    Connections {
        target: telepathyHelper
        onSetupReady: {
            telepathyReady = true
            if (multiplePhoneAccounts && !telepathyHelper.defaultCallAccount &&
                dualSimSettings.mainViewDontAskCount < 3 && pageStackNormalMode.depth === 1 && !mainView.greeterMode) {
                PopupUtils.open(Qt.createComponent("Dialogs/NoDefaultSIMCardDialog.qml").createObject(mainView))
            }
        }
    }

    Connections {
        target: telepathyHelper
        onActiveAccountsChanged: {
            // check if the selected account is not active anymore
            for (var i in telepathyHelper.activeAccounts) {
                if (telepathyHelper.activeAccounts[i] == account) {
                    return;
                }
            }
            account = Qt.binding(defaultPhoneAccount)
        }
        onDefaultCallAccountChanged: account = Qt.binding(defaultPhoneAccount)
    }

    Settings {
        id: dualSimSettings
        category: "DualSim"
        property bool dialPadDontAsk: false
        property int mainViewDontAskCount: 0
    }

    Settings {
        id: generalSettings
        property string lastCalledPhoneNumber: ""
    }

    PhoneUtils {
        id: phoneUtils
    }

    Binding {
        target: application
        property: "fullScreen"
        // the applicationActive avoids the flickering when we unlock
        // the screen and the app is in foreground
        value: mainView.greeterMode && mainView.applicationActive
    }

    state: greeter.greeterActive ? "greeterMode" : "normalMode"
    states: [
        State {
            name: "greeterMode"

            StateChangeScript {
                script: {
                    // preload greeter stack if not done yet
                    if (pageStackGreeterMode.depth == 0) {
                        pageStackGreeterMode.push(Qt.resolvedUrl("DialerPage/DialerPage.qml"))
                    }
                    // make sure to reset the view so that the contacts page is not loaded
                    if (callManager.hasCalls) {
                        switchToLiveCall();
                    } else {
                        removeLiveCallView();
                    }
                }
            }
        },
        State {
            name: "normalMode"

            StateChangeScript {
                script: {
                    // make sure to reset the view so that the contacts page is not loaded
                    if (callManager.hasCalls) {
                        switchToLiveCall();
                    } else {
                        removeLiveCallView();
                    }
                }
            }
        }
    ]

    function isEmergencyNumber(number) {
        // TODO should we only check for emergency numbers
        // in the selected account?

        // check for specific account emergency numbers
        for (var i in telepathyHelper.accounts) {
            var account = telepathyHelper.accounts[i];
            for (var j in account.emergencyNumbers) {
                if (number == account.emergencyNumbers[j]) {
                    return true;
                }
            }
            // then check using libphonenumber
            if (phoneUtils.isEmergencyNumber(number, account.countryCode)) {
                return true;
            }
        }
        return false;
    }

    function addNewPhone(phoneNumber)
    {
        pageStackNormalMode.push(Qt.resolvedUrl("ContactsPage/ContactsPage.qml"),
                                 {"phoneToAdd": phoneNumber})
    }

    function viewContact(contact, contactListPage, model) {
        var initialPropers = {"model": model}

        if (typeof(contact) == 'string') {
            initialPropers["contactId"] = contact
        } else {
            initialPropers["contact"] = contact
        }
        pageStackNormalMode.push(Qt.resolvedUrl("ContactViewPage/DialerContactViewPage.qml"),
                                 initialPropers)
    }

    function addPhoneToContact(contact, phoneNumber, contactListPage, model) {
        var initialPropers =  {"addPhoneToContact": phoneNumber,
                               "contactListPage": contactListPage,
                               "model": model }

        if (typeof(contact) == 'string') {
            initialPropers["contactId"] = contact
        } else {
            initialPropers["contact"] = contact
        }

        pageStackNormalMode.push(Qt.resolvedUrl("ContactViewPage/DialerContactViewPage.qml"),
                                 initialPropers)
    }

    function sendMessage(phoneNumber) {
        Qt.openUrlExternally("message:///" + encodeURIComponent(phoneNumber))
    }

    function callVoicemail() {
        if (mainView.greeterMode) {
            return;
        }
        call(mainView.account.voicemailNumber);
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

    function checkMMI(number) {
        var endString1 = "#"
        var endString2 = "*"
        // check if it ends with # or *
        if (number.slice(-endString1.length) == endString1 || number.slice(-endString2.length) == endString2) {
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

    function callEmergency(number) {
        // if we are in flight mode, we first need to disable it and wait for
        // the modems to update
        if (telepathyHelper.flightMode) {
            pendingNumberToDial = number;
            telepathyHelper.flightMode = false;
            PopupUtils.open(flightModeProgressDialog, mainView, {"emergencyMode": true})
            return;
        }

        animateLiveCall();

        var account = null;
        // check if the selected account is active and can make emergency calls
        if (mainView.account && mainView.account.active && mainView.account.emergencyCallsAvailable) {
            account = mainView.account
        } else if (telepathyHelper.activeAccounts.length > 0) {
            // now try to use one of the connected accounts
            account = telepathyHelper.activeAccounts[0];
        } else {
            // if no account is active, use any account that can make emergency calls
            for (var i in telepathyHelper.accounts) {
                if (telepathyHelper.accounts[i].emergencyCallsAvailable) {
                    account = telepathyHelper.accounts[i];
                    break;
                }
            }
        }

        // not sure what to do when no accounts can make emergency calls
        if (account == null) {
            pendingNumberToDial = number;
            return;
        }

        if (!accountReady) {
            pendingNumberToDial = number;
            return;
        }

        callManager.startCall(number, account.accountId);
    }

    function call(number, skipDefaultSimDialog) {
        // clear the values here so that the changed signals are fired when the new value is set
        pendingNumberToDial = "";

        if (number === "") {
            return
        }

        if (isEmergencyNumber(number)) {
            callEmergency(number);
            return;
        }

        if (telepathyHelper.flightMode) {
            PopupUtils.open(Qt.createComponent("Dialogs/DisableFlightModeDialog.qml").createObject(mainView), mainView, {})
            return
        }

        // check if at least one account is selected
        if (multiplePhoneAccounts && !mainView.account) {
            Qt.inputMethod.hide()
            showNotification(i18n.tr("No SIM card selected"), i18n.tr("You need to select a SIM card"));
            return
        }

        if (multiplePhoneAccounts && !telepathyHelper.defaultCallAccount && !dualSimSettings.dialPadDontAsk && !skipDefaultSimDialog) {
            var properties = {}
            properties["phoneNumber"] = number
            properties["accountId"] = mainView.account.accountId
            PopupUtils.open(Qt.createComponent("Dialogs/SetDefaultSIMCardDialog.qml").createObject(mainView), mainView, properties)
            return
        }

        if (mainView.account && !mainView.greeterMode && mainView.account.simLocked) {
            var properties = {}
            properties["accountId"] = mainView.account.accountId
            PopupUtils.open(Qt.createComponent("Dialogs/SimLockedDialog.qml").createObject(mainView), mainView, properties)
            return
        }

        // avoid cleaning the keypadEntry in case there is no signal
        if (!mainView.account) {
            showNotification(i18n.tr("No network"), i18n.tr("There is currently no network."))
            return
        }

        if (!mainView.account.connected) {
            showNotification(i18n.tr("No network"),
                             telepathyHelper.accountIds.length >= 2 ? i18n.tr("There is currently no network on %1").arg(mainView.account.displayName)
                                                                    : i18n.tr("There is currently no network."))
            return
        }

        if (checkUSSD(number)) {
            PopupUtils.open(ussdProgressDialog)
            account.ussdManager.initiate(number)
            return
        }

        animateLiveCall();

        if (!accountReady) {
            pendingNumberToDial = number;
            return;
        }

        if (account && account.connected) {
            generalSettings.lastCalledPhoneNumber = number
            callManager.startCall(number, account.accountId);
        }
    }

    function populateDialpad(number, accountId) {
        // populate the dialpad with the given number but don't start the call
        // FIXME: check what to do when not in the dialpad view

        // if not on the livecall view, go back to the dialpad
        while (pageStackNormalMode.depth > 1) {
            pageStackNormalMode.pop();
        }

        if (pageStackNormalMode.currentPage && typeof(pageStackNormalMode.currentPage.dialNumber) != 'undefined') {
            pageStackNormalMode.currentPage.dialNumber = number;
        }
    }

    function removeLiveCallView() {
        // if on contacts page in a live call and no calls are found, pop it out
        if (pageStackNormalMode.depth > 2 && pageStackNormalMode.currentPage.objectName == "contactsPage") {
            pageStackNormalMode.pop();
        }

        if (pageStackNormalMode.depth > 1 && pageStackNormalMode.currentPage.objectName == "pageLiveCall") {
            pageStackNormalMode.pop();
        }

        while (pageStackGreeterMode.depth > 1) {
            pageStackGreeterMode.pop();
        }
    }

    function switchToKeypadView() {
        while (pageStackNormalMode.depth > 1) {
            pageStackNormalMode.pop();
        }
        while (pageStackGreeterMode.depth > 1) {
            pageStackGreeterMode.pop();
        }
    }

    function animateLiveCall() {
        if (currentStack.currentPage && currentStack.currentPage.triggerCallAnimation) {
            currentStack.currentPage.triggerCallAnimation();
        } else {
            switchToLiveCall();
        }
    }

    function switchToLiveCall(initialStatus, initialNumber) {
        if (pageStackNormalMode.depth > 2 && pageStackNormalMode.currentPage.objectName == "contactsPage") {
            // pop contacts Page
            pageStackNormalMode.pop();
        }

        var properties = {}
        properties["initialStatus"] = initialStatus
        properties["initialNumber"] = initialNumber
        if (isEmergencyNumber(pendingNumberToDial)) {
            properties["defaultTimeout"] = 30000
        }

        if (currentStack.currentPage.objectName == "pageLiveCall") {
            return;
        }

        currentStack.push(Qt.resolvedUrl("LiveCallPage/LiveCall.qml"), properties)
    }

    function showNotification(title, text) {
        PopupUtils.open(Qt.resolvedUrl("Dialogs/NotificationDialog.qml"), mainView, {title: title, text: text});
    }

    Component.onCompleted: {
        i18n.domain = "dialer-app"
        i18n.bindtextdomain("dialer-app", i18nDirectory)
        pageStackNormalMode.push(Qt.createComponent("DialerPage/DialerPage.qml"))

        // when running in windowed mode, do not allow resizing
        view.minimumWidth  = width * 0.9
        view.maximumWidth = width * 1.1
        view.minimumHeight = height * 0.9
        view.maximumHeight = height * 1.1

        // if there are calls, even if we don't have info about them yet, push the livecall view
        if (callManager.hasCalls) {
            switchToLiveCall();
        }
    }

    Component {
        id: flightModeProgressDialog
        Dialog {
            id: flightModeProgressIndicator
            property bool emergencyMode: false
            visible: false
            title: i18n.tr("Disabling flight mode")
            ActivityIndicator {
                running: parent.visible
            }
            Connections {
                target: telepathyHelper
                onEmergencyCallsAvailableChanged: {
                    if (!emergencyMode) {
                        PopupUtils.close(flightModeProgressIndicator)
                        return
                    }
                    flightModeTimer.start()
                }
            }
            // FIXME: workaround to give modems some time to become available
            Timer {
                id: flightModeTimer
                interval: 10000
                repeat: false
                onTriggered: {
                    PopupUtils.close(flightModeProgressIndicator)
                    if (telepathyHelper.emergencyCallsAvailable && pendingNumberToDial !== "") {
                        if (!isEmergencyNumber(pendingNumberToDial)) {
                            return;
                        }

                        callEmergency(pendingNumberToDial);
                        pendingNumberToDial = "";
                    }
                }
            }
        }
    }

    Component {
        id: ussdProgressDialog
        Dialog {
            id: ussdProgressIndicator
            objectName: "ussdProgressIndicator"
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
            objectName: "ussdErrorDialog"
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
        onSetupReady: {
            accountReady = true;
            mainView.applicationReady()

            if (!telepathyHelper.ready) {
                return;
            }

            if (pendingNumberToDial != "") {
                callManager.startCall(pendingNumberToDial, mainView.account.accountId);
            }
            pendingNumberToDial = "";
        }
    }

    Connections {
        target: callManager
        onHasCallsChanged: {
            if (!callManager.hasCalls) {
                mainView.lastHasCalls = callManager.hasCalls
                return;
            }

            // if we are animating the dialpad view, do not switch to livecall directly
            if (currentStack.currentPage && currentStack.currentPage.callAnimationRunning) {
                mainView.lastHasCalls = callManager.hasCalls
                return;
            }

            // if not, just open the live call
            if (mainView.lastHasCalls != callManager.hasCalls || mainView.greeterMode) {
                mainView.lastHasCalls = callManager.hasCalls
                switchToLiveCall();
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

    Repeater {
        model: telepathyHelper.phoneAccounts
        Item {
            Connections {
                target: modelData.ussdManager
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
        }
    }

    PageStack {
        id: pageStackNormalMode
        anchors.fill: parent
        active:  mainView.state == "normalMode"
        visible: active
    }

    PageStack {
        id: pageStackGreeterMode
        anchors.fill: parent
        active: mainView.state == "greeterMode"
        visible: active
    }
}

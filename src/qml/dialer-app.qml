/*
 * Copyright 2012-2016 Canonical Ltd.
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

import QtQuick 2.4
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
    property alias multiplePhoneAccounts: accountsModel.multipleAccounts
    property QtObject account: accountsModel.defaultCallAccount
    property bool simLocked: account && account.simLocked
    property bool greeterMode: (state == "greeterMode")
    property bool lastHasCalls: callManager.hasCalls
    property bool telepathyReady: false
    property var currentStack: mainView.greeterMode ? pageStackGreeterMode : pageStackNormalMode
    property alias inputInfo: inputInfoObject
    property var bottomEdge: null

    automaticOrientation: false
    implicitWidth: units.gu(40)
    implicitHeight: units.gu(71)

    property bool hasCalls: callManager.hasCalls

    signal applicationReady
    signal closeUSSDProgressDialog

    property string pendingNumberToDial: ""
    property string delayedDialNumber: ""
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
            accountReady = true;
            mainView.applicationReady()

            if (multiplePhoneAccounts && !telepathyHelper.defaultCallAccount &&
                dualSimSettings.mainViewDontAskCount < 3 && pageStackNormalMode.depth === 1 && !mainView.greeterMode) {
                PopupUtils.open(Qt.createComponent("Dialogs/NoDefaultSIMCardDialog.qml").createObject(mainView))
            }

            if (!telepathyHelper.ready) {
                return;
            }

            if (pendingNumberToDial != "") {
                var dialPrefix = setDelayedDialNumberAndReturnPrefix(pendingNumberToDial);
                callManager.startCall(dialPrefix, mainView.account.accountId);
            }
            pendingNumberToDial = "";
        }
    }

    Connections {
        target: accountsModel
        onActiveAccountsChanged: {
            // check if the selected account is not active anymore
            for (var i in accountsModel.activeAccounts) {
                if (accountsModel.activeAccounts[i] == account) {
                    return;
                }
            }
            account = Qt.binding(function() { return accountsModel.defaultCallAccount })
        }
        onDefaultCallAccountChanged: {
            account = Qt.binding(function() { return accountsModel.defaultCallAccount })
        }
    }

    AccountsModel {
        id: accountsModel
    }

    InputInfo {
        id: inputInfoObject
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
        for (var i in telepathyHelper.accounts.all) {
            var account = telepathyHelper.accounts.all[i];
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
        var initialPropers = {}
        if (model)
            initialPropers["model"]  = model

        if (typeof(contact) == 'string') {
            initialPropers["contactId"] = contact
        } else {
            initialPropers["contact"] = contact
        }
        pageStackNormalMode.push(Qt.resolvedUrl("ContactViewPage/DialerContactViewPage.qml"),
                                 initialPropers)
    }

    function addPhoneToContact(contact, phoneNumber, contactListPage, model) {
        var initialPropers =  {}

        if (phoneNumber)
            initialPropers["addPhoneToContact"] = phoneNumber

        if (contactListPage)
            initialPropers["contactListPage"] = contactListPage

        if (model)
            initialPropers["model"] = model

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
        delayedDialNumber = "";
        // if we are in flight mode, we first need to disable it and wait for
        // the modems to update
        if (telepathyHelper.flightMode) {
            pendingNumberToDial = number;
            telepathyHelper.flightMode = false;
            PopupUtils.open(Qt.resolvedUrl("Dialogs/FlightModeProgressDialog.qml"), mainView, {"emergencyMode": true})
            return;
        }

        animateLiveCall();

        var account = null;
        // check if the selected account is active and can make emergency calls
        if (mainView.account && mainView.account.active && mainView.account.emergencyCallsAvailable) {
            account = mainView.account
        } else if (accountsModel.activeAccounts.length > 0) {
            // now try to use one of the connected accounts
            account = accountsModel.activeAccounts[0];
        } else {
            // if no account is active, use any account that can make emergency calls
            for (var i in telepathyHelper.accounts.all) {
                if (telepathyHelper.accounts.all[i].emergencyCallsAvailable) {
                    account = telepathyHelper.accounts.all[i];
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

    function setDelayedDialNumberAndReturnPrefix(number) {
        // If the number contains ';' or ',', we want to dial
        // the leading number first, and key in everything later
        // with delays
        var semiIdx = number.indexOf(";"); semiIdx = (semiIdx == -1) ? number.length : semiIdx;
        var commaIdx = number.indexOf(","); commaIdx = (commaIdx == -1) ? number.length : commaIdx;
        var minDelayIdx = Math.min(semiIdx, commaIdx);
        delayedDialNumber = number.substring(minDelayIdx);
        return number.substring(0, minDelayIdx);
    }

    function call(number, skipDefaultSimDialog) {
        // clear the values here so that the changed signals are fired when the new value is set
        pendingNumberToDial = "";
        delayedDialNumber = "";

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
            showSimLockedDialog();
            return
        }

        // avoid cleaning the keypadEntry in case there is no signal
        if (!mainView.account) {
            showNotification(i18n.tr("No network"), i18n.tr("There is currently no network."))
            return
        }

        if (!mainView.account.connected) {
            showNotification(i18n.tr("No network"),
                             telepathyHelper.voiceAccounts.displayed.length >= 2 ? i18n.tr("There is currently no network on %1").arg(mainView.account.displayName)
                                                                    : i18n.tr("There is currently no network."))
            return
        }

        if (checkUSSD(number)) {
            PopupUtils.open(Qt.resolvedUrl("Dialogs/UssdProgressDialog.qml"), mainView)
            account.ussdManager.initiate(number)
            return
        }

        var dialPrefix = setDelayedDialNumberAndReturnPrefix(number);

        animateLiveCall();

        if (!accountReady) {
            pendingNumberToDial = number;
            return;
        }

        if (account && account.connected) {
            generalSettings.lastCalledPhoneNumber = number
            callManager.startCall(dialPrefix, account.accountId);
        }
    }

    function populateDialpad(number, accountId) {
        // populate the dialpad with the given number but don't start the call
        // FIXME: check what to do when not in the dialpad view

        // if not on the livecall view, go back to the dialpad
        while (pageStackNormalMode.depth > 1) {
            pageStackNormalMode.pop();
        }

        var dialerPage = pageStackNormalMode.currentPage
        if (dialerPage && typeof(dialerPage.dialNumber) != 'undefined') {
            dialerPage.dialNumber = number;
            if (accountId) {
                dialerPage.selectAccount(accountId)
            }

            if (dialerPage.bottomEdgeItem) {
                dialerPage.bottomEdgeItem.collapse()
            }
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

    function showSimLockedDialog() {
        var properties = {}
        properties["accountId"] = mainView.account.accountId
        PopupUtils.open(Qt.createComponent("Dialogs/SimLockedDialog.qml").createObject(mainView), mainView, properties)
    }

    function accountForModem(modemName) {
        var modemAccounts = telepathyHelper.phoneAccounts.displayed
        for (var i in modemAccounts) {
            if (modemAccounts[i].modemName == modemName) {
                return modemAccounts[i]
            }
        }
        return null
    }

    Component.onCompleted: {
        i18n.domain = "dialer-app"
        i18n.bindtextdomain("dialer-app", i18nDirectory)
        pageStackNormalMode.push(Qt.createComponent("DialerPage/DialerPage.qml"))

        // when running in windowed mode, do not allow resizing
        view.minimumWidth  = units.gu(40)
        view.minimumHeight = units.gu(52)

//        view.maximumWidth = Qt.binding( function() { return implicitWidth * 3.0; } )
//        view.maximumHeight = Qt.binding( function() { return implicitHeight * 3.0; } )

        // if there are calls, even if we don't have info about them yet, push the livecall view
        if (callManager.hasCalls) {
            switchToLiveCall();
        }
    }

    // WORKAROUND: Due the missing feature on SDK, they can not detect if
    // there is a mouse attached to device or not. And this will cause the
    // bootom edge component to not work correct on desktop.
    Binding {
        target:  QuickUtils
        property: "mouseAttached"
        value: inputInfo.hasMouse
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
        model: telepathyHelper.phoneAccounts.all
        Item {
            Connections {
                target: modelData.ussdManager
                onInitiateFailed: {
                    mainView.closeUSSDProgressDialog()
                    PopupUtils.open(Qt.resolvedUrl("Dialogs/UssdErrorDialog.qml"), mainView)
                }
                onInitiateUSSDComplete: {
                    mainView.closeUSSDProgressDialog()
                }
                onBarringComplete: {
                    mainView.closeUSSDProgressDialog()
                    mainView.ussdResponseTitle = String(i18n.tr("Call Barring") + " - " + cbService + "\n" + ssOp)
                    mainView.ussdResponseText = ""
                    for (var prop in cbMap) {
                        if (cbMap[prop] !== "") {
                            mainView.ussdResponseText += String(prop + ": " + cbMap[prop] + "\n")
                        }
                    }
                    PopupUtils.open(Qt.resolvedUrl("Dialogs/UssdResponseDialog.qml"), mainView)
                }
                onForwardingComplete: {
                    mainView.closeUSSDProgressDialog()
                    mainView.ussdResponseTitle = String(i18n.tr("Call Forwarding") + " - " + cfService + "\n" + ssOp)
                    mainView.ussdResponseText = ""
                    for (var prop in cfMap) {
                        if (cfMap[prop] !== "") {
                            mainView.ussdResponseText += String(prop + ": " + cfMap[prop] + "\n")
                        }
                    }
                    PopupUtils.open(Qt.resolvedUrl("Dialogs/UssdResponseDialog.qml"), mainView)
                }
                onWaitingComplete: {
                    mainView.closeUSSDProgressDialog()
                    mainView.ussdResponseTitle = String(i18n.tr("Call Waiting") + " - " + ssOp)
                    mainView.ussdResponseText = ""
                    for (var prop in cwMap) {
                        if (cwMap[prop] !== "") {
                            mainView.ussdResponseText += String(prop + ": " + cwMap[prop] + "\n")
                        }
                    }
                    PopupUtils.open(Qt.resolvedUrl("Dialogs/UssdResponseDialog.qml"), mainView)
                }
                onCallingLinePresentationComplete: {
                    mainView.closeUSSDProgressDialog()
                    mainView.ussdResponseTitle = String(i18n.tr("Calling Line Presentation") + " - " + ssOp)
                    mainView.ussdResponseText = status
                    PopupUtils.open(Qt.resolvedUrl("Dialogs/UssdResponseDialog.qml"), mainView)
                }
                onConnectedLinePresentationComplete: {
                    mainView.closeUSSDProgressDialog()
                    mainView.ussdResponseTitle = String(i18n.tr("Connected Line Presentation") + " - " + ssOp)
                    mainView.ussdResponseText = status
                    PopupUtils.open(Qt.resolvedUrl("Dialogs/UssdResponseDialog.qml"), mainView)
                }
                onCallingLineRestrictionComplete: {
                    mainView.closeUSSDProgressDialog()
                    mainView.ussdResponseTitle = String(i18n.tr("Calling Line Restriction") + " - " + ssOp)
                    mainView.ussdResponseText = status
                    PopupUtils.open(Qt.resolvedUrl("Dialogs/UssdResponseDialog.qml"), mainView)
                }
                onConnectedLineRestrictionComplete: {
                    mainView.closeUSSDProgressDialog()
                    mainView.ussdResponseTitle = String(i18n.tr("Connected Line Restriction") + " - " + ssOp)
                    mainView.ussdResponseText = status
                    PopupUtils.open(Qt.resolvedUrl("Dialogs/UssdResponseDialog.qml"), mainView)
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

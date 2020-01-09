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

import QtContacts 5.0
import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Telephony 0.1
import Ubuntu.Contacts 0.1
import Ubuntu.Components.ListItems 1.3 as ListItems

import "../"

Page {
    id: page

    property bool bottomEdgeCommitted: bottomEdge.status === BottomEdge.Committed
    property alias bottomEdgeItem: bottomEdge
    property alias dialNumber: keypadEntry.value
    property alias input: keypadEntry.input
    property alias callAnimationRunning: callAnimation.running
    property bool greeterMode: false
    property var mmiPlugins: []
    readonly property bool compactView: page.height <= units.gu(60)

    function selectAccount(accountId) {
        for (var i in accountsModel.activeAccounts) {
            var account = accountsModel.activeAccounts[i]
            if (account.accountId === accountId) {
                headerSections.selectedIndex = i
                return
            }
        }
    }

    header: PageHeader {
        id: pageHeader

        property list<Action> actionsGreeter
        property list<Action> actionsNormal: [
            Action {
                objectName: "contacts"
                iconName: "contact"
                text: i18n.tr("Contacts")
                onTriggered: pageStackNormalMode.push(Qt.resolvedUrl("../ContactsPage/ContactsPage.qml"))
            },
            Action {
                iconName: "settings"
                text: i18n.tr("Settings")
                onTriggered: pageStackNormalMode.push(Qt.resolvedUrl("../SettingsPage/SettingsPage.qml"))
            }

        ]
        title: page.title
        focus: false
        trailingActionBar {
            actions: mainView.greeterMode ? actionsGreeter : actionsNormal
        }

        // make sure the SIM selector never gets focus
        onFocusChanged: {
            if (focus) {
                focus = false
            }
        }

        leadingActionBar {
            property list<QtObject> backActionList: [
                Action {
                    iconName: "back"
                    text: i18n.tr("Close")
                    visible: mainView.greeterMode
                    onTriggered: {
                        greeter.showGreeter()
                        dialNumber = "";
                    }
                }
            ]
            property list<QtObject> simLockedActionList: [
                Action {
                    id: simLockedAction
                    objectName: "simLockedAction"
                    iconName: "simcard-locked"
                    onTriggered: {
                        mainView.showSimLockedDialog()
                    }
                }
            ]
            actions: {
                if (mainView.simLocked && !mainView.greeterMode) {
                    return simLockedActionList
                } else {
                    return backActionList
                }
            }
        }

        Sections {
            id: headerSections
            model: mainView.multiplePhoneAccounts ? accountsModel.activeAccountNames : []
            selectedIndex: accountsModel.defaultCallAccountIndex
            focus: false
            onSelectedIndexChanged: {
                if (selectedIndex >= 0) {
                    mainView.account = accountsModel.activeAccounts[selectedIndex]
                } else {
                    mainView.account = null
                }
            }
            onModelChanged: {
                selectedIndex = accountsModel.defaultCallAccountIndex
            }
        }

        extension: headerSections.model.length > 1 ? headerSections : null
    }

    objectName: "dialerPage"
    title: {
        // avoid clearing the title when app is inactive
        // under some states
        if (!mainView.telepathyReady) {
            return i18n.tr("Initializing...")
        } else if (greeter.greeterActive) {
            if (mainView.applicationActive) {
                return i18n.tr("Emergency Calls")
            } else {
                return " "
            }
        } else if (telepathyHelper.flightMode) {
            return i18n.tr("Flight Mode")
        } else if (mainView.account && mainView.account.simLocked) {
            // just in case we need it back in the future somewhere, keep the original string
            var oldTitle = i18n.tr("SIM Locked")
            // show Emergency Calls for sim locked too. There is going to be an icon indicating it is locked
            return i18n.tr("Emergency Calls")
        } else if (mainView.account && mainView.account.networkName && mainView.account.networkName != "") {
            return mainView.account.networkName
        } else if (mainView.account && mainView.account.type != AccountEntry.PhoneAccount) {
            return mainView.account.protocolInfo.serviceDisplayName != "" ? mainView.account.protocolInfo.serviceDisplayName :
                                                                            mainView.account.protocolInfo.name
        } else if (multiplePhoneAccounts && !mainView.account) {
            return i18n.tr("Phone")
        }
        return i18n.tr("No network")
    }

    state: mainView.state
    // -------- Greeter mode ----------
    states: [
        State {
            name: "greeterMode"
            PropertyChanges {
                target: contactLabel
                visible: false
            }
            PropertyChanges {
                target: addContact
                visible: false
            }
        },
        State {
            name: "normalMode"
            PropertyChanges {
                target: contactLabel
                visible: true
            }
            PropertyChanges {
                target: addContact
                visible: true
            }
        }
    ]

    // Forward key presses
    Keys.onPressed: {
        if (!active) {
            return
        }

        // in case Enter is pressed, remove focus from the view to prevent multiple calls to get placed
        if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
            page.focus = false;
        }

        keypad.keyPressed(event.key, event.text)
    }

    function triggerCallAnimation() {
        callAnimation.start();
    }

    Connections {
        target: mainView
        onPendingNumberToDialChanged: {
            keypadEntry.value = mainView.pendingNumberToDial;
            if (mainView.pendingNumberToDial !== "") {
                mainView.switchToKeypadView();
            }
        }
    }

    function createObjectAsynchronously(componentFile, callback) {
        var component = Qt.createComponent(componentFile, Component.Asynchronous);

        function componentCreated() {
            if (component.status == Component.Ready) {
                var incubator = component.incubateObject(page, {}, Qt.Asynchronous);

                function objectCreated(status) {
                    if (status == Component.Ready) {
                        callback(incubator.object);
                    }
                }
                incubator.onStatusChanged = objectCreated;

            } else if (component.status == Component.Error) {
                console.log("Error loading component:", component.errorString());
            }
        }

        component.statusChanged.connect(componentCreated);
    }

    function pushMmiPlugin(plugin) {
        mmiPlugins.push(plugin);
    }

    Component.onCompleted: {
        // load MMI plugins
        var plugins = application.mmiPluginList()
        for (var i in plugins) {
            createObjectAsynchronously(plugins[i], pushMmiPlugin);
        }
    }

    AccountsModel {
        id: accountsModel

        onDefaultCallAccountIndexChanged: {
            headerSections.selectedIndex = defaultCallAccountIndex
        }
    }

    // background
    Rectangle {
        anchors.fill: parent
        color: Theme.palette.normal.background
    }

    FocusScope {
        id: keypadContainer

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: footer.top
            topMargin: pageHeader.height
        }
        focus: true

        Item {
            id: entryWithButtons

            anchors {
                top: parent.top
                left: parent.left
                leftMargin: units.gu(2)
                right: parent.right
                rightMargin: units.gu(2)
            }
            height: page.compactView ? units.gu(7) : units.gu(10)

            CustomButton {
                id: addContact

                anchors {
                    left: parent.left
                    verticalCenter: keypadEntry.verticalCenter
                }
                width: opacity > 0 ? (page.compactView ? units.gu(4) : units.gu(3)) : 0
                height: (keypadEntry.value !== "" && contactWatcher.isUnknown) ? parent.height : 0
                icon: "contact-new"
                iconWidth: units.gu(3)
                iconHeight: units.gu(3)
                opacity: (keypadEntry.value !== "" && contactWatcher.isUnknown) ? 1.0 : 0.0

                Behavior on opacity {
                    UbuntuNumberAnimation { }
                }

                Behavior on width {
                    UbuntuNumberAnimation { }
                }

                onClicked: mainView.addNewPhone(keypadEntry.value)
            }

            KeypadEntry {
                id: keypadEntry
                objectName: "keypadEntry"

                anchors {
                    top: parent.top
                    topMargin: units.gu(3)
                    left: addContact.right
                    right: backspace.left
                }
                focus: true
                placeHolder: i18n.tr("Enter a number")
                Keys.forwardTo: [callButton]
                value: mainView.pendingNumberToDial
                height: page.compactView ? units.gu(2) : units.gu(4)
                maximumFontSize: page.compactView ? units.dp(20) : units.dp(30)
                onCommitRequested: {
                    callButton.clicked()
                }
            }

            CustomButton {
                id: backspace
                objectName: "eraseButton"
                anchors {
                    right: parent.right
                    verticalCenter: keypadEntry.verticalCenter
                }
                width: opacity > 0 ? (page.compactView ? units.gu(4) : units.gu(3)) : 0
                height: input.text !== "" ? parent.height : 0
                icon: "erase"
                iconWidth: units.gu(3)
                iconHeight: units.gu(3)
                opacity: input.text !== "" ? 1 : 0

                Behavior on opacity {
                    UbuntuNumberAnimation { }
                }

                Behavior on width {
                    UbuntuNumberAnimation { }
                }

                onPressAndHold: input.text = ""

                onClicked:  {
                    if (input.cursorPosition > 0)  {
                        input.remove(input.cursorPosition, input.cursorPosition - 1)
                    }
                }
            }
        }

        ListItems.ThinDivider {
            id: divider

            anchors {
                left: parent.left
                leftMargin: units.gu(2)
                right: parent.right
                rightMargin: units.gu(2)
                top: entryWithButtons.bottom
            }
        }

        ContactWatcher {
            id: contactWatcher
            identifier: keypadEntry.value
            // for this contact watcher we are only interested in matching phone numbers
            addressableFields: ["tel"]
        }

        Label {
            id: contactLabel
            anchors {
                horizontalCenter: divider.horizontalCenter
                bottom: entryWithButtons.bottom
                bottomMargin: units.gu(1)
            }
            text: contactWatcher.isUnknown ? "" : contactWatcher.alias
            color: theme.palette.normal.backgroundSecondaryText
            opacity: text != "" ? 1 : 0
            fontSize: "small"
            Behavior on opacity {
                UbuntuNumberAnimation { }
            }
        }

        Keypad {
            id: keypad
            showVoicemail: true

            anchors {
                top: divider.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: units.gu(2)
            }
            labelPixelSize: page.compactView ? units.dp(20) : units.dp(30)
            spacing: page.compactView ? 0 : 5
            onKeyPressed: {
                // handle special keys (backspace, arrows, etc)
                keypadEntry.handleKeyEvent(keycode, keychar)

                if (keycode == Qt.Key_Space) {
                    return
                }

                callManager.playTone(keychar);
                input.insert(input.cursorPosition, keychar)
                if(checkMMI(dialNumber)) {
                    // check for custom strings
                    for (var i in mmiPlugins) {
                        if (mmiPlugins[i].code == dialNumber) {
                            dialNumber = ""
                            mmiPlugins[i].trigger()
                        }
                    }
                }
            }
            onKeyPressAndHold: {
                // we should only call voicemail if the keypad entry was empty,
                // but as we add numbers when onKeyPressed is triggered, the keypad entry will be "1"
                if (keycode == Qt.Key_1 && dialNumber == "1") {
                    dialNumber = ""
                    mainView.callVoicemail()
                } else if (keycode == Qt.Key_0) {
                    // replace 0 by +
                    input.remove(input.cursorPosition - 1, input.cursorPosition)
                    input.insert(input.cursorPosition, "+")
                } else if (dialNumber.length > 1 && keycode == Qt.Key_ssharp) {
                    // replace '#' by ';'. don't do this if this itself is the first character
                    input.remove(input.cursorPosition - 1, input.cursorPosition)
                    input.insert(input.cursorPosition, ";")
                } else if (dialNumber.length > 1 && keycode == Qt.Key_Asterisk) {
                    // replace '*' by ','. don't do this if this itself is the first character
                    input.remove(input.cursorPosition - 1, input.cursorPosition)
                    input.insert(input.cursorPosition, ",")
                }
            }
        }
    }

    Item {
        id: footer

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: units.gu(10)

        CallButton {
            id: callButton
            objectName: "callButton"
            enabled: mainView.telepathyReady
            anchors {
                bottom: footer.bottom
                bottomMargin: units.gu(5)
                horizontalCenter: parent.horizontalCenter
            }
            onClicked: {
                if (dialNumber == "") {
                    if (mainView.greeterMode) {
                        return;
                    }
                    keypadEntry.value = generalSettings.lastCalledPhoneNumber
                    return;
                }

                if (mainView.greeterMode && !mainView.isEmergencyNumber(dialNumber)) {
                    // we only allow users to call any number in greeter mode if there are
                    // no sim cards present. The operator will block the number if it thinks
                    // it's necessary.
                    // for phone accounts, active means the the status is not offline:
                    // "nomodem", "nosim" or "flightmode"

                    var denyEmergencyCall = false
                    // while in flight mode we can't detect if sims are present in some devices
                    if (telepathyHelper.flightMode) {
                        denyEmergencyCall = true
                    } else {
                        for (var i in accountsModel.activeAccounts) {
                            var account = accountsModel.activeAccounts[i]
                            if (account.type == AccountEntry.PhoneAccount) {
                                denyEmergencyCall = true;
                            }
                        }
                    }
                    if (denyEmergencyCall) {
                        // if there is at least one sim card present, just ignore the call
                        showNotification(i18n.tr("Emergency call"), i18n.tr("This is not an emergency number."))
                        keypadEntry.value = "";
                        return;
                    }

                    // this is a special case, we need to call using callEmergency() directly to avoid
                    // all network and dual sim checks we have in mainView.call()
                    mainView.callEmergency(keypadEntry.value)
                    return;
                }

                console.log("Starting a call to " + keypadEntry.value);
                mainView.call(keypadEntry.value);
            }
        }
    }

    SequentialAnimation {
        id: callAnimation

        PropertyAction {
            target: callButton
            property: "color"
            value: theme.palette.normal.negative
        }

        ParallelAnimation {
            UbuntuNumberAnimation {
                target: keypadContainer
                property: "opacity"
                to: 0.0
                duration: UbuntuAnimation.SlowDuration
            }
            UbuntuNumberAnimation {
                target: callButton
                property: "iconRotation"
                to: -90.0
                duration: UbuntuAnimation.SlowDuration
            }
        }
        ScriptAction {
            script: {
                mainView.switchToLiveCall(i18n.tr("Calling"), keypadEntry.value)
                keypadEntry.value = ""
                callButton.iconRotation = 0.0
                keypadContainer.opacity = 1.0
                callButton.color = callButton.defaultColor
            }
        }
    }

    DialerBottomEdge {
        id: bottomEdge
        enabled: !mainView.greeterMode
        height: page.height
        hint.text: i18n.tr("Recent")
        hint.visible: enabled
    }
}

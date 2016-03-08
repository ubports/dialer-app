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
import QtQuick 2.0
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Telephony 0.1
import Ubuntu.Contacts 0.1
import Ubuntu.Components.ListItems 1.3 as ListItems

import "../"

Page {
    id: page

    property alias dialNumber: keypadEntry.value
    property alias input: keypadEntry.input
    property alias callAnimationRunning: callAnimation.running
    property bool greeterMode: false
    property var mmiPlugins: []
    property var accountsModel: {
        var model = []

        // do not show any accounts in greeter mode
        if (mainView.greeterMode) {
            return []
        }

        // populate model with all active phone accounts
        for (var i in telepathyHelper.activeAccounts) {
            var account = telepathyHelper.activeAccounts[i]
            if (account.type == AccountEntry.PhoneAccount) {
                model.push(account)
            }
        }
        // do not show dual sim switch if there is only one sim
        if (model.length == 1 && model[0].type == AccountEntry.PhoneAccount) {
            return []
        }
        return model
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
                onTriggered: Qt.openUrlExternally("settings:///system/phone")
            }

        ]
        title: page.title
        trailingActionBar {
            actions: mainView.greeterMode ? actionsGreeter : actionsNormal
        }

        leadingActionBar {
            actions: [
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
        }

        Sections {
            id: headerSections
            model: {
                var accountNames = []
                for (var i in page.accountsModel) {
                    accountNames.push(page.accountsModel[i].displayName)
                }
                return accountNames
            }
            selectedIndex: accountIndex(mainView.account)
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
            return i18n.tr("SIM Locked")
        } else if (mainView.account && mainView.account.networkName != "") {
            return mainView.account.networkName
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

    function accountIndex(account) {
        var index = -1;
        for (var i in page.accountsModel) {
            if (page.accountsModel[i] == account) {
                index = i;
                break;
            }
        }
        return index;
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

    Component.onCompleted: {
        // load MMI plugins
        var plugins = application.mmiPluginList()
        for (var i in plugins) {
            var component = Qt.createComponent(plugins[i]);
            mmiPlugins.push(component.createObject(page))
        }
    }

    Connections {
        target: headerSections
        onSelectedIndexChanged: {
            mainView.account = page.accountsModel[headerSections.selectedIndex]
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
            fill: parent
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
            height: units.gu(10)

            CustomButton {
                id: addContact

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                width: opacity > 0 ? units.gu(4) : 0
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
                height: units.gu(4)
                focus: true
                placeHolder: i18n.tr("Enter a number")
                Keys.forwardTo: [callButton]
                value: mainView.pendingNumberToDial
            }

            CustomButton {
                id: backspace
                objectName: "eraseButton"
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                width: opacity > 0 ? units.gu(4) : 0
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
            color: UbuntuColors.darkGrey
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
                topMargin: units.gu(2)
                horizontalCenter: parent.horizontalCenter
            }

            onKeyPressed: {
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
                        for (var i in telepathyHelper.activeAccounts) {
                            var account = telepathyHelper.activeAccounts[i]
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
            value: "red"
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
    }
}

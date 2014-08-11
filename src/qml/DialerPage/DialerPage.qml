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

import QtContacts 5.0
import QtQuick 2.0
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 0.1
import Ubuntu.Telephony 0.1
import Ubuntu.Contacts 0.1
import Ubuntu.Components.ListItems 0.1 as ListItems

import "../"

PageWithBottomEdge {
    id: page

    property alias dialNumber: keypadEntry.value
    property alias input: keypadEntry.input
    objectName: "dialerPage"

    head.actions: [
        Action {
            iconName: "contact"
            text: i18n.tr("Contacts")
            onTriggered: pageStack.push(Qt.resolvedUrl("../ContactsPage/ContactsPage.qml"))
        },
        Action {
            iconName: "settings"
            text: i18n.tr("Settings")
            onTriggered: Qt.openUrlExternally("settings:///system/phone")
        }
    ]

    title: i18n.tr("Keypad")

    // -------- Greeter mode ----------
    states: [
        State {
            name: "greeterMode"
            when: greeter.greeterActive

            PropertyChanges {
                target: page.head
                actions: []
            }
            PropertyChanges {
                target: contactLabel
                visible: false
            }
        }
    ]

    // -------- Bottom Edge Setup -----
    bottomEdgeEnabled: !greeter.greeterActive
    bottomEdgePageSource: Qt.resolvedUrl("../HistoryPage/HistoryPage.qml")
    bottomEdgeExpandThreshold: bottomEdgePage ? bottomEdgePage.delegateHeight * 3 : 0
    bottomEdgeTitle: i18n.tr("Recent")
    reloadBottomEdgePage: false

    property int historyDelegateHeight: bottomEdgePage ? bottomEdgePage.delegateHeight : 1

    onBottomEdgeExposedAreaChanged: {
        if (!bottomEdgePage)  {
            return
        }

        var index =  Math.floor(bottomEdgeExposedArea / historyDelegateHeight)
        if (index < 3) {
            bottomEdgePage.currentIndex = index
        } else {
            bottomEdgePage.currentIndex = -1
        }
    }

    onBottomEdgeReleased: {
        if (bottomEdgePage.currentIndex < 3) {
            bottomEdgePage.activateCurrentIndex()
        } else {
            bottomEdgePage.currentIndex = -1
        }
    }

    onIsReadyChanged: {
        if (bottomEdgePage) {
            bottomEdgePage.fullView = isReady
        }
    }

    onDialNumberChanged: {
        if(checkUSSD(dialNumber)) {
            // check for custom strings
            if (dialNumber === "*#06#") {
                dialNumber = ""
                mainView.ussdResponseTitle = "IMEI"
                mainView.ussdResponseText = ussdManager.serial(mainView.account.accountId)
                PopupUtils.open(ussdResponseDialog)
            }
        }
    }

    function accountIndex(account) {
        var index = -1;
        for (var i in telepathyHelper.accounts) {
            if (telepathyHelper.accounts[i] == account) {
                index = i;
                break;
            }
        }
        return index;
    }

    Connections {
        target: mainView
        onPendingNumberToDialChanged: {
            keypadEntry.value = mainView.pendingNumberToDial;
            if (mainView.pendingNumberToDial !== "") {
                mainView.switchToKeypadView();
            }
        }
        onAccountChanged: {
            var newAccountIndex = accountIndex(account);
            if (newAccountIndex >= 0 && newAccountIndex !== page.head.sections.selectedIndex) {
                page.head.sections.selectedIndex = newAccountIndex
            }
        }
    }

    head.sections.model: {
        // does not show dual sim switch if there is only one sim
        if (!multipleAccounts) {
            return undefined
        }

        var accountNames = []
        for(var i=0; i < telepathyHelper.accounts.length; i++) {
            accountNames.push(telepathyHelper.accounts[i].displayName)
        }
        return accountNames
    }

    // Account switcher
    head.sections.selectedIndex: {
        if (!mainView.account) {
            return -1
        }
        return accountIndex(mainView.account)
    }

    Connections {
        target: page.head.sections
        onSelectedIndexChanged: {
            mainView.account = telepathyHelper.accounts[page.head.sections.selectedIndex]
        }
    }

    FocusScope {
        id: keypadContainer

        anchors.fill: parent
        focus: true

        Item {
            id: entryWithButtons

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: units.gu(10)

            CustomButton {
                id: addContact

                anchors {
                    left: parent.left
                    leftMargin: units.gu(2)
                    verticalCenter: parent.verticalCenter
                }
                width: units.gu(3)
                height: (keypadEntry.value !== "" && contactWatcher.isUnknown) ? units.gu(3) : 0
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
                    rightMargin: units.gu(2)
                    verticalCenter: parent.verticalCenter
                }
                width: units.gu(3)
                height: input.text !== "" ? units.gu(3) : 0
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
            phoneNumber: keypadEntry.value
        }

        Label {
            id: contactLabel
            anchors {
                horizontalCenter: divider.horizontalCenter
                bottom: entryWithButtons.bottom
                bottomMargin: units.gu(1)
            }
            text: contactWatcher.isUnknown ? "" : contactWatcher.alias
            color: UbuntuColors.lightAubergine
            opacity: text != "" ? 1 : 0
            fontSize: "small"
            Behavior on opacity {
                UbuntuNumberAnimation { }
            }
        }

        Keypad {
            id: keypad

            anchors {
                top: divider.bottom
                topMargin: units.gu(2)
                horizontalCenter: parent.horizontalCenter
            }

            onKeyPressed: {
                input.insert(input.cursorPosition, label)
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
            anchors {
                bottom: footer.bottom
                bottomMargin: units.gu(5)
                horizontalCenter: parent.horizontalCenter
            }
            onClicked: {
                console.log("Starting a call to " + keypadEntry.value);
                // check if at least one account is selected
                if (multipleAccounts && !mainView.account) {
                    Qt.inputMethod.hide()
                    PopupUtils.open(noSimCardSelectedDialog)
                    return
                }

                if (multipleAccounts && !telepathyHelper.defaultCallAccount && !settings.dialPadDontAsk) {
                    var properties = {}
                    properties["phoneNumber"] = dialNumber
                    properties["accountId"] = mainView.account.accountId
                    PopupUtils.open(setDefaultSimCardDialog, footer, properties)
                    return
                }

                // avoid cleaning the keypadEntry in case there is no signal
                if (!mainView.account.connected) {
                    PopupUtils.open(noNetworkDialog)
                    return
                }
                callAnimation.start()
            }
            enabled: {
                if (dialNumber == "") {
                    return false;
                }

                if (greeter.greeterActive) {
                    return mainView.isEmergencyNumber(dialNumber);
                }

                return true;
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
                mainView.call(keypadEntry.value, mainView.account.accountId);
                keypadEntry.value = ""
                callButton.iconRotation = 0.0
                keypadContainer.opacity = 1.0
                callButton.color = callButton.defaultColor
            }
        }
    }
}

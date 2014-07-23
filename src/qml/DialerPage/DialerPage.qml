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
import Ubuntu.Components.ListItems 0.1 as ListItems
import "../"

PageWithBottomEdge {
    id: page
    property string voicemailNumber: callManager.voicemailNumber
    property alias dialNumber: keypadEntry.value
    property alias input: keypadEntry.input
    property bool multipleAccounts: telepathyHelper.accountIds.length > 1
    objectName: "dialerPage"

    head.actions: [
        Action {
                iconSource: "image://theme/contact"
                text: i18n.tr("Contacts")
                onTriggered: pageStack.push(Qt.resolvedUrl("../ContactsPage/ContactsPage.qml"))
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
                bottomEdgeEnabled: false
            }
            PropertyChanges {
                target: contactLabel
                visible: false
            }
        }
    ]

    // -------- Bottom Edge Setup -----
    bottomEdgeEnabled: true
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
        bottomEdgePage.fullView = isReady;
    }

    onDialNumberChanged: {
        if(checkUSSD(dialNumber)) {
            // check for custom strings
            if (dialNumber === "*#06#") {
                dialNumber = ""
                mainView.ussdResponseTitle = "IMEI"
                mainView.ussdResponseText = ussdManager.serial(mainView.accountId)
                PopupUtils.open(ussdResponseDialog)
            }
        }
    }

    Connections {
        target: mainView
        onPendingNumberToDialChanged: {
            keypadEntry.value = mainView.pendingNumberToDial;
            if (mainView.pendingNumberToDial !== "") {
                mainView.switchToKeypadView();
            }
        }
        onAccountIdChanged: {
            var newAccountIndex = mainView.accounts.indexOf(accountId)
            if (newAccountIndex !== page.head.sections.selectedIndex) {
                page.head.sections.selectedIndex = newAccountIndex
            }
        }
    }

    head.sections.model: multipleAccounts ? mainView.accounts : []
    Connections {
        target: head.sections
        onSelectedIndexChanged: {
            var currentAccountIndex = mainView.accounts.indexOf(mainView.accountId)
            if (currentAccountIndex !== selectedIndex) {
                mainView.accountId = mainView.accounts[selectedIndex]
            }
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
                width: height
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
                    verticalCenter: parent.verticalCenter
                    left: addContact.right
                    right: backspace.left
                }

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
                width: height
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
                topMargin: units.gu(3)
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
                // avoid cleaning the keypadEntry in case there is no signal
                if (!telepathyHelper.isAccountConnected(mainView.accountId)) {
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
                mainView.call(keypadEntry.value, mainView.accountId);
                keypadEntry.value = "";
            }
        }
    }
}

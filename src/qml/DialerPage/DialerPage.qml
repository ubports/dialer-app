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
import Ubuntu.Components 0.1
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

    tools: ToolbarItems {
        ToolbarButton {
            id: contactButton
            objectName: "contactButton"
            action: Action {
                iconSource: "image://theme/contact"
                text: i18n.tr("Contacts")
                onTriggered: pageStack.push(Qt.resolvedUrl("../ContactsPage/ContactsPage.qml"))
            }
        }
    }

    ToolbarItems {
        id: emptyToolbar
        visible: false
    }

    title: i18n.tr("Keypad")

    // -------- Greeter mode ----------
    states: [
        State {
            name: "greeterMode"
            when: greeter.greeterActive

            PropertyChanges {
                target: page
                tools: emptyToolbar
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
            if (dialNumber == "*#06#") {
                dialNumber = ""
                mainView.ussdResponseTitle = "IMEI"
                mainView.ussdResponseText = ussdManager.serial(mainView.account.accountId)
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
    }

    FocusScope {
        id: keypadContainer

        anchors.fill: parent
        focus: true

        // TODO replace by the sdk sections component when it's released
        Rectangle {
            id: accountList
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            clip: !multipleAccounts
            height: multipleAccounts ? childrenRect.height : 0
            z: 1
            color: "white"
            Row {
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                }
                height: childrenRect.height
                width: childrenRect.width
                spacing: units.gu(2)
                Repeater {
                    model: telepathyHelper.accounts
                    delegate: Label {
                        width: paintedWidth
                        height: paintedHeight
                        text: model.displayName
                        font.pixelSize: FontUtils.sizeToPixels("small")
                        color: mainView.account == modelData ? "red" : "#5d5d5d"
                        MouseArea {
                            anchors {
                                fill: parent
                                // increase touch area
                                leftMargin: units.gu(-1)
                                rightMargin: units.gu(-1)
                                bottomMargin: units.gu(-1)
                                topMargin: units.gu(-1)
                            }
                            onClicked: mainView.account = modelData
                            z: 2
                        }
                    }
                }
            }
        }

        KeypadEntry {
            id: keypadEntry

            anchors {
                top: accountList.bottom
                topMargin: units.gu(3)
                left: parent.left
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
                verticalCenter: keypadEntry.verticalCenter
            }
            width: input.text !== "" ? units.gu(3) : 0
            height: units.gu(3)
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

        /*ContactSearchListView {
            id: contactSearch
            property string searchTerm: keypadEntry.value != "" ? keypadEntry.value : "some value that won't match"
            anchors {
                left: parent.left
                right: parent.right
                bottom: keypadEntryBackground.bottom
                margins: units.gu(0.5)
            }

            states: [
                State {
                    name: "empty"
                    when: contactSearch.count == 0
                    PropertyChanges {
                        target: contactSearch
                        height: 0
                    }
                }
            ]

            Behavior on height {
                UbuntuNumberAnimation { }
            }

            filter: UnionFilter {
                DetailFilter {
                    detail: ContactDetail.Name
                    field: Name.FirstName
                    value: contactSearch.searchTerm
                    matchFlags: DetailFilter.MatchKeypadCollation | DetailFilter.MatchContains
                }

                DetailFilter {
                    detail: ContactDetail.Name
                    field: Name.LastName
                    value: contactSearch.searchTerm
                    matchFlags: DetailFilter.MatchContains | DetailFilter.MatchKeypadCollation
                }

                DetailFilter {
                    detail: ContactDetail.PhoneNumber
                    field: PhoneNumber.Number
                    value: contactSearch.searchTerm
                    matchFlags: DetailFilter.MatchPhoneNumber
                }

                DetailFilter {
                    detail: ContactDetail.PhoneNumber
                    field: PhoneNumber.Number
                    value: contactSearch.searchTerm
                    matchFlags: DetailFilter.MatchContains
                }

            }

            // FIXME: uncomment this code if we end up having both the header and the toolbar.
            onCountChanged: {
                if (count > 0) {
                    page.header.hide();
                } else {
                    page.header.show();
                }
            }

            onDetailClicked: {
                mainView.call(detail.number);
            }
        }*/

        ListItems.ThinDivider {
            id: divider

            anchors {
                left: parent.left
                leftMargin: units.gu(2)
                right: parent.right
                rightMargin: units.gu(2)
                top: keypadEntry.bottom
                topMargin: units.gu(4)
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
                bottom: divider.top
                bottomMargin: units.gu(1)
            }
            text: contactWatcher.isUnknown ? "" : contactWatcher.alias
            color: UbuntuColors.lightAubergine
            opacity: text != "" ? 1 : 0
            Behavior on opacity {
                UbuntuNumberAnimation { }
            }
        }

        Keypad {
            id: keypad

            anchors {
                bottom: footer.top
                bottomMargin: units.gu(3)
                horizontalCenter: parent.horizontalCenter
            }

            onKeyPressed: {
                input.insert(input.cursorPosition, label)
            }
        }

        Item {
            id: footer

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: units.gu(10)

            CallButton {
                id: callButton
                objectName: "callButton"
                anchors.bottom: footer.bottom
                anchors.bottomMargin: units.gu(5)
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    console.log("Starting a call to " + keypadEntry.value);
                    // avoid cleaning the keypadEntry in case there is no signal
                    if (!mainView.account.connected) {
                        PopupUtils.open(noNetworkDialog)
                        return
                    }
                    mainView.call(keypadEntry.value, mainView.account.accountId);
                    keypadEntry.value = "";
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
    }
}

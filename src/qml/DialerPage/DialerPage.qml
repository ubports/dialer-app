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
//import Ubuntu.Contacts 0.1
import Ubuntu.Components.ListItems 0.1 as ListItems
import "../"

PageWithBottomEdge {
    id: page
    property string voicemailNumber: callManager.voicemailNumber
    property alias dialNumber: keypadEntry.value
    property alias input: keypadEntry.input

    tools: ToolbarItems {
        ToolbarButton {
            objectName: "contactButton"
            action: Action {
                iconSource: "image://theme/contact"
                text: i18n.tr("Contacts")
                onTriggered: pageStack.push(Qt.resolvedUrl("../ContactsPage/ContactsPage.qml"))
            }
        }
    }

    title: i18n.tr("Keypad")

    // -------- Bottom Edge Setup -----
    bottomEdgePageSource: Qt.resolvedUrl("../HistoryPage/HistoryPage.qml")
    bottomEdgeExpandThreshold: bottomEdgePage ? bottomEdgePage.delegateHeight * 3.4 : 0
    bottomEdgeTitle: i18n.tr("Recent")
    reloadBottomEdgePage: false
    Binding {
        target: bottomEdgePage
        when: bottomEdgePage
        property: "fullView"
        value: bottomEdgeExposedArea > bottomEdgeExpandThreshold
    }

    property int historyDelegateHeight: bottomEdgePage ? bottomEdgePage.delegateHeight : 1

    Binding {
        target: bottomEdgePage
        when: bottomEdgePage
        property: "currentIndex"
        value: Math.floor(bottomEdgeExposedArea / historyDelegateHeight) - 1
    }
    onBottomEdgeReleased: {
        bottomEdgePage.activateCurrentIndex()
    }


    onDialNumberChanged: {
        if(checkUSSD(dialNumber)) {
            // check for custom strings
            if (dialNumber == "*#06#") {
                dialNumber = ""
                mainView.ussdResponseTitle = "IMEI"
                // TODO: handle dual sim
                mainView.ussdResponseText = ussdManager.serial(telepathyHelper.accountIds[0])
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

        Rectangle {
            id: keypadEntryBackground
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: keypad.top
            anchors.bottomMargin: units.gu(1.5)
            color: "#FFFFFF"
            opacity: 0.05
        }

        KeypadEntry {
            id: keypadEntry

            anchors {
                top: parent.top
                topMargin: units.gu(2)
                bottom: keypadEntryBackground.bottom
                left: parent.left
                right: parent.right
                bottomMargin: units.gu(1)
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
                rightMargin: units.gu(1)
                verticalCenter: keypadEntry.verticalCenter
            }
            width: units.gu(3)
            height: units.gu(3)
            icon: "erase"
            iconWidth: units.gu(3)
            iconHeight: units.gu(3)
            opacity: input.text !== "" ? 1 : 0

            Behavior on opacity {
                UbuntuNumberAnimation { }
            }

            onPressAndHold: input.text = ""

            onClicked:  {
                if (input.cursorPosition != 0)  {
                    var position = input.cursorPosition;
                    input.text = input.text.slice(0, input.cursorPosition - 1) + input.text.slice(input.cursorPosition);
                    input.cursorPosition = position - 1;
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

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: keypadEntryBackground.bottom
        }

        Keypad {
            id: keypad

            anchors.bottom: footer.top
            anchors.horizontalCenter: parent.horizontalCenter

            onKeyPressed: {
                if (input.cursorPosition != 0)  {
                    var position = input.cursorPosition;
                    input.text = input.text.slice(0, input.cursorPosition) + label + input.text.slice(input.cursorPosition);
                    input.cursorPosition = position +1 ;
                } else {
                    keypadEntry.value += label
                }
            }
        }

        Item {
            id: footer

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: units.gu(3)
            height: units.gu(10)

            CallButton {
                id: callButton
                objectName: "callButton"
                anchors.bottom: footer.bottom
                anchors.bottomMargin: units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    console.log("Starting a call to " + keypadEntry.value);
                    mainView.call(keypadEntry.value);
                    keypadEntry.value = "";
                }
                enabled: dialNumber != "" && telepathyHelper.connected
            }

        }
    }
}

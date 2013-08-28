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
import Ubuntu.Components.ListItems 0.1 as ListItems

Page {
    title: i18n.tr("Call")
    property string voicemailNumber: callManager.voicemailNumber
    property alias dialNumber: keypadEntry.value
    property alias input: keypadEntry.input

    function isVoicemailActive() {
        return mainView.isVoicemailActive();
    }

    tools: ToolbarItems {
        opened: false
        locked: true
    }

    FocusScope {
        id: keypadContainer

        anchors.fill: parent
        focus: true

        KeypadEntry {
            id: keypadEntry

            // TODO: remove anchors.top once the new tabs are implemented
            anchors.top: keypadContainer.top
            anchors.bottom: keypad.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottomMargin: units.gu(2)

            focus: true
            placeHolder: i18n.tr("Enter a number")
            Keys.forwardTo: [callButton]
        }

        Keypad {
            id: keypad

            anchors.bottom: footer.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: units.gu(2)

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
            height: units.gu(10)

            ListItems.ThinDivider {
                id: divider3

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
            }

            CallButton {
                id: callButton
                objectName: "callButton"
                anchors.top: footer.top
                anchors.topMargin: units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    console.log("Starting a call to " + keypadEntry.value);
                    callManager.startCall(keypadEntry.value);
                }
                enabled: dialNumber != "" && telepathyHelper.connected
            }

            CustomButton {
                id: backspace
                objectName: "eraseButton"
                anchors.left: callButton.right
                anchors.verticalCenter: callButton.verticalCenter
                anchors.leftMargin: units.gu(2)
                width: units.gu(7)
                height: units.gu(7)
                icon: "../assets/erase.png"
                iconWidth: units.gu(3)
                iconHeight: units.gu(3)

                onPressAndHold: input.text = ""

                onClicked:  {
                    if (input.cursorPosition != 0)  {
                        var position = input.cursorPosition;
                        input.text = input.text.slice(0, input.cursorPosition - 1) + input.text.slice(input.cursorPosition);
                        input.cursorPosition = position - 1;
                    }
                }
            }
        }
    }
}

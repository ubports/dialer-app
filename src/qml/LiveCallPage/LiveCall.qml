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
import QtGraphicalEffects 1.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItems
import Ubuntu.Telephony 0.1
import Ubuntu.Contacts 0.1
import QtContacts 5.0
import "../DialerPage"
import "../"

Page {
    id: liveCall

    property QtObject call: callManager.foregroundCall
    property string dtmfEntry: ""
    property alias number: contactWatcher.phoneNumber
    property bool onHold: call ? call.held : false
    property bool isSpeaker: call ? call.speaker : false
    property bool isMuted: call ? call.muted : false
    property bool dtmfVisible: false
    property string phoneNumberSubTypeLabel: ""
    Component.onDestruction: mainView.switchToCallLogView()
    Timer {
        id: callWatcher
        interval: 10000
        repeat: false
        running: true
        onTriggered: {
            if (!call) {
                // TODO: notify about failed call
                pageStack.pop()
            }
        }
    }

    // TRANSLATORS: %1 is the duration of the call
    title: dtmfLabelHelper.text !== "" ? dtmfLabelHelper.text : contactWatcher.alias != "" ? contactWatcher.alias : contactWatcher.phoneNumber
    tools: ToolbarItems {
        opened: false
        locked: true
    }

    function endCall() {
        if (call) {
            call.endCall();
        }
    }

    // FIXME: this invisible label is only used for
    // calculating the size of the screen and resizing
    // the dtmf string accordingly so it can fit the page header
    Label {
        id: dtmfLabelHelper
        visible: false
        text: dtmfEntry
        anchors.left: parent.left
        anchors.leftMargin: units.gu(2)
        anchors.right: parent.right
        anchors.rightMargin: units.gu(4)
        fontSize: "x-large"
        onTextChanged: {
            if(paintedWidth > width) {
                // drop the first number
                dtmfEntry = dtmfEntry.substr(1)
            }
        }
    }

    Item {
        id: helper
        function updateSubTypeLabel() {
            phoneNumberSubTypeLabel = contactWatcher.isUnknown ? "": phoneTypeModel.get(phoneTypeModel.getTypeIndex(phoneDetail)).label
        }
        Component.onCompleted: updateSubTypeLabel()

        ContactWatcher {
            id: contactWatcher
            // FIXME: handle conf calls
            phoneNumber: call ? call.phoneNumber : ""
            onPhoneNumberContextsChanged: helper.updateSubTypeLabel()
            onPhoneNumberSubTypesChanged: helper.updateSubTypeLabel()
            onIsUnknownChanged: helper.updateSubTypeLabel()
        }


        PhoneNumber {
            id: phoneDetail
            contexts: contactWatcher.phoneNumberContexts
            subTypes: contactWatcher.phoneNumberSubTypes
        }

        ContactDetailPhoneNumberTypeModel {
            id: phoneTypeModel
            Component.onCompleted: helper.updateSubTypeLabel()
        }
    }

    StopWatch {
        id: stopWatch
        time: call ? call.elapsedTime : 0
        visible: false
    }

    /*BackgroundCall {
        id: backgroundCall

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        call: callManager.backgroundCall
        visible: callManager.hasBackgroundCall
    }*/

    Image {
        id: background

        fillMode: Image.PreserveAspectCrop
        // FIXME: use something different than a hardcoded path of a unity8 asset
        source: contactWatcher.avatar != "" ? contactWatcher.avatar : "../assets/live_call_background.png"
        anchors {
            top: topPanel.bottom
            left: parent.left
            right: parent.right
            bottom: footer.top
        }
        smooth: true
    }

    FastBlur {
        anchors.fill: background
        source: background
        radius: 64
        opacity: keypad.opacity
        cached: true
    }

    Item {
        id: topPanel
        clip: true
        height: contactWatcher.isUnknown ? 0 : units.gu(5)
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        Label {
            anchors {
                left: parent.left
                leftMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }
            fontSize: "medium"
            text: phoneNumberSubTypeLabel
        }
        Label {
            anchors {
                right: parent.right
                rightMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }
            text: contactWatcher.phoneNumber
            fontSize: "medium"
            opacity: 0.2
        }
    }

    Item {
        id: centralArea
        anchors {
            top: topPanel.bottom
            left: parent.left
            right: parent.right
            bottom: buttonsArea.top
        }

        // FIXME: re-enable the keypad entry once design decides where to place it
        /*KeypadEntry {
            id: keypadEntry

            anchors.centerIn: parent
            placeHolder: liveCall.number
            placeHolderPixelFontSize: units.dp(43)
            focus: true
            input.readOnly: true
        }*/

        Keypad {
            id: keypad

            color: Qt.rgba(0,0,0, 0.4)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: units.gu(2)
            anchors.horizontalCenter: parent.horizontalCenter
            onKeyPressed: {
                //keypadEntry.value += label
                if (call) {
                    dtmfEntry += label
                    call.sendDTMF(label)
                }
            }

            visible: opacity > 0.0
            opacity: dtmfVisible ? 1.0 : 0.0

            Behavior on opacity {
                UbuntuNumberAnimation { }
            }
        }
    }

    Item {
        id: gridLinesVertical
        height: buttonsArea.width
        width: buttonsArea.height
        rotation: -90
        anchors.centerIn: buttonsArea
        Column {
            anchors.fill: parent
            Item {
                height: units.gu(11)
                width: buttonsArea.height
                ListItems.ThinDivider {
                    anchors.bottom: parent.bottom
                }
            }
            Item {
                height: units.gu(7)
                width: buttonsArea.height
                ListItems.ThinDivider {
                    anchors.bottom: parent.bottom
                }
            }
            Item {
                height: units.gu(7)
                width: buttonsArea.height
                ListItems.ThinDivider {
                    anchors.bottom: parent.bottom
                }
            }
        }
    }

    UbuntuShape {
        id: buttonsArea

        color: Qt.rgba(0,0,0, 0.5)

        height: childrenRect.height
        width: childrenRect.width
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: footer.top
            bottomMargin: units.gu(4)
        }
        radius: "medium"

        Row {
            id: controlButtons
            height: childrenRect.height
            width: childrenRect.width

            Label {
                id: durationLabel

                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }
                verticalAlignment: Qt.AlignVCenter
                horizontalAlignment: Qt.AlignHCenter
                width: units.gu(11)
                text: (call && call.active) ? stopWatch.elapsed : i18n.tr("calling")
            }

            LiveCallKeypadButton {
                objectName: "muteButton"
                iconSource: selected ? "microphone-mute" : "microphone"
                selected: liveCall.isMuted
                iconWidth: units.gu(3)
                iconHeight: units.gu(3)
                onClicked: {
                    if (call) {
                        call.muted = !call.muted
                    }
                }
            }

            LiveCallKeypadButton {
                objectName: "pauseStartButton"
                iconSource: selected ? "media-playback-start" : "media-playback-pause"
                selected: liveCall.onHold
                iconWidth: units.gu(3)
                iconHeight: units.gu(3)
                onClicked: {
                    if (call) {
                        call.held = !call.held
                    }
                }
            }

            LiveCallKeypadButton {
                objectName: "speakerButton"
                iconSource: selected ? "speaker" : "speaker-mute"
                selected: liveCall.isSpeaker
                iconWidth: units.gu(3)
                iconHeight: units.gu(3)
                onClicked: {
                    if (call) {
                        call.speaker = !selected
                    }
                }
            }
        }
    }

    Item {
        id: footer
        height: units.gu(10)
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        LiveCallKeypadButton {
            id: contactButton
            objectName: "contactButton"
            iconSource: "contact"
            iconWidth: units.gu(4)
            iconHeight: units.gu(4)

            anchors {
                verticalCenter: hangupButton.verticalCenter
                right: hangupButton.left
                rightMargin: units.gu(1)
            }
        }

        HangupButton {
            id: hangupButton

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            onClicked: endCall()
        }

        LiveCallKeypadButton {
            id: dtmfButton
            objectName: "dtmfButton"
            iconSource: "keypad"
            iconWidth: units.gu(4)
            iconHeight: units.gu(4)

            anchors {
                verticalCenter: hangupButton.verticalCenter
                left: hangupButton.right
                leftMargin: units.gu(1)
            }

            onClicked: dtmfVisible = !dtmfVisible
        }
    }
}

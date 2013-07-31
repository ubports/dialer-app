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
import Ubuntu.Telephony 0.1
import "../DialerPage"
import "../"

Page {
    id: liveCall

    property QtObject call: callManager.foregroundCall
    property alias number: contactWatcher.phoneNumber
    property bool onHold: call ? call.held : false
    property bool isSpeaker: call ? call.speaker : false
    property bool isMuted: call ? call.muted : false
    property bool dtmfVisible: false

    // TRANSLATORS: %1 is the duration of the call
    title: contactWatcher.alias != "" ? contactWatcher.alias : contactWatcher.phoneNumber
    tools: ToolbarItems {
        opened: false
        locked: true
    }

    function endCall() {
        if (call) {
            call.endCall();
        }
    }

    StopWatch {
        id: stopWatch
        time: call ? call.elapsedTime : 0
        visible: false
    }

    ContactWatcher {
        id: contactWatcher
        phoneNumber: call ? call.phoneNumber : ""
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

        // FIXME: use something different than a hardcoded path of a unity8 asset
        source: contactWatcher.avatar != "" ? contactWatcher.avatar : "../assets/live_call_background.png"
        anchors {
            top: parent.top
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
        id: centralArea
        anchors {
            top: parent.top
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

            anchors.centerIn: parent
            onKeyPressed: {
                //keypadEntry.value += label
                if (call) {
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

    UbuntuShape {
        id: buttonsArea

        color: Qt.rgba(0,0,0, 0.6)

        height: childrenRect.height
        width: keypad.width
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: footer.top
            bottomMargin: units.gu(4)
        }
        radius: "medium"

        Row {
            height: childrenRect.height
            width: childrenRect.width
            spacing: units.gu(1)

            Label {
                id: durationLabel

                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }
                verticalAlignment: Qt.AlignVCenter
                horizontalAlignment: Qt.AlignHCenter
                width: paintedWidth + units.gu(2)
                text: stopWatch.elapsed
            }

            LiveCallKeypadButton {
                objectName: "muteButton"
                iconSource: selected ? "../assets/microphone-mute.png" : "../assets/microphone.png"
                selected: liveCall.isMuted
                onClicked: {
                    if (call) {
                        call.muted = !call.muted
                    }
                }
            }

            LiveCallKeypadButton {
                objectName: "pauseStartButton"
                iconSource: selected ? "../assets/play.png" : "../assets/pause.png"
                selected: liveCall.onHold
                onClicked: {
                    if (call) {
                        call.held = !call.held
                    }
                }
            }

            LiveCallKeypadButton {
                objectName: "speakerButton"
                iconSource: selected ? "../assets/speaker.png" : "../assets/speaker-mute.png"
                selected: liveCall.isSpeaker
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
        height: units.gu(12)
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        LiveCallKeypadButton {
            id: contactButton
            objectName: "contactButton"
            iconSource: "../assets/avatar-default.png"

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
            iconSource: "../assets/keypad.png"

            anchors {
                verticalCenter: hangupButton.verticalCenter
                left: hangupButton.right
                leftMargin: units.gu(1)
            }

            onClicked: dtmfVisible = !dtmfVisible
        }
    }
}

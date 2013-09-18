/*
 * Copyright 2012-2013 Canonical Ltd.
 *
 * This file is part of phone-app.
 *
 * phone-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * phone-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Ubuntu.Components 0.1
import "../DialerPage"
import "../LiveCallPage"

Page {
    id: voicemail

    property variant contact
    property QtObject call: callManager.foregroundCall
    property string number: callManager.voicemailNumber
    Component.onDestruction: mainView.switchToCallLogView()

    title: i18n.tr("Voicemail")

    function isVoicemailActive() {
        return mainView.isVoicemailActive();
    }

    function endCall() {
        if (call) {
            call.endCall();
        }
    }

    Item {
        id: container

        anchors.fill: parent

        Item {
            id: body

            anchors.fill: parent

            Label {
                id: number

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: stopWatch.top
                anchors.topMargin: units.gu(0.5)
                text: voicemail.number
                color: "#a0a0a2"
                style: Text.Sunken
                styleColor: Qt.rgba(0.0, 0.0, 0.0, 0.5)
                fontSize: "medium"
            }

            Label {
                id: dialing

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: units.gu(2)
                anchors.top: number.bottom

                text: i18n.tr("Dialing")
                color: "#a0a0a2"
                style: Text.Sunken
                styleColor: Qt.rgba(0.0, 0.0, 0.0, 0.5)
                fontSize: "medium"
                opacity: (call && call.voicemail && call.dialing) ? 1.0 : 0.0
            }

            StopWatch {
                id: stopWatch
                time: call && call.voicemail ? call.elapsedTime : 0

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: units.gu(2)
                anchors.bottom: keypad.top
                opacity: (call && call.voicemail && !call.dialing) ? 1.0 : 0.0
            }

            Keypad {
                id: keypad

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                onKeyPressed: {
                    if (call) {
                        call.sendDTMF(label)
                    }
                }
            }

            Row {
                anchors.top: keypad.bottom
                anchors.topMargin: units.gu(3)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: units.gu(0.5)
                Button {
                    id: dialhangupButton
                    iconSource: "../assets/incall_hangup.png"
                    width: isVoicemailActive() ? units.gu(8) : units.gu(16)
                    color: isVoicemailActive() ? "#bf400c" : "#268bd2"
                    onClicked: {
                        if(isVoicemailActive())
                            endCall()
                        else
                            mainView.callNumber(voicemail.number)
                    }
                }

                Button {
                    id: speakerButton
                    width: units.gu(8)
                    visible: isVoicemailActive()
                    iconSource: call && call.speaker ? "../assets/speaker.png" : "../assets/speaker-mute.png"
                    color: "#565656"
                    state: call && call.speaker ? "pressed" : ""
                    onClicked: {
                        if (call) {
                            call.speaker = !call.speaker
                        }
                    }
                }
            }
        }
    }
}

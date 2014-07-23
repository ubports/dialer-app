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
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 0.1 as ListItems
import Ubuntu.Telephony 0.1
import Ubuntu.Contacts 0.1
import QtContacts 5.0
import "../DialerPage"
import "../"

Page {
    id: liveCall
    objectName: "pageLiveCall"

    property QtObject call: callManager.foregroundCall
    property string dtmfEntry: ""
    property alias number: contactWatcher.phoneNumber
    property bool onHold: call ? call.held : false
    property bool isSpeaker: call ? call.speaker : false
    property bool isMuted: call ? call.muted : false
    property bool dtmfVisible: call ? call.voicemail : false
    property bool isVoicemail: call ? call.voicemail : false
    property string phoneNumberSubTypeLabel: ""
    property string caller: {
        if (contactWatcher.alias !== "") {
            return contactWatcher.alias;
        } else if (contactWatcher.phoneNumber !== "") {
            return contactWatcher.phoneNumber;
        } else {
            return "Calling..."
        }
    }

    property list<Action> regularActions: [
        Action {
            objectName: "fakeBackButton"
            visible: false
        },
        Action {
            objectName: "newCallButton"
            iconName: "contact"
            text: i18n.tr("New Call")
            onTriggered: pageStack.push(Qt.resolvedUrl("../ContactsPage/ContactsPage.qml"))
        }
    ]
    property list<Action> greeterModeActions: [
        Action {
            objectName: "fakeBackButton"
            visible: false
        }
    ]

    title: caller
    head.actions: greeter.greeterActive ? greeterModeActions : regularActions
    x: header ? header.height : 0

    // if there are no calls, just reset the view
    Connections {
        target: callManager
        onHasCallsChanged: {
            if(!callManager.hasCalls) {
                mainView.switchToKeypadView();
                pageStack.currentPage.dialNumber = pendingNumberToDial;
            }
        }
    }

    states: [
        State {
            name: "keypadVisible"
            when: dtmfVisible

            PropertyChanges {
                target: durationLabel
                font.pixelSize: FontUtils.sizeToPixels("medium")
                anchors.topMargin: units.gu(2)
            }

            PropertyChanges {
                target: callerLabel
                font.pixelSize: FontUtils.sizeToPixels("small")
            }

            PropertyChanges {
                target: keypad
                opacity: 1.0
            }
        }
    ]

    transitions: [
        Transition {
            ParallelAnimation {
                UbuntuNumberAnimation {
                    targets: [durationLabel,callerLabel]
                    properties: "font.pixelSize,anchors.topMargin"
                }
                UbuntuNumberAnimation {
                    targets: [keypad]
                    properties: "opacity"
                }
            }
        }

    ]

    onCallChanged: {
        // reset the DTMF keypad visibility status
        dtmfVisible = (call && call.voicemail);
    }

    onActiveChanged: {
        callManager.callIndicatorVisible = !active;
    }

    Component.onCompleted: {
        callManager.callIndicatorVisible = !active;
    }

    Timer {
        id: callWatcher
        interval: 10000
        repeat: false
        running: true
        onTriggered: {
            if (!callManager.hasCalls) {
                // TODO: notify about failed call
                mainView.switchToKeypadView();
            }
        }
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
        objectName: "stopWatch"
        time: call ? call.elapsedTime : 0
    }

    Item {
        id: centralArea
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: buttonsArea.top
        }

        Label {
            id: durationLabel

            anchors {
                top: parent.top
                topMargin: units.gu(5)
                horizontalCenter: parent.horizontalCenter
            }
            horizontalAlignment: Qt.AlignHCenter
            width: units.gu(11)
            text: {
                if (dtmfVisible && dtmfLabelHelper.text !== "") {
                    return dtmfLabelHelper.text;
                } else if (call && call.active) {
                    return stopWatch.elapsed;
                } else {
                    return i18n.tr("calling")
                }
            }
            fontSize: "x-large"
        }

        Label {
            id: callerLabel

            anchors {
                top: durationLabel.bottom
                topMargin: units.gu(1)
                horizontalCenter: parent.horizontalCenter
            }
            text: caller
            fontSize: "large"
            color: UbuntuColors.lightAubergine
        }

        MultiCallDisplay {
            id: multiCallArea
            calls: callManager.calls
            opacity: (calls.length > 1 && !keypad.visible && !conferenceCallArea.visible) ? 1 : 0
            anchors {
                fill: parent
                margins: units.gu(1)
            }
        }

        ConferenceCallDisplay {
            id: conferenceCallArea
            opacity: conference && !keypad.visible ? 1 : 0
            anchors {
                fill: parent
                margins: units.gu(1)
            }

            states: [
                State {
                    name: "whileInMulticall"
                    when: callManager.foregroundCall && callManager.backgroundCall
                    PropertyChanges {
                        target: conferenceCallArea
                        conference: null
                    }
                },
                State {
                    name: "singleCallIsConf"
                    when: callManager.foregroundCall && !callManager.backgroundCall && callManager.foregroundCall.isConference
                    PropertyChanges {
                        target: conferenceCallArea
                        conference: callManager.foregroundCall
                    }
                }

            ]
        }

        Keypad {
            id: keypad

            anchors.bottom: parent.bottom
            anchors.bottomMargin: units.gu(2)
            anchors.horizontalCenter: parent.horizontalCenter
            onKeyPressed: {
                if (call) {
                    dtmfEntry += label
                    call.sendDTMF(label)
                }
            }

            visible: opacity > 0.0
            opacity: 0.0
        }
    }

    Row {
        id: buttonsArea
        height: childrenRect.height
        width: childrenRect.width
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: footer.top
            bottomMargin: units.gu(2)
        }

        LiveCallKeypadButton {
            objectName: "muteButton"
            iconSource: selected ? "microphone-mute" : "microphone"
            enabled: !isVoicemail
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
            iconSource: {
                if (callManager.backgroundCall) {
                    return "switch"
                } else if (selected) {
                    return "media-playback-start"
                } else {
                    return "media-playback-pause"
                }
            }
            enabled: !isVoicemail
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

        LiveCallKeypadButton {
            id: dtmfButton
            objectName: "dtmfButton"
            iconSource: "keypad"
            iconWidth: units.gu(4)
            iconHeight: units.gu(4)
            enabled: !isVoicemail
            onClicked: dtmfVisible = !dtmfVisible
        }
    }

    Item {
        id: footer
        height: units.gu(10)
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        HangupButton {
            id: hangupButton
            objectName: "hangupButton"

            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: units.gu(5)
            }
            onClicked: endCall()
        }
    }
}

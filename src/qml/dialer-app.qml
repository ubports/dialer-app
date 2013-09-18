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

MainView {
    id: mainView

    property bool applicationActive: Qt.application.active
    automaticOrientation: false
    width: units.gu(40)
    height: units.gu(71)

    signal applicationReady

    onApplicationActiveChanged: {
        if (applicationActive) {
            telepathyHelper.registerChannelObserver()
        } else {
            telepathyHelper.unregisterChannelObserver()
        }
    }

    function callVoicemail() {
        callManager.startCall(callManager.voicemailNumber);
    }

    function call(number) {
        callManager.startCall(number);
    }

    function switchToCallLogView() {
        pageStack.currentPage.currentTab = 2;
    }

    function isVoicemailActive() {
        if (callManager.foregroundCall) {
            return callManager.foregroundCall.voicemail;
        } else {
            return false
        }
    }

    Component.onCompleted: {
        Theme.name = "Ubuntu.Components.Themes.SuruGradient";
        pageStack.push(Qt.createComponent("MainPage.qml"))
    }

    Connections {
        target: telepathyHelper
        onAccountReady: {
            mainView.applicationReady()
        }
    }

    Connections {
        target: callManager
        onHasCallsChanged: updateCalls()
        onForegroundCallChanged: updateCalls()
        function updateCalls() {
            if(!callManager.hasCalls) {
                while (pageStack.depth > 1) {
                    pageStack.pop();
                }
                return
            }
            // if there are no calls, or if the views are already loaded, do not continue processing
            if ((callManager.foregroundCall || callManager.backgroundCall) && pageStack.depth === 1) {
                if ((callManager.foregroundCall && callManager.foregroundCall.voicemail)
                        || (callManager.backgroundCall && callManager.backgroundCall.voicemail)) {
                    pageStack.push(Qt.resolvedUrl("VoicemailPage/VoicemailPage.qml"))
                } else  {
                    pageStack.push(Qt.resolvedUrl("LiveCallPage/LiveCall.qml"));
                }
                application.activateWindow();
            }
        }
    }

    PageStack {
        id: pageStack
        anchors.fill: parent
    }
}

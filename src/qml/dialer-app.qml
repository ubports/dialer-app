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
import "DialerPage"
import "HistoryPage"
import "ContactsPage"

MainView {
    id: mainView

    automaticOrientation: true
    width: units.gu(40)
    height: units.gu(71)

    signal applicationReady


    function callVoicemail() {
        callManager.startCall(callManager.voicemailNumber);
    }

    function call(number) {
        callManager.startCall(number);
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
    }

    Connections {
        target: callManager
        onForegroundCallChanged: {
            // if there is no call, or if the views are already loaded, do not continue processing
            if (!callManager.foregroundCall) {
                while (pageStack.depth > 1) {
                    pageStack.pop();
                }
                tabs.selectedTabIndex = 2;
                return;
            }

            if (callManager.foregroundCall.voicemail) {
                pageStack.push(Qt.resolvedUrl("VoicemailPage/VoicemailPage.qml"))
            } else {
                pageStack.push(Qt.resolvedUrl("LiveCallPage/LiveCall.qml"));
            }

            application.activateWindow();
        }
    }

    PageStack {
        id: pageStack
        anchors.fill: parent

        Page {
            id: mainPage
            title: i18n.tr("Phone")

            Tabs {
                id: tabs

                Tab {
                    title: i18n.tr("Dialer")
                    page: DialerPage {
                        id: dialerPage
                    }
                }

                Tab {
                    title: i18n.tr("Contacts")
                    page: ContactsPage {
                        id: contactsPage
                    }
                }

                Tab {
                    title: i18n.tr("History")
                    page: HistoryPage {
                        id: historyPage
                    }
                }
            }
        }

        Component.onCompleted: pageStack.push(mainPage)
    }
}

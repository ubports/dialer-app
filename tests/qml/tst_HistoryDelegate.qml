/*
 * Copyright 2015 Canonical Ltd.
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

import QtQuick 2.2
import QtTest 1.0
import Ubuntu.Test 0.1
import "../../src/qml/HistoryPage"

Item {
    id: root
    width: units.gu(40)
    height: units.gu(10)

    signal clearCallNotificationCalled(string remoteParticipant, string accountId)

    Item {
        id: callNotification

        function clearCallNotification(remoteParticipant, accountId) {
            root.clearCallNotificationCalled(remoteParticipant, accountId);
        }
    }

    Item {
        id: mainView

        function populateDialpad(remoteParticipant, accountId) {
            // FIXME: implement
        }
    }

    Item {
        id: model
        property variant participants: [ {identifier: "12345"} ]
        property string senderId: "12345"
        property string remoteParticipant: "12345"
        property string accountId: "theAccountId"
        property bool callMissed: true
        property int eventCount: 1
        property variant timestamp: 0
    }

    Item {
        id: historyPage
        property alias bottomEdgeItem: bottomEdge

        Item {
            id: bottomEdge

            function collapse() {
                // do nothing
            }
        }
    }

    HistoryDelegate {
        id: delegate
    }

    UbuntuTestCase {
        id: historyDelegateTestCase
        name: 'historyDelegateTestCase'

        SignalSpy {
            id: clearNotificationSpy
            target: root
            signalName: 'clearCallNotificationCalled'
        }

        function test_notificationClearedAfterItemPressed() {
            delegate.activate()
            compare(clearNotificationSpy.count, 1, 'clear notification not called')
        }
    }
}

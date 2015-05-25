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

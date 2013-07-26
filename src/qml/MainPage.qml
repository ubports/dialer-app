import QtQuick 2.0
import Ubuntu.Components 0.1

Page {
    id: mainPage
    title: i18n.tr("Phone")
    property alias currentTab: tabs.selectedTabIndex

    Tabs {
        id: tabs

        Tab {
            title: i18n.tr("Dialer")
            page: Loader{
                id: dialerPage
                source: Qt.resolvedUrl("DialerPage/DialerPage.qml")
                anchors.fill: parent
            }
        }

        Tab {
            title: i18n.tr("Contacts")
        }

        Tab {
            title: i18n.tr("History")
            page: Loader{
                id: historyPage
                source: Qt.resolvedUrl("HistoryPage/HistoryPage.qml")
                asynchronous: true
                anchors.fill: parent
            }
        }
    }
}

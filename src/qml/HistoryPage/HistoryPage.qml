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
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.History 0.1
import Ubuntu.Telephony 0.1
import "dateUtils.js" as DateUtils

Page {
    id: historyPage
    objectName: "historyPage"
    tools: ToolbarItems {
        opened: false
        locked: true
    }

    property string searchTerm

    HistoryEventModel {
        id: historyEventModel
        type: HistoryThreadModel.EventTypeVoice
        filter: HistoryFilter {
            filterProperty: "accountId"
            filterValue: telepathyHelper.accountId
        }

        sort: HistorySort {
            sortField: "timestamp"
            sortOrder: HistorySort.DescendingOrder
        }
    }

    SortProxyModel {
        id: sortProxy
        sortRole: HistoryEventModel.TimestampRole
        sourceModel: historyEventModel
        ascending: false
    }

    ListView {
        id: historyList
        objectName: "historyList"

        anchors.fill: parent
        model: sortProxy
        currentIndex: -1
        section.property: "date"
        section.delegate: Item {
            ListItem.ThinDivider {
                anchors.top: parent.top
            }
            anchors.left: parent.left
            anchors.right: parent.right
            height: units.gu(5)
            Component.onCompleted: console.log(section)
            Label {
                anchors.left: parent.left
                anchors.leftMargin: units.gu(2)
                anchors.verticalCenter: parent.verticalCenter
                fontSize: "medium"
                elide: Text.ElideRight
                color: "gray"
                opacity: 0.6
                text: DateUtils.friendlyDay(section, i18n);
                verticalAlignment: Text.AlignVCenter
            }
            ListItem.ThinDivider {
                anchors.bottom: parent.bottom
            }
        }

        delegate: Loader {
            id: historyLoader
            sourceComponent: HistoryDelegate {
                id: historyDelegate
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                onClicked: mainView.call(model.participants[0])
                isFirst: model.index == 0
            }

            asynchronous: true
            anchors.left: parent.left
            anchors.right: parent.right
            height: item ? item.height : units.gu(8.5)

            Binding {
                target: historyLoader.item
                property: "model"
                value: model
                when: historyLoader.status == Loader.Ready
            }
        }
    }

    Scrollbar {
        flickableItem: historyList
        align: Qt.AlignTrailing
    }
}

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
import Ubuntu.Contacts 0.1
import "dateUtils.js" as DateUtils

Page {
    id: historyPage
    objectName: "historyPage"
    property string searchTerm
    title: i18n.tr("Recent")
    anchors.fill: parent
    property int delegateHeight: delegate.height
    property bool fullView: true
    property int currentIndex: 0

    function activateCurrentIndex() {
        if (fullView || currentIndex < 0 || currentIndex >= historyList.count) {
            return;
        }
        console.log("BLABLA triggering item " + currentIndex);
    }

    // Use this delegate just to calculate the height
    HistoryDelegate {
        id: delegate
        visible: false
    }

    // FIXME: this is a big hack to fix the placing of the listview items
    // when dragging the bottom edge
    flickable: null
    Connections {
        target: pageStack
        onDepthChanged: {
            if (pageStack.depth > 1)
                flickable = historyList
        }
    }

    HistoryEventModel {
        id: historyEventModel
        type: HistoryThreadModel.EventTypeVoice
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

    MultipleSelectionListView {
        id: historyList
        objectName: "historyList"

        Connections {
            target: Qt.application
            onActiveChanged: {
                if (!Qt.application.active) {
                    historyList.currentContactExpanded = -1
                }
            }
        }

        property int currentContactExpanded: -1
        anchors.fill: parent
        listModel: sortProxy
        acceptAction.text: i18n.tr("Delete")
        /*section.property: "date"
        section.delegate: Item {
            anchors.left: parent.left
            anchors.right: parent.right
            height: units.gu(5)
            Label {
                anchors.left: parent.left
                anchors.leftMargin: units.gu(2)
                anchors.verticalCenter: parent.verticalCenter
                fontSize: "medium"
                elide: Text.ElideRight
                color: "gray"
                opacity: 0.6
                text: DateUtils.friendlyDay(Qt.formatDate(section, "yyyy/MM/dd"));
                verticalAlignment: Text.AlignVCenter
            }
            ListItem.ThinDivider {
                anchors.bottom: parent.bottom
            }
        }*/
        onSelectionDone: {
            for (var i=0; i < items.count; i++) {
                var event = items.get(i).model
                historyEventModel.removeEvent(event.accountId, event.threadId, event.eventId, event.type)
            }
        }
        listDelegate: delegateComponent

        Component {
            id: delegateComponent
            HistoryDelegate {
                id: historyDelegate
                objectName: "historyDelegate" + index
                anchors.left: parent.left
                anchors.right: parent.right
                selected: historyList.isSelected(historyDelegate)
                isFirst: model.index == 0
                removable: !historyList.isInSelectionMode
                fullView: historyPage.fullView

                Item {
                    Connections {
                        target: historyList
                        onCurrentContactExpandedChanged: {
                            if (index != historyList.currentContactExpanded) {
                                historyDelegate.detailsShown = false
                            }
                        }
                    }
                }

                onPressAndHold: {
                    if (!historyList.isInSelectionMode) {
                        historyList.startSelection()
                    }
                    historyList.selectItem(historyDelegate)
                }
                onClicked: {
                    if (historyList.isInSelectionMode) {
                        if (!historyList.selectItem(historyDelegate)) {
                            historyList.deselectItem(historyDelegate)
                        }
                        return
                    }

                    if (!interactive) {
                        return;
                    }

                    if (historyList.currentContactExpanded == index) {
                        historyList.currentContactExpanded = -1
                        detailsShown = false
                        return
                    // expand and display the extended options
                    } else {
                        historyList.currentContactExpanded = index
                        detailsShown = !detailsShown
                    }
                }
            }
        }
    }

    Scrollbar {
        flickableItem: historyList
        align: Qt.AlignTrailing
    }
}

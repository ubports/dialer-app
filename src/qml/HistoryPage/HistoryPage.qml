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
    title: selectionMode ? i18n.tr("Select") : i18n.tr("Recent")
    anchors.fill: parent
    active: false
    property int delegateHeight: delegate.height
    property bool fullView: false
    property alias currentIndex: historyList.currentIndex
    property alias selectionMode: historyList.isInSelectionMode

    function activateCurrentIndex() {
        if ((historyList.currentIndex > 2) || !historyList.currentItem) {
            return;
        }

        historyList.currentItem.activate();
    }

    ToolbarItems {
        id: historySelectionToolbar
        visible: false
        back: ToolbarButton {
            id: selectionModeCancelButton
            objectName: "selectionModeCancelButton"
            action: Action {
                objectName: "selectionModeCancelAction"
                iconName: "close"
                onTriggered: historyList.cancelSelection()
            }
        }
        ToolbarButton {
            id: selectionModeSelectAllButton
            objectName: "selectionModeSelectAllButton"
            action: Action {
                objectName: "selectionModeSelectAllAction"
                iconName: "filter"
                onTriggered: historyList.selectAll()
            }
        }
        ToolbarButton {
            id: selectionModeDeleteButton
            objectName: "selectionModeDeleteButton"
            action: Action {
                objectName: "selectionModeDeleteAction"
                enabled: historyList.selectedItems.count > 0
                iconName: "delete"
                onTriggered: historyList.endSelection()
            }
        }
    }

    tools: selectionMode ? historySelectionToolbar : null
    onActiveChanged: {
        if (!active && selectionMode) {
            historyList.cancelSelection();
        }
    }

    // Use this delegate just to calculate the height
    HistoryDelegate {
        id: delegate
        visible: false
        property variant model: Item {
            property string senderId: "dummy"
            property variant participants: ["dummy"]
        }
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

        property var _currentSwipedItem: null

        function _updateSwipeState(item)
        {
            if (item.swipping) {
                return
            }

            if (item.swipeState !== "Normal") {
                if (_currentSwipedItem !== item) {
                    if (_currentSwipedItem) {
                        _currentSwipedItem.resetSwipe()
                    }
                    _currentSwipedItem = item
                }
            } else if (item.swipeState !== "Normal" && _currentSwipedItem === item) {
                _currentSwipedItem = null
            }
        }

        Connections {
            target: Qt.application
            onActiveChanged: {
                if (!Qt.application.active) {
                    historyList.currentIndex = -1
                }
            }
        }

        currentIndex: -1
        anchors.fill: parent
        listModel: sortProxy
        /*section.property: "date"
        section.delegate: Item {
            anchors.left: parent.left
            anchors.right: parent.right
            height: historyPage.fullView ? 0 : units.gu(5)
            clip: true
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
        onIsInSelectionModeChanged: {
            if (isInSelectionMode && _currentSwipedItem) {
                _currentSwipedItem.resetSwipe()
                _currentSwipedItem = null
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
                isFirst: model.index === 0
                locked: historyList.isInSelectionMode
                fullView: historyPage.fullView
                detailsShown: ListView.isCurrentItem && fullView
                active: historyDelegate.ListView.isCurrentItem && !fullView

                // collapse the item before remove it, to avoid crash
                ListView.onRemove: SequentialAnimation {
                    PropertyAction {
                        target: historyDelegate
                        property: "ListView.delayRemove"
                        value: true
                    }
                    ScriptAction {
                        script: {
                            if (historyList._currentSwipedItem === historyDelegate) {
                                historyList._currentSwipedItem = null
                            }

                            if (ListView.isCurrentItem) {
                                contactListView.currentIndex = -1
                            }
                        }
                    }
                    PropertyAction {
                        target: historyDelegate
                        property: "ListView.delayRemove"
                        value: false
                    }
                }

                onItemPressAndHold: {
                    if (!historyList.isInSelectionMode) {
                        historyList.startSelection()
                    }
                    historyList.selectItem(historyDelegate)
                }
                onItemClicked: {
                    if (historyList.isInSelectionMode) {
                        if (!historyList.selectItem(historyDelegate)) {
                            historyList.deselectItem(historyDelegate)
                        }
                        return
                    }

                    if (!interactive) {
                        return;
                    }

                    if (historyList.currentIndex == index) {
                        historyList.currentIndex = -1
                        return
                    // expand and display the extended options
                    } else {
                        historyList.currentIndex = index
                    }
                }
                onSwippingChanged: historyList._updateSwipeState(historyDelegate)
                onSwipeStateChanged: historyList._updateSwipeState(historyDelegate)
            }
        }
    }

    Scrollbar {
        flickableItem: historyList
        align: Qt.AlignTrailing
    }
}

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
    property int delegateHeight: delegate.height
    property bool fullView: false
    property alias currentIndex: historyList.currentIndex
    property alias selectionMode: historyList.isInSelectionMode

    function activateCurrentIndex() {
        if (historyList.currentItem) {
            historyList.currentItem.activate();
        }
    }

    title: selectionMode ? i18n.tr("Select") : i18n.tr("Recent")
    anchors.fill: parent
    active: false

    Rectangle {
        anchors.fill: parent
        color: Theme.palette.normal.background
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
        if (!active) {
            if (selectionMode) {
                historyList.cancelSelection();
            }
            historyList.resetSwipe()
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

        function resetSwipe()
        {
            if (_currentSwipedItem) {
                _currentSwipedItem.resetSwipe()
                _currentSwipedItem = null
            }
        }

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

                anchors{
                    left: parent.left
                    right: parent.right
                }

                selected: historyDelegate.ListView.isCurrentItem || historyList.isSelected(historyDelegate)
                isFirst: model.index === 0
                locked: historyList.isInSelectionMode
                fullView: historyPage.fullView

                // Animate item removal
                ListView.onRemove: SequentialAnimation {
                    PropertyAction {
                        target: historyDelegate
                        property: "ListView.delayRemove"
                        value: true
                    }

                    // reset swipe state
                    ScriptAction {
                        script: {
                            if (historyList._currentSwipedItem === historyDelegate) {
                                historyList._currentSwipedItem.resetSwipe()
                                historyList._currentSwipedItem = null
                            }

                            if (ListView.isCurrentItem) {
                                contactListView.currentIndex = -1
                            }
                        }
                    }

                    // animate the removal
                    UbuntuNumberAnimation {
                        target: historyDelegate
                        property: "height"
                        to: 1
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

                    historyDelegate.activate()
                }

                onSwippingChanged: historyList._updateSwipeState(historyDelegate)
                onSwipeStateChanged: historyList._updateSwipeState(historyDelegate)

                leftSideAction: Action {
                    iconName: "delete"
                    text: i18n.tr("Delete")
                    onTriggered:  historyEventModel.removeEvent(model.accountId, model.threadId, model.eventId, model.type)
                }
                rightSideActions: [
                    // FIXME: the first action should go to contac call log details page
                    Action {
                        iconName: unknownContact ? "contact-new" : "stock_contact"
                        text: i18n.tr("Details")
                        onTriggered: {
                            if (unknownContact) {
                                mainView.addNewPhone(phoneNumber)
                            } else {
                                mainView.viewContact(contactId)
                            }
                        }
                    },
                    Action {
                        iconName: "message"
                        text: i18n.tr("Send message")
                        onTriggered: {
                            mainView.sendMessage(phoneNumber)
                        }
                    }
                ]
            }
        }
    }

    Scrollbar {
        flickableItem: historyList
        align: Qt.AlignTrailing
    }
}

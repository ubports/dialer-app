/*
 * Copyright 2012-2016 Canonical Ltd.
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

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.History 0.1
import Ubuntu.Telephony 0.1
import Ubuntu.Contacts 0.1
import "dateUtils.js" as DateUtils

Page {
    id: historyPage
    objectName: "historyPage"

    property bool bottomEdgeCommitted: false
    property QtObject bottomEdgeItem: null
    property string searchTerm
    property int delegateHeight: delegate.height
    // NOTE: in case we need to re-enable progressive bottom edge gesture,
    // set fullView to currentIndex == -1
    property bool fullView: true
    property alias currentIndex: historyList.currentIndex
    property alias selectionMode: historyList.isInSelectionMode

    function activateCurrentIndex() {
        if (!fullView && historyList.currentItem) {
            historyList.currentItem.activate();
        }
    }

    title: selectionMode ? i18n.tr("Select") : i18n.tr("Recent")
    flickable: null

    header: PageHeader {
        id: pageHeader

        property alias leadingActions: leadingBar.actions
        property alias trailingActions: trailingBar.actions

        title: historyPage.title

        leadingActionBar {
            id: leadingBar
        }

        trailingActionBar {
            id: trailingBar
        }

        extension: Sections {
            id: headerSections
            model: [ i18n.ctr("All Calls", "All"), i18n.tr("Missed") ]
            selectedIndex: 0
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.palette.normal.background
    }

    states: [
        State {
            id: selectState
            name: "select"
            when: selectionMode

            property list<QtObject> leadingActions: [
                Action {
                    objectName: "selectionModeCancelAction"
                    iconName: "back"
                    onTriggered: historyList.cancelSelection()
                }
            ]

            property list<QtObject> trailingActions: [
                Action {
                    objectName: "selectionModeSelectAllAction"
                    iconName: "select"
                    onTriggered: {
                        if (historyList.selectedItems.count === historyList.count) {
                            historyList.clearSelection()
                        } else {
                            historyList.selectAll()
                        }
                    }
                },
                Action {
                    objectName: "selectionModeDeleteAction"
                    enabled: historyList.selectedItems.count > 0
                    iconName: "delete"
                    onTriggered: historyList.endSelection()
                }
            ]

            PropertyChanges {
                target: pageHeader
                leadingActions: selectState.leadingActions
                trailingActions: selectState.trailingActions
            }
        }
    ]

    onBottomEdgeCommittedChanged: {
        if (!bottomEdgeCommitted) {
            return
        }
        if (historyList.count > 0) {
            swipeItemDemo.enable()
        }
    }

    // Use this delegate just to calculate the height
    HistoryDelegate {
        id: delegate
        visible: false
        property variant model: Item {
            property string senderId: "dummy"
            property variant participants: [ {identifier:"dummy"} ]
        }
    }

    Connections {
        target: headerSections
        onSelectedIndexChanged: {
            if (headerSections.selectedIndex == 0) {
                historyEventModel.filter = emptyFilter;
            } else {
                historyEventModel.filter = missedFilter;
            }
        }
    }

    // FIXME: this is a workaround to force the model perform the query
    HistoryUnionFilter {
        id: emptyFilter
        HistoryFilter {
            filterProperty: "missed"
            filterValue: true
        }
        HistoryFilter {
            filterProperty: "missed"
            filterValue: false
        }
    }

    HistoryFilter {
        id: missedFilter
        filterProperty: "missed"
        filterValue: true
    }

    HistoryGroupedEventsModel {
        id: historyEventModel
        groupingProperties: ["participants", "date"]
        type: HistoryThreadModel.EventTypeVoice
        sort: HistorySort {
            sortField: "timestamp"
            sortOrder: HistorySort.DescendingOrder
        }
        filter: emptyFilter
        matchContacts: true
    }

    MultipleSelectionListView {
        id: historyList
        objectName: "historyList"
        clip: true

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
        anchors {
            fill: parent
            topMargin: pageHeader.height
        }
        listModel: historyEventModel

        onSelectionDone: {
            var events = [];
            for (var i=0; i < items.count; i++) {
                var eventGroup = items.get(i).model.events
                for (var j in eventGroup) {
                    events.push(eventGroup[j]);
                }
            }
            if (events.length > 0) {
                historyEventModel.removeEvents(events)
            }
        }
        onIsInSelectionModeChanged: {
            if (isInSelectionMode && _currentSwipedItem) {
                _currentSwipedItem.resetSwipe()
                _currentSwipedItem = null
            }
        }

        Label {
            id: emptyLabel
            fontSize: "large"
            anchors.centerIn: parent
            visible: historyList.count === 0
            text: i18n.tr("No recent calls")
        }

        Component {
            id: sectionComponent
            Label {
                anchors {
                    left: parent.left
                    leftMargin: units.gu(2)
                    right: parent.right
                    rightMargin: units.gu(2)
                }
                text: DateUtils.friendlyDay(section)
                height: units.gu(3)
                fontSize: "small"
                verticalAlignment: Text.AlignVCenter
                ListItem.ThinDivider {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                }
            }
        }

        section.property: "date"
        section.delegate: fullView ? sectionComponent : null

        listDelegate: delegateComponent
        displaced: Transition {
            UbuntuNumberAnimation {
                property: "y"
            }
        }

        remove: Transition {
            ParallelAnimation {
                UbuntuNumberAnimation {
                    property: "height"
                    to: 0
                }

                UbuntuNumberAnimation {
                    properties: "opacity"
                    to: 0
                }
                ScriptAction {
                    script: {
                        historyList.resetSwipe()
                    }
                }
            }
        }

        Component {
            id: delegateComponent
            HistoryDelegate {
                id: historyDelegate
                objectName: "historyDelegate" + index

                anchors{
                    left: parent.left
                    right: parent.right
                }

                selected: historyList.isSelected(historyDelegate)
                selectionMode: historyList.isInSelectionMode
                isFirst: model.index === 0
                locked: historyList.isInSelectionMode
                fullView: historyPage.fullView
                active: !fullView && ListView.isCurrentItem

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
                    onTriggered:  {
                        historyEventModel.removeEvents(model.events)
                    }
                }
                property bool knownNumber: participants[0].identifier != "x-ofono-private" && participants[0].identifier != "x-ofono-unknown"
                rightSideActions: [
                    Action {
                        iconName: "info"
                        text: i18n.tr("Details")
                        onTriggered: {
                            pageStackNormalMode.push(Qt.resolvedUrl("HistoryDetailsPage.qml"),
                                                          { phoneNumber: participants[0].identifier,
                                                            events: model.events,
                                                            eventModel: historyEventModel})
                        }
                    },
                    Action {
                        iconName: "message"
                        text: i18n.tr("Send message")
                        onTriggered: {
                            mainView.sendMessage(phoneNumber)
                        }
                        visible: knownNumber
                        enabled: knownNumber
                    },
                    Action {
                        iconName: unknownContact ? "contact-new" : "stock_contact"
                        text: i18n.tr("Contact Details")
                        onTriggered: {
                            if (unknownContact) {
                                mainView.addNewPhone(phoneNumber)
                            } else {
                                mainView.viewContact(contactId, null, null)
                            }
                        }
                        visible: knownNumber
                        enabled: knownNumber
                    }
                ]
            }
        }

        onCountChanged: {
            if (bottomEdgeCommitted && historyList.count > 0) {
                swipeItemDemo.enable()
            }
        }
    }

    Scrollbar {
        flickableItem: historyList
        align: Qt.AlignTrailing
    }

    SwipeItemDemo {
        id: swipeItemDemo
        objectName: "swipeItemDemo"

        parent: QuickUtils.rootItem(this)
        anchors.fill: parent
    }
}

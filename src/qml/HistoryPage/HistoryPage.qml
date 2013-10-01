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

    MultipleSelectionListView {
        id: historyList
        property int currentContactExpanded: -1
        anchors.fill: parent
        listModel: sortProxy
        acceptAction.text: i18n.tr("Delete")
        section.property: "date"
        section.delegate: Item {
            ListItem.ThinDivider {
                anchors.top: parent.top
            }
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
                text: DateUtils.friendlyDay(section, i18n);
                verticalAlignment: Text.AlignVCenter
            }
            ListItem.ThinDivider {
                anchors.bottom: parent.bottom
            }
        }
        onSelectionDone: {
            for (var i=0; i < items.count; i++) {
                var event = items.get(i).model
                historyEventModel.removeEvent(event.accountId, event.threadId, event.eventId, event.type)
            }
        }
        listDelegate: delegateItem

        Component {
            id: delegateItem
            Item {
                id: item
                height: delegate.detailsShown ? (delegate.height + pickerLoader.height) : delegate.height
                width: parent ? parent.width : 0
                clip: true
                Behavior on height {
                    UbuntuNumberAnimation { }
                }
                Connections {
                    target: historyList
                    onCurrentContactExpandedChanged: {
                        if (index != historyList.currentContactExpanded) {
                            delegate.detailsShown = false
                        }
                    }
                }

                HistoryDelegate {
                    id: delegate
                    property bool detailsShown: false
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    selected: historyList.isSelected(item)
                    isFirst: model.index == 0
                    width: parent ? parent.width : 0
                    clip: true
                    removable: !historyList.isInSelectionMode
                    showDivider: false

                    onPressAndHold: {
                        if (!historyList.isInSelectionMode) {
                            historyList.startSelection()
                        }
                        historyList.selectItem(item)
                    }
                    onClicked: {
                        if (historyList.isInSelectionMode) {
                            if (!historyList.selectItem(item)) {
                                historyList.deselectItem(item)
                            }
                            return
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
                    Rectangle {
                        id: selectionMark

                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            right: parent.right
                        }

                        color: "black"
                        visible: delegate.selected
                        Icon {
                            name: "select"
                            height: units.gu(3)
                            width: height
                            anchors.centerIn: parent
                        }
                    }
                }
                Loader {
                    id: pickerLoader

                    source: delegate.detailsShown ? Qt.resolvedUrl("CallLogContactDelegate.qml") : ""
                    anchors {
                        top: delegate.bottom
                        topMargin: units.gu(1)
                        left: parent.left
                        right: parent.right
                    }
                    onStatusChanged: {
                        if (status == Loader.Ready) {
                            pickerLoader.item.phoneNumber = participants[0]
                            pickerLoader.item.contactId = delegate.contactId
                        }
                    }
                    Connections {
                        target: pickerLoader.item
                        onItemClicked: historyList.currentContactExpanded = -1
                    }
                }
                ListItem.ThinDivider {
                    anchors {
                        bottom: pickerLoader.bottom
                        right: parent.right
                        left: parent.left
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

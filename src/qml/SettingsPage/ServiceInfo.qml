/*
 * This file is part of dialer-app
 *
 * Copyright (C) 2013-2017 Canonical Ltd.
 *
 * Contact: Sebastien Bacher <sebastien.bacher@canonical.com>
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 3, as published
 * by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranties of
 * MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.History 0.1
import "dateUtils.js" as DateUtils

Page {
    id: page
    property var sim
    property string serviceName
    property string serviceNumber
    property string lastTimestamp
    title: serviceName

    header: PageHeader {
        id: pageHeader
        title: page.title
    }

    HistoryEventModel {
        id: historyEventModel
        type: HistoryThreadModel.EventTypeVoice
        sort: HistorySort {
            sortField: "timestamp"
            sortOrder: HistorySort.DescendingOrder
        }

        property string phoneNumber: serviceNumber
        onCountChanged: lastTimestamp = historyEventModel.get(0).timestamp

        filter: HistoryUnionFilter {
            // FIXME: this is not the best API for this case, but will be changed later
            HistoryIntersectionFilter {
                HistoryFilter {
                    property string threadId: historyEventModel.threadIdForParticipants("ofono/ofono/account0",
                                                                                        HistoryThreadModel.EventTypeVoice,
                                                                                        [historyEventModel.phoneNumber],
                                                                                        HistoryThreadModel.MatchPhoneNumber);
                    filterProperty: "threadId"
                    filterValue: threadId != "" ? threadId : "something that won't match"
                }
                HistoryFilter {
                    filterProperty: "accountId"
                    filterValue: "ofono/ofono/account0"
                }
            }

            HistoryIntersectionFilter {
                HistoryFilter {
                    property string threadId: historyEventModel.threadIdForParticipants("ofono/ofono/account1",
                                                                                        HistoryThreadModel.EventTypeVoice,
                                                                                        [historyEventModel.phoneNumber],
                                                                                        HistoryThreadModel.MatchPhoneNumber);
                    filterProperty: "threadId"
                    filterValue: threadId != "" ? threadId : "something that won't match"
                }
                HistoryFilter {
                    filterProperty: "accountId"
                    filterValue: "ofono/ofono/account1"
                }
            }
        }
    }

    Column {
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }

        ListItem.Base {
            anchors.left: parent.left
            anchors.right: parent.right
            height: lastCalledCol.height + units.gu(6)
            Column {
                id: lastCalledCol
                anchors.left: parent.left
                anchors.right: parent.right
                height: childrenRect.height
                spacing: units.gu(2)

                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: "contact"
                    width: 144
                    height: width
                }

                Label {
                    id: calledLabel
                    objectName: "calledLabel"
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: lastTimestamp
                    text: i18n.tr("Last called %1").arg(DateUtils.formatFriendlyDate(lastTimestamp))
                }
            }
        }
    }

    ListItem.SingleControl {
        anchors.bottom: parent.bottom
        control: Button {
            width: parent.width - units.gu(4)
            text: i18n.tr("Call")
            onClicked: {
                var account = mainView.accountForModem(sim.path)
                var accountId = account ? account.accountId : null
                mainView.populateDialpad(serviceNumber, accountId)
            }
        }
    }
}

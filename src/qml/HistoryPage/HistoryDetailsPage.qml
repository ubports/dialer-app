/*
 * Copyright 2014-2016 Canonical Ltd.
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
import Ubuntu.Telephony 0.1
import Ubuntu.Telephony.PhoneNumber 0.1 as PhoneUtils
import Ubuntu.Contacts 0.1
import QtContacts 5.0
import "dateUtils.js" as DateUtils

Page {
    id: historyDetailsPage

    property alias phoneNumber: contactWatcher.identifier
    property string phoneNumberSubTypeLabel
    property variant events: null
    property QtObject eventModel: null
    readonly property bool unknownContact: contactWatcher.contactId === ""
    property bool knownNumber: phoneNumber != "x-ofono-private" && phoneNumber != "x-ofono-unknown"

    objectName: "historyDetailsPage"
    anchors.fill: parent

    function getFormattedPhoneLabel(phoneNumber) {
        if (phoneNumber == "x-ofono-private") {
            return i18n.tr("Private number")
        } else if (phoneNumber == "x-ofono-unknown") {
            return i18n.tr("Unknown number")
        }
        var formattedPhoneNumber = PhoneUtils.PhoneUtils.format(phoneNumber)
        if (formattedPhoneNumber !== "") {
            return formattedPhoneNumber
        }
        return phoneNumber
    }

    function getContactAliasOrPhoneNumber(phoneNumber) {
        if (contactWatcher.alias != "") {
            return contactWatcher.alias
        }
        return getFormattedPhoneLabel(phoneNumber);
    }

    title: getContactAliasOrPhoneNumber(phoneNumber)

    header: PageHeader {
        id: pageHeader

        title: historyDetailsPage.title
        trailingActionBar {
            actions: [
                Action {
                    iconName: unknownContact ? "contact-new" : "stock_contact"
                    text: i18n.tr("Contact Details")
                    visible: knownNumber
                    onTriggered: {
                        if (unknownContact) {
                            mainView.addNewPhone(phoneNumber)
                        } else {
                            mainView.viewContact(contactWatcher.contactId, null, null)
                        }
                    }
                },
                Action {
                    iconName: "share"
                    text: i18n.tr("Share")
                    onTriggered: {
                        // FIXME: implement
                    }
                    visible: false
                },
                Action {
                    iconName: "delete"
                    text: i18n.tr("Delete")
                    onTriggered: {
                        eventModel.removeEvents(events);
                        pageStackNormalMode.pop();
                    }
                }
            ]
        }
    }

    Item {
        id: helper

        function updateSubTypeLabel() {
            var subLabel = contactWatcher.isUnknown
            if (phoneNumber) {
                var typeInfo = phoneTypeModel.get(phoneTypeModel.getTypeIndex(phoneDetail))
                if (typeInfo) {
                    subLabel = typeInfo.label
                }
            }
            phoneNumberSubTypeLabel = subLabel
        }

        Component.onCompleted: updateSubTypeLabel()

        ContactWatcher {
            id: contactWatcher
            // FIXME: handle conf calls
            onDetailPropertiesChanged: helper.updateSubTypeLabel()
            onIsUnknownChanged: helper.updateSubTypeLabel()
            // FIXME: if we add support for VOIP, use the account
            addressableFields: ["tel"]
        }

        PhoneNumber {
            id: phoneDetail
            contexts: contactWatcher.detailProperties.phoneNumberContexts ? contactWatcher.detailProperties.phoneNumberContexts : []
            subTypes: contactWatcher.detailProperties.phoneNumberSubTypes ? contactWatcher.detailProperties.phoneNumberSubTypes : []
        }

        ContactDetailPhoneNumberTypeModel {
            id: phoneTypeModel
            Component.onCompleted: helper.updateSubTypeLabel()
        }
    }

    ListView {
        id: eventsView
        anchors.fill: parent
        model: events
        header: Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: units.gu(12)

            Label {
                id: phoneLabel
                anchors {
                    top: parent.top
                    topMargin: units.gu(2)
                    left: parent.left
                    leftMargin: units.gu(2)
                }
                verticalAlignment: Text.AlignTop
                fontSize: "medium"
                text: getContactAliasOrPhoneNumber(phoneNumber)
                elide: Text.ElideRight
                color: theme.palette.normal.backgroundSecondaryText
                height: units.gu(2)
            }

            Label {
                id: phoneTypeLabel
                anchors {
                    top: phoneLabel.bottom
                    left: phoneLabel.left
                }
                text: historyDetailsPage.phoneNumberSubTypeLabel
                height: units.gu(2)
                verticalAlignment: Text.AlignVCenter
                fontSize: "small"
                visible: contactWatcher.interactive && !contactWatcher.isUnknown // non-interactive entries are calls from unknown or private numbers
            }

            Label {
                id: dateLabel
                anchors {
                    left: phoneLabel.left
                    top: phoneTypeLabel.bottom
                    topMargin: units.gu(2)
                }
                text: DateUtils.friendlyDay(historyDetailsPage.events[0].date)
                height: units.gu(3)
                fontSize: "medium"
                font.weight: Font.DemiBold
                verticalAlignment: Text.AlignVCenter
            }

            ListItem.ThinDivider {
                id: divider
                anchors {
                    top: dateLabel.bottom
                    left: parent.left
                    leftMargin: units.gu(2)
                    right: parent.right
                    rightMargin: units.gu(2)
                }
            }

            AbstractButton {
                id: messageButton
                anchors {
                    top: parent.top
                    topMargin: units.gu(1)
                    right: parent.right
                }
                width: units.gu(4)
                height: units.gu(4)
                visible: knownNumber
                enabled: knownNumber

                Icon {
                    name: "message"
                    width: units.gu(2)
                    height: units.gu(2)
                    anchors.centerIn: parent
                    asynchronous: true
                }

                onClicked: mainView.sendMessage(phoneNumber)
            }

            AbstractButton {
                id: callButton
                anchors {
                    top: messageButton.top
                    right: messageButton.left
                }
                width: units.gu(4)
                height: units.gu(4)
                visible: knownNumber
                Icon {
                    name: "call-start"
                    width: units.gu(2)
                    height: units.gu(2)
                    anchors.centerIn: parent
                    asynchronous: true
                }
                onClicked: {
                    mainView.populateDialpad(phoneNumber, mainView.account ? mainView.account.accountId : "");
                }
            }
        }

        delegate: ListItemWithActions {
            readonly property bool incoming: modelData.senderId !== "self"
            height: units.gu(5)
            anchors {
                left: parent.left
                right: parent.right
            }

            leftSideAction: Action {
                iconName: "delete"
                text: i18n.tr("Delete")
                onTriggered:  {
                    // remove from the history service
                    eventModel.removeEvents([modelData]);

                    // as this page only displays an array of events, we need to update manually
                    // the list of displayed events
                    var updatedEvents = historyDetailsPage.events;
                    updatedEvents.splice(index, 1);
                    historyDetailsPage.events = updatedEvents;
                }
            }

            Label {
                id: timeLabel
                // TRANSLATORS: HH:mm is the time format, translate it according to:
                // http://qt-project.org/doc/qt-5/qml-qtqml-qt.html#formatDate-method
                text: Qt.formatTime(modelData.timestamp, Qt.DefaultLocaleShortDate)
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                verticalAlignment: Qt.AlignVCenter
            }

            Label {
                id: remoteParticipantId
                // FIXME: we need to check if the id is actually a phone number
                text: getFormattedPhoneLabel(modelData.remoteParticipant)
                anchors {
                    left: timeLabel.right
                    leftMargin: units.gu(1)
                    verticalCenter: parent.verticalCenter
                }
                color: theme.palette.normal.backgroundSecondaryText
                verticalAlignment: Qt.AlignVCenter
                MouseArea {
                    anchors.fill:parent
                    onClicked: mainView.populateDialpad(modelData.remoteParticipant, mainView.account ? mainView.account.accountId : "");
                }
            }

            Label {
                id: simLabel
                anchors {
                    left: remoteParticipantId.right
                    leftMargin: units.gu(1)
                    verticalCenter: timeLabel.verticalCenter
                }

                height: units.gu(2)
                fontSize: "x-small"
                text: telepathyHelper.accountForId(modelData.accountId).displayName
                verticalAlignment: Text.AlignVCenter
                visible: telepathyHelper.voiceAccounts.displayed.length > 1
            }

            Label {
                id: durationLabel
                text: DateUtils.formatCallDuration(modelData.duration)
                anchors {
                    right: parent.right
                    top: parent.top
                    topMargin: units.gu(-0.5)
                }
                verticalAlignment: Text.AlignTop
                visible: !modelData.missed
                fontSize: "small"
                height: units.gu(2)
            }

            Label {
                id: typeLabel
                text: {
                    if (modelData.missed) {
                        return i18n.tr("Missed");
                    } else if (incoming) {
                        return i18n.tr("Incoming");
                    } else {
                        return i18n.tr("Outgoing");
                    }
                }
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                    bottomMargin: units.gu(-0.5)
                }
                verticalAlignment: Text.AlignBottom
                fontSize: "x-small"
            }
        }
    }

}

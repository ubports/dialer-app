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
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Components.Popups 0.1
import Ubuntu.Telephony 0.1
import Ubuntu.Telephony.PhoneNumber 0.1 as PhoneUtils
import Ubuntu.Contacts 0.1
import QtContacts 5.0
import "dateUtils.js" as DateUtils

ListItemWithActions {
    id: historyDelegate

    readonly property bool incoming: model.senderId !== "self"
    readonly property bool unknownContact: contactWatcher.contactId === ""
    readonly property alias phoneNumber: contactWatcher.phoneNumber
    readonly property alias contactId: contactWatcher.contactId
    readonly property alias interactive: contactWatcher.interactive

    property string phoneNumberSubTypeLabel: ""
    property bool isFirst: false
    property bool fullView: false
    property bool active: false

    function activate() {
        // ignore private and unknown numbers
        if (model.participants[0] == "x-ofono-private" || model.participants[0] == "x-ofono-unknown") {
            return;
        }

        if (fullView) {
            mainView.call(model.participants[0], mainView.accountId);
        } else {
            mainView.populateDialpad(model.participants[0], mainView.accountId);
        }
    }

    function selectCallType()  {
        if (model.callMissed) {
            return i18n.tr("Missed");
        } else if (incoming) {
            return i18n.tr("Incoming");
        } else {
            return i18n.tr("Outgoing");
        }
    }

    height: units.gu(8)
    color: Theme.palette.normal.background
    triggerActionOnMouseRelease: true

    states: [
        State {
            name: "basicView"
            when: !fullView
            PropertyChanges {
                target: time
                opacity: 0
            }
            PropertyChanges {
                target: callType
                opacity: 0
            }
        }
    ]

    transitions: [
        Transition {
            UbuntuNumberAnimation {
                properties: "opacity"
            }
        }
    ]

    Item {
        id: helper

        function updateSubTypeLabel() {
            phoneNumberSubTypeLabel = contactWatcher.isUnknown ? model.participants[0] : phoneTypeModel.get(phoneTypeModel.getTypeIndex(phoneDetail)).label
        }

        Component.onCompleted: updateSubTypeLabel()

        ContactWatcher {
            id: contactWatcher
            // FIXME: handle conf calls
            phoneNumber: model.participants[0]
            onPhoneNumberContextsChanged: helper.updateSubTypeLabel()
            onPhoneNumberSubTypesChanged: helper.updateSubTypeLabel()
            onIsUnknownChanged: helper.updateSubTypeLabel()
        }

        PhoneNumber {
            id: phoneDetail
            contexts: contactWatcher.phoneNumberContexts
            subTypes: contactWatcher.phoneNumberSubTypes
        }

        ContactDetailPhoneNumberTypeModel {
            id: phoneTypeModel
            Component.onCompleted: helper.updateSubTypeLabel()
        }
    }

    Rectangle {
        anchors {
            fill: parent
            topMargin: units.gu(-1)
            bottomMargin: units.gu(-1)
            leftMargin: units.gu(-2)
            rightMargin: units.gu(-2)
        }
        opacity: historyDelegate.active ? 0.2 : 0.0
        color: "black"
        Behavior on opacity {
            UbuntuNumberAnimation {}
        }
    }

    ContactAvatar {
        id: avatar
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        width: height
        fallbackAvatarUrl: contactWatcher.avatar === "" ? "image://theme/stock_contact" : contactWatcher.avatar
        fallbackDisplayName: contactWatcher.alias !== "" ? contactWatcher.alias : contactWatcher.phoneNumber
        showAvatarPicture: (fallbackAvatarUrl != "image://theme/stock_contact") || (initials.length === 0)
    }

    Label {
        id: titleLabel
        anchors {
            top: parent.top
            left: avatar.right
            leftMargin: units.gu(2)
            right: time.left
        }
        height: units.gu(2)
        verticalAlignment: Text.AlignVCenter
        fontSize: "medium"
        text: {
            if (contactWatcher.phoneNumber == "x-ofono-private") {
                return i18n.tr("Private number")
            } else if (contactWatcher.phoneNumber == "x-ofono-unknown") {
                return i18n.tr("Unknown number")
            } else if (contactWatcher.alias != "") {
                return contactWatcher.alias
            }
            return PhoneUtils.PhoneUtils.format(contactWatcher.phoneNumber)
        }
        elide: Text.ElideRight
        color: UbuntuColors.lightAubergine
    }

    Label {
        id: phoneLabel
        anchors {
            bottom: parent.bottom
            left: avatar.right
            leftMargin: units.gu(2)
        }
        height: units.gu(2)
        verticalAlignment: Text.AlignVCenter
        fontSize: "small"
        // FIXME: handle conference call
        text: phoneNumberSubTypeLabel
        visible: interactive && !contactWatcher.isUnknown // non-interactive entries are calls from unknown or private numbers
    }

    // time and duration on the right side of the delegate
    Label {
        id: time
        anchors {
            right: parent.right
            verticalCenter: titleLabel.verticalCenter
        }
        height: units.gu(2)
        verticalAlignment: Text.AlignVCenter
        fontSize: "small"
        text: Qt.formatTime(model.timestamp, "hh:mm")
    }

    Label {
        id: callType
        anchors {
            right: parent.right
            verticalCenter: phoneLabel.verticalCenter
        }
        height: units.gu(2)
        verticalAlignment: Text.AlignVCenter
        fontSize: "small"
        text: selectCallType()
    }
}

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

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItems
import Ubuntu.Contacts 0.1
import Ubuntu.Telephony 0.1

Column {
    id: multiCallArea

    property variant calls: null

    spacing: units.gu(1)
    visible: opacity > 0

    Behavior on opacity {
        UbuntuNumberAnimation { }
    }

    Repeater {
        id: multiCallRepeater
        model: multiCallArea.calls

        Item {
            id: callDelegate
            objectName: "callDelegate"
            property QtObject callEntry: modelData
            property bool isLast: index == (multiCallRepeater.count - 1)
            property bool active: !callEntry.held
            property string phoneNumber: callEntry.phoneNumber

            height: units.gu(10) + conferenceArea.height
            anchors {
                left: parent ? parent.left : undefined
                right: parent ? parent.right : undefined
            }

            ContactWatcher {
                id: contactWatcher
                identifier: callEntry.phoneNumber
                // FIXME: if we add VOIP support, set the addressableFields with the account fields
                addressableFields: ["tel"]
            }

            ContactAvatar {
                id: avatar
                anchors {
                    left: parent.left
                    leftMargin: units.gu(2)
                    top: parent.top
                    topMargin: units.gu(2)
                }
                width: height
                height: units.gu(6)
                fallbackAvatarUrl: contactWatcher.avatar === "" ? "image://theme/stock_contact" : contactWatcher.avatar
                fallbackDisplayName: aliasLabel.text
                showAvatarPicture: (fallbackAvatarUrl != "image://theme/stock_contact") || (initials.length === 0)
            }

            Label {
                id: aliasLabel
                fontSize: "large"
                anchors {
                    left: avatar.right
                    leftMargin: units.gu(1)
                    verticalCenter: avatar.verticalCenter
                    right: callStatus.left
                    rightMargin: units.gu(1)
                }
                text: {
                    if (callEntry.isConference) {
                        return i18n.tr("Conference");
                    } else if (callEntry.voicemail) {
                        return i18n.tr("Voicemail");
                    } else if (contactWatcher.alias != "") {
                        return contactWatcher.alias;
                    } else {
                        return contactWatcher.identifier;
                    }
                }
                elide: Text.ElideRight
            }

            StopWatch {
                id: stopWatch
                time: callEntry.elapsedTime
            }

            Label {
                id: durationLabel
                text: callEntry.active ? stopWatch.elapsed : i18n.tr("Calling")
                anchors {
                    right: parent.right
                    rightMargin: units.gu(2)
                    verticalCenter: avatar.verticalCenter
                }
            }

            Label {
                id: callStatus
                fontSize: "medium"
                anchors {
                    right: durationLabel.left
                    rightMargin: units.gu(2)
                    verticalCenter: durationLabel.verticalCenter
                }
                color: callEntry.held ? theme.palette.normal.negative : theme.palette.normal.positive
                text: {
                    if (callEntry.dialing) {
                        return ""
                    } else if (callEntry.held) {
                        return i18n.tr("On hold");
                    } else {
                        return i18n.tr("Active");
                    }
                }
                font.weight: Font.DemiBold
            }

            ConferenceCallDisplay {
                id: conferenceArea
                conference: callEntry
                anchors {
                    left: aliasLabel.left
                    right: parent.right
                    top: avatar.bottom
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: liveCall.changeCallHoldingStatus(callEntry, false);
                enabled: callEntry.held
            }

            ListItems.ThinDivider {
                anchors {
                    left: parent.left
                    leftMargin: units.gu(2)
                    right: parent.right
                    rightMargin: units.gu(2)
                    bottom: parent.bottom
                }
                visible: !isLast
            }
        }
    }
}

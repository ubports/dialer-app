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
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.Telephony 0.1

Column {
    id: conferenceCallArea

    property QtObject conference: null

    visible: opacity > 0
    height: childrenRect.height

    Behavior on opacity {
        UbuntuNumberAnimation { }
    }

    Repeater {
        id: repeater
        model: conference ? conference.calls : null
        ListItem.Empty {
            id: callDelegate
            property QtObject callEntry: modelData
            property bool isLast: index == (repeater.count - 1)

            removable: true
            confirmRemoval: true
            showDivider: false
            height: units.gu(4)

            anchors {
                left: parent.left
                right: parent.right
            }

            ContactWatcher {
                id: contactWatcher
                identifier: callEntry.phoneNumber
                // FIXME: if we want to support VOIP, change the addressableFields
                // according to what the account supports
                addressableFields: ["tel"]
            }

            Label {
                id: aliasLabel
                fontSize: "large"
                anchors {
                    left: parent.left
                    leftMargin: units.gu(1)
                    right: splitButton.left
                    verticalCenter: parent.verticalCenter
                }
                text: {
                    if (callEntry.voicemail) {
                        return i18n.tr("Voicemail");
                    } else if (contactWatcher.alias != "") {
                        return contactWatcher.alias;
                    } else {
                        return contactWatcher.identifier;
                    }
                }
                elide: Text.ElideRight
            }

            backgroundIndicator: Rectangle {
                id: body
                anchors.fill: parent

                color: theme.palette.normal.negative
                clip: true

                Icon {
                    name: "call-end"
                    color: theme.palette.normal.negativeText
                    asynchronous: true
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        margins: units.gu(1)
                        horizontalCenter: parent.horizontalCenter
                    }
                    width: height
                }
            }

            onItemRemoved: callEntry.endCall()

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
                    verticalCenter: parent.verticalCenter
                }
            }

            AbstractButton {
                id: splitButton

                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    right: durationLabel.left
                }
                width: visible ? callStatus.width + units.gu(2) : 0

                visible: !callManager.backgroundCall
                onClicked: callEntry.splitCall()

                Label {
                    id: callStatus
                    fontSize: "medium"
                    anchors {
                        centerIn: parent
                    }
                    color: theme.palette.normal.backgroundSecondaryText
                    text: i18n.tr("Private")
                    font.weight: Font.DemiBold
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            ListItem.ThinDivider {
                anchors {
                    left: parent.left
                    right: parent.right
                    rightMargin: units.gu(2)
                    bottom: parent.bottom
                }
                visible: !isLast
            }
        }
    }
}

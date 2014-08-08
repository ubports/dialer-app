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
import Ubuntu.Telephony 0.1

Column {
    id: conferenceCallArea

    property QtObject conference: null

    spacing: units.gu(1)
    visible: opacity > 0

    Behavior on opacity {
        UbuntuNumberAnimation { }
    }

    Repeater {
        id: repeater
        model: conference ? conference.calls : null
        ListItem.Empty {
            id: callDelegate
            property QtObject callEntry: modelData

            removable: true
            confirmRemoval: true
            showDivider: false
            height: (conferenceCallArea.height - units.gu(repeater.count-1)) / (repeater.count > 0 ? repeater.count : 1)

            anchors {
                left: parent.left
                right: parent.right
            }

            backgroundIndicator: Rectangle {
                id: body
                anchors.fill: parent

                color: "red"
                clip: true

                Row {
                    anchors {
                        top: parent.top
                        bottom:  parent.bottom
                        right: parent.right
                        rightMargin: units.gu(2)
                    }
                    spacing: units.gu(2)
                    Icon {
                        name: "call-end"
                        color: "white"
                        anchors {
                            verticalCenter: parent.verticalCenter
                        }
                        width: units.gu(5)
                        height: units.gu(5)
                    }
                    Label {
                        text: i18n.tr("Hangup")
                        verticalAlignment: Text.AlignVCenter
                        anchors {
                            verticalCenter: parent.verticalCenter
                        }
                        width: units.gu(7)
                        fontSize: "medium"
                    }
                }
            }

            onItemRemoved: callEntry.endCall()

            Rectangle {
                color: callEntry.held ? "black" : "white"
                opacity: 0.5
                anchors.fill: parent
                radius: units.gu(0.5)
                antialiasing: true

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }

            ContactWatcher {
                id: watcher
                phoneNumber: callEntry.phoneNumber
            }

            Label {
                id: aliasLabel
                fontSize: "large"
                anchors {
                    left: parent.left
                    top: parent.top
                    margins: units.gu(1)
                }
                text: watcher.alias != "" ? watcher.alias : watcher.phoneNumber;
            }

            Label {
                fontSize: "medium"
                anchors {
                    left: parent.left
                    top: aliasLabel.bottom
                    margins: units.gu(1)
                }
                text: callEntry.held ? i18n.tr("on hold") : i18n.tr("active")
            }

            Button {
                text: i18n.tr("Private")
                anchors {
                    verticalCenter: parent.verticalCenter
                    right: parent.right
                    rightMargin: units.gu(1)
                }
                visible: !callManager.backgroundCall
                onClicked: callEntry.splitCall()
            }
        }
    }
}

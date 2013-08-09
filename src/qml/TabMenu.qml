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

Rectangle {
    id: menu
    height: units.gu(8)

    signal tabChanged(int index)

    color: Theme.palette.normal.base

    // TODO: use proper icons
    property variant items: ["keypad.png", "live_call_contacts.png", "calllog.png"]
    Grid {
        rows: 1
        columns: 3
        spacing: units.gu(8)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        Repeater {
            model: 3
            Image {
                clip: true
                id: text
                height: units.gu(4)
                width: units.gu(4)
                source: "assets/" + menu.items[index]
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        tabMenu.tabChanged(index)
                    }
                }
            }
        }
    }
    z: 1
}

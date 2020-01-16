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

AbstractButton {
    id: button
    width: units.gu(21)
    height: units.gu(4.5)
    // FIXME: waiting on #1072733
    //iconSource: "../assets/dialer_call.png"
    opacity: button.pressed ? 0.5 : (enabled ? 1 : 0.2)

    Behavior on opacity {
        UbuntuNumberAnimation { }
    }

    UbuntuShape {
        anchors.fill: parent
        color: button.pressed ? theme.palette.highlighted.negative : theme.palette.normal.negative
        radius: "medium"
    }

    Icon {
        anchors.centerIn: parent
        width: units.gu(3)
        height: units.gu(3)
        name: "call-end"
        color: theme.palette.normal.negativeText
        asynchronous: true
        z: 1
    }
}

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

AbstractButton {
    id: button
    width: units.gu(20)
    height: units.gu(8)
    // FIXME: waiting on #1072733
    //iconSource: "../assets/dialer_call.png"

    UbuntuShape {
        anchors.fill: parent
        color: button.pressed ? "#aaaaaa" : "#bababa"
        radius: "medium"
    }

    Image {
        anchors.centerIn: parent
        width: units.gu(6)
        height: units.gu(6)
        source: "../assets/incall_hangup.png"
        fillMode: Image.PreserveAspectFit
        z: 1
    }
}

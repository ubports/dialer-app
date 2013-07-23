/*
 * Copyright 2012-2013 Canonical Ltd.
 *
 * This file is part of phone-app.
 *
 * phone-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * phone-app is distributed in the hope that it will be useful,
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
        color: button.pressed ? "#cd3804" : "#dd4814"
        radius: "medium"
    }

    Image {
        anchors.centerIn: parent
        width: units.gu(4)
        height: units.gu(4)
        source: "../assets/dialer_call.png"
        fillMode: Image.PreserveAspectFit
        z: 1

    }
}

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

AbstractButton {
    id: button

    property alias iconRotation: icon.rotation
    property alias color: shape.color

    width: units.gu(21)
    height: units.gu(4.5)
    opacity: button.pressed ? 0.5 : (enabled ? 1 : 0.2)

    UbuntuShape {
        id: shape

        anchors.fill: parent
        color: "#0F8B21"
        radius: "medium"
    }

    Icon {
        id: icon

        anchors.centerIn: parent
        width: units.gu(3)
        height: units.gu(3)
        name: "call-start"
        color: "white"
        z: 1
    }
}

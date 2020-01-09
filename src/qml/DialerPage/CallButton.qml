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

    readonly property string defaultColor: theme.palette.normal.positive
    property alias iconRotation: icon.rotation
    property alias color: shape.color

    width: units.gu(21)
    height: units.gu(4.5)
    opacity: button.pressed ? 0.5 : (enabled ? 1 : 0.2)

    Behavior on opacity {
        UbuntuNumberAnimation { }
    }

    UbuntuShape {
        id: shape

        anchors.fill: parent
        color: defaultColor
        radius: "medium"
    }

    Icon {
        id: icon

        anchors.centerIn: parent
        width: units.gu(3)
        height: units.gu(3)
        name: "call-start"
        color: theme.palette.normal.positiveText
        asynchronous: true
        z: 1
    }
}

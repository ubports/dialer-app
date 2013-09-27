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

    property alias iconSource: icon.name
    property bool selected: false

    width: units.gu(7)
    height: units.gu(7)

    property int iconWidth: 0
    property int iconHeight: 0

    /*BorderImage {
        anchors.fill: parent
        source: (selected || pressed) ? "../assets/dialer_pad_bg_pressed.png" : "../assets/dialer_pad_bg.png"
    }*/

    Icon {
        id: icon
        anchors.centerIn: parent
        width: (iconWidth > 0) ? iconWidth : undefined
        height: (iconHeight > 0) ? iconHeight : undefined
        color: "white"
    }
}

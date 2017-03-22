/*
 * Copyright 2016 Canonical Ltd.
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
import QtSystemInfo 5.5

Item {
    // FIXME: implement correctly without relying on unity private stuff
    property bool hasMouse: miceModel.count > 0 || touchPadModel.count > 0
    property bool hasKeyboard: keyboardsModel.count > 0

    InputDeviceManager {
        id: miceModel
        filter: InputInfo.Mouse
    }

    InputDeviceManager {
        id: touchPadModel
        filter: InputInfo.TouchPad
    }

    InputDeviceManager {
        id: keyboardsModel
        filter: InputInfo.Keyboard
    }

    Component.onCompleted: console.log("Has mouse: " + hasMouse)
    onHasMouseChanged: console.log("Has mouse: " + hasMouse)
}


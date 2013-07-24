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
    property QtObject call

    border.color: "black"
    color: "white"
    height: units.gu(8)

    Image {
        id: avatar
        anchors.margins: units.gu(0.5)
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: height
        source: (call && call.contactAvatar != "") ? call.contactAvatar : "../assets/avatar_incall_rightpane.png"
        onStatusChanged: if (status == Image.Error) source = "../assets/avatar_incall_rightpane.png"
        asynchronous: true
    }

    Text {
        text: call ? call.phoneNumber : ""
        anchors.margins: units.gu(0.5)
        anchors.left: avatar.right
        anchors.verticalCenter: avatar.verticalCenter
    }

    Button {
        id: swapButton

        anchors.margins: units.gu(0.5)
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: i18n.tr("Swap Calls")

        onClicked: call.held = false
    }
}

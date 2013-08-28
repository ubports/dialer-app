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

    width: units.gu(11.33)
    height: units.gu(7)

    property alias label: labelItem.text
    property alias sublabel: sublabelItem.text
    property alias sublabelSize: sublabelItem.fontSize
    property alias iconSource: subImage.source
    property int keycode
    property bool isCorner: false
    property int corner

    // TODO: use proper button click feedback
    Rectangle {
        anchors.fill: parent
        visible: button.pressed
        color: "black"
        opacity: 0.2
    }

    Item {
        height: childrenRect.height
        width: parent.width
        clip: true
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        Label {
            id: labelItem

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenterOffset: -units.gu(0.5)
            horizontalAlignment: Text.AlignHCenter
            fontSize: "large"
            height: paintedHeight
            font.weight: Font.DemiBold
            verticalAlignment: Text.AlignTop
            color: "#F3F3E7"
        }

        Label {
            id: sublabelItem

            anchors.top: labelItem.bottom
            anchors.topMargin: units.dp(1.5)
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            fontSize: "x-small"
            color: "#888888"
        }

        Image {
            id: subImage
            visible: source != ""
            anchors.top: labelItem.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: units.dp(1.5)
            opacity: 0.8
        }
    }
}

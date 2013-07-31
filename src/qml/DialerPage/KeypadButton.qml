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

    width: units.gu(9)
    height: units.gu(7)

    property alias label: labelItem.text
    property alias sublabel: sublabelItem.text
    property alias sublabelSize: sublabelItem.fontSize
    property alias iconSource: subImage.source
    property int keycode
    property bool isCorner: false
    property int corner

    Label {
        id: labelItem

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenterOffset: -units.gu(0.5)
        horizontalAlignment: Text.AlignHCenter
        fontSize: "x-large"
        height: paintedHeight
        verticalAlignment: Text.AlignTop
        opacity: 0.9
    }

    Label {
        id: sublabelItem

        anchors.bottom: parent.bottom
        anchors.bottomMargin: units.dp(7)
        anchors.horizontalCenter: parent.horizontalCenter
        horizontalAlignment: Text.AlignHCenter
        fontSize: "x-small"
        color: "#a3a3a3"
    }

    Image {
        id: subImage
        visible: source != ""
        anchors.centerIn: sublabelItem
        opacity: 0.8
    }
}

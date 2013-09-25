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

Item {
    property bool isFirst: false

    width: units.gu(2)
    height: units.gu(10)

    BorderImage {
        id: topLine
        visible: !isFirst
        anchors.top: parent.top
        anchors.bottom: circle.top
        anchors.verticalCenter: circle.verticalCenter
        source: "../assets/timeline_vertical_line.sci"
        smooth: true
    }

    Image {
        id: circle
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        source: "../assets/timeline_circle.png"
        smooth: true
    }

    BorderImage {
        id: bottomLine
        anchors.top: circle.bottom
        anchors.bottom: parent.bottom
        anchors.verticalCenter: circle.verticalCenter
        source: "../assets/timeline_vertical_line.sci"
        smooth: true
    }
}

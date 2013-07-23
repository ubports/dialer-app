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

    width: units.gu(11)
    height: units.gu(8)

    property alias label: labelItem.text
    property alias labelFontPixelSize: labelItem.font.pixelSize
    property alias sublabel: sublabelItem.text
    property alias sublabelSize: sublabelItem.fontSize
    property alias iconSource: subImage.source
    property int keycode
    property bool isCorner: false
    property int corner

    BorderImage {
        id: shape

        anchors.fill: parent
        source: pressed ? "../assets/dialer_pad_bg_pressed.sci" : "../assets/dialer_pad_bg.sci"
    }

    Label {
        id: labelItem

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenterOffset: -units.gu(0.5)
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: units.dp(43)
        font.weight: Font.Light
        color: "#464646"
        height: paintedHeight
        verticalAlignment: Text.AlignTop
        opacity: 0.9
        style: Text.Raised
        styleColor: "#ffffff"
    }

    Label {
        id: sublabelItem

        anchors.bottom: shape.bottom
        anchors.bottomMargin: units.dp(7)
        anchors.horizontalCenter: parent.horizontalCenter
        horizontalAlignment: Text.AlignHCenter
        fontSize: "x-small"
        color: "#a3a3a3"
        style: Text.Raised
        styleColor: "#ffffff"
    }

    Image {
        id: subImage
        visible: source != ""
        anchors.centerIn: sublabelItem
        opacity: 0.8
    }
}

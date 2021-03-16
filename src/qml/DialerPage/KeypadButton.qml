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

MouseArea {
    id: button

    property alias label: labelItem.text
    property alias sublabel: sublabelItem.text
    property alias sublabelSize: sublabelItem.fontSize
    property alias iconSource: subImage.name
    property alias labelFont: labelItem.font
    property int keycode
    property bool isCorner: false
    property int corner
    property bool isVertical: parent.height > (parent.width * .75)

    UbuntuShape {
        objectName: "keypadButtonUbuntuShape"
        anchors.fill: parent
        opacity: button.pressed ? 1 : 0

        Behavior on opacity {
            UbuntuNumberAnimation {
                duration: UbuntuAnimation.BriskDuration
            }
        }
    }

    states: [
        State {
            name: "VERTICAL"
            when: isVertical
            AnchorChanges {
                target: labelItem
                anchors.horizontalCenter: parent.horizontalCenter
            }
            AnchorChanges {
                target: sublabelItem
                anchors.horizontalCenter: labelItem.horizontalCenter
                anchors.top: labelItem.bottom
            }
            AnchorChanges {
                target: subImage
                anchors.horizontalCenter: labelItem.horizontalCenter
                anchors.top: labelItem.bottom
            }
        },

        State {
            name: "HORIZONTAL"
            when: !isVertical
            AnchorChanges {
                target: labelItem
                anchors.horizontalCenter: undefined
                anchors.left: parent.left
            }
            AnchorChanges {
                target: sublabelItem
                anchors.left: labelItem.right
                anchors.verticalCenter: parent.verticalCenter
            }
            AnchorChanges {
                target: subImage
                anchors.left: labelItem.right
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    ]

    Item {
        objectName: "keypadButtonLabelsContainer"
        anchors.fill: parent
        scale: button.pressed ? 0.9 : 1

        Behavior on scale {
            UbuntuNumberAnimation {
                duration: UbuntuAnimation.BriskDuration
            }
        }

        Label {
            id: labelItem

            anchors {
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: button.state == "VERTICAL" ? -units.gu(0.5) : 0
                leftMargin: button.state == "VERTICAL" ? undefined : units.gu(0.5)
            }

            font.pixelSize: units.dp(30)
            color: theme.palette.normal.backgroundSecondaryText
        }

        Label {
            id: sublabelItem

            anchors {
                topMargin: button.state == "VERTICAL" ? units.dp(1.5) : undefined
                leftMargin: button.state == "VERTICAL" ? undefined : units.gu(0.5)
            }

            fontSize: "x-small"
            color: theme.palette.normal.backgroundSecondaryText
        }

        Icon {
            id: subImage
            visible: name != ""

            anchors {
                topMargin: button.state == "VERTICAL" ? units.dp(1.5) : undefined
                leftMargin: button.state == "VERTICAL" ? undefined : units.gu(0.5)
            }

            opacity: 0.8
            width: units.gu(2)
            height: units.gu(2)
            asynchronous: true
        }
    }
}

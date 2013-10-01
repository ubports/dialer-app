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
import Ubuntu.Components.ListItems 0.1 as ListItems

FocusScope {
    id: keypadEntry

    property alias value: input.text
    property alias input: input
    property alias placeHolder: hint.text
    property alias placeHolderPixelFontSize: hint.font.pixelSize

    // FIXME: enable this once the new tabs are implemented
    //height: units.gu(11)

    Label {
        id: dots
        clip: true
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: "..."
        visible: (input.contentWidth > (keypadEntry.width - dots.width))
        font.pixelSize: input.font.pixelSize
        font.weight: Font.Light
        font.family: "Ubuntu"
        color: "#AAAAAA"
    }

    TextInput {
        id: input

        anchors.left: dots.visible ? dots.right : parent.left
        anchors.right: parent.right
        anchors.rightMargin: units.gu(2)
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: TextInput.AlignHCenter
        text: ""
        font.pixelSize: units.dp(39)
        font.weight: Font.Light
        font.family: "Ubuntu"
        color: "#AAAAAA"
        focus: true
        cursorVisible: true
        clip: true
        opacity: 0.9

        // Use a custom cursor that does not blink to avoid extra CPU usage.
        // https://bugs.launchpad.net/dialer-app/+bug/1188669
        cursorDelegate: Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: units.dp(3)
            color: "#DD4814"
            visible: input.text != ""
        }

        // force cursor to be always visible
        onCursorVisibleChanged: {
            if (!cursorVisible)
                cursorVisible = true
        }
    }

    MouseArea {
        anchors.fill: input
        property bool held: false
        onClicked: {
            input.cursorPosition = input.positionAt(mouseX,TextInput.CursorOnCharacter)
        }
        onPressAndHold: {
            if (input.text != "") {
                held = true
                input.selectAll()
                input.copy()
            } else {
                input.paste()
            }
        }
        onReleased: {
            if(held) {
                input.deselect()
                held = false
            }

        }
    }

    Label {
        id: hint
        visible: input.text == ""
        anchors.centerIn: input
        text: ""
        fontSize: "x-large"
        font.weight: Font.Light
        font.family: "Ubuntu"
        color: "#464646"
        opacity: 0.9
    }

}

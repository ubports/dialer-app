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
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 0.1 as ListItems
import Ubuntu.Telephony.PhoneNumber 0.1

FocusScope {
    id: keypadEntry

    property alias value: input.text
    property alias input: input
    property alias placeHolder: hint.text
    property alias placeHolderPixelFontSize: hint.font.pixelSize


    PhoneNumberInput {
        id: input

        property bool __adjusting: false
        readonly property double maximumFontSize: units.dp(30)
        readonly property double minimumFontSize: FontUtils.sizeToPixels("large")

        anchors {
            left: parent.left
            leftMargin: units.gu(2)
            right: parent.right
            rightMargin: units.gu(2)
            verticalCenter: parent.verticalCenter
        }
        horizontalAlignment: contentWidth < width ? TextInput.AlignHCenter : TextInput.AlignRight
        font.pixelSize: maximumFontSize
        font.family: "Ubuntu"
        color: UbuntuColors.darkGrey
        focus: true
        cursorVisible: true
        clip: true
        defaultRegion: PhoneUtils.defaultRegion
        updateOnlyWhenFocused: false
        // FIXME: this should probably be done in the component itself
        autoFormat: input.text.length > 0 && input.text.charAt(0) !== "*" && input.text.charAt(0) !== "#"

        // Use a custom cursor that does not blink to avoid extra CPU usage.
        // https://bugs.launchpad.net/dialer-app/+bug/1188669
        cursorDelegate: Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: units.dp(3)
            color: "#DD4814"
            visible: input.text !== ""
        }

        // force cursor to be always visible
        onCursorVisibleChanged: {
            if (!cursorVisible)
                cursorVisible = true
        }

        onContentWidthChanged: {
            // avoid infinite recursion here
            if (__adjusting) {
                return;
            }

            __adjusting = true;

            // start by resetting the font size to discover the scale that should be used
            font.pixelSize = maximumFontSize

            // check if it really needs to be scaled
            if (contentWidth > width) {
                var factor = width / contentWidth;
                font.pixelSize = Math.max(font.pixelSize * factor, minimumFontSize);
                console.debug("PIX SIZE:" + font.pixelSize + "/" + minimumFontSize)
            }
            __adjusting = false;
        }
    }

    MouseArea {
        anchors.fill: input
        property bool held: false
        onClicked: {
            input.cursorPosition = input.positionAt(mouseX,TextInput.CursorOnCharacter)
        }
        onPressAndHold: {
            if (input.text !== "") {
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
        visible: input.text === ""
        anchors.centerIn: parent
        text: ""
        font.pixelSize: input.maximumFontSize
        color: UbuntuColors.darkGrey
        opacity: 0.9
    }
}

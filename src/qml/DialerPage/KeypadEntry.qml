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
import Ubuntu.Components.ListItems 1.3 as ListItems
import Ubuntu.Components.Themes.Ambiance 1.3
import Ubuntu.Telephony.PhoneNumber 0.1
import Ubuntu.Components.Popups 1.3

FocusScope {
    id: keypadEntry

    property alias value: input.text
    property alias input: input
    property alias placeHolder: hint.text
    property alias placeHolderPixelFontSize: hint.font.pixelSize
    property double maximumFontSize: units.dp(30)

    // this is used by tests. do not remove it
    property alias selectedText: input.selectedText

    signal commitRequested()

    function handleKeyEvent(key, text) {
        if (input.length == 0) {
            return
        }

        switch (key) {
        case Qt.Key_Backspace:
            input.remove(input.cursorPosition-1, input.cursorPosition)
            break
        case Qt.Key_Delete:
            input.remove(input.cursorPosition, input.cursorPosition+1)
            break
        case Qt.Key_Left:
            input.cursorPosition--
            break
        case Qt.Key_Right:
            input.cursorPosition++
            break
        case Qt.Key_Enter:
        case Qt.Key_Return:
            keypadEntry.commitRequested()
            break
        }
    }

    onValueChanged: input.deselect()
    onMaximumFontSizeChanged: input.adjustTextSize()

    PhoneNumberField {
        id: input

        property bool __adjusting: false
        readonly property double minimumFontSize: FontUtils.sizeToPixels("large")

        style: TextFieldStyle {
            background: null
            frameSpacing: 0
        }

        function adjustTextSize()
        {
            // avoid infinite recursion here
            if (__adjusting) {
                return;
            }

            __adjusting = true;

            // start by resetting the font size to discover the scale that should be used
            font.pixelSize = keypadEntry.maximumFontSize

            // check if it really needs to be scaled
            if (contentWidth > width) {
                var factor = width / contentWidth;
                font.pixelSize = Math.max(font.pixelSize * factor, minimumFontSize);
            }
            __adjusting = false
        }

        anchors {
            left: parent.left
            leftMargin: units.gu(2)
            right: parent.right
            rightMargin: units.gu(2)
            verticalCenter: parent.verticalCenter
        }
        horizontalAlignment: (text.length < 19 ? TextInput.AlignHCenter : TextInput.AlignRight)
        font.family: "Ubuntu"
        color: theme.palette.normal.backgroundSecondaryText
        focus: false
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

        onContentWidthChanged: adjustTextSize()
        Connections {
            target: units
            onGridUnitChanged: input.adjustTextSize()
        }
        Component.onCompleted: input.adjustTextSize()
    }

    MouseArea {
        anchors.fill: input
        propagateComposedEvents: true
        onClicked: {
            input.cursorPosition = input.positionAt(mouseX,TextInput.CursorOnCharacter)
        }
        onPressAndHold: {
            input.cursorPosition = input.positionAt(mouseX,TextInput.CursorOnCharacter)
            PopupUtils.open(Qt.resolvedUrl("TextInputPopover.qml"), input, {target: input})
        }
    }

    Label {
        id: hint
        visible: input.text === ""
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }

        text: ""
        font.pixelSize: input.font.pixelSize
        fontSizeMode: Text.HorizontalFit
        color: theme.palette.normal.backgroundSecondaryText
        opacity: 0.9
        horizontalAlignment: Text.AlignHCenter
    }
}

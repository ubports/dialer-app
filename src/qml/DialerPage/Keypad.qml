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
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItems

Item {
    id: keypad

    property int keysWidth: units.gu(11)
    property int keysHeight: units.gu(8)
    property bool showVoicemail: false

    width: keys.width
    height: keys.height

    signal keyPressed(int keycode, string keychar)
    signal keyPressAndHold(int keycode, string keychar)

    Grid {
        id: keys

        rows: 4
        columns: 3
        columnSpacing: units.gu(2.0)
        rowSpacing: units.gu(0.5)
        anchors.centerIn: parent

        KeypadButton {
            objectName: "buttonOne"
            width: keysWidth
            height: keysHeight
            label: i18n.tr("1")
            keycode: Qt.Key_1
            onKeyPressed: keypad.keyPressed(keycode, "1")
            onPressAndHold: keypad.keyPressAndHold(keycode, "1")
            iconSource: showVoicemail ? "voicemail" : ""
        }

        KeypadButton {
            objectName: "buttonTwo"
            width: keysWidth
            height: keysHeight
            label: i18n.tr("2")
            sublabel: i18n.tr("ABC")
            keycode: Qt.Key_2
            onKeyPressed: keypad.keyPressed(keycode, "2")
            onPressAndHold: keypad.keyPressAndHold(keycode, "2")
        }

        KeypadButton {
            objectName: "buttonThree"
            width: keysWidth
            height: keysHeight
            label: i18n.tr("3")
            sublabel: i18n.tr("DEF")
            keycode: Qt.Key_3
            onKeyPressed: keypad.keyPressed(keycode, "3")
            onPressAndHold: keypad.keyPressAndHold(keycode, "3")
        }

        KeypadButton {
            objectName: "buttonFour"
            width: keysWidth
            height: keysHeight
            label: i18n.tr("4")
            sublabel: i18n.tr("GHI")
            keycode: Qt.Key_4
            onKeyPressed: keypad.keyPressed(keycode, "4")
            onPressAndHold: keypad.keyPressAndHold(keycode, "4")
        }

        KeypadButton {
            objectName: "buttonFive"
            width: keysWidth
            height: keysHeight
            label: i18n.tr("5")
            sublabel: i18n.tr("JKL")
            keycode: Qt.Key_5
            onKeyPressed: keypad.keyPressed(keycode, "5")
            onPressAndHold: keypad.keyPressAndHold(keycode, "5")
        }

        KeypadButton {
            objectName: "buttonSix"
            width: keysWidth
            height: keysHeight
            label: i18n.tr("6")
            sublabel: i18n.tr("MNO")
            keycode: Qt.Key_6
            onKeyPressed: keypad.keyPressed(keycode, "6")
            onPressAndHold: keypad.keyPressAndHold(keycode, "6")
        }

        KeypadButton {
            objectName: "buttonSeven"
            width: keysWidth
            height: keysHeight
            label: i18n.tr("7")
            sublabel: i18n.tr("PQRS")
            keycode: Qt.Key_7
            onKeyPressed: keypad.keyPressed(keycode, "7")
            onPressAndHold: keypad.keyPressAndHold(keycode, "7")
        }

        KeypadButton {
            objectName: "buttonEight"
            width: keysWidth
            height: keysHeight
            label: i18n.tr("8")
            sublabel: i18n.tr("TUV")
            keycode: Qt.Key_8
            onKeyPressed: keypad.keyPressed(keycode, "8")
            onPressAndHold: keypad.keyPressAndHold(keycode, "8")
        }

        KeypadButton {
            objectName: "buttonNine"
            width: keysWidth
            height: keysHeight
            label: i18n.tr("9")
            sublabel: i18n.tr("WXYZ")
            keycode: Qt.Key_9
            onKeyPressed: keypad.keyPressed(keycode, "9")
            onPressAndHold: keypad.keyPressAndHold(keycode, "9")
        }

        KeypadButton {
            objectName: "buttonAsterisk"
            width: keysWidth
            height: keysHeight
            isCorner: true
            corner: Qt.BottomLeftCorner
            label: i18n.tr("*")
            keycode: Qt.Key_Asterisk
            onKeyPressed: keypad.keyPressed(keycode, "*")
            onPressAndHold: keypad.keyPressAndHold(keycode, "*")
        }

        KeypadButton {
            objectName: "buttonZero"
            width: keysWidth
            height: keysHeight
            label: i18n.tr("0")
            sublabel: i18n.tr("+")
            sublabelSize: "medium"
            keycode: Qt.Key_0
            onKeyPressed: keypad.keyPressed(keycode, "0")
            onPressAndHold: keypad.keyPressAndHold(keycode, "0")
        }

        KeypadButton {
            objectName: "buttonHash"
            width: keysWidth
            height: keysHeight
            isCorner: true
            corner: Qt.BottomRightCorner
            label: i18n.tr("#")
            keycode: Qt.Key_ssharp
            onKeyPressed: keypad.keyPressed(keycode, "#")
            onPressAndHold: keypad.keyPressAndHold(keycode, "#")
        }
    }
}

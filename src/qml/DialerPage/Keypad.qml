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

UbuntuShape {
    id: keypad

    property int keysWidth: units.gu(11)
    property int keysHeight: units.gu(7)

    width: keys.width + units.gu(2)
    height: keys.height + units.gu(2)
    radius: "medium"
    color: Qt.rgba(0,0,0,0.6)

    signal keyPressed(int keycode, string label)

    Grid {
        id: keys

        rows: 4
        columns: 3
        spacing: units.gu(1)
        anchors.centerIn: parent

        KeypadButton {
            objectName: "buttonOne"
            width: keysWidth
            height: keysHeight
            label: i18n.tr("1")
            keycode: Qt.Key_1
            onClicked: keypad.keyPressed(keycode, label)
            onPressAndHold: mainView.callVoicemail()
            iconSource: "../assets/voicemail.png"
        }

        KeypadButton {
            objectName: "buttonTwo"
            width: keysWidth
            height: keysHeight
            label: i18n.tr("2")
            sublabel: i18n.tr("ABC")
            keycode: Qt.Key_2
            onClicked: keypad.keyPressed(keycode, label)
        }

        KeypadButton {
            objectName: "buttonThree"
            width: keysWidth
            height: keysHeight
            label: i18n.tr("3")
            sublabel: i18n.tr("DEF")
            keycode: Qt.Key_3
            onClicked: keypad.keyPressed(keycode, label)
        }

        KeypadButton {
            objectName: "buttonFour"
            width: keysWidth
            height: keysHeight
            label: i18n.tr("4")
            sublabel: i18n.tr("GHI")
            keycode: Qt.Key_4
            onClicked: keypad.keyPressed(keycode, label)
        }

        KeypadButton {
            objectName: "buttonFive"
            width: keysWidth
            height: keysHeight
            label: i18n.tr("5")
            sublabel: i18n.tr("JKL")
            keycode: Qt.Key_5
            onClicked: keypad.keyPressed(keycode, label)
        }

        KeypadButton {
            objectName: "buttonSix"
            width: keysWidth
            height: keysHeight
            label: i18n.tr("6")
            sublabel: i18n.tr("MNO")
            keycode: Qt.Key_6
            onClicked: keypad.keyPressed(keycode, label)
        }

        KeypadButton {
            objectName: "buttonSeven"
            width: keysWidth
            height: keysHeight
            label: i18n.tr("7")
            sublabel: i18n.tr("PQRS")
            keycode: Qt.Key_7
            onClicked: keypad.keyPressed(keycode, label)
        }

        KeypadButton {
            objectName: "buttonEight"
            width: keysWidth
            height: keysHeight
            label: i18n.tr("8")
            sublabel: i18n.tr("TUV")
            keycode: Qt.Key_8
            onClicked: keypad.keyPressed(keycode, label)
        }

        KeypadButton {
            objectName: "buttonNine"
            width: keysWidth
            height: keysHeight
            label: i18n.tr("9")
            sublabel: i18n.tr("WXYZ")
            keycode: Qt.Key_9
            onClicked: keypad.keyPressed(keycode, label)
        }

        KeypadButton {
            objectName: "buttonAsterisk"
            width: keysWidth
            height: keysHeight
            isCorner: true
            corner: Qt.BottomLeftCorner
            label: i18n.tr("*")
            keycode: Qt.Key_Asterisk
            onClicked: keypad.keyPressed(keycode, label)
        }

        KeypadButton {
            objectName: "buttonZero"
            width: keysWidth
            height: keysHeight
            label: i18n.tr("0")
            sublabel: i18n.tr("+")
            sublabelSize: "medium"
            keycode: Qt.Key_0
            onClicked: keypad.keyPressed(keycode, label)
            onPressAndHold: keypad.keyPressed(keycode, sublabel)
        }

        KeypadButton {
            objectName: "buttonHash"
            width: keysWidth
            height: keysHeight
            isCorner: true
            corner: Qt.BottomRightCorner
            label: i18n.tr("#")
            keycode: Qt.Key_ssharp
            onClicked: keypad.keyPressed(keycode, label)
        }
    }
}

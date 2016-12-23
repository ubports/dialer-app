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

import QtQuick 2.3
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItems

Item {
    id: keypad

    readonly property int keysWidth: Math.min(units.gu(11), (keypad.width  / (keys.columns + 1)))
    readonly property int keysHeight: Math.min(units.gu(8), (keypad.height / (keys.rows + 1)))
    property double labelPixelSize: units.dp(30)
    property bool showVoicemail: false
    property alias spacing: keys.columnSpacing

    signal keyPressed(int keycode, string keychar)
    signal keyPressAndHold(int keycode, string keychar)

    GridLayout {
        id: keys

        rows: 4
        columns: 3
        rowSpacing: columnSpacing
        anchors.fill: parent
        //horizontalItemAlignment: Grid.AlignHCenter
        //verticalItemAlignment: Grid.AlignVCenter


        KeypadButton {
            objectName: "buttonOne"
            implicitWidth: keysWidth
            implicitHeight: keysHeight
            label: i18n.tr("1")
            keycode: Qt.Key_1
            onPressed: keypad.keyPressed(keycode, "1")
            onPressAndHold: keypad.keyPressAndHold(keycode, "1")
            iconSource: showVoicemail ? "voicemail" : ""
            labelFont.pixelSize: keypad.labelPixelSize

            // Layout
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            Layout.fillHeight: false
            Layout.fillWidth: false
        }

        KeypadButton {
            objectName: "buttonTwo"
            implicitWidth: keysWidth
            implicitHeight: keysHeight
            label: i18n.tr("2")
            sublabel: i18n.tr("ABC")
            keycode: Qt.Key_2
            onPressed: keypad.keyPressed(keycode, "2")
            onPressAndHold: keypad.keyPressAndHold(keycode, "2")
            labelFont.pixelSize: keypad.labelPixelSize

            // Layout
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            Layout.fillHeight: false
            Layout.fillWidth: false
        }

        KeypadButton {
            objectName: "buttonThree"
            implicitWidth: keysWidth
            implicitHeight: keysHeight
            label: i18n.tr("3")
            sublabel: i18n.tr("DEF")
            keycode: Qt.Key_3
            onPressed: keypad.keyPressed(keycode, "3")
            onPressAndHold: keypad.keyPressAndHold(keycode, "3")
            labelFont.pixelSize: keypad.labelPixelSize

            // Layout
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            Layout.fillHeight: false
            Layout.fillWidth: false
        }

        KeypadButton {
            objectName: "buttonFour"
            implicitWidth: keysWidth
            implicitHeight: keysHeight
            label: i18n.tr("4")
            sublabel: i18n.tr("GHI")
            keycode: Qt.Key_4
            onPressed: keypad.keyPressed(keycode, "4")
            onPressAndHold: keypad.keyPressAndHold(keycode, "4")
            labelFont.pixelSize: keypad.labelPixelSize

            // Layout
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            Layout.fillHeight: false
            Layout.fillWidth: false
        }

        KeypadButton {
            objectName: "buttonFive"
            implicitWidth: keysWidth
            implicitHeight: keysHeight
            label: i18n.tr("5")
            sublabel: i18n.tr("JKL")
            keycode: Qt.Key_5
            onPressed: keypad.keyPressed(keycode, "5")
            onPressAndHold: keypad.keyPressAndHold(keycode, "5")
            labelFont.pixelSize: keypad.labelPixelSize

            // Layout
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            Layout.fillHeight: false
            Layout.fillWidth: false
        }

        KeypadButton {
            objectName: "buttonSix"
            implicitWidth: keysWidth
            implicitHeight: keysHeight
            label: i18n.tr("6")
            sublabel: i18n.tr("MNO")
            keycode: Qt.Key_6
            onPressed: keypad.keyPressed(keycode, "6")
            onPressAndHold: keypad.keyPressAndHold(keycode, "6")
            labelFont.pixelSize: keypad.labelPixelSize

            // Layout
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            Layout.fillHeight: false
            Layout.fillWidth: false
        }

        KeypadButton {
            objectName: "buttonSeven"
            implicitWidth: keysWidth
            implicitHeight: keysHeight
            label: i18n.tr("7")
            sublabel: i18n.tr("PQRS")
            keycode: Qt.Key_7
            onPressed: keypad.keyPressed(keycode, "7")
            onPressAndHold: keypad.keyPressAndHold(keycode, "7")
            labelFont.pixelSize: keypad.labelPixelSize

            // Layout
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            Layout.fillHeight: false
            Layout.fillWidth: false
        }

        KeypadButton {
            objectName: "buttonEight"
            implicitWidth: keysWidth
            implicitHeight: keysHeight
            label: i18n.tr("8")
            sublabel: i18n.tr("TUV")
            keycode: Qt.Key_8
            onPressed: keypad.keyPressed(keycode, "8")
            onPressAndHold: keypad.keyPressAndHold(keycode, "8")
            labelFont.pixelSize: keypad.labelPixelSize

            // Layout
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            Layout.fillHeight: false
            Layout.fillWidth: false
        }

        KeypadButton {
            objectName: "buttonNine"
            implicitWidth: keysWidth
            implicitHeight: keysHeight
            label: i18n.tr("9")
            sublabel: i18n.tr("WXYZ")
            keycode: Qt.Key_9
            onPressed: keypad.keyPressed(keycode, "9")
            onPressAndHold: keypad.keyPressAndHold(keycode, "9")
            labelFont.pixelSize: keypad.labelPixelSize

            // Layout
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            Layout.fillHeight: false
            Layout.fillWidth: false
        }

        KeypadButton {
            objectName: "buttonAsterisk"
            implicitWidth: keysWidth
            implicitHeight: keysHeight
            isCorner: true
            corner: Qt.BottomLeftCorner
            label: i18n.tr("*")
            keycode: Qt.Key_Asterisk
            onPressed: keypad.keyPressed(keycode, "*")
            onPressAndHold: keypad.keyPressAndHold(keycode, "*")
            labelFont.pixelSize: keypad.labelPixelSize

            // Layout
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            Layout.fillHeight: false
            Layout.fillWidth: false
        }

        KeypadButton {
            objectName: "buttonZero"
            implicitWidth: keysWidth
            implicitHeight: keysHeight
            label: i18n.tr("0")
            sublabel: i18n.tr("+")
            sublabelSize: "medium"
            keycode: Qt.Key_0
            onPressed: keypad.keyPressed(keycode, "0")
            onPressAndHold: keypad.keyPressAndHold(keycode, "0")
            labelFont.pixelSize: keypad.labelPixelSize

            // Layout
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            Layout.fillHeight: false
            Layout.fillWidth: false
        }

        KeypadButton {
            objectName: "buttonHash"
            implicitWidth: keysWidth
            implicitHeight: keysHeight
            isCorner: true
            corner: Qt.BottomRightCorner
            label: i18n.tr("#")
            keycode: Qt.Key_ssharp
            onPressed: keypad.keyPressed(keycode, "#")
            onPressAndHold: keypad.keyPressAndHold(keycode, "#")
            labelFont.pixelSize: keypad.labelPixelSize

            // Layout
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            Layout.fillHeight: false
            Layout.fillWidth: false
        }
    }
}

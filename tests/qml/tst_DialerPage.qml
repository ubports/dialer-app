/*
 * Copyright 2014 Canonical Ltd.
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

import QtQuick 2.2
import QtTest 1.0
import Ubuntu.Test 0.1

import '../../src/qml/DialerPage'

Item {
    id: root

    width: units.gu(40)
    height: units.gu(60)

    DialerPage {
        id: dialerPage

        anchors.fill: parent
    }

    UbuntuTestCase {
        id: dialerPageTestCase
        name: 'dialerPageTestCase'

        when: windowShown

        function init() {
            waitForRendering(dialerPage);
        }

        function cleanup() {
            dialerPage.dialNumber = '';
        }

        function test_noNumberMustHideEraseButton() {
            var eraseButton = findChild(dialerPage, 'eraseButton');
            tryCompare(eraseButton, 'height', 0);
            tryCompare(eraseButton, 'opacity', 0);
        }

        function test_enterNumberMustShowEraseButton_data() {
            var keypadButtons = getKeypadButtons();
            var data = [];
            for (var index = 0; index < keypadButtons.length; index++) {
                var objectName = keypadButtons[index];
                data.push({tag: objectName, objectName: objectName});
            }
            return data;
        }

        function getKeypadButtons() {
            return [
                'buttonOne', 'buttonTwo', 'buttonThree', 'buttonFour',
                'buttonFive', 'buttonSix', 'buttonSeven', 'buttonEight',
                'buttonNine', 'buttonAsterisk', 'buttonZero', 'buttonHash'
            ];
        }

        function test_enterNumberMustShowEraseButton(data) {
            var keypadButton = findChild(dialerPage, data.objectName)
            mouseClick(
                keypadButton, keypadButton.width / 2, keypadButton.height / 2)

            var eraseButton = findChild(dialerPage, 'eraseButton');
            tryCompare(eraseButton, 'height', units.gu(3));
            tryCompare(eraseButton, 'opacity', 1);
        }
    }
}

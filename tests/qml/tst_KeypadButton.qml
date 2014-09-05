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

    KeypadButton {
        id: keypadButton
        label: 'test label'
        keycode: 1

        anchors.fill: parent
    }

    SignalSpy {
        id: spyOnKeyPressed
        target: keypadButton
        signalName: 'keyPressed'
    }

    UbuntuTestCase {
        id: keypadButtonTestCase
        name: 'keypadButtonTestCase'

        when: windowShown

        function init() {
            waitForRendering(keypadButton);
        }

        function cleanup() {
            spyOnKeyPressed.clear()
        }

        function test_clickMouseAreaMustScaleLabelsContainer() {
            var labelsContainer = findChild(
                keypadButton, 'keypadButtonLabelsContainer')
            compare(labelsContainer.scale, 1)

            var mouseArea = findChild(keypadButton, 'keypadButtonMouseArea')
            mousePress(mouseArea, mouseArea.width / 2, mouseArea.height / 2)

            tryCompare(labelsContainer, 'scale', 0.9)

            mouseRelease(mouseArea, mouseArea.width / 2, mouseArea.height / 2)

            tryCompare(labelsContainer, 'scale', 1)
        }

        function test_clickMouseAreaMustMakeUbuntuShapeVisible() {
            var ubuntuShape = findChild(
                keypadButton, 'keypadButtonUbuntuShape')
            compare(ubuntuShape.opacity, 0)

            var mouseArea = findChild(keypadButton, 'keypadButtonMouseArea')
            mousePress(mouseArea, mouseArea.width / 2, mouseArea.height / 2)

            tryCompare(ubuntuShape, 'opacity', 1)

            mouseRelease(mouseArea, mouseArea.width / 2, mouseArea.height / 2)

            tryCompare(ubuntuShape, 'opacity', 0)
        }

        function test_clickMouseAreaMustEmitKeyPressed() {
            var mouseArea = findChild(keypadButton, 'keypadButtonMouseArea')
            mouseClick(mouseArea, mouseArea.width / 2, mouseArea.height / 2)

            spyOnKeyPressed.wait()
            compare(
                spyOnKeyPressed.count, 1,
                'keyPressed signal was not emitted.')
        }

    }

}

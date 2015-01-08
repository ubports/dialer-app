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

import '../../src/qml/LiveCallPage'

Item {
    id: root

    width: units.gu(40)
    height: units.gu(60)

    StopWatch {
        id: timer
    }

    UbuntuTestCase {
        id: stopWatchTestCase
        name: 'stopWatchTestCase'

        when: windowShown

        function test_zero() {
            timer.time = 0;
            compare(timer.elapsed, "00:00");
        }

        function test_thirty_seconds() {
            timer.time = 30;
            compare(timer.elapsed, "00:30");
        }

        function test_one_minute() {
            timer.time = 60;
            compare(timer.elapsed, "01:00");
        }

        function test_one_hour() {
            timer.time = 3600;
            compare(timer.elapsed, "1:00:00");
        }

        function test_hour_thirty_seconds() {
            timer.time = 3600 + 30;
            compare(timer.elapsed, "1:00:30");
        }

        function test_hour_one_minute() {
            timer.time = 3600 + 60;
            compare(timer.elapsed, "1:01:00");
        }

        function test_hour_one_minute_thirty_seconds() {
            timer.time = 3600 + 60 + 30;
            compare(timer.elapsed, "1:01:30");
        }
    }

}

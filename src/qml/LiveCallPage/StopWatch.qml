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

Item {

    function pad(text, length) {
        while (text.length < length) text = '0' + text;
        return text;
    }

    property int time: 0
    property string elapsed: {
        var hours = Math.floor(time / (60 * 60));

        var divisor_for_minutes = time % (60 * 60);
        var minutes = String(Math.floor(divisor_for_minutes / 60));

        var divisor_for_seconds = divisor_for_minutes % 60;
        var seconds = String(Math.ceil(divisor_for_seconds));

        return hours == 0 ? "%1:%2".arg(pad(minutes, 2)).arg(pad(seconds, 2)) : 
            "%1:%2:%3".arg(hours).arg(pad(minutes, 2)).arg(pad(seconds, 2))
    }
}

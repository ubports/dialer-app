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

function areSameDay(date1, date2) {
    return date1.getFullYear() == date2.getFullYear()
        && date1.getMonth() == date2.getMonth()
        && date1.getDate() == date2.getDate()
}

function formatLogDate(timestamp) {
    var today = new Date()
    var date = new Date(timestamp)
    if (areSameDay(today, date)) {
        return Qt.formatTime(timestamp, Qt.DefaultLocaleShortDate)
    } else {
        return Qt.formatDateTime(timestamp, Qt.DefaultLocaleShortDate)
    }
}

function friendlyDay(timestamp) {
    var year = Qt.formatDate(timestamp, "yyyy");
    var month = Qt.formatDate(timestamp, "MM");
    var day = Qt.formatDate(timestamp, "dd");
    // NOTE: it is very weird, but javascript Date() object expects months to be between 0 and 11
    var date = new Date(year, month-1, day);
    var today = new Date();
    var yesterday = new Date();
    yesterday.setDate(today.getDate()-1);
    if (areSameDay(today, date)) {
        return i18n.tr("Today");
    } else if (areSameDay(yesterday, date)) {
        return i18n.tr("Yesterday");
    } else {
        return Qt.formatDate(date, Qt.DefaultLocaleShortDate);
    }
}

function formatFriendlyDate(timestamp) {
    return Qt.formatTime(timestamp, Qt.DefaultLocaleShortDate) + " - " + friendlyDay(timestamp);
}

function dateFromDuration(duration) {
    var durationTime = new Date();
    var processedDuration = duration;
    var seconds = processedDuration % 60;
    var minutes = 0;
    var hours = 0;


    // divide by 60 to get the minutes
    processedDuration = Math.floor(processedDuration / 60);
    if (processedDuration > 0) {
        minutes = processedDuration % 60;

        // divide again to get the hours
        processedDuration = Math.floor(processedDuration / 60);
        hours = processedDuration;
    }

    durationTime.setHours(hours);
    durationTime.setMinutes(minutes);
    durationTime.setSeconds(seconds);

    return durationTime;
}

function formatFriendlyCallDuration(duration) {
    var text = "";

    var durationTime = dateFromDuration(duration);

    var hours = parseInt(Qt.formatTime(durationTime, "hh"));
    var minutes = parseInt(Qt.formatTime(durationTime, "mm"));
    var seconds = parseInt(Qt.formatTime(durationTime, "ss"));

    if (hours > 0) {
        text = i18n.tr("%1 hour", "%1 hours", hours).arg(hours)
    } else if (minutes > 0) {
        text = i18n.tr("%1 min", "%1 mins", minutes).arg(minutes)
    } else {
        text = i18n.tr("%1 sec", "%1 secs", seconds).arg(seconds)
    }

    return text;
}

function formatCallDuration(duration) {
    var text = ""
    var durationTime = dateFromDuration(duration);

    var hours = parseInt(Qt.formatTime(durationTime, "hh"));
    var minutes = parseInt(Qt.formatTime(durationTime, "mm"));
    var seconds = parseInt(Qt.formatTime(durationTime, "ss"));

    if (hours > 0) {
        // TRANSLATORS: this is the duration time format when the call lasted more than an hour
        text = Qt.formatTime(durationTime, i18n.tr("hh:mm:ss"));
    } else {
        // TRANSLATORS: this is the duration time format when the call lasted less than an hour
        text = Qt.formatTime(durationTime, i18n.tr("mm:ss"));
    }
    return text;
}

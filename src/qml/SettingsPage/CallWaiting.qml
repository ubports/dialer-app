/*
 * This file is part of dialer-app
 *
 * Copyright (C) 2013-2017 Canonical Ltd.
 *
 * Contact: Iain Lane <iain.lane@canonical.com>
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 3, as published
 * by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranties of
 * MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import MeeGo.QOfono 0.2

Page {
    id: page
    objectName: "callWaitingPage"
    title: headerTitle
    property var sim
    property string headerTitle: i18n.tr("Call waiting")
    property bool attached: sim.netReg.status === "registered" || sim.netReg.status === "roaming"

    header: PageHeader {
        id: pageHeader
        title: page.title
    }

    OfonoCallSettings {
        id: callSettings
        modemPath: sim.path
        onVoiceCallWaitingChanged: {
            callWaitingIndicator.running = false;
        }
        onGetPropertiesFailed: {
            console.warn('callSettings, onGetPropertiesFailed');
            callWaitingIndicator.running = false;
        }
        onVoiceCallWaitingComplete: {
            //When the property change is complete, the value of checked should always be in sync with serverChecked 
            callWaitingSwitch.checked = callWaitingSwitch.serverChecked
            /* Log some additional output to help debug when things don't work */
            console.warn('callSettings, onVoiceCallWaitingComplete modem: ' + modemPath + ' success: ' + success + ' ' + voiceCallWaiting);
            callWaitingIndicator.running = false;
        }
    }

    ActivityIndicator {
        id: callWaitingIndicator
        running: true
        visible: running && attached
    }

    Switch {
        id: callWaitingSwitch
        objectName: "callWaitingSwitch"
        visible: !callWaitingIndicator.running
        enabled: callSettings.ready && attached
        property bool serverChecked: callSettings.voiceCallWaiting !== "disabled"
        onServerCheckedChanged: checked = serverChecked
        Component.onCompleted: checked = serverChecked
        onTriggered: {
            callWaitingIndicator.running = true;
            if (checked)
                callSettings.voiceCallWaiting = "enabled";
            else
                callSettings.voiceCallWaiting = "disabled";
        }
    }

    Column {
        anchors.fill: parent

        ListItem.Standard {
            id: callWaitingItem
            text: i18n.tr("Call waiting")
            control: callWaitingIndicator.running ?
                     callWaitingIndicator : callWaitingSwitch
        }

        ListItem.Base {
            height: textItem.height + units.gu(2)
            Label {
                id: textItem
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                text: i18n.tr("Lets you answer or start a new call while on another call, and switch between them")
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
            showDivider: false
        }
    }
}

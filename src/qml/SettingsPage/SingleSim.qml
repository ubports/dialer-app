/*
 * Copyright (C) 2014-2017 Canonical Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 * Ken Vandine <ken.vandine@canonical.com>
 * Jonas G. Drange <jonas.drange@canonical.com>
 *
*/
import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem

Column {
    property var sim
    property string carrierName: sim ? sim.netReg.name : null
    property string carrierString: carrierName ? carrierName : i18n.tr("SIM")

    ListItem.Standard {
        objectName: "callWait"
        text: i18n.tr("Call waiting")
        progression: true
        onClicked: pageStack.push(Qt.resolvedUrl("CallWaiting.qml"), {sim: sim})
    }

    ListItem.SingleValue {
        objectName: "callFwd"
        text: i18n.tr("Call forwarding")
        showDivider: false
        progression: true
        value: sim.getCallForwardingSummary()
        onClicked: pageStack.push(Qt.resolvedUrl("CallForwarding.qml"), {sim: sim})
    }

    ListItem.Divider {}

    ListItem.Standard {
        objectName: "simServices"
        // TRANSLATORS: %1 is the name of the (network) carrier
        text: i18n.tr("%1 Services").arg(carrierString)
        progression: true
        showDivider: false
        enabled: {
            var num;
            var map = sim.simMng.serviceNumbers;
            var nums = false;
            for(num in map) {
                if (map.hasOwnProperty(num)) {
                    nums = true;
                    break;
                }
            }
            return sim.simMng.present && nums;
        }
        onClicked: pageStack.push(Qt.resolvedUrl("Services.qml"),
                                  {carrierString: carrierString, sim: sim})
    }
}

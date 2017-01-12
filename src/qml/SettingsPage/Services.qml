/*
 * This file is part of dialer-app
 *
 * Copyright (C) 2013 Canonical Ltd.
 *
 * Contact: Sebastien Bacher <sebastien.bacher@canonical.com>
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

Page {
    id: root
    objectName: "servicesPage"
    title: headerTitle
    property string carrierString
    property variant sim
    property var names: []

    // TRANSLATORS: %1 is the name of the (network) carrier
    property string headerTitle: i18n.tr("%1 Services").arg(carrierString)

    header: PageHeader {
        id: pageHeader
        title: root.title
    }

    Component.onCompleted: {
        var keys = [];
        for (var x in sim.simMng.serviceNumbers) {
            keys.push(x);
        }
        names = keys;
    }

    Flickable {
        anchors.fill: parent
        contentHeight: contentItem.childrenRect.height
        boundsBehavior: (contentHeight > root.height) ?
                            Flickable.DragAndOvershootBounds :
                            Flickable.StopAtBounds
        /* Set the direction to workaround
           https://bugreports.qt-project.org/browse/QTBUG-31905 otherwise the UI
           might end up in a situation where scrolling doesn't work */
        flickableDirection: Flickable.VerticalFlick

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            Repeater {
                model: names

                ListItem.Standard {
                    progression: true
                    text: modelData
                    onClicked: pageStack.push(Qt.resolvedUrl("ServiceInfo.qml"), {serviceName: modelData, serviceNumber: sim.simMng.serviceNumbers[modelData], sim: sim})
                }
            }
        }
    }
}

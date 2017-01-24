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
import Ubuntu.Telephony 0.1

Page {
    id: settingsPage
    objectName: "phonePage"
    title: i18n.tr("Settings")
    flickable: flick

    property var modemAccounts: telepathyHelper.phoneAccounts.displayed
    property var sims: []

    function updateSims() {
        var component = Qt.createComponent("Ofono.qml");

        // remove previous objects
        sims.forEach(function (sim) {
            sim.destroy();
        })

        var result = []
        for (var i in settingsPage.modemAccounts) {
            var sim = component.createObject(settingsPage, {
                path: settingsPage.modemAccounts[i].modemName
            })
            result.push(sim)
        }
        sims = result
    }

    header: PageHeader {
        id: pageHeader
        title: settingsPage.title
        flickable: flick
    }

    states: [
        State {
            name: "noSim"
            StateChangeScript {
                script: loader.setSource("NoSims.qml")
            }
            when: sims.length === 0
        },
        State {
            name: "singleSim"
            StateChangeScript {
                script: loader.setSource("SingleSim.qml", {
                    sim: sims[0]
                })
            }
            when: sims.length === 1
        },
        State {
            name: "multiSim"
            StateChangeScript {
                script: loader.setSource("MultiSim.qml", {
                    sims: sims
                })
            }
            when: sims.length > 1
        }
    ]

    onModemAccountsChanged: updateSims()

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: contentItem.childrenRect.height
        boundsBehavior: (contentHeight > settingsPage.height) ?
            Flickable.DragAndOvershootBounds : Flickable.StopAtBounds

        Column {
            anchors { left: parent.left; right: parent.right }

            Loader {
                id: loader
                anchors { left: parent.left; right: parent.right }
            }

            ListItem.Standard {
                control: Switch {
                    objectName: "dialpadSounds"
                    property bool serverChecked: telepathyHelper.dialpadSoundsEnabled
                    onServerCheckedChanged: checked = serverChecked
                    Component.onCompleted: checked = serverChecked
                    onTriggered: telepathyHelper.dialpadSoundsEnabled = checked
                }
                text: i18n.tr("Dialpad tones")
            }

            ListItem.Standard {
                id: addAccount
                anchors {
                    left: parent.left
                    right: parent.right
                }
                text: i18n.tr("Add an online account")
                progression: true
                onClicked: onlineAccountHelper.item.run()
                enabled: (onlineAccountHelper.status === Loader.Ready) && (onlineAccountHelper.item.count > 0)
            }

            Repeater {
                model: telepathyHelper.voiceAccounts.all

                Loader {
                    id: accountPropertiesLoader
                    anchors {
                        left: parent.left
                        right: parent.right
                        margins: units.gu(1)
                    }
                    height: childrenRect.height
                    source: Qt.resolvedUrl("./AccountSettings/" + modelData.protocolInfo.name + ".qml")

                    onStatusChanged: {
                        if (status == Loader.Ready) {
                            item.account = modelData
                        }
                    }
                }
            }
        }
    }

    Loader {
        id: onlineAccountHelper

        anchors.fill: parent
        asynchronous: true
        source: Qt.resolvedUrl("OnlineAccountsHelper.qml")
    }
}

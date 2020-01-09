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

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Telephony 0.1

Component {
    Dialog {
        id: dialogue
        title: i18n.tr("Switch to default SIM:")
        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: units.gu(2)

            Row {
                spacing: units.gu(4)
                anchors.horizontalCenter: parent.horizontalCenter
                height: paintedHeight + units.gu(3)
                Repeater {
                    model: telepathyHelper.voiceAccounts.displayed
                    delegate: Label {
                        text: modelData.displayName
                        color: theme.palette.selected.focus
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                PopupUtils.close(dialogue)
                                telepathyHelper.setDefaultAccount(TelepathyHelper.Voice, modelData)
                            }
                        }
                    }
                }
            }

            Label {
                anchors.left: parent.left
                anchors.right: parent.right
                height: paintedHeight + units.gu(6)
                verticalAlignment: Text.AlignVCenter
                text: i18n.tr("Select a default SIM for all outgoing calls. You can always alter your choice in <a href=\"system_settings\">System Settings</a>.")
                wrapMode: Text.WordWrap
                onLinkActivated: {
                    PopupUtils.close(dialogue)
                    Qt.openUrlExternally("settings:///system/cellular")
                }
            }
            Row {
                spacing: units.gu(4)
                anchors.horizontalCenter: parent.horizontalCenter
                Button {
                    objectName: "noNoSimCardDefaultDialog"
                    text: i18n.tr("No")
                    color: theme.palette.selected.focus
                    onClicked: {
                        dualSimSettings.mainViewDontAskCount = 3
                        PopupUtils.close(dialogue)
                        Qt.inputMethod.hide()
                    }
                }
                Button {
                    objectName: "laterNoSimCardDefaultDialog"
                    text: i18n.tr("Later")
                    onClicked: {
                        PopupUtils.close(dialogue)
                        dualSimSettings.mainViewDontAskCount++
                        Qt.inputMethod.hide()
                    }
                }
            }
        }
    }
}

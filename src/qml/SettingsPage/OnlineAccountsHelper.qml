/*
 * Copyright (C) 2014 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.OnlineAccounts 0.1
import Ubuntu.OnlineAccounts.Client 0.1
import Ubuntu.Components.Popups 1.3

Item {
    id: root

    property var dialogInstance: null
    readonly property int count: accountsModel.count

    function run(){
        if (!root.dialogInstance) {
            root.dialogInstance = PopupUtils.open(dialog)
        }
    }

    ProviderModel {
        id: accountsModel

        applicationId: "dialer-app"
    }

    Component {
        id: dialog
        Dialog {
            id: dialogue
            title: "Online Accounts"
            text: i18n.tr("Pick an account to create.")

            ScrollView {
                width: dialog.width
                height: Math.min(listView.count, 3) * units.gu(7)

                ListView {
                    id: listView

                    anchors.fill: parent
                    clip: true
                    model: accountsModel
                    delegate: ListItem {
                        ListItemLayout {
                            title.text: model.displayName

                            Image {
                                SlotsLayout.position: SlotsLayout.First
                                source: "image://theme/" + model.iconName
                                width: units.gu(5)
                                height: width
                            }
                        }
                        onClicked: {
                            listView.enabled = false
                            setup.providerId = model.providerId
                            setup.exec()
                        }
                    }
                }
            }
            Button {
                text: i18n.tr("Cancel")
                onClicked: PopupUtils.close(dialogue)
            }

            Component.onDestruction: {
                root.dialogInstance  = null
            }
        }
    }

    Setup {
        id: setup
        applicationId: "dialer-app"
        providerId: "telephony-sip"
        onFinished: {
            PopupUtils.close(root.dialogInstance)
        }
    }
}

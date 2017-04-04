/*
 * This file is part of dialer-app
 *
 * Copyright (C) 2017 Canonical Ltd.
 *
 * Authors: Gustavo Pichorim Boiko <gustavo.boiko@canonical.com>
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
import Ubuntu.Components.ListItems 1.3 as ListItems
import Ubuntu.Components.Themes.Ambiance 0.1
import "../"

Page {
    id: page
    // TRANSLATORS: %1 is the displayname of the account
    title: i18n.tr("%1 Number Rewrite").arg(account.displayName)
    header: PageHeader {
        title: page.title
        flickable: contentFlickable
    }

    property var account: null
    property bool updating: false
    onAccountChanged: {
        if (!account) {
            return
        }


        var props = account.accountProperties
        for (var i in props) {
            console.log(i + ": " + props[i])
            console.log(props.defaultAreaCode)
        }

        updating = true
        numberRewriteSwitch.checked = props.numberRewrite ? props.numberRewrite : false
        countryCodeField.text = props.defaultCountryCode ? props.defaultCountryCode : ""
        areaCodeField.text = props.defaultAreaCode ? props.defaultAreaCode : ""
        removeInputField.text = props.removeCharacters ? props.removeCharacters : ""
        prefixInputField.text = props.prefix ? props.prefix : ""
        updating = false
    }

    function setAccountProperty(prop, value) {
        if (updating) {
            return
        }

        var properties = account.accountProperties
        properties[prop] = value
        account.accountProperties = properties
    }

    Flickable {
        id: contentFlickable
        anchors.fill: parent
        Column {
            height: childrenRect.height
            spacing: units.gu(1)
            anchors {
                left: parent.left
                right: parent.right
            }

            ListItems.Standard {
                control: Switch {
                    id: numberRewriteSwitch
                    objectName: "numberRewriteSwitch"
                    onCheckedChanged: {
                        setAccountProperty("numberRewrite", checked)
                    }
                }
                text: i18n.tr("Number rewrite")
                showDivider: !numberRewriteSwitch.checked
            }

            ListItems.Standard {
                id: countryCodeItem
                height: visible ? units.gu(6) : 0
                visible: numberRewriteSwitch.checked
                text: i18n.tr("Default country code")
                control: SettingsTextField {
                    id: countryCodeField
                    objectName: "countryCodeField"
                    placeholderText: i18n.tr("Enter a country code")
                    onTextChanged: {
                        setAccountProperty("defaultCountryCode", text)
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: UbuntuAnimation.SnapDuration
                    }
                }
            }

            ListItems.Standard {
                id: areaCodeItem
                height: visible ? units.gu(6) : 0
                // FIXME: re-enable the area code when we get libphonenumber detection fixed
                //visible: numberRewriteSwitch.checked
                visible: false
                text: i18n.tr("Default area code")
                control: SettingsTextField {
                    id: areaCodeField
                    objectName: "areaCodeField"
                    placeholderText: i18n.tr("Enter an area code")
                    onTextChanged: {
                        setAccountProperty("defaultAreaCode", text)
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: UbuntuAnimation.SnapDuration
                    }
                }
            }

            ListItems.Standard {
                id: removeInput
                visible: numberRewriteSwitch.checked
                height: visible ? units.gu(6) : 0
                text: i18n.tr("Characters to remove")
                control: SettingsTextField {
                    id: removeInputField
                    objectName: "removeInputField"
                    placeholderText: i18n.tr("Enter the characters to remove")
                    onTextChanged: {
                        setAccountProperty("removeCharacters", text)
                    }
                }

                Behavior on height {
                    NumberAnimation {
                        duration: UbuntuAnimation.SnapDuration
                    }
                }
            }

            ListItems.Standard {
                id: prefixInput
                visible: numberRewriteSwitch.checked
                height: visible ? units.gu(6) : 0
                text: i18n.tr("Prefix")
                control: SettingsTextField {
                    id: prefixInputField
                    objectName: "prefixInputField"
                    placeholderText: i18n.tr("Enter a prefix")
                    onTextChanged: {
                        setAccountProperty("prefix", text)
                    }
                }

                Behavior on height {
                    NumberAnimation {
                        duration: UbuntuAnimation.SnapDuration
                    }
                }
            }
        }
    }
}

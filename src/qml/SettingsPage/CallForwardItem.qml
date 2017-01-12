/*
 * This file is part of dialer-app
 *
 * Copyright (C) 2015-2017 Canonical Ltd.
 *
 * Contact: Jonas G. Drange <jonas.drange@canonical.com>
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
import Ubuntu.Components.Themes.Ambiance 0.1
import MeeGo.QOfono 0.2
import "callForwardingUtils.js" as Utils

Column {
    id: item

    property OfonoCallForwarding callForwarding
    property bool enabled: true
    property string rule

    property alias checked: check.checked
    property alias busy: d._pending
    property alias text: control.text
    property alias value: current.value
    property alias field: field

    signal checked ()
    signal failed ()
    signal enteredEditMode ()
    signal leftEditMode ()

   /**
     * Saves the rule.
     */
    function save () {
        d._pending = true;
        if (!Utils.requestRule(field.text)) {
            d._pending = false;
            d._editing = false;
            checked: callForwarding[rule] !== "";
        }
    }

   /**
     * Cancels editing the rule.
     */
    function cancel () {
        d._editing = false;
        check.checked = callForwarding[rule] !== "";
    }

    /**
     * Private object that keeps track of state of the UI.
     */
    QtObject {
        id: d

        /**
         * Server is working.
         */
        property bool _pending: !callForwarding.ready

        /**
         * Server failed to change/fetch setting.
         */
        property bool _failed: false

        /**
         * We're editing.
         */
        property bool _editing: false
        on_EditingChanged: Utils.editingChanged()

        /**
         * Whether or not the forwarding rule is active.
         */
        property bool _active: callForwarding[rule] !== ""
    }

    states: [
        State {
            name: "failed"
            when: d._failed
            PropertyChanges { target: control; enabled: false; control: check }
            PropertyChanges { target: check; checked: false }
            PropertyChanges { target: failed; visible: true }
            PropertyChanges { target: activity; visible: false }
        },
        State {
            name: "disabled"
            when: !enabled
            PropertyChanges { target: control; enabled: false }
            PropertyChanges { target: check; enabled: false }
            PropertyChanges { target: current; enabled: false }
        },
        State {
            name: "requesting"
            when: d._editing && d._pending
            PropertyChanges { target: control; control: activity }
            PropertyChanges { target: check; enabled: false; visible: false }
            PropertyChanges { target: current; enabled: false; visible: true }
        },
        State {
            name: "pending"
            when: d._pending
            PropertyChanges { target: control; control: activity }
            PropertyChanges { target: check; enabled: false; visible: false }
            PropertyChanges { target: current; enabled: false; visible: false }
        },
        State {
            name: "editing"
            when: d._editing
            PropertyChanges { target: check; enabled: false }
            PropertyChanges { target: current; visible: false }
            PropertyChanges { target: input; visible: true }
        },
        State {
            name: "active"
            when: d._active
            PropertyChanges { target: current; visible: true }
        }
    ]

    ListItem.ThinDivider { anchors { left: parent.left; right: parent.right }}

    ListItem.Standard {
        id: control
        onClicked: check.trigger(!check.checked)
        control: CheckBox {
            id: check
            objectName: "check_" + rule
            checked: callForwarding[rule] !== ""
            onTriggered: Utils.checked(checked)
            visible: !activity.running
        }
    }

    ListItem.Standard {
        id: input
        visible: false
        height: visible ? units.gu(6) : 0
        /* TRANSLATORS: This string will be truncated on smaller displays. */
        text: i18n.tr("Forward to")
        control: TextField {
            id: field
            objectName: "field_" + rule
            horizontalAlignment: TextInput.AlignRight
            inputMethodHints: Qt.ImhDialableCharactersOnly
            text: callForwarding[rule]
            font.pixelSize: units.dp(18)
            font.weight: Font.Light
            font.family: "Ubuntu"
            color: "#AAAAAA"
            maximumLength: 20
            focus: true
            cursorVisible: text === "" || text !== callForwarding[rule]
            placeholderText: i18n.tr("Enter a number")
            style: TextFieldStyle {
                overlaySpacing: units.gu(0.5)
                frameSpacing: 0
                background: Rectangle {
                    property bool error: (field.hasOwnProperty("errorHighlight") &&
                                          field.errorHighlight &&
                                          !field.acceptableInput)
                    onErrorChanged: error ? theme.palette.normal.negative : color
                    color: Theme.palette.normal.background
                    anchors.fill: parent
                    visible: field.activeFocus
                }
            }

            onVisibleChanged:
                if (visible === true) forceActiveFocus()
        }

        Behavior on height {
            NumberAnimation {
                duration: UbuntuAnimation.SnapDuration
            }
        }
    }

    ListItem.SingleValue {
        id: current
        objectName: "current_" + rule
        visible: value
        /* TRANSLATORS: This string will be truncated on smaller displays. */
        text: i18n.tr("Forward to")
        value: callForwarding[rule]
        onClicked: d._editing = true
    }

    /* Error message shown when updating fails. */
    Label {
        id: failed
        anchors {
            left: parent.left; right: parent.right; margins: units.gu(2);
        }
        visible: false
        height: contentHeight + units.gu(4)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: theme.palette.normal.negative
        text: i18n.tr("Call forwarding can't be changed right now.")
    }

    ActivityIndicator {
        id: activity
        running: d._pending
        visible: running
    }

    Connections {
        target: item
        Component.onCompleted: {
            item.callForwarding[item.rule + 'Changed'].connect(Utils.ruleChanged);
            item.callForwarding[item.rule + 'Complete'].connect(Utils.ruleComplete);
            item.callForwarding.readyChanged.connect(Utils.ruleReadyChanged);
        }
        Component.onDestruction: {
            item.callForwarding[item.rule + 'Changed'].disconnect(Utils.ruleChanged);
            item.callForwarding[item.rule + 'Complete'].disconnect(Utils.ruleComplete);
            item.callForwarding.readyChanged.disconnect(Utils.ruleReadyChanged);
        }
    }
}

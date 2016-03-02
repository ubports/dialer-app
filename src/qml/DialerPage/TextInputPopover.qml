/*
 * Copyright 2015 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3

Popover {
    id: popover
    objectName: "text_input_contextmenu"
    property Item target
    property bool canCopy: target && target.selectedText !== "" && !popover.password
    property bool password: target && target.hasOwnProperty('echoMode') && target.echoMode == TextInput.Password
    property list<Action> actions: [
        Action {
            text: i18n.dtr('ubuntu-ui-toolkit', "Select All")
            iconName: "edit-select-all"
            enabled: target && target.text !== "" && target.selectedText === ""
            visible: target && (target.selectedText === "" || popover.password)
            onTriggered: target.selectAll()
        },
        Action {
            text: i18n.dtr('ubuntu-ui-toolkit', "Cut")
            iconName: "edit-cut"
            // If paste/editing is not possible, then disable also "Cut" operation
            // It is applicable for ReadOnly's TextFields and TextAreas
            enabled: !target.readOnly
            visible: popover.canCopy
            onTriggered: {
                PopupUtils.close(popover);
                target.cut();
            }
        },
        Action {
            text: i18n.dtr('ubuntu-ui-toolkit', "Copy")
            iconName: "edit-copy"
            visible: popover.canCopy
            onTriggered: {
                PopupUtils.close(popover);
                target.copy();
            }
        },
        Action {
            text: i18n.dtr('ubuntu-ui-toolkit', "Paste")
            iconName: "edit-paste"
            enabled: target && target.canPaste
            onTriggered: {
                PopupUtils.close(popover);
                target.paste();
            }
        }
    ]

    function show() {
        visible = true;
        __foreground.show();
        // No input focus on the context menu!
    }

    // removes hide animation
    function hide() {
        popover.visible = false;
    }

    autoClose: false
    contentHeight: row.childrenRect.height + padding * 2
    contentWidth: row.childrenRect.width + padding * 2
    property int padding: units.gu(1)
    Row {
        id: row
        height: units.gu(6)
        x: popover.padding
        y: popover.padding

        Repeater {
            model: actions.length
            AbstractButton {
                id: button
                width: Math.max(units.gu(5), implicitWidth) + units.gu(2)
                height: units.gu(6)
                action: actions[modelData]
                styleName: "ToolbarButtonStyle"
            }
        }
    }
}

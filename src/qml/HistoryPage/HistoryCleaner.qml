/*
 * Copyright 2021 Ubports Foundation
 *
 * Authors:
 *  Lionel Duboeuf <lduboeuf@ouvaton.org>
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
import Ubuntu.History 0.1

Dialog {
    id: dialog
    title:  i18n.tr("Call history")

    state: "NONE"

    signal accepted()
    signal dismissed()

    function runDeleteOperation(afterMonth) {
        dialog.state = "INIT"
        var d = new Date()
        d.setMonth(d.getMonth() - afterMonth)
        deleteEventModel.removeAll(HistoryEventModel.EventTypeVoice, Qt.formatDateTime(d, "yyyy-MM-ddTHH:mm:ss.zzz"));
    }

    states: [
        State {
            name: "NONE"
            PropertyChanges { target: confirmPanel; visible: true }
            PropertyChanges { target: dialog; text: i18n.tr("Remove all after:") }
        },
        State {
            name: "INIT"
            PropertyChanges { target: dialog; text: i18n.tr("Checking...") }
        },
        State {
            name: "NO_LOGS"
            PropertyChanges { target: dialog; text: i18n.tr("No records to clean") }
            PropertyChanges { target: confirmPanel; visible: true }
        },
        State {
            name: "PENDING_DELETE"
            PropertyChanges { target: dialog; text: i18n.tr("Deleting %1 records... (This can take several minutes)").arg(deleteEventModel.count) }
            PropertyChanges { target: deleteIndicator; running: true }
        },
        State {
            name: "FINISHED"
            PropertyChanges { target: dialog; text: i18n.tr("Removed %1 records").arg(deleteEventModel.deletedCount) }
            PropertyChanges { target: dismissBtn; visible: true }
        },
        State {
            name: "ERROR"
            when: deleteEventModel.error !== HistoryManager.NO_ERROR
            PropertyChanges { target: dialog; text: i18n.tr("Removed %1 records, sorry, something went wrong.").arg(deleteEventModel.deletedCount) }
            PropertyChanges { target: dismissBtn; visible: true }
        },
        State {
            name: "TIMEOUT"
            PropertyChanges { target: dialog; text: i18n.tr("Removed %1 records, operation reached timeout. Please retry later").arg(deleteEventModel.deletedCount) }
            PropertyChanges { target: dismissBtn; visible: true }
        }
    ]

    ActivityIndicator {
        id: deleteIndicator
        running: false
    }

    HistoryFilter {
        id: removeFilter
        filterProperty: "timestamp"
        matchFlags: HistoryFilter.MatchLess
    }

    HistoryManager {
        id: deleteEventModel

        onOperationStarted: {
            dialog.state = "PENDING_DELETE"
        }

        onOperationEnded: {
            if (error === HistoryManager.NO_ERROR) {
                if (count === 0) {
                    dialog.state = "NO_LOGS"
                } else {
                    dialog.state = "FINISHED"
                }
            } else {
                dialog.state = "ERROR"
            }
        }
        onOperationTimeOutReached: {
            dialog.state = "TIMEOUT"
        }
    }

    Column {
        id: confirmPanel
        visible: false
        spacing: units.gu(2)
        OptionSelector {
            id: fromDateSelector
            objectName: "fromDateSelector"
            expanded: true
            model: [
                { value:1, label:i18n.tr("%1 month", "%1 months", 1).arg(1)},
                { value:3, label:i18n.tr("%1 month", "%1 months", 3).arg(3)},
                { value:6, label:i18n.tr("%1 month", "%1 months", 6).arg(6)},
                { value:12, label:i18n.tr("1 year")},
                { value:0, label:i18n.tr("Delete all")}
            ]
            delegate: OptionSelectorDelegate { text: modelData.label }
            onDelegateClicked: dialog.state = "NONE"
            function getSelectedValue() {
                return  model[selectedIndex].value
            }
        }

        Row {
            id: row
            width: parent.width
            spacing: units.gu(1)
            Button {
                objectName: "cancelBtn"
                width: parent.width/2 - row.spacing/2
                text: i18n.tr("Cancel")
                onClicked: dialog.dismissed()
            }
            Button {
                id: confirmBtn
                objectName: "confirmBtn"
                width: parent.width/2 - row.spacing/2
                text: i18n.tr("Confirm")
                color: theme.palette.normal.positiveText
                onClicked: dialog.runDeleteOperation(fromDateSelector.getSelectedValue())
            }
        }
    }

    Button {
        id: dismissBtn
        visible: false
        text: i18n.tr("OK")
        color: theme.palette.normal.positiveText
        onClicked: dialog.dismissed()
    }
}

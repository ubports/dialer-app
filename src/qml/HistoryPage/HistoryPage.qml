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

import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.History 0.1

Page {
    id: historyPage
    objectName: "historyPage"
    title: i18n.tr("History")
    tools: ToolbarItems {
        opened: false
        locked: true
    }

    property string searchTerm

    HistoryEventModel {
        id: historyEventModel
        type: HistoryThreadModel.EventTypeVoice

        // FIXME: do the sort and filtering
    }

    ListView {
        id: historyList

        anchors.fill: parent
        model: historyEventModel
        cacheBuffer: height * 3
        currentIndex: -1
        delegate: Loader {
            id: historyLoader
            sourceComponent: HistoryDelegate {
                id: historyDelegate
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
            }

            asynchronous: true
            anchors.left: parent.left
            anchors.right: parent.right
            height: item ? item.height : units.gu(8.5)

            Binding {
                target: historyLoader.item
                property: "model"
                value: model
                when: historyLoader.status == Loader.Ready
            }
        }
    }

    Scrollbar {
        flickableItem: historyList
        align: Qt.AlignTrailing
    }
}

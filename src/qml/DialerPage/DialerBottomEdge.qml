/*
 * Copyright 2016 Canonical Ltd.
 *
 * This file is part of dialer-app.
 *
 * dialer-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * messaging-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3

BottomEdge {
    id: bottomEdge

    height: parent ? parent.height : 0
    hint.text: i18n.tr("+")
    contentUrl: Qt.resolvedUrl("../HistoryPage/HistoryPage.qml")

    // delay loading bottom edge until after the first frame
    // is drawn to save on startup time
    preloadContent: false

    Timer {
        interval: 1
        repeat: false
        running: true
        onTriggered: bottomEdge.preloadContent = true
    }

    Binding {
        target: bottomEdge.contentItem
        property: "width"
        value: bottomEdge.width
    }

    Binding {
        target: bottomEdge.contentItem
        property: "height"
        value: bottomEdge.height
    }

    Binding {
        target: bottomEdge.contentItem
        property: "bottomEdgeCommitted"
        value: bottomEdge.status === BottomEdge.Committed
    }

    Binding {
        target: bottomEdge.contentItem
        property: "bottomEdgeItem"
        value: bottomEdge
    }
}

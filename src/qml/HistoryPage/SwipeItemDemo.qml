/*
 * Copyright 2012-2015 Canonical Ltd.
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
import QtQuick.Layouts 1.1
import Qt.labs.settings 1.0

import Ubuntu.Components 1.3
import Ubuntu.Contacts 0.1

Loader {
    id: root

    property bool necessary: true
    property bool enabled: false


    function enable() {
        root.enabled = true;
    }

    function disable() {
        if (root.enabled) {
            root.necessary = false;
            root.enabled = false;
        }
    }

    sourceComponent: necessary && enabled ? listItemDemoComponent : null

    Settings {
        property alias hintNecessary: root.necessary
    }

    Component {
        id: listItemDemoComponent

        Rectangle {
            id: rectangleContents

            color: "black"
            opacity: 0
            anchors.fill: parent

            Behavior on opacity {
                UbuntuNumberAnimation {
                    duration:  UbuntuAnimation.SlowDuration
                }
            }

            ListItemWithActions {
                id: listItem

                property int xPos: 0

                animated: false
                onXPosChanged: listItem.updatePosition(xPos)

                anchors {
                    top: parent.top
                    topMargin: units.gu(14)
                    left: parent.left
                    right: parent.right
                }
                height: units.gu(8)

                color: Theme.palette.normal.background
                leftSideAction: Action {
                    iconName: "delete"
                }
                rightSideActions: [
                    Action {
                        iconName: "info"
                    },
                    Action {
                        iconName: "message"
                    },
                    Action {
                        iconName: "stock_contact"
                    }
                ]

                ContactAvatar {
                    id: avatar
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: height
                    fallbackAvatarUrl: "image://theme/stock_contact"
                    fallbackDisplayName: "Ubuntu phone"
                    showAvatarPicture: true
                }

                Label {
                    id: titleLabel
                    anchors {
                        top: parent.top
                        topMargin: units.gu(0.5)
                        left: avatar.right
                        leftMargin: units.gu(2)
                        right: time.left
                        rightMargin: units.gu(1) + (countLabel.visible ? countLabel.width : 0)
                    }
                    height: units.gu(2)
                    verticalAlignment: Text.AlignTop
                    fontSize: "medium"
                    text: "(541) 754-3010"
                    elide: Text.ElideRight
                    color: theme.palette.normal.backgroundSecondaryText
                }

                // this item has the width of the text above. It is used to be able to align
                Item {
                    id: titleLabelArea
                    anchors {
                        top: titleLabel.top
                        left: titleLabel.left
                        bottom: titleLabel.bottom
                    }
                    width: titleLabel.paintedWidth
                }

                Label {
                    id: countLabel
                    anchors {
                        left: titleLabelArea.right
                        leftMargin: units.gu(0.5)
                        top: titleLabel.top
                    }
                    height: units.gu(2)
                    fontSize: "medium"
                    // TRANSLATORS: this is the count of events grouped into this single item
                    text: i18n.tr("(%1)").arg(2)
                }

                Label {
                    id: phoneLabel
                    anchors {
                        top: titleLabel.bottom
                        topMargin: units.gu(1)
                        left: avatar.right
                        leftMargin: units.gu(2)
                    }
                    height: units.gu(2)
                    verticalAlignment: Text.AlignTop
                    fontSize: "small"
                    text: i18n.tr("Mobile")
                }

                // time and duration on the right side of the delegate
                Label {
                    id: time
                    anchors {
                        right: parent.right
                        bottom: titleLabel.bottom
                    }
                    height: units.gu(2)
                    verticalAlignment: Text.AlignBottom
                    fontSize: "small"
                    text: Qt.formatTime( new Date(), Qt.DefaultLocaleShortDate)
                }

                Label {
                    id: callType
                    anchors {
                        right: parent.right
                        bottom: phoneLabel.bottom
                    }
                    height: units.gu(2)
                    verticalAlignment: Text.AlignBottom
                    fontSize: "small"
                    text: i18n.tr("Incoming")
                }
            }

            RowLayout {
                id: dragTitle

                anchors {
                    left: parent.left
                    right: parent.right
                    top: listItem.bottom
                    margins: units.gu(1)
                    //topMargin: units.gu(1)
                }
                height: units.gu(3)
                spacing: units.gu(2)

                Image {
                    visible: listItem.swipeState === "RightToLeft"
                    source: Qt.resolvedUrl("../assets/swipe_arrow.svg")
                    rotation: 180
                    Layout.preferredWidth: sourceSize.width
                    height: parent.height
                    verticalAlignment: Image.AlignVCenter
                    fillMode: Image.Pad
                    sourceSize {
                        width: units.gu(7)
                        height: units.gu(2)
                    }
                }

                Label {
                    id: dragMessage

                    Layout.fillWidth: true
                    height: parent.height
                    verticalAlignment: Image.AlignVCenter
                    wrapMode: Text.Wrap
                    fontSize: "large"
                    color: "#ffffff"
                }

                Image {
                    visible: listItem.swipeState === "LeftToRight"
                    source: Qt.resolvedUrl("../assets/swipe_arrow.svg")
                    Layout.preferredWidth: sourceSize.width
                    height: parent.height
                    verticalAlignment: Image.AlignVCenter
                    fillMode: Image.Pad
                    sourceSize {
                        width: units.gu(7)
                        height: units.gu(2)
                    }
                }
            }

            Button {
                objectName: "gotItButton"

                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    bottomMargin: units.gu(9)
                }
                width: units.gu(17)
                strokeColor: theme.palette.normal.positive
                text: i18n.tr("Got it")
                enabled: !dismissAnimation.running
                onClicked: dismissAnimation.start()
                InverseMouseArea {
                    anchors.fill: parent
                    topmostItem: true
                }
            }

            SequentialAnimation {
                id: slideAnimation

                readonly property real leftToRightXpos: (-3 * (listItem.actionWidth + units.gu(2)))
                readonly property real rightToLeftXpos: listItem.leftActionWidth

                loops: Animation.Infinite
                running: root.enabled

                PropertyAction {
                    target: dragMessage
                    property: "text"
                    value: i18n.tr("Swipe to reveal actions")
                }

                PropertyAction {
                    target: dragMessage
                    property: "horizontalAlignment"
                    value: Text.AlignLeft
                }

                ParallelAnimation {
                    PropertyAnimation {
                        target:  listItem
                        property: "xPos"
                        from: 0
                        to: slideAnimation.leftToRightXpos
                        duration: 2000
                    }
                    PropertyAnimation {
                        target: dragTitle
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: UbuntuAnimation.SleepyDuration
                    }
                }

                PauseAnimation {
                    duration: UbuntuAnimation.SleepyDuration
                }

                ParallelAnimation {
                    PropertyAnimation {
                        target: dragTitle
                        property: "opacity"
                        to: 0
                        duration: UbuntuAnimation.SlowDuration
                    }

                    PropertyAnimation {
                        target: listItem
                        property: "xPos"
                        from: slideAnimation.leftToRightXpos
                        to: 0
                        duration: UbuntuAnimation.SleepyDuration
                    }
                }

                PropertyAction {
                    target: dragMessage
                    property: "text"
                    value: i18n.tr("Swipe to delete")
                }

                PropertyAction {
                    target: dragMessage
                    property: "horizontalAlignment"
                    value: Text.AlignRight
                }

                ParallelAnimation {
                    PropertyAnimation {
                        target: listItem
                        property: "xPos"
                        from: 0
                        to: slideAnimation.rightToLeftXpos
                        duration: UbuntuAnimation.SleepyDuration
                    }
                    PropertyAnimation {
                        target: dragTitle
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: UbuntuAnimation.SlowDuration
                    }
                }

                PauseAnimation {
                    duration: UbuntuAnimation.SleepyDuration
                }

                ParallelAnimation {
                    PropertyAnimation {
                        target: dragTitle
                        property: "opacity"
                        to: 0
                        duration: UbuntuAnimation.SlowDuration
                    }

                    PropertyAnimation {
                        target: listItem
                        property: "xPos"
                        from: slideAnimation.rightToLeftXpos
                        to: 0
                        duration: UbuntuAnimation.SleepyDuration
                    }
                }
            }

            SequentialAnimation {
                id: dismissAnimation

                alwaysRunToEnd: true
                running: false

                UbuntuNumberAnimation {
                    target: rectangleContents
                    property: "opacity"
                    to: 0.0
                    duration:  UbuntuAnimation.SlowDuration
                }

                ScriptAction {
                    script: root.disable()
                }
            }

            Component.onCompleted: {
                opacity = 0.85
            }
        }
    }
}

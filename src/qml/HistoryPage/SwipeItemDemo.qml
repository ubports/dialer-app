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

import QtQuick 2.0
import Qt.labs.settings 1.0
import Ubuntu.Components 1.1
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

    // Display the hint only once after taking the very first photo
    Settings {
        property alias hintNecessary: root.necessary
    }

    Component {
        id: listItemDemoComponent

        Rectangle {
            color: "black"
            opacity: 0.8
            anchors.fill: parent

            ListItemWithActions {
                id: listItem

                property int xPos: 0
                animated: false
                onXPosChanged: listItem.updatePosition(xPos)

                anchors {
                    top: parent.top
                    topMargin: units.gu(8)
                    left: parent.left
                    right: parent.right
                }

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

                Label {
                    anchors {
                        fill: parent
                        leftMargin: units.gu(4)
                        rightMargin: units.gu(4)
                    }
                    text: listItem.swipeState === "LeftToRight" ?
                              i18n.tr("Drag left to right to revel the delete action") :
                              listItem.swipeState === "RightToLeft" ?
                                  i18n.tr("Drag right to left to revel the extra actions") : ""
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Image {
                id: swipeGetstureImage

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: infoMessage.top
                    bottomMargin: units.gu(5)
                }
                source: "../assets/swipe_gesture.png"
            }

            Label {
                id: infoMessage

                anchors {
                    left: parent.left
                    leftMargin: units.gu(2)
                    right: parent.right
                    rightMargin: units.gu(2)
                    bottom: parent.bottom
                    bottomMargin: units.gu(5)
                }

                text: i18n.tr("You can drag the item to left or right to revel more actions")
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                fontSize: "x-large"
                color: "#ebebeb"
            }

            SequentialAnimation {
                id: slideAnimation

                loops: Animation.Infinite
                running: root.enabled

                PropertyAnimation {
                    target: listItem
                    property: "xPos"
                    from: 0
                    to: listItem.leftActionWidth
                    duration: 1000
                }

                PauseAnimation {
                    duration: 1000
                }

                PropertyAction { target: listItem; property: "xPos"; value: 0 }

                PropertyAnimation {
                    target:  listItem
                    property: "xPos"
                    from: 0
                    to: (-3 * (listItem.actionWidth + units.gu(2)))
                    duration: 2000
                }

                PauseAnimation {
                    duration: 1000
                }

                PropertyAction { target: listItem; property: "xPos"; value: 0 }

            }

            MouseArea {
                anchors.fill: parent
                onPressed: root.disable()
            }
        }
    }
}

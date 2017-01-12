/*
 * This file is part of dialer-app
 *
 * Copyright (C) 2013-2017 Canonical Ltd.
 *
 * Contact:
 *     Sebastien Bacher <sebastien.bacher@canonical.com>
 *     Jonas G. Drange <jonas.drange@canonical.com>
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
 *
 * TODO: Add centrally stored setting for each call forwarding that describes a
 *       contact. lp:1467816
 *
 * TODO: If a setting failed to be set, the error text should be followed by
 *       “Contact {carrier name} for more information.”.
 */

import QtQuick 2.4
import QtContacts 5.0
import MeeGo.QOfono 0.2
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.Themes.Ambiance 0.1
import Ubuntu.Content 1.3
import "callForwardingUtils.js" as Utils

Page {
    id: page
    objectName: "callForwardingPage"
    title: headerTitle
    property var sim
    property string headerTitle: i18n.tr("Call forwarding")
    property QtObject editing: null
    property QtObject activeItem: null
    property var activeTransfer

    header: PageHeader {
        id: pageHeader
        title: page.title
        flickable: flick
    }

    states: [
        State {
            name: "forwardBusy"
            PropertyChanges { target: fwdSomeTitle; enabled: false }
            PropertyChanges { target: fwdAll; enabled: false; }
            PropertyChanges { target: fwdBusy; enabled: false; }
            PropertyChanges { target: fwdLost; enabled: false; }
            PropertyChanges { target: fwdUnreachable; enabled: false; }
            when: fwdAll.busy || fwdBusy.busy || fwdLost.busy || fwdUnreachable.busy
        },
        State {
            name: "forwardFailed"
            PropertyChanges { target: fwdSomeTitle; enabled: false }
            PropertyChanges { target: fwdFailedLabel; visible: true }
            PropertyChanges { target: fwdAll; enabled: false; }
            PropertyChanges { target: fwdBusy; enabled: false; }
            PropertyChanges { target: fwdLost; enabled: false; }
            PropertyChanges { target: fwdUnreachable; enabled: false; }
        },
        State {
            name: "editing"
            PropertyChanges { target: fwdAll; enabled: false; explicit: true }
            PropertyChanges { target: fwdBusy; enabled: false; explicit: true }
            PropertyChanges { target: fwdLost; enabled: false; explicit: true }
            PropertyChanges { target: fwdUnreachable; enabled: false; explicit: true }
            PropertyChanges { target: fwdSomeTitle; enabled: false }
            StateChangeScript {
                name: "editingEnabled"
                script: {
                    editing.opacity = 1;
                    editing.enabled = true;
                }
            }
            when: editing !== null
        },
        State {
            name: "forwardAll"
            PropertyChanges { target: fwdSomeTitle; }
            PropertyChanges { target: fwdBusy; enabled: false; value: ""; checked: false }
            PropertyChanges { target: fwdLost; enabled: false; value: ""; checked: false }
            PropertyChanges { target: fwdUnreachable; enabled: false; value: ""; checked: false }
            when: fwdAll.value !== ""
        }
    ]

    Flickable {
        id: flick

        // this is necessary to avoid the page to appear below the header
        clip: true
        flickableDirection: Flickable.VerticalFlick
        anchors {
            fill: parent
            bottomMargin: keyboardButtons.height + keyboard.height
        }
        contentHeight: contents.height + units.gu(2)
        contentWidth: parent.width

        // after add a new field we need to wait for the contentHeight to
        // change to scroll to the correct position
        onContentHeightChanged: Utils.show(page.activeItem)

        Column {
            id: contents
            anchors { left: parent.left; right: parent.right }
            spacing: units.gu(1)

            CallForwardItem {
                id: fwdAll
                anchors { left: parent.left; right: parent.right }
                rule: "voiceUnconditional"
                callForwarding: callForwarding
                text: i18n.tr("Forward every incoming call")
                onEnteredEditMode: {page.editing = fwdAll; Utils.show(field)}
                onLeftEditMode: page.editing = null
            }

            Label {
                id: fwdAllCaption
                anchors {
                    left: parent.left; right: parent.right; margins: units.gu(1)
                }
                width: parent.width
                wrapMode: Text.WordWrap
                fontSize: "small"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: i18n.tr("Redirects all phone calls to another number.")
                opacity: 0.8
            }

            Label {
                id: fwdFailedLabel
                anchors {
                    left: parent.left; right: parent.right; margins: units.gu(2)
                }
                width: parent.width
                wrapMode: Text.WordWrap
                visible: false
                text: i18n.tr("Call forwarding status can't be checked " +
                              "now. Try again later.")
                color: theme.palette.normal.negative
                horizontalAlignment: Text.AlignHCenter
            }

            SettingsItemTitle {
                id: fwdSomeTitle
                text: i18n.tr("Forward incoming calls when:")
            }

            CallForwardItem {
                id: fwdBusy
                objectName: "fwdBusy"
                anchors { left: parent.left; right: parent.right }
                callForwarding: callForwarding
                rule: "voiceBusy"
                text: i18n.tr("I'm on another call")
                onEnteredEditMode: {page.editing = fwdBusy; Utils.show(field)}
                onLeftEditMode: page.editing = null
            }

            CallForwardItem {
                id: fwdLost
                objectName: "fwdLost"
                anchors { left: parent.left; right: parent.right }
                callForwarding: callForwarding
                rule: "voiceNoReply"
                text: i18n.tr("I don't answer")
                onEnteredEditMode: {page.editing = fwdLost; Utils.show(field)}
                onLeftEditMode: page.editing = null
            }

            CallForwardItem {
                id: fwdUnreachable
                objectName: "fwdUnreachable"
                anchors { left: parent.left; right: parent.right }
                callForwarding: callForwarding
                rule: "voiceNotReachable"
                text: i18n.tr("My phone is unreachable")
                onEnteredEditMode: {
                    page.editing = fwdUnreachable;
                    Utils.show(field);
                }
                onLeftEditMode: page.editing = null
            }
        }
    } // Flickable

    Rectangle {
        id: keyboardButtons
        anchors {
            left: parent.left
            right: parent.right
            bottom: keyboard.top
        }
        color: Theme.palette.selected.background
        visible: editing !== null
        height: units.gu(6)
        Button {
            id: kbdContacts
            objectName: "contactsButton"
            anchors {
                left: parent.left
                leftMargin: units.gu(1)
                verticalCenter: parent.verticalCenter
            }
            activeFocusOnPress: false
            enabled: editing && !editing.busy
            text: i18n.tr("Contacts...")
            onClicked: page.activeTransfer = contactPicker.request()
        }

        Button {
            id: kbdCancel
            objectName: "cancelButton"
            anchors {
                right: kbdSet.left
                rightMargin: units.gu(1)
                verticalCenter: parent.verticalCenter
            }
            enabled: editing && !editing.busy
            text: i18n.tr("Cancel")
            onClicked: editing.cancel()
        }

        Button {
            id: kbdSet
            objectName: "setButton"
            anchors {
                right: parent.right
                rightMargin: units.gu(1)
                verticalCenter: parent.verticalCenter
            }
            enabled: editing && !editing.busy && editing.field.text
            text: i18n.tr("Set")
            activeFocusOnPress: false
            onClicked: editing.save()
        }
    }

    KeyboardRectangle {
        id: keyboard
        anchors.bottom: parent.bottom
        onHeightChanged: {
            if (page.activeItem) {
                Utils.show(page.activeItem);
            }
        }
    }

    Component {
        id: chooseNumberDialog
        Dialog {
            id: dialog
            property var contact
            title: i18n.tr("Please select a phone number")

            ListItem.ItemSelector {
                anchors {
                    left: parent.left
                    right: parent.right
                }
                activeFocusOnPress: false
                expanded: true
                text: i18n.tr("Numbers")
                model: contact.phoneNumbers
                selectedIndex: -1
                delegate: OptionSelectorDelegate {
                    text: modelData.number
                    activeFocusOnPress: false
                }
                onDelegateClicked: {
                    editing.field.text = contact.phoneNumbers[index].number;
                    PopupUtils.close(dialog);
                }
            }
        }
    }

    Component {
        id: hadNoNumberDialog
        Dialog {
            id: dialog
            title: i18n.tr("Could not forward to this contact")
            text: i18n.tr("Contact not associated with any phone number.")
            Button {
                text: i18n.tr("OK")
                activeFocusOnPress: false
                onClicked: PopupUtils.close(dialog)
            }
        }
    }

    VCardParser {
        id: contactParser

        function parseContact(vcardContact) {
            return vcardContact;
        }

        onVcardParsed: {
            var contact;
            if (contacts.length === 0) {
                console.warn('no contacts parsed');
                return;
            } else {
                contact = parseContact(contacts[0]);
                if (contact.phoneNumbers.length < 1) {
                    PopupUtils.open(hadNoNumberDialog);
                } else if (contact.phoneNumbers.length > 1) {
                    PopupUtils.open(chooseNumberDialog, page, {
                        'contact': contact
                    });
                } else {
                    editing.field.text = contact.phoneNumber.number;
                }
            }
        }
    }

    ContentTransferHint {
        id: importHint
        anchors.fill: parent
        activeTransfer: page.activeTransfer
    }

    ContentPeer {
        id: contactPicker
        contentType: ContentType.Contacts
        handler: ContentHandler.Source
        selectionType: ContentTransfer.Single
    }

    Connections {
        target: page.activeTransfer ? page.activeTransfer : null
        onStateChanged: {
            if (page.activeTransfer.state === ContentTransfer.Charged) {
                contactParser.vCardUrl = page.activeTransfer.items[0].url;
            }
        }
    }

    Connections {
        target: callForwarding
        onGetPropertiesFailed: page.state = "forwardFailed";
    }

    OfonoCallForwarding {
        id: callForwarding
        modemPath: sim.path
        function updateSummary () {
            var val;

            // Clear the summary and exit if any of the values are unknown.
            if (typeof voiceUnconditional === 'undefined' ||
                typeof voiceBusy === 'undefined' ||
                typeof voiceNoReply === 'undefined' ||
                typeof voiceNotReachable === 'undefined') {
                sim.setCallForwardingSummary('');
                return;
            }

            if (voiceUnconditional) {
                 val = i18n.tr("All calls");
            } else if (voiceBusy || voiceNoReply || voiceNotReachable) {
                val = i18n.tr("Some calls")
            } else {
                val = i18n.tr("Off")
            }
            sim.setCallForwardingSummary(val);
        }

        Component.onCompleted: updateSummary()
        onVoiceUnconditionalChanged: updateSummary()
        onVoiceBusyChanged: updateSummary()
        onVoiceNoReplyChanged: updateSummary()
        onVoiceNotReachableChanged: updateSummary()
    }
}

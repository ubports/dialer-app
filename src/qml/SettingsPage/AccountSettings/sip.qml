import QtQuick 2.0
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItems
import Ubuntu.Components.Themes.Ambiance 0.1

Column {
    property var account: null

    height: childrenRect.height
    spacing: units.gu(1)
    anchors {
        left: parent.left
        right: parent.right
    }

    onAccountChanged: {
        if (!account) {
            return
        }

        console.log("BLABLA account properties is " + account.accountProperties + " " + account.accountProperties.externalCallsNeedPrefix)
        prefixSwitch.checked = account.accountProperties.externalCallsNeedPrefix
        prefixInputField.text = account.accountProperties.externalCallsPrefix
    }

    function setAccountProperty(prop, value) {
        var properties = account.accountProperties
        properties[prop] = value
        account.accountProperties = properties
    }

    Item {
        id: spacing
        height: units.gu(1)
        width: 1
    }

    Label {
        anchors {
            left: parent.left
            right: parent.right
        }
        text: account.displayName
    }

    ListItems.Standard {
        control: Switch {
            id: prefixSwitch
            objectName: "prefixSwitch"
            onCheckedChanged: {
                setAccountProperty("externalCallsNeedPrefix", checked)
            }
        }
        text: i18n.tr("External calls need prefix")
        showDivider: !prefixInput.visible
    }

    ListItems.Standard {
        id: prefixInput
        visible: prefixSwitch.checked
        height: visible ? units.gu(6) : 0
        text: i18n.tr("Prefix")
        control: TextField {
            id: prefixInputField
            objectName: "prefixInputField"
            horizontalAlignment: TextInput.AlignRight
            inputMethodHints: Qt.ImhDialableCharactersOnly
            font {
                pixelSize: units.dp(18)
                weight: Font.Light
                family: "Ubuntu"
            }
            color: "#AAAAAA"
            maximumLength: 20
            focus: true
            placeholderText: i18n.tr("Enter a prefix")
            style: TextFieldStyle {
                overlaySpacing: units.gu(0.5)
                frameSpacing: 0
                background: Rectangle {
                    property bool error: (prefixInputField.hasOwnProperty("errorHighlight") &&
                                          prefixInputField.errorHighlight &&
                                          !prefixInputField.acceptableInput)
                    onErrorChanged: error ? theme.palette.normal.negative : color
                    color: Theme.palette.normal.background
                    anchors.fill: parent
                    visible: prefixInputField.activeFocus
                }
            }

            onTextChanged: {
                setAccountProperty("externalCallsPrefix", text)
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
}

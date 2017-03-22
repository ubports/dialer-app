import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Themes.Ambiance 0.1

TextField {
    id: textField
    horizontalAlignment: TextInput.AlignRight
    font {
        pixelSize: units.dp(18)
        weight: Font.Light
        family: "Ubuntu"
    }
    color: "#AAAAAA"
    maximumLength: 20
    focus: true
    style: TextFieldStyle {
        overlaySpacing: units.gu(0.5)
        frameSpacing: 0
        background: Rectangle {
            property bool error: (textField.hasOwnProperty("errorHighlight") &&
                                  textField.errorHighlight &&
                                  !textField.acceptableInput)
            onErrorChanged: error ? theme.palette.normal.negative : color
            color: Theme.palette.normal.background
            anchors.fill: parent
            visible: textField.activeFocus
        }
    }
}

import QtQuick
import qs.common

// Escape goes back to `original` first, then closes the panel
Rectangle {
    id: root

    property alias text: field.text
    property string original: ""
    property string placeholder: ""

    signal editingFinished
    signal accepted

    function focusEnd(): void {
        field.forceActiveFocus()
        field.cursorPosition = field.text.length
    }

    implicitHeight: 32
    radius: 6
    color: Theme.hover
    opacity: enabled ? 1 : 0.4

    TextInput {
        id: field

        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.text
        selectionColor: Theme.adapt("#333333")
        selectedTextColor: Theme.adapt("#ffffff")
        font.pixelSize: 12
        clip: true
        selectByMouse: true
        activeFocusOnTab: true

        onEditingFinished: root.editingFinished()
        onAccepted: root.accepted()
        Keys.onShortcutOverride: event => event.accepted = event.key === Qt.Key_Escape && field.text !== root.original
        Keys.onEscapePressed: field.text = root.original

        Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            visible: field.text === ""
            text: root.placeholder
            color: Theme.textDim
            font.pixelSize: 12
        }
    }
}

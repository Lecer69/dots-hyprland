import QtQuick
import Quickshell

PopupWindow {
    id: root

    // Anchor to the hovered tray icon item
    anchor.item: null
    anchor.edges: Edges.Bottom | Edges.Left

    color: "transparent"
    visible: false

    property string text: ""

    implicitWidth: content.implicitWidth + 16
    implicitHeight: content.implicitHeight + 10

    function showFor(anchorItem, newText) {
        root.text = newText
        root.anchor.item = anchorItem
        root.visible = true
    }

    function hide() {
        root.visible = false
    }

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: "#e2121212"
        border.color: "#30ffffff"
        border.width: 1

        Text {
            id: content
            anchors.centerIn: parent
            text: root.text
            color: "#e3ffffff"
            font.pixelSize: 12
        }
    }
}

import QtQuick
import Quickshell

PopupWindow {
    id: root

    property bool shown: false
    property string text: ""

    anchor.item: null
    anchor.edges: Edges.Bottom | Edges.Left

    color: "transparent"
    visible: shown || tipBg.opacity > 0.01

    implicitWidth: content.implicitWidth + 20
    implicitHeight: 28

    function showFor(anchorItem, newText) {
        root.text = newText
        root.anchor.item = anchorItem
        root.shown = true
    }

    function hide() {
        root.shown = false
    }

    Rectangle {
        id: tipBg

        anchors.fill: parent
        radius: 8
        color: "#0f0f0f"
        border.color: "#2a2a2a"
        border.width: 1

        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.95

        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        Text {
            id: content

            anchors.centerIn: parent
            text: root.text
            color: "#c8c8c8"
            font.pixelSize: 11
        }
    }
}
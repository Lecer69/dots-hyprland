import QtQuick
import QtQuick.Layouts
import qs.common

// A sink or source; the selected one is the default
Rectangle {
    id: root

    required property var node
    property bool selected: false

    signal clicked()

    implicitHeight: 34
    radius: 8
    color: root.selected ? (root.activeFocus ? Theme.adapt("#262626") : Theme.border)
        : area.containsMouse || root.activeFocus ? Theme.hover : "transparent"

    readonly property bool listRow: true
    activeFocusOnTab: true
    Keys.onUpPressed: KeyNav.step(root, false)
    Keys.onDownPressed: KeyNav.step(root, true)
    Keys.onSpacePressed: root.clicked()
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 12

        Rectangle {
            width: 8
            height: 8
            radius: 4
            color: root.selected ? Theme.text : Theme.adapt("#3a3a3a")
        }

        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: root.node.description || root.node.nickname || root.node.name
            color: root.selected ? Theme.adapt("#ffffff") : Theme.text
            font.pixelSize: 13
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

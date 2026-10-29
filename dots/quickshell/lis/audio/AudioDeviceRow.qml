import QtQuick
import QtQuick.Layouts

// A sink or source; the selected one is the default
Rectangle {
    id: root

    required property var node
    property bool selected: false

    signal clicked()

    implicitHeight: 34
    radius: 8
    color: root.selected ? "#1f1f1f" : area.containsMouse ? "#161616" : "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 12

        Rectangle {
            width: 8
            height: 8
            radius: 4
            color: root.selected ? "#e6e6e6" : "#3a3a3a"
        }

        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: root.node.description || root.node.nickname || root.node.name
            color: root.selected ? "#ffffff" : "#e6e6e6"
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

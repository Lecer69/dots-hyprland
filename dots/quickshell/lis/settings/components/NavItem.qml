import QtQuick
import qs.settings.data
import qs.settings.pages
import qs.settings
import qs.common

Rectangle {
    id: root
    property string label: ""
    property bool active: false
    // Lights the active item a step brighter
    property bool focused: false
    signal clicked

    implicitHeight: 32
    radius: 6
    color: active ? (focused ? Theme.adapt("#2a2a2a") : Theme.border)
         : hoverArea.containsMouse ? Theme.hover
         : "transparent"

    Text {
        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
        text: root.label
        font.pixelSize: 13
        color: root.active ? Theme.adapt("#ffffff")
             : hoverArea.containsMouse ? Theme.adapt("#cccccc")
             : Theme.adapt("#808080")
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
